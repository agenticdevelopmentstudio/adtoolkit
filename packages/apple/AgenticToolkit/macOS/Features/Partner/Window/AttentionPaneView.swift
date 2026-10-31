import SwiftUI
import AgenticToolkitCore

/// The "Needs you" pane: what the partner is waiting on the owner for, then
/// what was settled recently. One card per attention item.
public struct AttentionPaneView: View {
    @ObservedObject var model: AttentionPaneModel

    public init(model: AttentionPaneModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                section("Needs you", items: model.open, empty: "Nothing needs you.")
                if !model.done.isEmpty {
                    section("Done", items: model.done, empty: nil)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("partner.attention")
    }

    @ViewBuilder
    private func section(_ title: String, items: [AttentionItem], empty: String?) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 4)
        if items.isEmpty, let empty {
            Text(empty)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        ForEach(items) { item in
            AttentionCard(item: item, model: model)
        }
    }
}

/// One attention item: its kind, its text, what it refers to, and the one thing the owner can do about it.
struct AttentionCard: View {
    let item: AttentionItem
    let model: AttentionPaneModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.kind.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Self.color(for: item.kind))
                Spacer()
                Text(item.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(item.text)
                .font(.callout)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if let label = Self.referenceLabel(item.reference) {
                Button(label) { model.onOpenReference?(item.reference) }
                    .buttonStyle(.link)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            HStack {
                Spacer()
                actionView
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Self.color(for: item.kind).opacity(item.state == .done ? 0.05 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Self.color(for: item.kind).opacity(0.35))
        )
        .opacity(item.state == .done ? 0.7 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("partner.attention.\(item.id)")
    }

    @ViewBuilder
    private var actionView: some View {
        let action = model.action(for: item)
        switch action {
        case .discuss: button("Discuss", action)
        case .resolved: button("Resolved", action)
        case .confirm: button("Confirm", action)
        case .sending: ProgressView().controlSize(.small)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Done")
        }
    }

    private func button(_ title: String, _ action: AttentionPaneModel.CardAction) -> some View {
        Button(title) { model.perform(action, on: item) }
            .controlSize(.small)
    }

    static func color(for kind: AttentionKind) -> Color {
        switch kind {
        case .question: return .blue
        case .blocked: return .orange
        case .notification: return .yellow
        }
    }

    /// The reference as one line, preferring the keys that name a thing a person recognises.
    static func referenceLabel(_ reference: [String: String]) -> String? {
        guard !reference.isEmpty else { return nil }
        for key in ["url", "path", "commit", "review_id", "session_id"] {
            if let value = reference[key], !value.isEmpty { return value }
        }
        return reference.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}
