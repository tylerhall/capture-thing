//
//  CaptureWindowController.swift
//  Capture
//
//  Created by Tyler Hall on 4/18/21.
//

import AppKit
import CoreWLAN

class CaptureWindowController: NSWindowController {

    static let shared = CaptureWindowController(windowNibName: String(describing: CaptureWindowController.self))

    @IBOutlet weak var summaryTextField: NSTextField!
    @IBOutlet weak var detailsTextView: NSTextView!
    @IBOutlet weak var dropView: DroppableView!
    @IBOutlet weak var attachmentsTableView: NSTableView!
    @IBOutlet weak var screenshotCheckbox: NSButton!
    @IBOutlet weak var activeBrowserTabCheckbox: NSButton!
    @IBOutlet weak var allBrowserTabsCheckbox: NSButton!

    var attachments = [URL]()

    override func windowDidLoad() {
        super.windowDidLoad()

        detailsTextView.font = NSFont.systemFont(ofSize: 16)
        detailsTextView.textContainerInset = NSSize(width: 10, height: 10)

        setupDragging()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        restoreDefaults()
    }

    func restoreDefaults() {
        summaryTextField.stringValue = ""
        detailsTextView.string = ""
        screenshotCheckbox.state = UserDefaults.standard.bool(forKey: kCaptureScreenshot) ? .on : .off
        activeBrowserTabCheckbox.state = UserDefaults.standard.bool(forKey: kCaptureActiveTab) ? .on : .off
        allBrowserTabsCheckbox.state = UserDefaults.standard.bool(forKey: kCaptureAllTabs) ? .on : .off
        attachments.removeAll()
        attachmentsTableView.reloadData()
        window?.makeFirstResponder(summaryTextField)
    }

    @IBAction func focusSummaryTextField(_ sender: AnyObject?) {
        window?.makeFirstResponder(summaryTextField)
    }

    @IBAction func checkScreenshot(_ sender: AnyObject?) {
        screenshotCheckbox.state = (screenshotCheckbox.state == .on) ? .off : .on
    }

    @IBAction func checkActiveBrowserTab(_ sender: AnyObject?) {
        if activeBrowserTabCheckbox.state == .on {
            activeBrowserTabCheckbox.state = .off
        } else {
            activeBrowserTabCheckbox.state = .on
            allBrowserTabsCheckbox.state = .off
        }
    }

    @IBAction func checkAllBrowserTabs(_ sender: AnyObject?) {
        if allBrowserTabsCheckbox.state == .on {
            allBrowserTabsCheckbox.state = .off
        } else {
            allBrowserTabsCheckbox.state = .on
            activeBrowserTabCheckbox.state = .off
        }
    }

    @IBAction func activeBrowserCheckboxClicked(_ sender: AnyObject?) {
        if activeBrowserTabCheckbox.state == .on {
            allBrowserTabsCheckbox.state = .off
        }
    }

    @IBAction func allBrowsersCheckboxClicked(_ sender: AnyObject?) {
        if allBrowserTabsCheckbox.state == .on {
            activeBrowserTabCheckbox.state = .off
        }
    }

    @IBAction func saveButtonClicked(_ sender: AnyObject?) {
        window?.close()
        NSApp.hide(nil)

        let settings = CaptureThing.Settings(summary: summaryTextField.stringValue,
                                             details: detailsTextView.string,
                                             takeScreenshot: (screenshotCheckbox.state == .on),
                                             activeBrowserTab: (activeBrowserTabCheckbox.state == .on),
                                             allBrowserTabs: (allBrowserTabsCheckbox.state == .on),
                                             attachments: attachments)

        // Delay to the next run loop so the window closes before screenshots are taken.
        DispatchQueue.main.async {
            CaptureThing.shared.capture(settings: settings)
        }
    }

    @IBAction func cancelButtonClicked(_ sender: AnyObject?) {
        window?.close()
        NSApp.hide(nil)
    }

    func takeQuickScreenshot() {
        window?.close()
        NSApp.hide(nil)

        let settings = CaptureThing.Settings(summary: "Quick Screenshot",
                                             details: "",
                                             takeScreenshot: true,
                                             activeBrowserTab: false,
                                             allBrowserTabs: false,
                                             attachments: [])

        // Delay to the next run loop so the window closes before screenshots are taken.
        DispatchQueue.main.async {
            CaptureThing.shared.capture(settings: settings)
        }
    }
}

protocol DragDelegate: AnyObject {
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
    func draggingExited(_ sender: NSDraggingInfo?)
    func draggingEnded(_ sender: NSDraggingInfo)
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool
}

extension CaptureWindowController: DragDelegate {

    func setupDragging() {
        dropView.dragDelegate = self
    }

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    func draggingExited(_ sender: NSDraggingInfo?) {
        
    }
    
    func draggingEnded(_ sender: NSDraggingInfo) {
        
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let supportedClasses = [NSFilePromiseReceiver.self, NSURL.self]
        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]

        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { [weak self] (draggingItem, _, _) in
            guard let self = self else { return }
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                    filePromiseReceiver.receivePromisedFiles(atDestination: CaptureThing.shared.dropDestinationURL, options: [:],
                                                             operationQueue: CaptureThing.shared.workQueue) { (fileURL, error) in
                    if error == nil {
                        self.attachments.append(fileURL)
                        DispatchQueue.main.async { [weak self] in
                            self?.attachmentsTableView.reloadData()
                        }
                    }
                }
            case let fileURL as URL:
                do {
                    let newURL = CaptureThing.shared.dropDestinationURL.appendingPathComponent(fileURL.lastPathComponent)
                    try FileManager.default.copyItem(at: fileURL, to: newURL)
                    self.attachments.append(newURL)
                    DispatchQueue.main.async { [weak self] in
                        self?.attachmentsTableView.reloadData()
                    }
                } catch {
                    return
                }
            default:
                break
            }
        }

        return true
    }
}

extension CaptureWindowController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return attachments.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard attachments.indices.contains(row) else { return nil }
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"), owner: nil) as? NSTableCellView else { return nil }
        cell.textField?.stringValue = attachments[row].lastPathComponent
        return cell
    }
}


class DroppableView: NSView {
    weak var dragDelegate: DragDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dragDelegate?.draggingEntered(sender) ?? NSDragOperation.init()
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragDelegate?.draggingExited(sender)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragDelegate?.draggingEnded(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dragDelegate?.performDragOperation(sender) ?? false
    }
}
