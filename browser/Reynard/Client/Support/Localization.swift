//
//  Localization.swift
//  Reynard
//
//  Created by Minh Ton on 5/23/26.
//

import Foundation

// MARK: - Localization Helper

/// Shorthand for NSLocalizedString that fetches strings from the default Localizable.strings table.
/// Provides automatic Reynard bundle resolution and an inline default value for safety.
@inline(__always)
func L(_ key: String, comment: String = "") -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: comment)
}

/// Format helper for parameterized localized strings.
@inline(__always)
func L(_ key: String, _ args: CVarArg..., comment: String = "") -> String {
    let template = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: comment)
    return String(format: template, locale: .current, arguments: args)


// MARK: - Strongly-Typed Keys

/// Type-safe namespace for every user-facing localized string in the app.
/// Centralizing the keys here keeps Localizable.strings files in sync with code.
enum Strings {
    enum Common {
        static var ok: String { L("common.ok") }
        static var cancel: String { L("common.cancel") }
        static var add: String { L("common.add") }
        static var save: String { L("common.save") }
        static var remove: String { L("common.remove") }
        static var delete: String { L("common.delete") }
        static var edit: String { L("common.edit") }
        static var share: String { L("common.share") }
        static var allow: String { L("common.allow") }
        static var enabled: String { L("common.enabled") }
        static var details: String { L("common.details") }
        static var settings: String { L("common.settings") }
        static var permissions: String { L("common.permissions") }
        static var unknown: String { L("common.unknown") }
        static var today: String { L("common.today") }
        static var yesterday: String { L("common.yesterday") }
    }

    enum Tabs {
        static var homepage: String { L("tabs.homepage") }
        static var privateMode: String { L("tabs.private") }
        static var zeroTabs: String { L("tabs.zero_tabs") }
        static func tabCount(_ count: Int) -> String {
            count == 1 ? L("tabs.single_tab_format", count) : L("tabs.tab_count_format", count)
        }
    }

    enum Context {
        static var openInNewTab: String { L("context.open_in_new_tab") }
        static var openInNewPrivateTab: String { L("context.open_in_new_private_tab") }
        static var copyLink: String { L("context.copy_link") }
        static var shareLink: String { L("context.share_link") }
        static var shareImage: String { L("context.share_image") }
        static var saveToPhotos: String { L("context.save_to_photos") }
        static var copy: String { L("context.copy") }
    }

    enum AddressBar {
        static var placeholder: String { L("addressbar.placeholder") }
        static var noAddons: String { L("addressbar.no_addons") }
        static var manageAddons: String { L("addressbar.manage_addons") }
        static var requestMobile: String { L("addressbar.request_mobile") }
        static var requestDesktop: String { L("addressbar.request_desktop") }
    }

    enum Library {
        static var bookmarks: String { L("library.bookmarks") }
        static var history: String { L("library.history") }
        static var downloads: String { L("library.downloads") }
        static var settings: String { L("library.settings") }
    }

    enum Settings {
        static var title: String { L("settings.title") }

        enum Section {
            static var updates: String { L("settings.section.updates") }
            static var jit: String { L("settings.section.jit") }
            static var general: String { L("settings.section.general") }
            static var about: String { L("settings.section.about") }
        }

        enum General {
            static var addons: String { L("settings.general.addons") }
            static var browsing: String { L("settings.general.browsing") }
            static var search: String { L("settings.general.search") }
            static var appearance: String { L("settings.general.appearance") }
            static var compatibility: String { L("settings.general.compatibility") }
        }

        enum About {
            static var reynardBrowser: String { L("settings.about.reynard_browser") }
            static var engineVersion: String { L("settings.about.engine_version") }
            static var viewSourceCode: String { L("settings.about.view_source_code") }
            static var supportTheProject: String { L("settings.about.support_the_project") }
            static var githubProfile: String { L("settings.about.github_profile") }
        }

        enum JIT {
            static var enableJIT: String { L("settings.jit.enable_jit") }
            static var importPairingFile: String { L("settings.jit.import_pairing_file") }
            static var jitlessActive: String { L("settings.jit.jitless_active") }
            static var enableJITDetail: String { L("settings.jit.enable_jit_detail") }
            static var jitWarning: String { L("settings.jit.jit_warning") }
            static var importFailed: String { L("settings.jit.import_failed") }
            static var preparingJIT: String { L("settings.jit.preparing_jit") }
            static var preparingJITMessage: String { L("settings.jit.preparing_jit_message") }
            static var downloadFailed: String { L("settings.jit.download_failed") }
            static var restartRequired: String { L("settings.jit.restart_required") }
            static var restartRequiredMessage: String { L("settings.jit.restart_required_message") }
        }

        enum Updates {
            static var available: String { L("settings.updates.available") }
            static var updateNow: String { L("settings.updates.update_now") }
            static var version: String { L("settings.updates.version") }
            static var noReleaseNotes: String { L("settings.updates.no_release_notes") }
            static var trollstoreFooter: String { L("settings.updates.trollstore_footer") }
            static var updateUnavailable: String { L("settings.updates.update_unavailable") }
            static var updateUnavailableMessage: String { L("settings.updates.update_unavailable_message") }
            static var downloadInstructions: String { L("settings.updates.download_instructions") }
            static var downloadingUpdate: String { L("settings.updates.downloading_update") }
            static var downloadFailed: String { L("settings.updates.download_failed") }
        }

        enum Browsing {
            static var title: String { L("settings.browsing.title") }
            static var requestDesktopOn: String { L("settings.browsing.request_desktop_on") }
            static var allWebsite: String { L("settings.browsing.all_website") }
        }

        enum Compatibility {
            static var title: String { L("settings.compatibility.title") }
            static var useAndroidUA: String { L("settings.compatibility.use_android_ua") }
            static var uaOverrides: String { L("settings.compatibility.ua_overrides") }
            static var uaOverridesTitle: String { L("settings.compatibility.ua_overrides_title") }
            static var desktopFooter: String { L("settings.compatibility.desktop_footer") }
            static var androidFooter: String { L("settings.compatibility.android_footer") }
            static var overrideHint: String { L("settings.compatibility.override_hint") }
            static var overridesFooter: String { L("settings.compatibility.overrides_footer") }
            static var addWebsiteRow: String { L("settings.compatibility.add_website_row") }
            static var addWebsite: String { L("settings.compatibility.add_website") }
            static var addWebsitePlaceholder: String { L("settings.compatibility.add_website_placeholder") }
        }

        enum Search {
            static var title: String { L("settings.search.title") }
            static var searchEngine: String { L("settings.search.search_engine") }
            static var searchEnginePlaceholder: String { L("settings.search.search_engine_placeholder") }
            static var searchEngineFooter: String { L("settings.search.search_engine_footer") }
            static var searchEngineFooterShort: String { L("settings.search.search_engine_footer_short") }
            static var invalidURLTitle: String { L("settings.search.invalid_url_title") }
            static var invalidURLMessage: String { L("settings.search.invalid_url_message") }
        }

        enum Appearance {
            static var title: String { L("settings.appearance.title") }
            static var positionBottom: String { L("settings.appearance.position_bottom") }
            static var positionTop: String { L("settings.appearance.position_top") }
            static var tabs: String { L("settings.appearance.tabs") }
            static var landscapeTabBar: String { L("settings.appearance.landscape_tab_bar") }
        }

        enum Addons {
            static var title: String { L("settings.addons.title") }
            static var loadingAddons: String { L("settings.addons.loading_addons") }
            static var noAddonsInstalled: String { L("settings.addons.no_addons_installed") }
            static var discoverAddons: String { L("settings.addons.discover_addons") }
            static var installingAddon: String { L("settings.addons.installing_addon") }
            static var installFromFile: String { L("settings.addons.install_from_file") }
            static var installedAddons: String { L("settings.addons.installed_addons") }
            static var failedToInstall: String { L("settings.addons.failed_to_install") }
            static var failedToRemove: String { L("settings.addons.failed_to_remove") }
            static var failedToUpdatePermissions: String { L("settings.addons.failed_to_update_permissions") }
            static var failedToUpdatePrivateAccess: String { L("settings.addons.failed_to_update_private_access") }
            static var addon: String { L("settings.addons.addon") }
            static var notAllowedInPrivate: String { L("settings.addons.not_allowed_in_private") }
            static var allowInPrivate: String { L("settings.addons.allow_in_private") }
            static var removePromptPrefix: String { L("settings.addons.remove_prompt_prefix") }
            static var blockedPolicy: String { L("settings.addons.blocked_policy") }
            static var notVerified: String { L("settings.addons.not_verified") }
            static func notVerifiedFormat(_ name: String) -> String { L("settings.addons.not_verified_format", name) }
            static var notCompatible: String { L("settings.addons.not_compatible") }
            static func notCompatibleFormat(_ name: String, _ appName: String, _ version: String) -> String {
                L("settings.addons.not_compatible_format", name, appName, version)
            }
            static var restricted: String { L("settings.addons.restricted") }
            static var restrictedDisabled: String { L("settings.addons.restricted_disabled") }
            static var fallbackAppName: String { L("settings.addons.fallback_app_name") }
            static func removePromptFormat(_ name: String) -> String { L("settings.addons.remove_prompt_format", name) }

            enum Detail {
                static var title: String { L("settings.addons.detail.title") }
                static var information: String { L("settings.addons.detail.information") }
                static var links: String { L("settings.addons.detail.links") }
                static var author: String { L("settings.addons.detail.author") }
                static var version: String { L("settings.addons.detail.version") }
                static var lastUpdated: String { L("settings.addons.detail.last_updated") }
                static var rating: String { L("settings.addons.detail.rating") }
                static var homepage: String { L("settings.addons.detail.homepage") }
                static var moreAboutExtension: String { L("settings.addons.detail.more_about_extension") }
                static var outOf5Reviews: String { L("settings.addons.detail.out_of_5_reviews") }
                static var outOf5: String { L("settings.addons.detail.out_of_5") }
            }

            enum Permission {
                static var title: String { L("settings.addons.permission.title") }
                static var noPermissions: String { L("settings.addons.permission.no_permissions") }
                static var required: String { L("settings.addons.permission.required") }
                static var optional: String { L("settings.addons.permission.optional") }
                static var requiredDataCollection: String { L("settings.addons.permission.required_data_collection") }
                static var optionalDataCollection: String { L("settings.addons.permission.optional_data_collection") }
                static var allowForAllSites: String { L("settings.addons.permission.allow_for_all_sites") }
            }

            enum Prompt {
                static var add: String { L("settings.addons.prompt.add") }
                static var update: String { L("settings.addons.prompt.update") }
                static var addAddon: String { L("settings.addons.prompt.add_addon") }
                static var updateAddonPermissions: String { L("settings.addons.prompt.update_addon_permissions") }
                static var additionalOptions: String { L("settings.addons.prompt.additional_options") }
                static var showAllSites: String { L("settings.addons.prompt.show_all_sites") }
                static var allowInPrivateBrowsing: String { L("settings.addons.prompt.allow_in_private_browsing") }
                static var addNamePrompt: String { L("settings.addons.prompt.add_name_prompt") }
                static var requestsDataCollection: String { L("settings.addons.prompt.requests_data_collection") }
                static var requestsPermissions: String { L("settings.addons.prompt.requests_permissions") }
                static var updatedRequiresApproval: String { L("settings.addons.prompt.updated_requires_approval") }
                static var accessDataForSitesIn: String { L("settings.addons.prompt.access_data_for_sites_in") }
                static var sites: String { L("settings.addons.prompt.sites") }
            }
        }
    }

    enum Bookmarks {
        static var title: String { L("bookmarks.title") }
        static var searchPlaceholder: String { L("bookmarks.search_placeholder") }
        static var noMatching: String { L("bookmarks.no_matching") }
        static var showFoldersOnTop: String { L("bookmarks.show_folders_on_top") }
        static var editBookmarks: String { L("bookmarks.edit_bookmarks") }
        static var newFolder: String { L("bookmarks.new_folder") }
        static var sortBy: String { L("bookmarks.sort_by") }
        static var sortNone: String { L("bookmarks.sort_none") }
        static var sortDateAdded: String { L("bookmarks.sort_date_added") }
        static var sortName: String { L("bookmarks.sort_name") }
        static var sortAddress: String { L("bookmarks.sort_address") }
        static var folders: String { L("bookmarks.folders") }
        static var bookmarksSection: String { L("bookmarks.bookmarks_section") }
        static var addToFavorites: String { L("bookmarks.add_to_favorites") }
        static var addBookmark: String { L("bookmarks.add_bookmark") }
        static var editBookmark: String { L("bookmarks.edit_bookmark") }
        static var newFolderTitle: String { L("bookmarks.new_folder_title") }
        static var location: String { L("bookmarks.location") }
        static var sites: String { L("bookmarks.sites") }
    }

    enum History {
        static var title: String { L("history.title") }
        static var searchPlaceholder: String { L("history.search_placeholder") }
        static var empty: String { L("history.empty") }
        static var noMatching: String { L("history.no_matching") }
    }

    enum Downloads {
        static var title: String { L("downloads.title") }
        static var searchPlaceholder: String { L("downloads.search_placeholder") }
        static var openFolder: String { L("downloads.open_folder") }
        static var clearHistory: String { L("downloads.clear_history") }
        static var empty: String { L("downloads.empty") }
        static var noMatching: String { L("downloads.no_matching") }
        static var previous7Days: String { L("downloads.previous_7_days") }
        static var previous30Days: String { L("downloads.previous_30_days") }
        static var openInFiles: String { L("downloads.open_in_files") }
        static var cancelDownloadTitle: String { L("downloads.cancel_download_title") }
        static var cancelDownloadMessagePrefix: String { L("downloads.cancel_download_message_prefix") }
        static var keepDownloading: String { L("downloads.keep_downloading") }
        static var cancelDownload: String { L("downloads.cancel_download") }
        static var downloadAction: String { L("downloads.download_action") }
        static func confirmDownloadFormat(_ fileName: String) -> String { L("downloads.confirm_download_format", fileName) }
    }

    enum ClearHistory {
        static var title: String { L("clear_history.title") }
        static var button: String { L("clear_history.button") }
        static var timeframe: String { L("clear_history.timeframe") }
        static var additionalOptions: String { L("clear_history.additional_options") }
        static var lastHour: String { L("clear_history.last_hour") }
        static var today: String { L("clear_history.today") }
        static var todayAndYesterday: String { L("clear_history.today_and_yesterday") }
        static var allHistory: String { L("clear_history.all_history") }
        static var closeAllTabs: String { L("clear_history.close_all_tabs") }
        static var tabSingular: String { L("clear_history.tab_singular") }
        static var tabPlural: String { L("clear_history.tab_plural") }
        static func closeTabsFormat(_ count: Int) -> String {
            let unit = count == 1 ? tabSingular : tabPlural
            return L("clear_history.close_tabs_format", count, unit)
        }
    }

    enum ClearDownloads {
        static var title: String { L("clear_downloads.title") }
        static var button: String { L("clear_downloads.button") }
        static var timeframe: String { L("clear_downloads.timeframe") }
        static var footer: String { L("clear_downloads.footer") }
    }
}
