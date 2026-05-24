//
//  main.swift
//  Reynard
//
//  Created by Minh Ton on 1/2/26.
//

import Foundation
import GeckoView
import UIKit
import Darwin

@available(iOS, introduced: 13.0, obsoleted: 14.0)
private func configureUnsandboxedAppDataDirectories() {
    guard let cachesDirectory = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first else {
        return
    }

    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
        return
    }

    let appDataDirectory = cachesDirectory
        .appendingPathComponent(bundleIdentifier, isDirectory: true)
        .appendingPathComponent(".mozilla", isDirectory: true)
        .appendingPathComponent("firefox", isDirectory: true)

    do {
        try FileManager.default.createDirectory(
            at: appDataDirectory,
            withIntermediateDirectories: true
        )
    } catch {
        return
    }

    setenv("MOZ_APP_DATA", appDataDirectory.path, 1)
    setenv("MOZ_LOCAL_APP_DATA", appDataDirectory.path, 1)
}

/// Mirrors the user's iOS language preferences into the POSIX-style env vars
/// (`LANG`, `LC_MESSAGES`, `LC_CTYPE`) that Gecko's NSPR / intl bootstrap
/// reads before any preference is loaded. This affects ICU collation,
/// regional formatting (numbers, dates), and Gecko's
/// `Services.locale.requestedLocale`.
///
/// We also expose `REYNARD_ACCEPT_LANGUAGES` — a complete Accept-Language
/// header value built from the user's full preference list with decreasing
/// q-values — so a follow-up engine patch can pipe it into the
/// `intl.accept_languages` pref at startup. Until that wiring lands, the
/// static default in `patches/modules/libpref/init/all.js.patch` provides a
/// reasonable fallback (zh-CN, then English) and POSIX env vars below give
/// Gecko enough hints to localize regional formatting correctly.
private func configureSystemLanguageEnvironment() {
    let preferred = Locale.preferredLanguages
    guard !preferred.isEmpty else { return }

    /// Normalize an iOS BCP-47 tag into the form web servers expect.
    /// iOS hands out tags like "zh-Hans-CN" or "en-Latn-US"; HTTP servers
    /// generally want either the language code alone ("zh") or
    /// language-region ("zh-CN"). We drop the script subtag when there is
    /// also a region subtag — matches the behavior Safari uses.
    func canonicalize(_ tag: String) -> String {
        let parts = tag.split(separator: "-").map(String.init)
        guard parts.count >= 3 else { return tag }
        let isScript = parts[1].count == 4 && parts[1].first?.isUppercase == true
        if isScript {
            return "\(parts[0])-\(parts[2])"
        }
        return tag
    }

    let canonical = preferred.map(canonicalize)

    // Build the Accept-Language header: primary at q=1.0 (implicit), then
    // descending q values (0.9, 0.8, ...). Cap at 5 entries so the header
    // stays compact.
    var seen = Set<String>()
    var weighted: [String] = []
    for (i, tag) in canonical.prefix(5).enumerated() {
        guard !seen.contains(tag) else { continue }
        seen.insert(tag)
        if i == 0 {
            weighted.append(tag)
        } else {
            let q = max(0.1, 1.0 - Double(i) * 0.1)
            weighted.append("\(tag);q=\(String(format: "%.1f", q))")
        }
    }
    let acceptHeader = weighted.joined(separator: ",")
    setenv("REYNARD_ACCEPT_LANGUAGES", acceptHeader, 1)

    // POSIX locale identifier: iOS uses dash, POSIX uses underscore.
    // e.g. "zh-CN" → "zh_CN.UTF-8".
    let primaryPosix = canonical[0].replacingOccurrences(of: "-", with: "_") + ".UTF-8"
    setenv("LANG", primaryPosix, 1)
    setenv("LC_MESSAGES", primaryPosix, 1)
    setenv("LC_CTYPE", primaryPosix, 1)
}

MigrationController.shared.run()
JITController.shared.start()
configureSystemLanguageEnvironment()
if #unavailable(iOS 14.0),
   getEntitlementValue("com.apple.private.security.no-sandbox") {
    configureUnsandboxedAppDataDirectories()
}
GeckoRuntime.main(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
