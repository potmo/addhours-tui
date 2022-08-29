import Foundation

class Expandable: Drawable {
    
    private let header: Button
    private let expansion: Drawable
    private var expanded: Bool
    private var headerChild: ContainerChild
    private var expansionChild: ContainerChild
    
    init(title: String, @DrawableBuilder _ content: () -> [Drawable]) {
    
        self.expanded = false
        
        self.expansion = Margin(style: .backgroundColor(.brightBlack), left: 2){
            VStack(content)
        }
        
        self.header = Button(text: "▸ \(title)")
        
        self.headerChild = ContainerChild(drawable: header, requiresRedraw: .yes, drawBounds: GlobalDrawBounds(), didDraw: .skippedDraw)
        self.expansionChild = ContainerChild(drawable: expansion, requiresRedraw: .yes, drawBounds: GlobalDrawBounds(), didDraw: .skippedDraw)
        
        self.header
            .set(horizontalAlignment: .start, verticalAlignment: .center)
            .onPress { button in
                self.expanded.toggle()
                self.header.text( (self.expanded ? "▾" : "▸") + " \(title)" )
            }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
   
        (self.headerChild, self.expansionChild) = updateChildBounds(header: headerChild, expansion: expansionChild, with: bounds)
        
        headerChild = headerChild.draw(with: screenWriter, force: forced)
        
        guard expanded else {
            return headerChild.didDraw
        }
        
        expansionChild = expansionChild.draw(with: screenWriter, force: forced)
        
        return [expansionChild.didDraw, headerChild.didDraw].contains(.drew) ? .drew : .skippedDraw
    }
    
    func updateChildBounds(header: ContainerChild,
                           expansion: ContainerChild,
                           with bounds: GlobalDrawBounds) -> (header: ContainerChild, expansion: ContainerChild) {
        var availableBounds = bounds
        let headerBounds = header.drawable.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
        let newHeader = header.updateDrawBounds(with: headerBounds)
        availableBounds = availableBounds.offsetSize(columns: 0, rows: -headerBounds.height)
            .offset(columns: 0, rows: headerBounds.height)
        
        let expansionBound = expansion.drawable.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
        let newExpansion = expansionChild.updateDrawBounds(with: expansionBound)
        
        return (header: newHeader, expansion: newExpansion)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        (self.headerChild, self.expansionChild) = updateChildBounds(header: headerChild, expansion: expansionChild, with: bounds)
        
        headerChild = headerChild.update(with: cause)
        
        guard expanded else {
            return headerChild.requiresRedraw
        }
        
        expansionChild = expansionChild.update(with: cause)
        
        return headerChild.requiresRedraw || expansionChild.requiresRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        let headerSize = header.getMinimumSize()
        if expanded {
            let expansionSize = expansion.getMinimumSize()
            return DrawSize(width: max(headerSize.width, expansionSize.width), height: headerSize.height + expansionSize.height)
        } else {
            return headerSize
        }
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        let (header, expansion) = updateChildBounds(header: headerChild, expansion: expansionChild, with: bounds)
        let headerBounds = header.drawBounds
        let expansionBounds = expansion.drawBounds
        
        if expanded {
            return GlobalDrawBounds(column: headerBounds.column,
                                    row: headerBounds.row,
                                    width: max(headerBounds.width, expansionBounds.width),
                                    height: headerBounds.height + expansionBounds.height)
        } else {
            return headerBounds
        }
    }
    
    
}
