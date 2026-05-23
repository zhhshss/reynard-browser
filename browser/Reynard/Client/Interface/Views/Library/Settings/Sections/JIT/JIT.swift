//
//  JIT.swift
//  Reynard
//
//  Created by Minh Ton on 11/4/26.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

extension SettingsRootViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        importPairingFile(from: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
}

extension SettingsRootViewController {
    func makeJITFooterView() -> UIView {
        let footerView = UITableViewHeaderFooterView(reuseIdentifier: nil)
        footerView.contentView.preservesSuperviewLayoutMargins = true
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        
        let footerPointSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize
        let statusBoldFont = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: UIFont.systemFont(ofSize: footerPointSize, weight: .semibold))
        
        if isJITLessModeActive {
            let statusLabel = UILabel()
            statusLabel.numberOfLines = 0
            statusLabel.font = statusBoldFont
            statusLabel.adjustsFontForContentSizeCategory = true
            statusLabel.textColor = .systemOrange
            statusLabel.text = "\u{25B2} " + Strings.Settings.JIT.jitlessActive
            stack.addArrangedSubview(statusLabel)
        }
        
        let detailLabel = UILabel()
        detailLabel.numberOfLines = 0
        detailLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = Strings.Settings.JIT.enableJITDetail
        stack.addArrangedSubview(detailLabel)
        
        // if on 16.6 to 17.3.1, show warning about JIT
        if #available(iOS 16.6, *) {
            if #unavailable(iOS 17.4) {
                let warningLabel = UILabel()
                warningLabel.numberOfLines = 0
                warningLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
                warningLabel.adjustsFontForContentSizeCategory = true
                warningLabel.textColor = .systemRed
                warningLabel.text = Strings.Settings.JIT.jitWarning
                stack.addArrangedSubview(warningLabel)
            }
        }
        
        footerView.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: footerView.contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: footerView.contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: footerView.contentView.layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: footerView.contentView.layoutMarginsGuide.bottomAnchor),
        ])
        
        return footerView
    }
    
    func presentPairingFilePicker() {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let types = allowedPairingFileTypes()
            picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: allowedPairingDocumentTypeIdentifiers(), in: .import)
        }
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    func importPairingFile(from url: URL) {
        backgroundQueue.async { [weak self] in
            guard let self else { return }
            do {
                try installPairingFile(from: url)
                DispatchQueue.main.async { self.refreshControls() }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: Strings.Settings.JIT.importFailed, message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc func jitSwitchChanged(_ sender: UISwitch) {
        Prefs.JITSettings.isJITEnabled = sender.isOn
        guard sender.isOn else { presentJITRestartAlert(); return }
        guard !DDIManager.shared.hasRequiredDDIFiles() else { presentJITRestartAlert(); return }
        presentDDIDownloadAlert(for: sender)
    }
    
    @objc func handleJITLessModeActivated(_ notification: Notification) {
        refreshControls()
        tableView.reloadData()
    }
    
    func presentDDIDownloadAlert(for sender: UISwitch) {
        sender.isEnabled = false
        let alert = UIAlertController(
            title: Strings.Settings.JIT.preparingJIT,
            message: Strings.Settings.JIT.preparingJITMessage,
            preferredStyle: .alert
        )
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
        let token = UUID()
        activeDDIDownloadToken = token
        alert.addAction(UIAlertAction(title: Strings.Common.cancel, style: .cancel) { [weak self] _ in
            self?.cancelDDIDownload(for: sender, token: token)
        })
        present(alert, animated: true) { [weak self] in
            self?.attachProgressView(progressView, to: alert)
            self?.startDDIDownload(for: sender, alert: alert, progressView: progressView, token: token)
        }
    }
    
    func attachProgressView(_ progressView: UIProgressView, to alert: UIAlertController) {
        guard let messageText = alert.message,
              let messageLabel = alert.view.firstDescendantLabel(withText: messageText) else { return }
        alert.view.addSubview(progressView)
        let cancelAnchorView: UIView? = {
            if let button = alert.view.firstDescendantButton(withTitle: Strings.Common.cancel) { return button }
            return alert.view.firstDescendantView(containingLabelText: Strings.Common.cancel)
        }()
        var constraints = [
            progressView.widthAnchor.constraint(equalTo: messageLabel.widthAnchor),
            progressView.centerXAnchor.constraint(equalTo: messageLabel.centerXAnchor),
            progressView.topAnchor.constraint(greaterThanOrEqualTo: messageLabel.bottomAnchor, constant: 12),
        ]
        if let cancelAnchorView {
            let verticalGuide = UILayoutGuide()
            alert.view.addLayoutGuide(verticalGuide)
            constraints.append(contentsOf: [
                verticalGuide.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
                verticalGuide.bottomAnchor.constraint(equalTo: cancelAnchorView.topAnchor, constant: -16),
                progressView.centerYAnchor.constraint(equalTo: verticalGuide.centerYAnchor),
            ])
        } else {
            constraints.append(progressView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20))
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    func startDDIDownload(for sender: UISwitch, alert: UIAlertController, progressView: UIProgressView, token: UUID) {
        DDIManager.shared.ensureRequiredDDIFiles(
            progress: { [weak self] value in
                guard let self, self.activeDDIDownloadToken == token else { return }
                progressView.setProgress(Float(value), animated: true)
            },
            completion: { [weak self] result in
                guard let self, self.activeDDIDownloadToken == token else { return }
                self.activeDDIDownloadToken = nil
                sender.isEnabled = Prefs.JITSettings.hasPairingFile
                switch result {
                case .success:
                    self.dismissAlertIfPresented(alert) { self.presentJITRestartAlert() }
                case .failure(let error):
                    Prefs.JITSettings.isJITEnabled = false
                    sender.setOn(false, animated: true)
                    self.dismissAlertIfPresented(alert) {
                        self.presentAlert(title: Strings.Settings.JIT.downloadFailed, message: error.localizedDescription)
                    }
                }
            }
        )
    }
    
    func cancelDDIDownload(for sender: UISwitch, token: UUID) {
        guard activeDDIDownloadToken == token else { return }
        activeDDIDownloadToken = nil
        DDIManager.shared.cancelActiveDownload()
        Prefs.JITSettings.isJITEnabled = false
        sender.setOn(false, animated: true)
        sender.isEnabled = Prefs.JITSettings.hasPairingFile
    }
    
    func dismissAlertIfPresented(_ alert: UIAlertController, completion: @escaping () -> Void) {
        guard presentedViewController === alert else { completion(); return }
        alert.dismiss(animated: true, completion: completion)
    }
    
    func presentJITRestartAlert() {
        let alert = UIAlertController(
            title: Strings.Settings.JIT.restartRequired,
            message: Strings.Settings.JIT.restartRequiredMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default) { _ in
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                exit(EXIT_SUCCESS)
            }
        })
        present(alert, animated: true)
    }
}

@available(iOS 14.0, *)
func allowedPairingFileTypes() -> [UTType] {
    var types = [UTType.propertyList]
    ["mobiledevicepairing", "mobiledevicepair", "plist"].forEach { ext in
        if let type = UTType(filenameExtension: ext), !types.contains(type) {
            types.append(type)
        }
    }
    return types
}

func allowedPairingDocumentTypeIdentifiers() -> [String] {
    var identifiers = [kUTTypePropertyList as String]
    ["mobiledevicepairing", "mobiledevicepair", "plist"].forEach { ext in
        if let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            ext as CFString,
            nil
        )?.takeRetainedValue() as String?,
           !identifiers.contains(uti) {
            identifiers.append(uti)
        }
    }
    return identifiers
}
func installPairingFile(from sourceURL: URL) throws {
    let fileManager = FileManager.default
    let destinationURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("pairingFile.plist", isDirectory: false)
    try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    
    let normalizedSourceURL = sourceURL.standardizedFileURL
    let normalizedDestinationURL = destinationURL.standardizedFileURL
    
    guard normalizedSourceURL != normalizedDestinationURL else {
        Prefs.JITSettings.isJITEnabled = false
        return
    }
    
    if fileManager.fileExists(atPath: normalizedDestinationURL.path) {
        try fileManager.removeItem(at: normalizedDestinationURL)
    }
    
    try fileManager.copyItem(at: normalizedSourceURL, to: normalizedDestinationURL)
    Prefs.JITSettings.isJITEnabled = false
}
