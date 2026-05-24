//
//  HomeView.swift
//  Reynard
//
//  Created by Minh Ton on 5/24/26.
//

import UIKit

protocol HomeViewDelegate: AnyObject {
    func homeViewDidTapSearchHint(_ homeView: HomeView)
    func homeView(_ homeView: HomeView, didTapQuickLink url: String)
}

/// Native Reynard start page shown when the selected tab has no URL.
///
/// Sits in front of GeckoView at full size and is hidden the moment a URL
/// commits, so it never competes with web content for hit testing.
final class HomeView: UIView {

    // MARK: - Quick Link Definitions

    /// A predefined site shown in the quick-link grid. Brand colors are
    /// approximated so each tile is visually distinct without bundling
    /// any external logo assets.
    private struct QuickLink {
        let title: String
        let monogram: String
        let url: String
        let backgroundColor: UIColor
    }

    private static let quickLinks: [QuickLink] = [
        QuickLink(title: "Google", monogram: "G",
                  url: "https://www.google.com",
                  backgroundColor: UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)),
        QuickLink(title: "Bing", monogram: "B",
                  url: "https://www.bing.com",
                  backgroundColor: UIColor(red: 0.00, green: 0.47, blue: 0.55, alpha: 1.0)),
        QuickLink(title: "Wikipedia", monogram: "W",
                  url: "https://www.wikipedia.org",
                  backgroundColor: UIColor(red: 0.20, green: 0.20, blue: 0.23, alpha: 1.0)),
        QuickLink(title: "GitHub", monogram: "G",
                  url: "https://github.com",
                  backgroundColor: UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1.0)),
        QuickLink(title: "YouTube", monogram: "Y",
                  url: "https://www.youtube.com",
                  backgroundColor: UIColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 1.0)),
        QuickLink(title: "X", monogram: "X",
                  url: "https://x.com",
                  backgroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)),
    ]

    // MARK: - Public

    weak var delegate: HomeViewDelegate?

    // MARK: - Subviews

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 28
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.text = "Reynard"
        label.font = UIFont.systemFont(ofSize: 44, weight: .heavy)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.text = "Gecko-powered, on iOS."
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    /// Pill-shaped fake search field. Tapping it just focuses the real
    /// address bar — we don't manage any editable state here.
    private lazy var searchPill: UIControl = {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.tertiarySystemBackground
                : UIColor.systemBackground
        }
        control.layer.cornerCurve = .continuous
        control.layer.cornerRadius = 22
        control.layer.shadowColor = UIColor.black.cgColor
        control.layer.shadowOpacity = 0.08
        control.layer.shadowOffset = CGSize(width: 0, height: 2)
        control.layer.shadowRadius = 8
        control.addTarget(self, action: #selector(searchPillTapped), for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .secondaryLabel
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false

        let placeholder = UILabel()
        placeholder.text = "Search or enter website"
        placeholder.textColor = .secondaryLabel
        placeholder.font = .systemFont(ofSize: 16, weight: .regular)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.isUserInteractionEnabled = false

        control.addSubview(icon)
        control.addSubview(placeholder)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            placeholder.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            placeholder.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            placeholder.trailingAnchor.constraint(lessThanOrEqualTo: control.trailingAnchor, constant: -12),
            control.heightAnchor.constraint(equalToConstant: 44),
        ])
        return control
    }()

    private lazy var quickLinkGrid: UIStackView = makeQuickLinkGrid()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        backgroundColor = .systemGroupedBackground

        let brandStack = UIStackView(arrangedSubviews: [brandLabel, taglineLabel])
        brandStack.axis = .vertical
        brandStack.alignment = .center
        brandStack.spacing = 6

        contentStack.addArrangedSubview(brandStack)
        contentStack.addArrangedSubview(searchPill)
        contentStack.setCustomSpacing(36, after: searchPill)
        contentStack.addArrangedSubview(quickLinkGrid)

        addSubview(contentStack)

        NSLayoutConstraint.activate([
            // Vertical center, slightly biased toward the top third.
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            // Search pill is narrower than the full stack so it sits like a
            // little iOS Spotlight bar.
            searchPill.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            searchPill.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.92),
        ])

        applyBrandGradient()
    }

    // MARK: - Branding

    /// Renders the "Reynard" wordmark using a warm orange→pink gradient that
    /// matches the app icon. The gradient mask is re-applied whenever the
    /// label's bounds change.
    private func applyBrandGradient() {
        // Trigger an initial sizing pass so `brandLabel.bounds` is non-zero
        // when we ask for the gradient image.
        brandLabel.sizeToFit()
        guard brandLabel.bounds.width > 0 else { return }

        let renderer = UIGraphicsImageRenderer(size: brandLabel.bounds.size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let colors = [
                UIColor(red: 0.98, green: 0.45, blue: 0.21, alpha: 1.0).cgColor,
                UIColor(red: 0.94, green: 0.31, blue: 0.51, alpha: 1.0).cgColor,
            ] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 1.0]
            ) else { return }
            cg.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: brandLabel.bounds.width, y: brandLabel.bounds.height),
                options: []
            )
        }
        brandLabel.textColor = UIColor(patternImage: image)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyBrandGradient()
    }

    // MARK: - Quick Link Grid

    private func makeQuickLinkGrid() -> UIStackView {
        let columnsPerRow = 3
        let rows = stride(from: 0, to: Self.quickLinks.count, by: columnsPerRow).map { rowStart in
            let slice = Array(Self.quickLinks[rowStart..<min(rowStart + columnsPerRow, Self.quickLinks.count)])
            let row = UIStackView(arrangedSubviews: slice.enumerated().map { offset, link in
                makeQuickLinkButton(for: link, tag: rowStart + offset)
            })
            row.axis = .horizontal
            row.alignment = .top
            row.distribution = .equalSpacing
            row.spacing = 16
            return row
        }
        let grid = UIStackView(arrangedSubviews: rows)
        grid.axis = .vertical
        grid.alignment = .center
        grid.spacing = 18
        grid.translatesAutoresizingMaskIntoConstraints = false
        return grid
    }

    private func makeQuickLinkButton(for link: QuickLink, tag: Int) -> UIView {
        let container = UIControl()
        container.tag = tag
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addTarget(self, action: #selector(quickLinkTapped(_:)), for: .touchUpInside)

        let badge = UIView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.backgroundColor = link.backgroundColor
        badge.layer.cornerCurve = .continuous
        badge.layer.cornerRadius = 16
        badge.layer.shadowColor = UIColor.black.cgColor
        badge.layer.shadowOpacity = 0.10
        badge.layer.shadowOffset = CGSize(width: 0, height: 3)
        badge.layer.shadowRadius = 6
        badge.isUserInteractionEnabled = false

        let monogram = UILabel()
        monogram.translatesAutoresizingMaskIntoConstraints = false
        monogram.text = link.monogram
        monogram.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        monogram.textColor = .white
        monogram.textAlignment = .center
        monogram.isUserInteractionEnabled = false

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = link.title
        title.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        title.textColor = .secondaryLabel
        title.textAlignment = .center
        title.isUserInteractionEnabled = false

        container.addSubview(badge)
        badge.addSubview(monogram)
        container.addSubview(title)

        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: container.topAnchor),
            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.widthAnchor.constraint(equalToConstant: 58),
            badge.heightAnchor.constraint(equalToConstant: 58),
            monogram.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            monogram.centerYAnchor.constraint(equalTo: badge.centerYAnchor, constant: -1),
            title.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            title.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 76),
        ])

        // Press-down feedback.
        container.addTarget(self, action: #selector(quickLinkTouchDown(_:)), for: .touchDown)
        container.addTarget(self, action: #selector(quickLinkTouchUp(_:)),
                            for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return container
    }

    // MARK: - Actions

    @objc private func searchPillTapped() {
        delegate?.homeViewDidTapSearchHint(self)
    }

    @objc private func quickLinkTapped(_ sender: UIControl) {
        guard Self.quickLinks.indices.contains(sender.tag) else { return }
        let link = Self.quickLinks[sender.tag]
        delegate?.homeView(self, didTapQuickLink: link.url)
    }

    @objc private func quickLinkTouchDown(_ sender: UIControl) {
        UIView.animate(
            withDuration: 0.08, delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseIn]
        ) {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            sender.alpha = 0.7
        }
    }

    @objc private func quickLinkTouchUp(_ sender: UIControl) {
        UIView.animate(
            withDuration: 0.18, delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]
        ) {
            sender.transform = .identity
            sender.alpha = 1
        }
    }
}
