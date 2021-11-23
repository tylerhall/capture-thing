//
//  PrefsWindowController.swift
//  Capture
//
//  Created by Tyler Hall on 4/19/21.
//

import AppKit

let kShowShortcut = "kShowShortcut"
let kCaptureScreenshot = "kCaptureScreenshot"
let kCaptureActiveTab = "kCaptureActiveTab"
let kCaptureAllTabs = "kCaptureAllTabs"
let kCapturePath = "kCapturePath"

class PrefsWindowController: NSWindowController {
    
    static let shared = PrefsWindowController(windowNibName: String(describing: PrefsWindowController.self))

    @IBOutlet weak var showShortcutKeyView: MASShortcutView!
    @IBOutlet weak var screenshotCheckbox: NSButton!
    @IBOutlet weak var activeBrowserTabCheckbox: NSButton!
    @IBOutlet weak var allBrowserTabsCheckbox: NSButton!
    @IBOutlet weak var captureFolderPathControl: NSPathControl!

    override func windowDidLoad() {
        super.windowDidLoad()
        showShortcutKeyView.associatedUserDefaultsKey = kShowShortcut
        captureFolderPathControl.url = UserDefaults.standard.url(forKey: kCapturePath)
    }

    @IBAction func activeBrowserCheckboxClicked(_ sender: AnyObject?) {
        if activeBrowserTabCheckbox.state == .on {
            allBrowserTabsCheckbox.state = .off
            UserDefaults.standard.set(false, forKey: kCaptureAllTabs)
        }
    }

    @IBAction func allBrowsersCheckboxClicked(_ sender: AnyObject?) {
        if allBrowserTabsCheckbox.state == .on {
            activeBrowserTabCheckbox.state = .off
            UserDefaults.standard.set(false, forKey: kCaptureActiveTab)
        }
    }

    @IBAction func chooseCaptureFolder(_ sender: AnyObject?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.runModal()
        if let url = panel.url {
            captureFolderPathControl.url = url
            UserDefaults.standard.set(url, forKey: kCapturePath)
        }
    }
}
