import Foundation

class ScrollList: Drawable {
    
    
    private var children: [Drawable]
    private var needsRedraw: RequiresRedraw
    private var lastDrawBounds: [GlobalDrawBounds]
    private var scroll = Scroll.bottom
    private let SCROLL_BAR_WIDTH = 1
    
    init(@DrawableBuilder _ content: () -> [Drawable]) {
        self.children = content()
        self.needsRedraw = .yes
        self.lastDrawBounds = []
    }
    
    func setChildren(children: [Drawable]) {
        self.children = children
    }

    
    @discardableResult
    func addChild(_ child: Drawable, at index: Int)->Self {
        //TODO: Maybe if a new element is added above the scroll window we should scroll to compensate
        children.insert(child, at: index)
        needsRedraw = .yes
        return self
    }
    
    @discardableResult
    func addChild(_ child: Drawable)->Self {
        children.append(child)
        needsRedraw = .yes
        return self
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        var childRedrew = false
        var forceRest = false
        
        let childDrawBounds = getChildDrawBounds(in: bounds)
        
        let currentDrawBounds = childDrawBounds.map(\.0)
        
        // if the bounds does not match then that means that we need to redraw all of them
        if lastDrawBounds != currentDrawBounds || needsRedraw == .yes {
            forceRest = true
        }
        
        let childrenToDraw = childDrawBounds
            .filter{ (childBounds, child) in
                // check fully above
                if childBounds.row + childBounds.height < bounds.row {
                    return false
                }
                
                // check fully below
                if childBounds.row > bounds.row + bounds.height {
                    return false
                }
                
                return true
            }
        
        for (drawBounds, child) in childrenToDraw {
            
            let redraw = child.draw(with: screenWriter.bound(to: bounds),
                                    in: drawBounds,
                                    force: forced || forceRest)
            
            switch redraw {
                case .skippedDraw:
                    continue
                case .drew:
                    childRedrew = true
                    forceRest = true
            }
        }
        
        
        
        
        if forceRest {
            let startBackgroundRow: Int
            if let lastChild = childrenToDraw.last {
                startBackgroundRow = max(bounds.row, min(bounds.row + bounds.height, lastChild.0.row + lastChild.0.height))
            } else {
                startBackgroundRow = bounds.row
            }
            
            let backgroundLine = Array(repeating: "/", count: bounds.width).joined()
            for row in startBackgroundRow ..< bounds.row + bounds.height {
                screenWriter.moveTo(bounds.column, row)
                screenWriter.printLineAtCursor(backgroundLine)
            }
            
            let scrollPosition = Double(getScrollPosition(in: bounds))
            let maxScrollPosition = Double(getScrollMaxValue(in: bounds))
            
            let scrollThumbPosition = bounds.row +  1 + Int((Double(bounds.height - 3) * scrollPosition / maxScrollPosition).rounded(.towardZero))
            
            // draw thumbnail. If the height is less than 3 then the scrollbar doesnt fit so then we skip writing it
            if bounds.height >= 3 {
                //TODO: make scrollthumb draggable and clickable
                screenWriter.print("▴", column: bounds.column + bounds.width - 1, row: bounds.row)
                for row in bounds.row + 1 ..< bounds.row + bounds.height - 1 {
                    if row == scrollThumbPosition {
                        screenWriter.print("▤", column: bounds.column + bounds.width - 1, row: row)
                    }
                    else {
                        screenWriter.print("░", column: bounds.column + bounds.width - 1, row: row)
                    }
                    
                }
                screenWriter.print("▾", column: bounds.column + bounds.width - 1, row: bounds.row + bounds.height - 1)
            }
             
        }
        
        needsRedraw = .no
        return childRedrew ? .drew : .skippedDraw
    }
    

    
    private func getScrollPosition(in bounds: GlobalDrawBounds) -> Int {
        switch scroll {
            case .bottom:
                return getMinimumSize().height - bounds.height
            case .top:
                return 0
            case .offset(let offset):
                return offset
        }
    }
    
    private func getScrollMaxValue(in bounds: GlobalDrawBounds) -> Int {
        return max(1,getMinimumSize().height - bounds.height)
    }
    
    func scroll(_ rows: Int, in bounds: GlobalDrawBounds) {
        let scrollOffset = getScrollPosition(in: bounds)
        scroll(to: scrollOffset + rows, in: bounds)
    }
    
    func scroll(to row: Int, in bounds: GlobalDrawBounds) {
        let maxValue = getScrollMaxValue(in: bounds)
        let newOffset = min(maxValue, max(0, row))
        let oldValue = scroll
        if newOffset == maxValue {
            scroll = .bottom
        } else if newOffset == 0 {
            scroll = .top
        } else {
            scroll = .offset(newOffset)
        }
        
        if oldValue != scroll {
            needsRedraw = .yes
        }
        
    }
    func scrollToBottom() {
        guard scroll != .bottom else {
            return
        }
        scroll = .bottom
        needsRedraw = .yes
    }
    
    func scrollToTop() {
        guard scroll != .top else {
            return
        }
        scroll = .top
        needsRedraw = .yes
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        //TODO: handle mouse scroll bar events
        switch cause {
            case .mouse(.scrollUp(let x, let y)):
                if bounds.contains(x: x, y: y) {
                    scroll(-1, in: bounds)
                }
            case .mouse(.scrollDown(let x, let y)):
                if bounds.contains(x: x, y: y) {
                    scroll(1, in: bounds)
                }
            default:
                break
        }
        
        let childDrawBounds = getChildDrawBounds(in: bounds)
        
        let childUpdates = childDrawBounds.map{(drawBounds, child) in
            return child.update(with: cause, in: drawBounds)
        }
        
        lastDrawBounds = childDrawBounds.map(\.0)
        
        if childUpdates.contains(.yes) {
            return .yes
        } else {
            return .no
        }

    }
    
    func getChildDrawBounds(in bounds: GlobalDrawBounds) -> [(GlobalDrawBounds, Drawable)]{
        var childBounds: [(GlobalDrawBounds, Drawable)] = []
        
        let scrollOffset = getScrollPosition(in: bounds)
        
        var row = bounds.row
        for child in children {
            let childSize = child.getMinimumSize()
            let drawBounds = GlobalDrawBounds(column: bounds.column,
                                              row: row,
                                              width: bounds.width,
                                              height: childSize.height)
                .offset(columns: 0, rows: -scrollOffset)
                .offsetSize(columns: -SCROLL_BAR_WIDTH, rows: 0)
            
            childBounds.append((drawBounds, child))
            row += childSize.height
        }
        
        return childBounds
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds
    }
    
    func getMinimumSize() -> DrawSize {
        let sizes = children.map{$0.getMinimumSize()}
        let width = sizes.map(\.width).max() ?? 0
        let height = max(3,sizes.map(\.height).reduce(0,+)) // make sure we have at least three lines for the scroll bar
        
        return DrawSize(width: width, height: height)
    }
    
    
    enum Scroll: Equatable {
        case bottom
        case top
        case offset(_:Int)
    }
    
    
    
    
}
