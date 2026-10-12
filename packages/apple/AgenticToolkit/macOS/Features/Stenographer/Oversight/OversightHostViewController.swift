import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// The AI Oversight window's content: a Findings | Scripts switcher over the
/// findings list (what oversight recorded) and the scripts editor (what it runs).
@MainActor
final class OversightHostViewController: NSViewController {

    private let segmented = NSSegmentedControl(
        labels: ["Findings", "Scripts"], trackingMode: .selectOne, target: nil, action: nil
    )
    private let container = NSView()
    private let findingsVC: OversightFindingsViewController
    private let scriptsVC: OversightScriptsViewController
    private var shownVC: NSViewController?

    private var themeObserver: ThemePaletteObserver?

    init(service: any StenographerDaemonService) {
        self.findingsVC = OversightFindingsViewController(service: service)
        self.scriptsVC = OversightScriptsViewController(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Forwards the findings tab's title-bar config gear so the window controller can
    /// hoist it into the title bar. The gear is window-level (oversight config), so a
    /// single accessory serves both the Findings and Scripts tabs.
    func makeTitlebarAccessory() -> NSTitlebarAccessoryViewController {
        findingsVC.makeTitlebarAccessory()
    }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 860, height: 460))
        root.wantsLayer = true

        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.target = self
        segmented.action = #selector(segmentChanged)
        segmented.selectedSegment = 0

        container.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(segmented)
        root.addSubview(container)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            segmented.centerXAnchor.constraint(equalTo: root.centerXAnchor),

            container.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        themeObserver = ThemePaletteObserver { [weak self] palette in
            self?.view.layer?.backgroundColor = palette.windowBackgroundColor.cgColor
        }
        show(findingsVC)
    }

    @objc private func segmentChanged() {
        show(segmented.selectedSegment == 0 ? findingsVC : scriptsVC)
    }

    private func show(_ viewController: NSViewController) {
        guard viewController !== shownVC else { return }
        shownVC?.view.removeFromSuperview()
        shownVC.map { $0.removeFromParent() }
        addChild(viewController)
        let child = viewController.view
        child.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: container.topAnchor),
            child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        shownVC = viewController
    }
}
