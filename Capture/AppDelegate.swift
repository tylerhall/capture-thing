//
//  AppDelegate.swift
//  Capture
//
//  Created by Tyler Hall on 4/18/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var isLaunching = true

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.addObserver(self, forKeyPath: kShowShortcut, options: NSKeyValueObservingOptions.init(), context: nil)
        shortcutsDidChange()

        // Always show the prefs window until we have picked a capture folder...
        if UserDefaults.standard.url(forKey: kCapturePath) == nil {
            PrefsWindowController.shared.showWindow(nil)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == kShowShortcut {
            shortcutsDidChange()
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        guard !isLaunching else {
            isLaunching = false
            return false
        }

        showCaptureWindow()
        return false
    }

    @objc func shortcutsDidChange() {
        MASShortcutBinder.shared()?.breakBinding(withDefaultsKey: kShowShortcut)
        MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: kShowShortcut, toAction: { [weak self] in
            self?.handleHotkey()
        })
    }

    @IBAction func showPrefs(_ sender: AnyObject?) {
        PrefsWindowController.shared.showWindow(nil)
    }

    @IBAction func newCapture(_ sender: AnyObject?) {
        showCaptureWindow()
    }

    @IBAction func openCaptureFolder(_ sender: AnyObject?) {
        if let url = CaptureThing.shared.currentFileURL?.deletingLastPathComponent() {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func handleHotkey() {
        let windowIsVisible = (CaptureWindowController.shared.window?.isVisible ?? false)

        if windowIsVisible && NSApp.isActive {
            CaptureWindowController.shared.takeQuickScreenshot()
        } else {
            showCaptureWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func showCaptureWindow() {
        // Always show the prefs window until we have picked a capture folder...
        guard UserDefaults.standard.url(forKey: kCapturePath) != nil else {
            PrefsWindowController.shared.showWindow(nil)
            return
        }

        CaptureWindowController.shared.showWindow(nil)
    }
}
