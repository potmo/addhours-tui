import Foundation

class Menu: Drawable {
    
    private var children: [MenuItem]
    init(children: [MenuItem]){
        self.children = children
    }
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        // update states
        if case let .mouse(event) = cause {
           
            var currentBounds = bounds
            
            for (index, child) in children.enumerated() {
                
                // Stop when we are about to draw out of bounds
                if (currentBounds.height <= 0) {
                    break
                }
                
                let (newChild, usedSpace) = child.updateMouse(with: event,
                                                              in: currentBounds,
                                                              horizontally: .fill,
                                                              vertically: .alignStart)
                
                children[index] = newChild
                
                currentBounds = currentBounds.offset(columns: 0, rows: usedSpace.height)
                    .offsetSize(columns: 0, rows: -usedSpace.height)
            }
        }
        
        var currentBounds = bounds
        
        for child in children {
            
            // Stop when we are about to draw out of bounds
            if (currentBounds.height <= 0) {
                break
            }
            
            //TODO: Figure out caching
            let usedSpace = child.draw(cause: cause,
                                       in: currentBounds,
                                       with: screenWriter,
                                       horizontally: .fill,
                                       vertically: .alignStart)
            currentBounds = currentBounds.offset(columns: 0, rows: usedSpace.height)
                .offsetSize(columns: 0, rows: -usedSpace.height)
        }
        
        return getMinimumSize()
        
    }
    
    func getMinimumSize() -> DrawSize {
        let childSizes = children.map{$0.getMinimumSize()}
        let width = childSizes.map(\.width).max() ?? 0
        let height = childSizes.map(\.height).reduce(0, +)
        return DrawSize(width: width, height: height)
    }
    
    
}

enum MenuItem:Drawable {
    case branch(title: String, children: [MenuItem], `open`: Bool, state: MouseState)
    case leaf(drawable: Drawable)

    func updateMouse(with mouseEvent: Mouse, in bounds: GlobalDrawBounds, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> (MenuItem, DrawSize) {
        
        switch self {
            case .branch(let title, let children, let open, let state):
                let menuArrowWidth = 2
                let titleWidth = menuArrowWidth + (title.lines.map(\.count).max() ?? 0)
                let titleHeight = title.lines.count
                let titleSize = DrawSize(width: titleWidth, height: titleHeight)
                let drawBounds = bounds.truncateToSize(size: titleSize,
                                                       horizontally: horizontalDirective,
                                                       vertically: verticalDirective)
                
                let childIndentation = 1
                var currentBounds = bounds.offset(columns: 0, rows: drawBounds.height)
                    .offsetSize(columns: 0 , rows: -drawBounds.height)
                    .offset(columns: childIndentation, rows: 0)
                    .offsetSize(columns: -childIndentation, rows: 0)
                
                var newChildren:[MenuItem] = []
                for (index, child) in children.enumerated() {
                    
                    // Stop when we are about to draw out of bounds
                    if (currentBounds.height <= 0) {
                        // fast forward with all others unmodified
                        newChildren.append(contentsOf: children[index...])
                        break
                    }
                    
                    //TODO: Figure out caching
                    let (newChild, usedSpace) = child.updateMouse(with: mouseEvent,
                                                                  in: currentBounds,
                                                                  horizontally: .fill,
                                                                  vertically: .alignStart)
                    currentBounds = currentBounds.offset(columns: 0, rows: usedSpace.height)
                        .offsetSize(columns: 0, rows: -usedSpace.height)

                    newChildren.append(newChild)
                }
                
                
                if state == .normal, case let .move(x, y,_,_,_) = mouseEvent {
                    if drawBounds.contains(x: x, y: y) {
                        let newBranch = MenuItem.branch(title: title,
                                                        children: newChildren,
                                                        open: open,
                                                        state: .hovered)
                        return (newBranch, newBranch.getMinimumSize())
                    }
                }
                
                if state == .hovered, case let .move(x, y,_,_,_) = mouseEvent {
                    if !drawBounds.contains(x: x,y: y) {
                        let newBranch = MenuItem.branch(title: title,
                                                        children: newChildren,
                                                        open: open,
                                                        state: .normal)
                        return (newBranch, newBranch.getMinimumSize())
                    }
                }
                
                if state == .hovered, case let .leftButtonDown(x, y,_,_,_) = mouseEvent {
                    if drawBounds.contains(x: x,y: y) {
                        let newBranch = MenuItem.branch(title: title,
                                                        children: newChildren,
                                                        open: open,
                                                        state: .pressed)
                        return (newBranch, newBranch.getMinimumSize())
                    }
                }
                
                if state == .pressed, case let .leftButtonUp(x, y,_,_,_) = mouseEvent {
                    if drawBounds.contains(x: x,y: y) {
                        let newBranch = MenuItem.branch(title: title,
                                                        children: newChildren,
                                                        open: !open,
                                                        state: .hovered)
                        return (newBranch, newBranch.getMinimumSize())
                        
                    } else {
                        let newBranch = MenuItem.branch(title: title,
                                                        children: newChildren,
                                                        open: open,
                                                        state: .normal)
                        return (newBranch, newBranch.getMinimumSize())
                    }
                }
                
                
                let newBranch = MenuItem.branch(title: title,
                                                children: newChildren,
                                                open: open,
                                                state: state)
                return (newBranch, newBranch.getMinimumSize())
                
            case .leaf(let drawable):
                return (self, drawable.getMinimumSize())
        }
        
    }
    
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        switch self {
            case .branch(let title, let children, let open, let state):
                
                //TODO: Really break this out into a separate function
                let menuArrowWidth = 2
                let titleWidth = menuArrowWidth + (title.lines.map(\.count).max() ?? 0)
                let titleHeight = title.lines.count
                let titleSize = DrawSize(width: titleWidth, height: titleHeight)
                let drawBounds = bounds.truncateToSize(size: titleSize,
                                                       horizontally: horizontalDirective,
                                                       vertically: verticalDirective)
                                
                let triangle = open ? "▾" : "▸"
                let text = triangle + " " + title
                let drawSize = DrawSize(width: drawBounds.width, height: drawBounds.height)
                
                let style: TextStyle
                switch state {
                    case .normal:
                        style = TextStyle().color(.ansi(.red))
                    case .hovered:
                        style = TextStyle().color(.ansi(.brightRed))
                    case .pressed:
                        style = TextStyle().color(.ansi(.brightRed)).bold()
                }
                
                let appearence = text.rightPadFit(with: " ", toFit: drawSize.width, ellipsis: true)
                    .bottomPadFit(with: " ", repeated: drawSize.width, toFit: drawSize.height)
                    .with(style: style)
                    .escapedString()
                
                screenWriter.print(appearence, column: drawBounds.column, row: drawBounds.row)
                
                let childIndentation = 1
                var currentBounds = bounds.offset(columns: 0, rows: drawBounds.height)
                    .offsetSize(columns: 0 , rows: -drawBounds.height)
                    .offset(columns: childIndentation, rows: 0)
                    .offsetSize(columns: -childIndentation, rows: 0)
                
                var usedHeight = 0
                for child in children {
                    
                    // Stop when we are about to draw out of bounds
                    if (currentBounds.height <= 0 || currentBounds.width <= 0) {
                        break
                    }
                    
                    //TODO: Figure out caching
                    let usedSpace = child.draw(cause: cause,
                                               in: currentBounds,
                                               with: screenWriter,
                                               horizontally: .fill,
                                               vertically: .alignStart)
                    currentBounds = currentBounds.offset(columns: 0, rows: usedSpace.height)
                        .offsetSize(columns: 0, rows: -usedSpace.height)
                    usedHeight += usedSpace.height
                }
                
                // write indentation
                let indentationPadding = Array(repeating: " ", count: childIndentation).joined(separator: "")
                for row in bounds.row+1..<bounds.row + 1 + usedHeight {
                    screenWriter.print(indentationPadding, column: bounds.column, row: row)
                }
                
                return getMinimumSize()
                
            case .leaf(let drawable):
                // TODO: figure out the caching
                return drawable.draw(cause: .forced,
                                     in: bounds,
                                     with: screenWriter,
                                     horizontally: horizontalDirective,
                                     vertically: verticalDirective)
        }
        
    }
    
    func getMinimumSize() ->DrawSize {
        switch self {
            case .leaf(let drawable):
                return drawable.getMinimumSize()
            case .branch(let title, let children, let open, _):
                let menuArrowWidth = 2
                let titleWidth = menuArrowWidth + (title.lines.map(\.count).max() ?? 0)
                let titleHeight = title.lines.count
                guard open else {
                    return DrawSize(width: titleWidth, height: titleHeight)
                }
                let childSizes = children.map{$0.getMinimumSize()}
                
                let width = max(titleWidth, childSizes.map(\.width).max() ?? 0)
                let height = titleHeight + childSizes.map(\.height).reduce(0, +)
                return DrawSize(width: width, height: height)
        }
    }
    
    enum MouseState {
        case hovered
        case pressed
        case normal
    }
}
