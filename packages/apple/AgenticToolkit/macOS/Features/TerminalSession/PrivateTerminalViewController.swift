import AppKit
import Combine
import SwiftTerm

import AgenticToolkitCore
import AgenticToolkitCoreMacOS
import AgenticToolkitCoreUI

/// A terminal pane whose contents stay private: one shell behind the privacy
/// words, under a privacy screen until the user authenticates.
///
/// - **The privacy screen** is up by default and goes back up whenever the
///   user asks. Lifting it takes the eye on the screen, or the eye in the
///   title bar, and the Mac owner's authentication every time.
/// - **The privacy words** are the vault's, read from the keychain only after
///   authentication. The shell starts when the pane first appears, as any
///   terminal does — but only once the words are in memory, because with none
///   known nothing it printed could be concealed. So appearing unlocks the
///   vault (one prompt, and none if another pane already unlocked it), and the
///   privacy screen stays up: starting is not showing.
/// - **Nothing outside the app can read it.** The terminal sits inside a
///   ``ConcealedContainerView``, so accessibility clients and screen readers
///   find no element there, a scripted view dump stops at it, and while it is
///   revealed the window is excluded from screen capture. There is no
///   AppleScript object for it and no URL that opens it.
///
/// The words are edited from the pane's options: Edit Privacy Words… asks for
/// authentication and opens ``PrivacyWordsEditor``.
@MainActor
public final class PrivateTerminalViewController: NSViewController {

    public let session: TerminalSession
    private let vault: PrivacyWordsVault

    private let concealed = ConcealedContainerView()
    private let privacyScreen = ThemedBackgroundView(role: .windowBackground)
    private let screenMessage = ThemedLabel(role: .secondaryText, textRole: .body)
    private var paddingConstraints: (
        top: NSLayoutConstraint,
        leading: NSLayoutConstraint,
        bottom: NSLayoutConstraint,
        trailing: NSLayoutConstraint
    )?
    private var themeObserver: ThemePaletteObserver?
    private var cancellables = Set<AnyCancellable>()
    /// An authentication is on screen, so a second click does not stack another.
    private var isAuthenticating = false
    /// The pane has appeared and asked to start, so reappearing after a
    /// cancelled prompt does not ask again — the eye is there for that.
    private var hasAskedToStart = false

    /// Whether the contents are on screen.
    public private(set) var isRevealed = false {
        didSet { applyRevealState() }
    }

    public init(vault: PrivacyWordsVault, workingDirectory: String?) {
        self.vault = vault
        session = TerminalSession(name: "Private Terminal", workingDirectory: workingDirectory, isPrivate: true)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Views

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.frame = NSRect(x: 0, y: 0, width: 800, height: 600)

        concealed.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(concealed)
        pin(concealed, to: container)

        let terminalView = session.terminalView
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        concealed.addSubview(terminalView)
        let constraints = (
            top: terminalView.topAnchor.constraint(equalTo: concealed.topAnchor),
            leading: terminalView.leadingAnchor.constraint(equalTo: concealed.leadingAnchor),
            bottom: concealed.bottomAnchor.constraint(equalTo: terminalView.bottomAnchor),
            trailing: concealed.trailingAnchor.constraint(equalTo: terminalView.trailingAnchor)
        )
        paddingConstraints = constraints
        NSLayoutConstraint.activate([constraints.top, constraints.leading, constraints.bottom, constraints.trailing])

        // Outside the concealed container, on top of it: the screen hides
        // nothing worth hiding from a screen reader, and its eye has to be
        // reachable by one to be pressed.
        buildPrivacyScreen()
        privacyScreen.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(privacyScreen)
        pin(privacyScreen, to: container)

        view = container
        applyRevealState()
    }

    private func buildPrivacyScreen() {
        let eye = NSButton(
            image: Self.symbol("eye.slash", pointSize: 48, description: "Show the private terminal"),
            target: self, action: #selector(revealPressed(_:)))
        eye.isBordered = false
        eye.toolTip = "Show the private terminal"
        eye.setAccessibilityLabel("Show the private terminal")
        eye.accessibilityID("privateTerminal.reveal")

        screenMessage.alignment = .center
        screenMessage.cell?.wraps = true
        screenMessage.cell?.usesSingleLineMode = false
        screenMessage.lineBreakMode = .byWordWrapping

        let stack = NSStackView(views: [eye, screenMessage])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        privacyScreen.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: privacyScreen.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: privacyScreen.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: privacyScreen.leadingAnchor, constant: 20),
            screenMessage.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Another private terminal can unlock the words, and the editor can
        // change them: a shell already running takes the new words from the
        // next byte. One that has not started waits for its own unlock.
        vault.$filter
            .receive(on: RunLoop.main)
            .sink { [weak self] filter in
                guard let self, let filter, self.session.isStarted || self.hasAskedToStart else { return }
                self.startOrUpdate(filter: filter)
            }
            .store(in: &cancellables)

        UserSettings.shared.changes
            .filter { TerminalAppearance.settingKeys.contains($0) }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.reapplyAppearance() }
            .store(in: &cancellables)

        themeObserver = ThemePaletteObserver(host: view) { [weak self] palette in
            self?.applyAppearance(palette: palette)
        }
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        startWhenVisible()
    }

    // MARK: - Starting

    /// Starts the shell the first time the pane is on screen, unlocking the
    /// words to do it. A cancelled prompt leaves the pane waiting for its eye.
    private func startWhenVisible() {
        guard !session.isStarted, !hasAskedToStart else { return }
        hasAskedToStart = true
        if let filter = vault.filter { return startOrUpdate(filter: filter) }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.vault.unlock(reason: "start the private terminal")
                if let filter = self.vault.filter { self.startOrUpdate(filter: filter) }
            } catch {
                self.screenMessage.stringValue = error.localizedDescription
            }
        }
    }

    /// Hands the session its words — which starts the shell the first time —
    /// and tells anything waiting to connect that there is now a terminal.
    private func startOrUpdate(filter: TextSubstitutionFilter) {
        let wasStarted = session.isStarted
        session.privacyFilter = filter
        guard !wasStarted, session.isStarted else { return }
        applyRevealState()
        NotificationCenter.default.post(name: .terminalPaneConnectableDidChange, object: self)
    }

    // MARK: - Revealing

    @objc private func revealPressed(_ sender: Any?) {
        reveal()
    }

    @objc private func toggleRevealPressed(_ sender: Any?) {
        if isRevealed { hide() } else { reveal() }
    }

    /// Asks for authentication and, on success, lifts the privacy screen —
    /// starting the shell the first time.
    public func reveal() {
        guard !isRevealed, !isAuthenticating else { return }
        isAuthenticating = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isAuthenticating = false }
            do {
                try await self.vault.authenticate(reason: "show the private terminal")
                if let filter = self.vault.filter { self.startOrUpdate(filter: filter) }
                self.isRevealed = true
            } catch {
                self.screenMessage.stringValue = error.localizedDescription
            }
        }
    }

    /// Puts the privacy screen back up. No authentication: hiding is always allowed.
    public func hide() {
        isRevealed = false
    }

    private func applyRevealState() {
        guard isViewLoaded else { return }
        privacyScreen.isHidden = isRevealed
        session.terminalView.isHidden = !isRevealed
        concealed.isRevealed = isRevealed
        screenMessage.stringValue = session.isStarted
            ? "Click the eye to show this terminal."
            : "Click the eye to start this private terminal."

        let terminalView = session.terminalView
        if isRevealed {
            DispatchQueue.main.async { [weak terminalView] in
                terminalView?.window?.makeFirstResponder(terminalView)
            }
        } else if let window = view.window, let responder = window.firstResponder as? NSView,
                  responder.isDescendant(of: concealed) {
            // Keystrokes must not keep going into a terminal nobody can see.
            window.makeFirstResponder(nil)
        }
        (parent as? PaneViewController)?.refreshAccessories()
    }

    // MARK: - The privacy words

    @objc private func editWordsPressed(_ sender: Any?) {
        (parent as? PaneViewController)?.dismissOptionsDialog()
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isAuthenticating = false }
            do {
                try await self.vault.authenticate(reason: "edit the privacy words")
                guard let window = self.view.window else { return }
                PrivacyWordsEditor.present(vault: self.vault, on: window)
            } catch {
                guard let window = self.view.window else { return }
                let alert = NSAlert()
                alert.messageText = "The privacy words could not be opened."
                alert.informativeText = error.localizedDescription
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
        }
    }

    // MARK: - Appearance

    private func reapplyAppearance() {
        applyAppearance(palette: view.resolvedThemeScope.palette)
    }

    private func applyAppearance(palette: SemanticPalette) {
        if let paddingConstraints {
            let padding = TerminalAppearance.resolvedPadding(theme: palette.theme)
            paddingConstraints.top.constant = padding.top
            paddingConstraints.leading.constant = padding.leading
            paddingConstraints.bottom.constant = padding.bottom
            paddingConstraints.trailing.constant = padding.trailing
        }
        TerminalAppearance.apply(to: session.terminalView, palette: palette)
    }

    private func pin(_ subview: NSView, to container: NSView) {
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: container.topAnchor),
            subview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.bottomAnchor.constraint(equalTo: subview.bottomAnchor),
            container.trailingAnchor.constraint(equalTo: subview.trailingAnchor)
        ])
    }

    private static func symbol(_ name: String, pointSize: CGFloat, description: String) -> NSImage {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: description) ?? NSImage()
        return image.withSymbolConfiguration(.init(pointSize: pointSize, weight: .regular)) ?? image
    }
}

extension PrivateTerminalViewController: PaneAccessoryProviding {

    /// The eye beside the gear: shows the terminal (after authentication) or
    /// hides it again.
    public func makePaneAccessoryViews() -> [NSView] {
        let title = isRevealed ? "Hide the private terminal" : "Show the private terminal"
        let button = NSButton(
            image: Self.symbol(isRevealed ? "eye" : "eye.slash", pointSize: 13, description: title),
            target: self, action: #selector(toggleRevealPressed(_:)))
        button.isBordered = false
        button.toolTip = title
        button.setAccessibilityLabel(title)
        button.accessibilityID("privateTerminal.toggleVisibility")
        return [button]
    }
}

extension PrivateTerminalViewController: PaneOptionsProviding {

    public func makePaneOptionRows() -> [NSView] {
        let edit = NSButton(title: "Edit Privacy Words…", target: self, action: #selector(editWordsPressed(_:)))
        edit.bezelStyle = .rounded
        edit.accessibilityID("privateTerminal.options.editWords")

        let note = NSTextField(wrappingLabelWithString:
            "The words this terminal shows in place of the real ones. Kept in the "
            + "keychain; opening them asks you to authenticate.")
        note.textColor = .secondaryLabelColor
        note.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true

        let stack = NSStackView(views: [edit, note])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        return [stack]
    }
}

extension PrivateTerminalViewController: TerminalPaneConnectable {
    /// Offered once the shell is running; until the words are unlocked there
    /// is nothing to type into.
    public var connectableTerminal: TerminalSession? { session.isStarted ? session : nil }
}

extension PrivateTerminalViewController: PaneContentTeardown {
    public func paneContentWillBeDiscarded() {
        session.terminateProcess()
    }
}

extension PrivateTerminalViewController: PaneContentRemovalConfirmation {
    public var removalConfirmationMessage: String? {
        session.isStarted && session.state == .running
            ? "This pane has a running private terminal session. Removing the pane ends it."
            : nil
    }
}
