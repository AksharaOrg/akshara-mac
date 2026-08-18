import Cocoa

@objc(AksharaCapsLockHUD)
public class CapsLockHUD: NSObject {
    @objc public static let shared = CapsLockHUD()

    private var window: NSWindow?
    private var dismissTimer: Timer?
    private var lastKnownState: Bool = false
    private var monitor: Any?

    private override init() {
        super.init()
        // Register global event monitor for Caps Lock changes.
        // Input Methods already have keyboard access so this works without
        // additional permissions.
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            let isCapsOn = event.modifierFlags.contains(.capsLock)
            if isCapsOn != self.lastKnownState {
                self.lastKnownState = isCapsOn
                DispatchQueue.main.async {
                    self.displayHUD(capsLockOn: isCapsOn)
                }
            }
        }
        // Also add a local monitor so it works when Akshara itself has focus
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return event }
            let isCapsOn = event.modifierFlags.contains(.capsLock)
            if isCapsOn != self.lastKnownState {
                self.lastKnownState = isCapsOn
                DispatchQueue.main.async {
                    self.displayHUD(capsLockOn: isCapsOn)
                }
            }
            return event
        }
    }

    // Called from ObjC as a fallback (e.g. handleEvent: if it does fire)
    @objc public func showWithCapsLockOn(_ capsLockOn: Bool) {
        DispatchQueue.main.async {
            self.displayHUD(capsLockOn: capsLockOn)
        }
    }

    private func displayHUD(capsLockOn: Bool) {
        assert(Thread.isMainThread)

        // Build window once
        if window == nil {
            let size = NSSize(width: 220, height: 220)
            let win = NSWindow(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            win.isOpaque = false
            win.backgroundColor = .clear
            // Use the highest possible window level so it appears above everything
            win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            win.ignoresMouseEvents = true
            win.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .stationary]
            win.isReleasedWhenClosed = false

            let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
            effectView.material = .hudWindow
            effectView.blendingMode = .behindWindow
            effectView.state = .active
            effectView.wantsLayer = true
            effectView.layer?.cornerRadius = 20
            effectView.layer?.masksToBounds = true

            let hudView = HUDView(frame: NSRect(origin: .zero, size: size))
            effectView.addSubview(hudView)

            win.contentView = effectView
            window = win
        }

        guard let window = window,
              let effectView = window.contentView as? NSVisualEffectView,
              let hudView = effectView.subviews.first as? HUDView
        else { return }

        hudView.isCapsOn = capsLockOn
        hudView.needsDisplay = true

        // Center horizontally, 120pt above bottom of main screen
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.midX - window.frame.width / 2
            let y = sf.minY + 120
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.alphaValue = 0.0
        window.orderFrontRegardless()

        dismissTimer?.invalidate()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            window.animator().alphaValue = 1.0
        }, completionHandler: {
            let win = window
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.4
                    win.animator().alphaValue = 0.0
                }, completionHandler: {
                    win.orderOut(nil)
                })
            }
        })
    }
}

class HUDView: NSView {
    var isCapsOn: Bool = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        let bounds = self.bounds

        // "අක" badge box
        let boxW: CGFloat = 84, boxH: CGFloat = 60
        let boxRect = NSRect(
            x: bounds.midX - boxW / 2,
            y: bounds.midY - boxH / 2 + 14,
            width: boxW, height: boxH
        )
        let boxPath = NSBezierPath(roundedRect: boxRect, xRadius: 10, yRadius: 10)

        // Highlighter Green #1BFC06 when ON, dark when OFF
        let onColor  = NSColor(red: 0x34/255.0, green: 0xC7/255.0, blue: 0x59/255.0, alpha: 1)
        let offColor = NSColor(white: 0.22, alpha: 1)
        (isCapsOn ? onColor : offColor).setFill()
        boxPath.fill()

        // "අක" text
        let font = NSFont(name: "Sinhala Sangam MN", size: 40) ?? NSFont.systemFont(ofSize: 40)
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: isCapsOn ? NSColor.black : NSColor.white
        ]
        let label = NSAttributedString(string: "අක", attributes: labelAttrs)
        let ls = label.size()
        label.draw(at: NSPoint(x: bounds.midX - ls.width / 2,
                               y: boxRect.midY - ls.height / 2))

        // Status text
        let statusAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let statusLabel = NSAttributedString(
            string: isCapsOn ? "Caps Lock On" : "Caps Lock Off",
            attributes: statusAttrs
        )
        let sl = statusLabel.size()
        statusLabel.draw(at: NSPoint(x: bounds.midX - sl.width / 2, y: bounds.minY + 42))

        ctx.restoreGState()
    }
}
