import Cocoa

extension NSEvent {
    var isRightClick: Bool {
        let rightClick = (self.type == .rightMouseDown)
        let controlClick = self.modifierFlags.contains(.control)
        return rightClick || controlClick
    }
}

extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let fd = fontDescriptor.withSymbolicTraits(traits)
        if let font = NSFont(descriptor: fd, size: pointSize) {
            return font
        } else {
            return self
        }
     }

     func italics() -> NSFont {
        return withTraits(.italic)
     }

     func bold() -> NSFont {
         return withTraits(.bold)
     }

     func boldItalics() -> NSFont {
         return withTraits([.bold, .italic])
     }
}

extension NSImage {
    func writeJPGToURL(_ url: URL, quality: Float = 0.85) -> Bool {
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: quality]
        guard let imageData = self.tiffRepresentation else { return false }
        guard let imageRep = NSBitmapImageRep(data: imageData) else { return false }
        guard let fileData = imageRep.representation(using: .jpeg, properties: properties) else { return false }

        do {
            try fileData.write(to: url)
        } catch {
            return false
        }

        return true
    }
    
    func writePNGToURL(_ url: URL) -> Bool {
        guard let imageData = self.tiffRepresentation else { return false }
        guard let imageRep = NSBitmapImageRep(data: imageData) else { return false }
        guard let fileData = imageRep.representation(using: .png, properties: [:]) else { return false }

        do {
            try fileData.write(to: url)
        } catch {
            return false
        }

        return true
    }

    func tint(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()

        return image
    }

    func scaleBy(factor: CGFloat = 0.5) -> NSImage {
        let newSize = NSMakeSize(size.width * factor, size.height * factor)
        let scaledImage = NSImage(size: newSize)
        scaledImage.lockFocus()
        draw(in: NSMakeRect(0, 0, newSize.width, newSize.height))
        scaledImage.unlockFocus()
        return scaledImage
    }
}

extension NSTableView {
    func reloadOnMainThread(_ complete: (() -> ())? = nil) {
        DispatchQueue.main.async {
            self.reloadData()
            complete?()
        }
    }

    func reloadMaintainingSelection(_ complete: (() -> ())? = nil) {
        let oldSelectedRowIndexes = selectedRowIndexes
        reloadOnMainThread {
            if oldSelectedRowIndexes.count == 0 {
                if self.numberOfRows > 0 {
                    self.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                }
            } else {
                self.selectRowIndexes(oldSelectedRowIndexes, byExtendingSelection: false)
            }
        }
    }

    func selectFirstPossibleRow() {
        for i in 0..<numberOfRows {
            if let delegate = delegate, let shouldSelect = delegate.tableView?(self, shouldSelectRow: i) {
                if shouldSelect {
                    selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    return
                }
            } else {
                selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }
        }
    }

    func selectLastPossibleRow() {
        for i in stride(from: numberOfRows - 1, to: 0, by: -1) {
            if let delegate = delegate, let shouldSelect = delegate.tableView?(self, shouldSelectRow: i) {
                if shouldSelect {
                    selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    return
                }
            } else {
                selectRowIndexes(IndexSet(integer: numberOfRows - 1), byExtendingSelection: false)
            }
        }
    }
}

extension NSOutlineView {
    var selectedItem: Any? {
        get {
            if (selectedRow >= 0) && (selectedRow < numberOfRows) {
                return item(atRow: selectedRow)
            } else {
                return nil
            }
        }
    }

    var selectedView: NSView? {
        get {
            if (selectedRow >= 0) && (selectedRow < numberOfRows) {
                return view(atColumn: 0, row: self.selectedRow, makeIfNecessary: false)
            } else {
                return nil
            }
        }
    }

    func expandAll() {
        DispatchQueue.main.async {
            self.expandItem(nil, expandChildren: true)
        }
    }
}

extension NSView {
    func pinEdges(to other: NSView, offset: CGFloat = 0, animate: Bool = false) {
        if animate {
            animator().leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: offset).isActive = true
        } else {
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: offset).isActive = true
            trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
            topAnchor.constraint(equalTo: other.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
        }
    }
}

extension NSWindow {
    func toolbarHeight() -> CGFloat {
        if let windowFrameHeight = contentView?.frame.height {
            let contentLayoutRectHeight = contentLayoutRect.height
            let fullSizeContentViewNoContentAreaHeight = windowFrameHeight - contentLayoutRectHeight
            return fullSizeContentViewNoContentAreaHeight
        }
        
        return 0
    }
}

extension String {
    // I should really just stop using these and switch to one of the better, full-featured attributed string
    // libraries, but meh. This stuff works for now.
    func boldString(textColor: NSColor = NSColor.textColor) -> NSMutableAttributedString {
        let attrStr = NSMutableAttributedString(string: self)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: NSRange(self.startIndex..., in: self))
        attrStr.addAttribute(NSAttributedString.Key.font, value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize), range: NSRange(self.startIndex..., in: self))
        return attrStr
    }

    func coloredAttributedString(textColor: NSColor = NSColor.textColor) -> NSMutableAttributedString {
        let attrStr = NSMutableAttributedString(string: self)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: NSRange(self.startIndex..., in: self))
        attrStr.addAttribute(NSAttributedString.Key.font, value: NSFont.systemFont(ofSize: NSFont.systemFontSize), range: NSRange(self.startIndex..., in: self))
        return attrStr
    }
}
