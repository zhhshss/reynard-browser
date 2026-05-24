//
//  TabBarCell.swift
//  Reynard
//
//  Created by Minh Ton on 5/3/26.
//

import UIKit

final class TabBarCell: UICollectionViewCell {
    enum LayoutMode {
        case expanded
        case faviconOnly
    }

    static let reuseIdentifier = "TabBarCell"
    static let expandedMinimumWidth: CGFloat = 220
    static let collapsedMinimumWidth: CGFloat = 96

    private static let fallbackFavicon = UIImage(systemName: "globe")

    var onClose: (() -> Void)?

    // MARK: - Swipe to close (Safari-style vertical flick on tab bar)

    /// Vertical pan distance (in points) past which we treat a release as a
    /// definitive close gesture, irrespective of velocity.
    private let swipeCloseDistanceThreshold: CGFloat = 44
    /// Vertical velocity (points/sec) past which we close even on a short pan.
    private let swipeCloseVelocityThreshold: CGFloat = 700
    private var swipePanGesture: UIPanGestureRecognizer?
    private var swipeAnimator: UIViewPropertyAnimator?
    private lazy var swipeFeedback: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    
    private let faviconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "x.square.fill"), for: .normal)
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 14, weight: .regular),
            forImageIn: .normal
        )
        button.tintColor = .secondaryLabel
        button.isHidden = true
        return button
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        return stackView
    }()
    
    private var titleStackExpandedTrailingConstraint: NSLayoutConstraint!
    private var titleStackCollapsedTrailingConstraint: NSLayoutConstraint!
    private var titleStackExpandedLeadingConstraint: NSLayoutConstraint!
    private var titleStackCollapsedLeadingConstraint: NSLayoutConstraint!
    private var titleLabelExpandedWidthConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 0
        
        contentView.addSubview(titleStackView)
        titleStackView.addArrangedSubview(faviconImageView)
        titleStackView.addArrangedSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(separatorView)
        
        faviconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        faviconImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        faviconImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        titleStackExpandedTrailingConstraint = titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -34)
        titleStackCollapsedTrailingConstraint = titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
        titleStackExpandedLeadingConstraint = titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 10)
        titleStackCollapsedLeadingConstraint = titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8)
        titleLabelExpandedWidthConstraint = titleLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -58)
        
        NSLayoutConstraint.activate([
            titleStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleStackExpandedLeadingConstraint,
            titleStackExpandedTrailingConstraint,
            
            faviconImageView.widthAnchor.constraint(equalToConstant: 16),
            faviconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabelExpandedWidthConstraint,
            
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            closeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 22),
            closeButton.heightAnchor.constraint(equalToConstant: 22),
            
            separatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 2 / UIScreen.main.scale),
        ])

        // Safari-style vertical swipe to dismiss the tab. Attached to the
        // cell itself (not contentView) so the gesture can translate the
        // entire cell even while the collection view tries to scroll.
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeToClose(_:)))
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
        swipePanGesture = pan
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        faviconImageView.image = Self.fallbackFavicon
        titleLabel.isHidden = false
        titleStackView.spacing = 6
        titleStackExpandedLeadingConstraint.isActive = true
        titleStackCollapsedLeadingConstraint.isActive = false
        titleStackExpandedTrailingConstraint.isActive = true
        titleStackCollapsedTrailingConstraint.isActive = false
        titleLabelExpandedWidthConstraint.isActive = true
        onClose = nil
        // Reset any in-flight swipe state so a recycled cell starts clean.
        swipeAnimator?.stopAnimation(true)
        swipeAnimator = nil
        transform = .identity
        alpha = 1
    }
    
    func configure(tab: Tab, selected: Bool, layoutMode: LayoutMode, itemWidth: CGFloat) {
        let displayTitle = tab.title.isEmpty ? Strings.Tabs.homepage : tab.title
        titleLabel.text = displayTitle
        faviconImageView.image = tab.favicon ?? Self.fallbackFavicon
        contentView.backgroundColor = selected ? .systemGray6 : .systemGray5
        titleLabel.textColor = selected ? .label : .secondaryLabel
        faviconImageView.tintColor = selected ? .label : .secondaryLabel
        let minimumVisibleTitle = "WWWWW" as NSString
        let minimumTitleWidth = minimumVisibleTitle.size(withAttributes: [.font: titleLabel.font as Any]).width
        let estimatedTitleBudget = itemWidth - 58
        let isTooNarrowForTitle = estimatedTitleBudget < minimumTitleWidth
        let isCollapsed = layoutMode == .faviconOnly || isTooNarrowForTitle
        
        titleLabel.isHidden = isCollapsed
        titleStackView.spacing = isCollapsed ? 0 : 6
        titleStackExpandedLeadingConstraint.isActive = !isCollapsed
        titleStackCollapsedLeadingConstraint.isActive = isCollapsed
        titleStackExpandedTrailingConstraint.isActive = !isCollapsed
        titleStackCollapsedTrailingConstraint.isActive = isCollapsed
        titleLabelExpandedWidthConstraint.isActive = !isCollapsed
        closeButton.isHidden = isCollapsed || !selected
        separatorView.isHidden = selected
    }
    
    func containsCloseButton(point: CGPoint) -> Bool {
        guard !closeButton.isHidden else {
            return false
        }
        
        let pointInContentView = convert(point, to: contentView)
        return closeButton.frame.contains(pointInContentView)
    }
    
    @objc private func closeTapped() {
        onClose?()
    }

    // MARK: - Swipe to Close

    @objc private func handleSwipeToClose(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)

        switch gesture.state {
        case .began:
            swipeAnimator?.stopAnimation(true)
            swipeAnimator = nil

        case .changed:
            // Allow downward pull more freely than upward (Safari's behavior
            // doesn't dismiss on upward flick from the tab bar). We still
            // visualize upward pulls with a rubber-band feel.
            let dy = translation.y
            let absorbed = dy >= 0 ? dy : dy * 0.35
            transform = CGAffineTransform(translationX: 0, y: absorbed)
            let fade = max(0, min(1, abs(absorbed) / 120))
            alpha = 1 - 0.5 * fade

        case .ended, .cancelled:
            let shouldClose = gesture.state != .cancelled
                && translation.y > 0
                && (translation.y > swipeCloseDistanceThreshold
                    || velocity.y > swipeCloseVelocityThreshold)
            if shouldClose {
                swipeFeedback.impactOccurred()
                let exitOffset = bounds.height + 24
                swipeAnimator = UIViewPropertyAnimator(
                    duration: 0.22,
                    controlPoint1: CGPoint(x: 0.4, y: 0),
                    controlPoint2: CGPoint(x: 1, y: 1)
                )
                swipeAnimator?.addAnimations { [weak self] in
                    guard let self else { return }
                    self.transform = CGAffineTransform(translationX: 0, y: exitOffset)
                    self.alpha = 0
                }
                swipeAnimator?.addCompletion { [weak self] _ in
                    guard let self else { return }
                    self.onClose?()
                    // Reset the cell visually now that the data source has
                    // been asked to remove it. If the close handler keeps
                    // the cell around, it'll be recycled and prepareForReuse
                    // will sanitize state.
                    self.transform = .identity
                    self.alpha = 1
                }
                swipeAnimator?.startAnimation()
            } else {
                // Spring back to rest.
                UIView.animate(
                    withDuration: 0.32,
                    delay: 0,
                    usingSpringWithDamping: 0.75,
                    initialSpringVelocity: 0.4,
                    options: [.beginFromCurrentState, .allowUserInteraction]
                ) { [weak self] in
                    self?.transform = .identity
                    self?.alpha = 1
                }
            }

        default:
            break
        }
    }
}

extension TabBarCell: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              pan === swipePanGesture else {
            return true
        }
        // Only begin a swipe-to-close gesture when the user's initial motion
        // is more vertical than horizontal. This leaves horizontal pans for
        // the collection view's own scrolling.
        let velocity = pan.velocity(in: self)
        return abs(velocity.y) > abs(velocity.x) && abs(velocity.y) > 80
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // We've already required vertical primacy in `shouldBegin`, so we
        // never need to share the recognizer with the horizontal scrolling
        // collection view.
        false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Let the close button's tap recognizer win over our pan.
        otherGestureRecognizer.view === closeButton
    }
}
