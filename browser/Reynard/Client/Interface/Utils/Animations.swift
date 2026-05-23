//
//  Animations.swift
//  Reynard
//
//  Created by Minh Ton on 5/23/26.
//

import UIKit

// MARK: - Animation Helpers

/// Central animation helpers that honor the "Reduce Motion" accessibility
/// preference, provide consistent timing curves, and integrate haptic
/// feedback for key interactions.
enum Animations {

    /// Standard duration presets used throughout the browser UI.
    /// Each value collapses to ~0 (instant apply) when Reduce Motion is on,
    /// so users with vestibular sensitivities never see flying or scaling.
    enum Duration {
        static var instant: TimeInterval { adjusted(0.10) }
        static var quick: TimeInterval { adjusted(0.18) }
        static var standard: TimeInterval { adjusted(0.24) }
        static var moderate: TimeInterval { adjusted(0.35) }
        static var slow: TimeInterval { adjusted(0.45) }
        static var presentation: TimeInterval { adjusted(0.60) }

        static func adjusted(_ duration: TimeInterval) -> TimeInterval {
            UIAccessibility.isReduceMotionEnabled ? min(0.001, duration) : duration
        }
    }

    /// Curated spring parameters. iOS native UIs use ~0.8 damping with a
    /// gentle initial velocity for most modal presentations.
    enum Spring {
        /// Snappy, low-overshoot — for tab bar reorders, button feedback.
        static let snappy: (damping: CGFloat, velocity: CGFloat) = (0.9, 0.5)
        /// Standard interactive bounce — for sheet & overview presentations.
        static let standard: (damping: CGFloat, velocity: CGFloat) = (0.82, 0.8)
        /// Playful overshoot — for celebratory or attention-grabbing moments.
        static let bouncy: (damping: CGFloat, velocity: CGFloat) = (0.7, 1.2)
        /// Very stiff — for incremental layout updates that need to feel solid.
        static let crisp: (damping: CGFloat, velocity: CGFloat) = (0.95, 0.3)
    }

    /// True when system motion preferences allow non-instantaneous animations.
    static var motionEnabled: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }

    /// Runs a UIView.animate block with the given duration, falling back to
    /// instant apply if Reduce Motion is on. The completion still fires so
    /// downstream state updates always run.
    @discardableResult
    static func run(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = [.curveEaseOut],
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> Bool {
        guard motionEnabled else {
            animations()
            completion?(true)
            return false
        }
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: options,
            animations: animations,
            completion: completion
        )
        return true
    }

    /// Runs a spring animation with the given preset.
    @discardableResult
    static func spring(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        damping: CGFloat,
        velocity: CGFloat,
        options: UIView.AnimationOptions = [.curveEaseInOut],
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> Bool {
        guard motionEnabled else {
            animations()
            completion?(true)
            return false
        }
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: options,
            animations: animations,
            completion: completion
        )
        return true
    }
}

// MARK: - Haptic Feedback

/// Centralized haptic palette. Generators are cached and prepared on demand
/// so the first tap of a session never feels delayed.
enum Haptics {
    private static let lightImpact: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    private static let mediumImpact: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    private static let rigidImpact: UIImpactFeedbackGenerator = {
        let generator: UIImpactFeedbackGenerator
        if #available(iOS 13.0, *) {
            generator = UIImpactFeedbackGenerator(style: .rigid)
        } else {
            generator = UIImpactFeedbackGenerator(style: .medium)
        }
        generator.prepare()
        return generator
    }()
    private static let selection: UISelectionFeedbackGenerator = {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        return generator
    }()
    private static let notification: UINotificationFeedbackGenerator = {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }()

    /// Light tap — for subtle confirmations such as toggling a setting.
    static func light() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium impact — for switching tabs, dismissing modals, etc.
    static func medium() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Sharp impact — for snapping interactions like docking a card.
    static func rigid() {
        rigidImpact.impactOccurred()
        rigidImpact.prepare()
    }

    /// Selection tick — for moving through a stepper-like control.
    static func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    /// Success notification — for completed downloads or successful saves.
    static func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Warning notification — for risky or destructive confirmations.
    static func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// Error notification — for failures and validation problems.
    static func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
}
