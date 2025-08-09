import AppKit

// MARK: - HUD toast

final class Toast {
    private var window: NSWindow?
    
    func show(text: String, duration: TimeInterval = 1.25) {
        let label = NSTextField(labelWithString: text)
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.lineBreakMode = .byTruncatingMiddle
        
        let padding: CGFloat = 14
        let size = label.intrinsicContentSize
        let frame = NSRect(x: 0, y: 0, width: size.width + padding*2, height: size.height + padding)
        let win = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .statusBar
        win.hasShadow = true
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.transient, .ignoresCycle]
        
        let bg = NSVisualEffectView(frame: frame)
        bg.material = .hudWindow
        bg.blendingMode = .withinWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 10
        
        label.frame = NSRect(x: padding, y: (frame.height - size.height)/2 - 1, width: size.width, height: size.height)
        bg.addSubview(label)
        win.contentView = bg
        
        if let screen = NSScreen.main {
            let origin = CGPoint(x: screen.frame.maxX - frame.width - 20, y: screen.frame.maxY - frame.height - 36)
            win.setFrameOrigin(origin)
        }
        
        win.alphaValue = 0
        win.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            win.animator().alphaValue = 1
        }
        
        self.window = win
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, let win = self.window else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                win.animator().alphaValue = 0
            }, completionHandler: {
                win.orderOut(nil)
                self.window = nil
            })
        }
    }
}
