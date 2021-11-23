//
//  CaptureThing.swift
//  Capture
//
//  Created by Tyler Hall on 4/18/21.
//

import Foundation
import CoreWLAN
import CoreGraphics
import AVFoundation
import AppKit

class CaptureThing {

    static let shared = CaptureThing()
    
    lazy var getAllTabsScriptSafari: NSAppleScript = {
       let script = """
        set outList to {}
        tell application "Safari"
            repeat with w in windows
                repeat with t in (tabs of w)
                    set theTitle to name of t
                    copy theTitle to end of outList
                    set theURL to URL of t
                    copy theURL to end of outList
                end repeat
            end repeat
        end tell

        return outList
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.compileAndReturnError(nil)
        return appleScript!
    }()

    lazy var getActiveTabsScriptSafari: NSAppleScript = {
       let script = """
        set outList to {}
        tell application "Safari"
            set theTitle to the name of current tab of first window
            copy theTitle to end of outList
            set theURL to the URL of current tab of first window
            copy theURL to end of outList
        end tell

        return outList
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.compileAndReturnError(nil)
        return appleScript!
    }()

    lazy var getAllTabsScriptChrome: NSAppleScript = {
       let script = """
        set outList to {}

        tell application "Google Chrome"
            repeat with w in windows
                repeat with t in (tabs of w)
                    set theTitle to title of t
                    copy theTitle to end of outList
                    set theURL to URL of t
                    copy theURL to end of outList
                end repeat
            end repeat
        end tell

        return outList
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.compileAndReturnError(nil)
        return appleScript!
    }()

    lazy var getActiveTabsScriptChrome: NSAppleScript = {
       let script = """
        set outList to {}

        tell application "Google Chrome"
            set theTitle to title of active tab of first window
            copy theTitle to end of outList
            set theURL to URL of active tab of first window
            copy theURL to end of outList
        end tell

        return outList
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.compileAndReturnError(nil)
        return appleScript!
    }()

    lazy var getAllTabsScriptBrave: NSAppleScript = {
        let script = """
        set outList to {}

        tell application "Brave Browser"
            repeat with w in windows
                repeat with t in (tabs of w)
                    set theTitle to title of t
                    copy theTitle to end of outList
                    set theURL to URL of t
                    copy theURL to end of outList
                end repeat
            end repeat
        end tell

        return outList
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.compileAndReturnError(nil)
        return appleScript!
    }()

    lazy var getActiveTabScriptBrave: NSAppleScript = {
        let script = """
        set outList to {}

        tell application "Brave Browser"
            set theTitle to title of active tab of first window
            copy theTitle to end of outList
            set theURL to URL of active tab of first window
            copy theURL to end of outList
        end tell

        return outList
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.compileAndReturnError(nil)
        return appleScript!
    }()
    
    enum Browser: Int {
        case Safari = 0
        case Brave = 1
        case Chrome = 2
    }

    struct Settings {
        var summary: String
        var details: String
        var takeScreenshot: Bool
        var activeBrowserTab: Bool
        var allBrowserTabs: Bool
        var attachments: [URL]
    }
    
    var hostname: String?

    var currentFileURL: URL? {
        guard let captureFolderURL = UserDefaults.standard.url(forKey: kCapturePath) else { return nil }

        let dfDir = DateFormatter()
        dfDir.dateFormat = "yyyy/MM/"
        let dateDir = dfDir.string(from: Date())

        let dfFilename = DateFormatter()
        dfFilename.dateFormat = "yyyy-MM-dd EEEE"
        let dateFilename = dfFilename.string(from: Date())

        var url = captureFolderURL.appendingPathComponent(dateDir)

        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }

        url.appendPathComponent(dateFilename)
        url.appendPathExtension("md")
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try ("" as NSString).write(to: url, atomically: false, encoding: String.Encoding.utf8.rawValue)
            } catch {
                return nil
            }
        }

        return url
    }

    var attachmentsDir: URL? {
        guard let currentFileURL = currentFileURL else { return nil }

        var dir = currentFileURL.deletingLastPathComponent()
        dir.appendPathComponent("attachments")

        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }

        return dir
    }

    var dropDestinationURL: URL {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }

    var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()

    init() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.hostname = Host.current().name
        }
    }
}

extension CaptureThing {

    func capture(settings: Settings) {
        var outStr = makeHeader(summary: settings.summary, details: settings.details)

        if settings.takeScreenshot {
            outStr += makeScreenshot()
        }

        outStr += makeAttachments(attachments: settings.attachments)

        if settings.allBrowserTabs {
            outStr += makeAllBrowserTabs()
        } else if settings.activeBrowserTab {
            outStr += makeActiveBrowserTab()
        }

        outStr += "### Misc Info\n"
        outStr += makeTimestamp()
        outStr += makeWifi()
        outStr += makeHostname()

        outStr += "\n* * * * *\n\n"

        writeToFile(str: outStr)
    }

    func makeHeader(summary: String, details: String) -> String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        let dateStr = df.string(from: Date())

        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        var outStr = "# \(dateStr)\n"
        outStr += trimmedSummary + "\n"
        outStr += "----------\n"

        if details.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            outStr += details + "\n\n"
        }

        return outStr
    }

    func makeScreenshot() -> String {
        guard let attachmentsDir = attachmentsDir else { return "" }

        var outStr = ""
        if let filenames = takeScreenshots(folderURL: attachmentsDir), filenames.count > 0 {
            var i = 1
            for filename in filenames {
                outStr += "![Screenshot \(i)](attachments/\(filename))\n"
                i += 1
            }
            outStr += "\n"
        }
        return outStr
    }

    func makeAttachments(attachments: [URL]) -> String {
        guard let attachmentsDir = attachmentsDir else { return "" }
        guard attachments.count > 0 else { return "" }

        let unixTimestamp = Int32(Date().timeIntervalSince1970)
        let sortingDF = DateFormatter()
        sortingDF.dateFormat = "yyyy-MM-dd"
        let sortingKey = sortingDF.string(from: Date())

        var outStr = "### Attachments\n"
        for srcURL in attachments {
            do {
                let fn = "\(sortingKey) \(unixTimestamp)" + srcURL.lastPathComponent
                var destURL = attachmentsDir
                destURL.appendPathComponent(fn)
                try FileManager.default.copyItem(at: srcURL, to: destURL)
                outStr += "* [\(srcURL.lastPathComponent)](attachments/\(fn))\n"
            } catch {

            }
        }

        outStr += "\n"

        return outStr
    }

    func makeWifi() -> String {
        if let ssid = CWWiFiClient.shared().interface()?.ssid() {
            return "*WiFi: \(ssid)*\n"
        } else {
            return ""
        }
    }

    func makeHostname() -> String {
        if let hostname = hostname {
            return "*Computer: \(hostname)*\n"
        } else {
            return ""
        }
    }

    func makeTimestamp() -> String {
        let df = ISO8601DateFormatter()
        let dateStr = df.string(from: Date())
        return "*Timestamp: \(dateStr)*\n"
    }

    func makeActiveBrowserTab() -> String {
        guard let browser = Browser(rawValue: UserDefaults.standard.integer(forKey: kBrowser)) else { return "" }
        
        var eventDescriptor: NSAppleEventDescriptor
        switch browser {
        case .Safari:
            eventDescriptor = getActiveTabsScriptSafari.executeAndReturnError(nil)
        case .Brave:
            eventDescriptor = getActiveTabScriptBrave.executeAndReturnError(nil)
        case .Chrome:
            eventDescriptor = getActiveTabsScriptChrome.executeAndReturnError(nil)
        }

        guard let listDescriptor = eventDescriptor.coerce(toDescriptorType: typeAEList) else { return "" }
        guard listDescriptor.numberOfItems > 0 else { return "" }

        var outStr = "### Active Browser Tab\n"
        for i in stride(from: 1, through: listDescriptor.numberOfItems, by: 2) {
            if let title = listDescriptor.atIndex(i)?.stringValue, let url = listDescriptor.atIndex(i + 1)?.stringValue {
                outStr += "* [\(title)](\(url))\n"
            }
        }

        outStr += "\n"

        return outStr
    }

    func makeAllBrowserTabs() -> String {
        guard let browser = Browser(rawValue: UserDefaults.standard.integer(forKey: kBrowser)) else { return "" }
        
        var eventDescriptor: NSAppleEventDescriptor
        switch browser {
        case .Safari:
            eventDescriptor = getAllTabsScriptSafari.executeAndReturnError(nil)
        case .Brave:
            eventDescriptor = getAllTabsScriptBrave.executeAndReturnError(nil)
        case .Chrome:
            eventDescriptor = getAllTabsScriptChrome.executeAndReturnError(nil)
        }

        guard let listDescriptor = eventDescriptor.coerce(toDescriptorType: typeAEList) else { return "" }
        guard listDescriptor.numberOfItems > 0 else { return "" }

        var outStr = "### All Browser Tabs\n"
        for i in stride(from: 1, through: listDescriptor.numberOfItems, by: 2) {
            if let title = listDescriptor.atIndex(i)?.stringValue, let url = listDescriptor.atIndex(i + 1)?.stringValue {
                outStr += "* [\(title)](\(url))\n"
            }
        }

        outStr += "\n"

        return outStr
    }

    func writeToFile(str: String) {
        guard let fileURL = currentFileURL else { return }

        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seekToEnd()
            if let data = str.data(using: .utf8) {
                fileHandle.write(data)
            }
            try fileHandle.close()
        } catch {

        }
    }
}

extension CaptureThing {

    func takeScreenshots(folderURL: URL) -> [String]? {
        let sortingDF = DateFormatter()
        sortingDF.dateFormat = "yyyy-MM-dd"
        let sortingKey = sortingDF.string(from: Date())

        var filenames = [String]()

        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if (result != CGError.success) {
            print("error: \(result)")
            return nil
        }

        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)

        if (result != CGError.success) {
            print("error: \(result)")
            return nil
        }

        for i in 1...displayCount {
            let unixTimestamp = Int32(Date().timeIntervalSince1970)

            let baseFilename = "\(sortingKey) - Screenshot \(unixTimestamp)" + "_" + "\(i)"
            let filename = baseFilename + ".jpg"

            var fileURL = folderURL.appendingPathComponent(baseFilename)
            fileURL.appendPathExtension("jpg")

            let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i - 1)])!
            let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!

            do {
                try jpegData.write(to: fileURL, options: .atomic)
                filenames.append(filename)
            }
            catch {
                print("error: \(error)")
            }
        }

        return filenames
    }
}
