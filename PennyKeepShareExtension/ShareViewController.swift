//
//  ShareViewController.swift
//  PennyKeepShareExtension
//
//  Created by Sota Mitsumori on 2025/12/14.
//

import UIKit
import UniformTypeIdentifiers
import Social

class ShareViewController: SLComposeServiceViewController {
    
    private var selectedFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🔵 [ShareExtension] ShareViewController viewDidLoad called")
        
        // Set placeholder text
        self.placeholder = "Import PayPay CSV to PennyKeep"
        
        // Get the shared file
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = extensionItem.attachments {
                for attachment in attachments {
                    // Check if it's a file
                    if attachment.hasItemConformingToTypeIdentifier(UTType.commaSeparatedText.identifier) ||
                       attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ||
                       attachment.hasItemConformingToTypeIdentifier("public.data") {
                        
                        attachment.loadItem(forTypeIdentifier: attachment.registeredTypeIdentifiers.first ?? "public.data", options: nil) { [weak self] (item, error) in
                            guard let self = self else { return }
                            
                            if let error = error {
                                print("Error loading item: \(error)")
                                return
                            }
                            
                            if let url = item as? URL {
                                // Copy file to shared container
                                self.copyFileToSharedContainer(url: url)
                            } else if let data = item as? Data {
                                // Save data to shared container
                                self.saveDataToSharedContainer(data: data)
                            } else if let string = item as? String {
                                // Save string to shared container
                                self.saveStringToSharedContainer(string: string)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func isContentValid() -> Bool {
        print("🔵 [ShareExtension] isContentValid called")
        // Always allow posting
        return true
    }
    
    override func didSelectPost() {
        print("🔵 [ShareExtension] didSelectPost called")
        // This is called when the user taps Post
        // The file has already been copied to shared container
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
    
    private func copyFileToSharedContainer(url: URL) {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.pennykeep") else {
            print("Failed to get shared container URL")
            return
        }
        
        let fileName = url.lastPathComponent
        let destinationURL = sharedContainerURL.appendingPathComponent("IncomingPayPayCSV").appendingPathComponent(fileName)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)
        
        // Copy file
        do {
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Notify main app
            UserDefaults(suiteName: "group.com.pennykeep")?.set(true, forKey: "hasIncomingPayPayCSV")
            UserDefaults(suiteName: "group.com.pennykeep")?.set(fileName, forKey: "incomingPayPayCSVFileName")
            UserDefaults(suiteName: "group.com.pennykeep")?.synchronize()
            
            print("✅ File copied to shared container: \(destinationURL)")
        } catch {
            print("❌ Failed to copy file: \(error)")
        }
    }
    
    private func saveDataToSharedContainer(data: Data) {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.pennykeep") else {
            print("Failed to get shared container URL")
            return
        }
        
        let fileName = "PayPay_\(Date().timeIntervalSince1970).csv"
        let destinationURL = sharedContainerURL.appendingPathComponent("IncomingPayPayCSV").appendingPathComponent(fileName)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        do {
            try data.write(to: destinationURL)
            
            // Notify main app
            UserDefaults(suiteName: "group.com.pennykeep")?.set(true, forKey: "hasIncomingPayPayCSV")
            UserDefaults(suiteName: "group.com.pennykeep")?.set(fileName, forKey: "incomingPayPayCSVFileName")
            UserDefaults(suiteName: "group.com.pennykeep")?.synchronize()
            
            print("✅ Data saved to shared container: \(destinationURL)")
        } catch {
            print("❌ Failed to save data: \(error)")
        }
    }
    
    private func saveStringToSharedContainer(string: String) {
        guard let data = string.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }
        saveDataToSharedContainer(data: data)
    }
}
