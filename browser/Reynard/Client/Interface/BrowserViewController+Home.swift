//
//  BrowserViewController+Home.swift
//  Reynard
//
//  Created by Minh Ton on 5/24/26.
//

import GeckoView
import UIKit

extension BrowserViewController: HomeViewDelegate {

    /// Wires up the native start page. Call once from `viewDidLoad` after
    /// `browserUI.configureLayout()` so the HomeView is in the hierarchy.
    func setupHomeView() {
        browserUI.homeView.delegate = self
        refreshHomeViewVisibility()
    }

    /// Show HomeView whenever the active tab hasn't navigated anywhere
    /// meaningful yet. We treat empty, nil, and the about:blank family as
    /// "on the start page" — anything else is real web content.
    func refreshHomeViewVisibility() {
        let url = tabManager.selectedTab?.url?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let isOnHome = url == nil
            || url?.isEmpty == true
            || url == "about:blank"
            || url?.hasPrefix("about:blank?") == true
        browserUI.homeView.isHidden = !isOnHome
    }

    // MARK: - HomeViewDelegate

    func homeViewDidTapSearchHint(_ homeView: HomeView) {
        // Focusing the address bar opens the keyboard exactly like the user
        // tapped it directly; no extra animations needed because
        // setSearchFocused already coordinates the chrome transitions.
        setSearchFocused(true, animated: true)
        browserUI.addressBar.becomeFirstResponder()
    }

    func homeView(_ homeView: HomeView, didTapQuickLink url: String) {
        guard let tab = tabManager.selectedTab else { return }
        // Load into the current (empty) tab rather than opening a new one —
        // this matches the iOS Safari start-page behavior where tapping a
        // favorite navigates the active tab.
        tab.session.load(url)
        // Optimistically hide the home view; the location-changed callback
        // will reconcile if the navigation is cancelled.
        browserUI.homeView.isHidden = true
    }
}
