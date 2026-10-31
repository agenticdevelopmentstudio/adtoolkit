import AppKit

import AgenticToolkitCore

/// The Coding Partner's settings: one sidebar topic with General, Jobs, Attention and Code Reviews tabs.
@MainActor
public enum PartnerSettingsPanel {

    public static func make(controller: PartnerController,
                            projects: @escaping @MainActor () -> [PartnerToolSource.Project] = { [] })
        -> ComposableSettings.SectionTabsPanel {
        let panel = ComposableSettings.SectionTabsPanel(
            section: "Coding Partner",
            icon: NSImage(systemSymbolName: "person.2.wave.2", accessibilityDescription: nil))
        // Reading the jobs seeds the built-in ones, so the Jobs tab has something to show on a fresh install.
        _ = controller.jobs()
        let editor = PartnerJobsEditorModel(
            store: controller.store, guidelines: PartnerGuidelinesInstaller(paths: controller.paths))
        panel.setPanels([
            PartnerGeneralSettingsViewController(controller: controller),
            PartnerJobsSettingsViewController(controller: controller, model: editor),
            PartnerAttentionSettingsViewController(),
            PartnerCodeReviewsSettingsViewController(store: controller.store, projects: projects)
        ])
        return panel
    }
}
