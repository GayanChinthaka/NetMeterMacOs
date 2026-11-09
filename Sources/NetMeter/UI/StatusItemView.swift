import AppKit

public final class StatusItemView: NSView {
    public override var isFlipped: Bool { return true }
    
    // Pass clicks through to NSStatusBarButton so native menu & highlights work
    public override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
    
    // Data
    public var topArrow: String = "↓"
    public var topArrowColor: NSColor = NSColor(red: 0.20, green: 0.85, blue: 0.45, alpha: 1.0)
    public var topText: String = "0 KB/s"
    
    public var bottomArrow: String = "↑"
    public var bottomArrowColor: NSColor = NSColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
    public var bottomText: String = "0 KB/s"
    
    public var isStacked: Bool = true
    public var displayMode: DisplayMode = .both
    public var uploadOnTop: Bool = false
    public var showColors: Bool = true
    public var fontSize: CGFloat = 10.5
    
    // Dynamic fonts based on fontSize
    private var stackedArrowFont: NSFont {
        NSFont.systemFont(ofSize: fontSize, weight: .bold)
    }
    private var stackedTextFont: NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold)
    }
    private var singleArrowFont: NSFont {
        NSFont.systemFont(ofSize: min(15.0, fontSize + 2.0), weight: .bold)
    }
    private var singleTextFont: NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: min(14.5, fontSize + 1.5), weight: .semibold)
    }
    
    public func calculateNeededWidth() -> CGFloat {
        if isStacked {
            let arrowW = ("↓" as NSString).size(withAttributes: [.font: stackedArrowFont]).width
            let textX = ceil(3.0 + arrowW + 3.0)
            
            if displayMode == .both {
                let w1 = (topText as NSString).size(withAttributes: [.font: stackedTextFont]).width
                let w2 = (bottomText as NSString).size(withAttributes: [.font: stackedTextFont]).width
                let maxTextW = max(w1, w2)
                return ceil(textX + maxTextW + 5.0)
            } else {
                let text = (displayMode == .downloadOnly) ? topText : bottomText
                let w = (text as NSString).size(withAttributes: [.font: stackedTextFont]).width
                return ceil(textX + w + 5.0)
            }
        } else {
            // Single line
            let downArrowW = ("↓" as NSString).size(withAttributes: [.font: singleArrowFont]).width
            let upArrowW = ("↑" as NSString).size(withAttributes: [.font: singleArrowFont]).width
            let downTextW = (topText as NSString).size(withAttributes: [.font: singleTextFont]).width
            let upTextW = (bottomText as NSString).size(withAttributes: [.font: singleTextFont]).width
            
            if displayMode == .both {
                return ceil(4.0 + downArrowW + 3.0 + downTextW + 10.0 + upArrowW + 3.0 + upTextW + 6.0)
            } else if displayMode == .downloadOnly {
                return ceil(4.0 + downArrowW + 3.0 + downTextW + 6.0)
            } else {
                return ceil(4.0 + upArrowW + 3.0 + upTextW + 6.0)
            }
        }
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let h = bounds.height
        let textColor = NSColor.labelColor
        
        if isStacked {
            let lineHeight: CGFloat = max(10.0, fontSize + 0.8)
            let totalH = lineHeight * 2.0
            // Vertically center with top breathing margin
            let startY = max(1.0, (h - totalH) / 2.0 + 0.8)
            
            let arrowX: CGFloat = 3.0 // Locked column for both arrows
            let arrowW = ("↓" as NSString).size(withAttributes: [.font: stackedArrowFont]).width
            let textX: CGFloat = ceil(arrowX + arrowW + 3.0)
            
            if displayMode == .both {
                let firstArrow = uploadOnTop ? bottomArrow : topArrow
                let firstArrowColor = showColors ? (uploadOnTop ? bottomArrowColor : topArrowColor) : textColor
                let firstText = uploadOnTop ? bottomText : topText
                
                let secondArrow = uploadOnTop ? topArrow : bottomArrow
                let secondArrowColor = showColors ? (uploadOnTop ? topArrowColor : bottomArrowColor) : textColor
                let secondText = uploadOnTop ? topText : bottomText
                
                // Row 1 (Top)
                let row1Y = startY
                (firstArrow as NSString).draw(
                    at: NSPoint(x: arrowX, y: row1Y),
                    withAttributes: [.font: stackedArrowFont, .foregroundColor: firstArrowColor]
                )
                (firstText as NSString).draw(
                    at: NSPoint(x: textX, y: row1Y),
                    withAttributes: [.font: stackedTextFont, .foregroundColor: textColor]
                )
                
                // Row 2 (Bottom)
                let row2Y = startY + lineHeight
                (secondArrow as NSString).draw(
                    at: NSPoint(x: arrowX, y: row2Y),
                    withAttributes: [.font: stackedArrowFont, .foregroundColor: secondArrowColor]
                )
                (secondText as NSString).draw(
                    at: NSPoint(x: textX, y: row2Y),
                    withAttributes: [.font: stackedTextFont, .foregroundColor: textColor]
                )
                
            } else {
                // Download only or Upload only in stacked style
                let arrow = (displayMode == .downloadOnly) ? topArrow : bottomArrow
                let arrowColor = showColors ? ((displayMode == .downloadOnly) ? topArrowColor : bottomArrowColor) : textColor
                let text = (displayMode == .downloadOnly) ? topText : bottomText
                
                let y = (h - (fontSize + 2.5)) / 2.0 + 0.5
                (arrow as NSString).draw(
                    at: NSPoint(x: arrowX, y: y),
                    withAttributes: [.font: stackedArrowFont, .foregroundColor: arrowColor]
                )
                (text as NSString).draw(
                    at: NSPoint(x: textX, y: y),
                    withAttributes: [.font: stackedTextFont, .foregroundColor: textColor]
                )
            }
            
        } else {
            // Horizontal Single-Line Mode
            let y = (h - (fontSize + 3.5)) / 2.0 + 0.8
            var curX: CGFloat = 4.0
            
            let drawSegment = { (arrow: String, arrowColor: NSColor, speed: String) in
                (arrow as NSString).draw(
                    at: NSPoint(x: curX, y: y),
                    withAttributes: [.font: self.singleArrowFont, .foregroundColor: self.showColors ? arrowColor : textColor]
                )
                let arrowW = (arrow as NSString).size(withAttributes: [.font: self.singleArrowFont]).width
                curX += arrowW + 3.0
                
                (speed as NSString).draw(
                    at: NSPoint(x: curX, y: y),
                    withAttributes: [.font: self.singleTextFont, .foregroundColor: textColor]
                )
                let textW = (speed as NSString).size(withAttributes: [.font: self.singleTextFont]).width
                curX += textW
            }
            
            if displayMode == .both {
                if uploadOnTop {
                    drawSegment(bottomArrow, bottomArrowColor, bottomText)
                    curX += 10.0
                    drawSegment(topArrow, topArrowColor, topText)
                } else {
                    drawSegment(topArrow, topArrowColor, topText)
                    curX += 10.0
                    drawSegment(bottomArrow, bottomArrowColor, bottomText)
                }
            } else if displayMode == .downloadOnly {
                drawSegment(topArrow, topArrowColor, topText)
            } else {
                drawSegment(bottomArrow, bottomArrowColor, bottomText)
            }
        }
    }
}

