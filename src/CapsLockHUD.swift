import Cocoa
import Carbon

@objc(AksharaCapsLockHUD)
public class CapsLockHUD: NSObject {
    @objc public static let shared = CapsLockHUD()
    
    private var window: NSWindow?
    private var dismissTimer: Timer?
    private var lastKnownState: Bool = NSEvent.modifierFlags.contains(.capsLock)
    
    private override init() {
        super.init()
        startMonitoring()
    }
    
    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentState = NSEvent.modifierFlags.contains(.capsLock)
            if currentState != self.lastKnownState {
                self.lastKnownState = currentState
                if self.isAksharaActive() {
                    self.show(capsLockOn: currentState)
                }
            }
        }
    }
    
    private func isAksharaActive() -> Bool {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return false }
        if let idPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID) {
            let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            return id.contains("com.local.inputmethod.Akshara")
        }
        return false
    }
    
    @objc public func show(capsLockOn: Bool) {
        // Ensure we execute on main thread
        DispatchQueue.main.async {
            self.displayHUD(capsLockOn: capsLockOn)
        }
    }
    
    private func displayHUD(capsLockOn: Bool) {
        if window == nil {
            let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 220, height: 220),
                               styleMask: .borderless,
                               backing: .buffered,
                               defer: false)
            win.isOpaque = false
            win.backgroundColor = .clear
            win.level = .screenSaver // Very high level
            win.ignoresMouseEvents = true
            win.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
            
            let contentView = HUDView(frame: win.contentView!.bounds)
            win.contentView = contentView
            window = win
        }
        
        guard let window = window, let hudView = window.contentView as? HUDView else { return }
        
        // Update state
        hudView.isCapsOn = capsLockOn
        hudView.needsDisplay = true
        
        // Position at bottom center of the main screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (window.frame.width / 2)
            let y = screenRect.minY + 120 // 120 points above the dock/bottom
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.alphaValue = 0.0
        window.orderFrontRegardless() // Force it to the absolute front
        
        // Cancel any existing timer
        dismissTimer?.invalidate()
        
        // Fade in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }, completionHandler: {
            // Schedule fade out
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.5
                    window.animator().alphaValue = 0.0
                }, completionHandler: {
                    window.orderOut(nil)
                })
            }
        })
    }
}

class HUDView: NSView {
    var isCapsOn: Bool = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        
        // Draw background squircle
        let bounds = self.bounds
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 20, dy: 20), xRadius: 24, yRadius: 24)
        
        // Translucent dark background for the HUD itself
        NSColor(white: 0.1, alpha: 0.85).setFill()
        bgPath.fill()
        
        // Draw the inner "අක" box
        let innerBoxSize = CGSize(width: 84, height: 60)
        let innerBoxRect = NSRect(x: bounds.midX - innerBoxSize.width/2,
                                  y: bounds.midY - innerBoxSize.height/2 + 15,
                                  width: innerBoxSize.width,
                                  height: innerBoxSize.height)
        
        let innerPath = NSBezierPath(roundedRect: innerBoxRect, xRadius: 10, yRadius: 10)
        
        // Highlighter Green #1BFC06
        let highlightColor = NSColor(red: 27.0/255.0, green: 252.0/255.0, blue: 6.0/255.0, alpha: 1.0)
        let normalColor = NSColor(white: 0.3, alpha: 1.0)
        
        if isCapsOn {
            highlightColor.setFill()
        } else {
            normalColor.setFill()
        }
        innerPath.fill()
        
        // Draw the "අක" text
        let text = "අක"
        let font = NSFont(name: "Sinhala Sangam MN", size: 42) ?? NSFont.systemFont(ofSize: 42)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: isCapsOn ? NSColor.black : NSColor.white
        ]
        
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attrString.size()
        let textRect = NSRect(x: bounds.midX - textSize.width/2,
                              y: innerBoxRect.midY - textSize.height/2 + 2,
                              width: textSize.width,
                              height: textSize.height)
        attrString.draw(in: textRect)
        
        // Draw "Caps Lock On" or "Caps Lock Off" text below
        let statusText = isCapsOn ? "Caps Lock On" : "Caps Lock Off"
        let statusFont = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: statusFont,
            .foregroundColor: NSColor.white
        ]
        
        let statusAttrString = NSAttributedString(string: statusText, attributes: statusAttributes)
        let statusSize = statusAttrString.size()
        let statusRect = NSRect(x: bounds.midX - statusSize.width/2,
                                y: bounds.minY + 45,
                                width: statusSize.width,
                                height: statusSize.height)
        statusAttrString.draw(in: statusRect)
        
        context?.restoreGState()
    }
}
