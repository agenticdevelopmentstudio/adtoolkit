import Foundation
import AgenticToolkitCore

/// Turns: one inbound event at a time, each ended by claude's `result`, or by the turn timeout.
extension PartnerController {

    /// Queues `inbound` and starts it at once if the partner is idle.
    public func enqueue(_ inbound: PartnerInbound) {
        queue.enqueue(inbound)
        setQueuedCount(queue.count)
        runNextTurnIfIdle()
    }

    /// Tells the partner the app is quitting, gives it up to ten seconds to answer, then stops it.
    public func prepareForQuit() async {
        if state == .idle || state == .thinking {
            let ending = sessions.sessions.map(\.id.uuidString)
            queue.enqueueFirst(.lifecycle(.willQuit(endingSessions: ending)))
            setQueuedCount(queue.count)
            quitTurnFinished = false
            runNextTurnIfIdle()
            let deadline = Date().addingTimeInterval(10)
            while !quitTurnFinished, process != nil, Date() < deadline {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        await stop()
    }

    /// Starts the next queued turn when nothing is in flight.
    func runNextTurnIfIdle() {
        guard state == .idle, let process, let inbound = queue.next() else { return }
        setQueuedCount(queue.count)
        currentInbound = inbound

        let attribution = inbound.attribution
        var messageID = UUID().uuidString
        if let source = attribution?.sourceID, let preset = presetMessageIDs.removeValue(forKey: source) {
            messageID = preset
            awaitingDone.append(String(source.dropFirst(Self.attentionSourcePrefix.count)))
        }
        let message = ChatMessage(id: messageID, role: .user, text: inbound.text, timestamp: now(),
                                  attribution: attribution)
        do { try store.append(message) } catch {
            Self.logger.error("Saving a partner message failed: \(error.localizedDescription)")
        }
        chatSession.noteUserMessage(message)
        chatSession.setState(.responding)
        setState(.thinking)
        startTurnTimeout()

        let text = inbound.text
        Task {
            do { try await process.send(text) } catch {
                // A write that fails means the process is gone; the reader's end reports it.
                Self.logger.error("Sending to the partner failed: \(error.localizedDescription)")
            }
        }
    }

    /// One decoded message from the current process.
    func handle(_ message: ClaudeStreamMessage, generation: Int) {
        guard generation == self.generation else { return }
        processSpoke = true
        if !sessionEstablished, let sessionID = configuration?.sessionID {
            sessionEstablished = true
            do { try store.setSessionID(sessionID) } catch {
                Self.logger.error("Saving the partner session id failed: \(error.localizedDescription)")
            }
        }
        for reply in chatSession.apply(message) {
            do { try store.append(reply) } catch {
                Self.logger.error("Saving a partner reply failed: \(error.localizedDescription)")
            }
        }
        completeAwaitedItems()
        if message.kind == .result {
            timeoutTask?.cancel()
            timeoutTask = nil
            if case .lifecycle(.willQuit) = currentInbound { quitTurnFinished = true }
            currentInbound = nil
            setState(.idle)
            runNextTurnIfIdle()
        }
    }

    // MARK: - Abandoning a turn

    func startTurnTimeout() {
        timeoutTask?.cancel()
        let duration = turnTimeout?() ?? .seconds(settings.get(UserSettings.partnerTurnTimeoutMinutes) * 60)
        let generation = generation
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await self?.abandonTurn(generation: generation, timedOut: true)
        }
    }

    /// The owner's stop button: ends the turn in flight the way a timeout does, without a notice.
    func interruptTurn() async {
        await abandonTurn(generation: generation, timedOut: false)
    }

    /// Kills the process mid-turn and resumes the same session in a new one. A timeout also records an
    /// attention item and tells the partner, ahead of anything queued, that its turn was cut off.
    private func abandonTurn(generation: Int, timedOut: Bool) async {
        guard !isRelaunching, generation == self.generation, state == .thinking,
              let process, var configuration else { return }
        // A `result` that cancelled the timeout after it woke has already ended this turn.
        if timedOut, Task.isCancelled { return }
        isRelaunching = true
        defer { isRelaunching = false }
        // A timeout runs inside `timeoutTask`; cancelling it would cancel the relaunch below.
        if !timedOut { timeoutTask?.cancel() }
        timeoutTask = nil
        self.generation += 1
        let token = self.generation
        await process.terminate()
        await readerTask?.value
        guard token == self.generation else { return }  // stopped or restarted meanwhile
        currentInbound = nil
        // Closes the turn in the chat the way an error result would: turnFailed, then ready.
        _ = chatSession.apply(ClaudeStreamMessage(
            kind: .result, isError: true, resultText: timedOut ? "The turn timed out." : "Interrupted."))
        if timedOut {
            do {
                try notifier.notify(title: "Partner turn timed out",
                                    body: "The turn ran past its time limit; the session was resumed.",
                                    createdBy: Self.createdBy)
            } catch {
                Self.logger.error("Recording a partner timeout failed: \(error.localizedDescription)")
            }
        }
        configuration.resume = sessionEstablished
        do {
            try await launch(configuration)
        } catch is CancellationError {
            return  // A stop or restart overtook the relaunch and owns the state now.
        } catch {
            self.process = nil
            tearDown()
            releaseLock()
            fail("could not relaunch claude: \(error.localizedDescription)", notify: true)
            return
        }
        if timedOut {
            queue.enqueueFirst(.lifecycle(.turnTimedOut))
            setQueuedCount(queue.count)
        }
        setState(.idle)
        runNextTurnIfIdle()
    }

    static let attentionSourcePrefix = "attention:"
}
