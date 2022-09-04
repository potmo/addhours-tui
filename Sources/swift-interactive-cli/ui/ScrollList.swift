import Foundation

class ScrollList: Drawable {
    
    
    private var children: [TypeErasedContainerChild]
    private var scroll = Scroll.bottom
    private let SCROLL_BAR_WIDTH = 1
    
    init(@DrawableBuilder _ content: () -> [Drawable]) {
        self.children = content().map{ drawable in
            return TypeErasedContainerChild(drawable: drawable,
                                  requiresRedraw: .yes,
                                  drawBounds: GlobalDrawBounds(),
                                  didDraw: .skippedDraw)
        }
    }
    
    func setChildren(children: [Drawable]) {
        self.children = children.map{ drawable in
            return TypeErasedContainerChild(drawable: drawable,
                                  requiresRedraw: .yes,
                                  drawBounds: GlobalDrawBounds(),
                                  didDraw: .skippedDraw)
        }
    }

    
    @discardableResult
    func addChild(_ child: Drawable, at index: Int)->Self {
        let containerChild = TypeErasedContainerChild(drawable: child,
                                            requiresRedraw: .yes,
                                            drawBounds: GlobalDrawBounds(),
                                            didDraw: .skippedDraw)
        children.insert(containerChild, at: index)
        
        return self
    }
    
    @discardableResult
    func addChild(_ child: Drawable)->Self {
        let containerChild = TypeErasedContainerChild(drawable: child,
                                            requiresRedraw: .yes,
                                            drawBounds: GlobalDrawBounds(),
                                            didDraw: .skippedDraw)
        children.append(containerChild)
        return self
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        
        self.children = updateChildDrawBounds(children: children, in: bounds)
            .map { child in
                
                if child.drawBounds.row + child.drawBounds.height < bounds.row {
                    return child.didDraw(.skippedDraw)
                }
                
                // check fully below
                if child.drawBounds.row > child.drawBounds.row + bounds.height {
                    return child.didDraw(.skippedDraw)
                }
                
                return child.draw(with: screenWriter,
                                  force: forced)
            }
        
        let childrenInBounds = children.filter{ child in
            if child.drawBounds.row + child.drawBounds.height < bounds.row {
                return false
            }
            
            // check fully below
            if child.drawBounds.row > child.drawBounds.row + bounds.height {
                return false
            }
            
            return true
        }
        
        let didDraw: DidRedraw = children.map(\.didDraw).contains(.drew) ? .drew : .skippedDraw
        
        if didDraw == .drew {
            let startBackgroundRow: Int
            if let lastChild = childrenInBounds.last {
                startBackgroundRow = max(bounds.row, min(bounds.row + bounds.height, lastChild.drawBounds.row + lastChild.drawBounds.height))
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
        
        return didDraw
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
        if newOffset == maxValue {
            scroll = .bottom
        } else if newOffset == 0 {
            scroll = .top
        } else {
            scroll = .offset(newOffset)
        }
    }
    func scrollToBottom() {
        guard scroll != .bottom else {
            return
        }
        scroll = .bottom
    }
    
    func scrollToTop() {
        guard scroll != .top else {
            return
        }
        scroll = .top
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
        
        self.children = updateChildDrawBounds(children: children, in: bounds)
        
        self.children = children.map { child in
            
            if child.drawBounds.row + child.drawBounds.height < bounds.row {
                return child.requiringRedraw(.no)
            }
            
            // check fully below
            if child.drawBounds.row > child.drawBounds.row + bounds.height {
                return child.requiringRedraw(.no)
            }
            
            return child.update(with: cause)
        }
        
        return children.map(\.requiresRedraw).contains(.yes) ? .yes : .no
    }
    
    func updateChildDrawBounds(children: [TypeErasedContainerChild],in bounds: GlobalDrawBounds) -> [TypeErasedContainerChild]{
        
        let scrollOffset = getScrollPosition(in: bounds)
        
        var row = bounds.row
        return children.map { child in
            let childSize = child.drawable.getMinimumSize()
            let drawBounds = GlobalDrawBounds(column: bounds.column,
                                              row: row,
                                              width: bounds.width,
                                              height: childSize.height)
                .offset(columns: 0, rows: -scrollOffset)
                .offsetSize(columns: -SCROLL_BAR_WIDTH, rows: 0)
            
            defer {
                row += childSize.height
            }
            return child.updateDrawBounds(with: drawBounds)
        }
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds
    }
    
    func getMinimumSize() -> DrawSize {
        let sizes = children.map(\.drawable).map{$0.getMinimumSize()}
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
