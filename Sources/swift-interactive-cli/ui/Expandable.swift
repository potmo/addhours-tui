import Foundation

class Expandable: Drawable {
    
    private var expanded: Bool
    private var header: ContainerChild<Button>
    private var expansion: ContainerChild<Margin>
    
    init(title: String, @DrawableBuilder _ content: () -> [Drawable]) {
    
        self.expanded = false
        
        self.header = ContainerChild(drawable: Button(text: "▸ \(title)"))
        self.expansion = ContainerChild(drawable: Margin(style: .backgroundColor(.brightBlack), left: 2){
            VStack(content)
        })
        
        self.header.drawable
            .set(horizontalAlignment: .start, verticalAlignment: .center)
            .onPress { button in
                self.expanded.toggle()
                self.header.drawable.text( (self.expanded ? "▾" : "▸") + " \(title)" )
            }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
   
        (self.header, self.expansion) = updateChildBounds(header: header, expansion: expansion, with: bounds)
        
        header = header.draw(with: screenWriter, force: forced)
        
        guard expanded else {
            return header.didDraw
        }
        
        expansion = expansion.draw(with: screenWriter, force: forced)
        
        return [expansion.didDraw, header.didDraw].contains(.drew) ? .drew : .skippedDraw
    }
    
    func updateChildBounds<H: Drawable, E: Drawable>(header: ContainerChild<H>,
                           expansion: ContainerChild<E>,
                           with bounds: GlobalDrawBounds) -> (header: ContainerChild<H>, expansion: ContainerChild<E>) {
        var availableBounds = bounds
        let headerBounds = header.drawable.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
        let newHeader = header.updateDrawBounds(with: headerBounds)
        availableBounds = availableBounds.offsetSize(columns: 0, rows: -headerBounds.height)
            .offset(columns: 0, rows: headerBounds.height)
        
        let expansionBound = expansion.drawable.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
        let newExpansion = expansion.updateDrawBounds(with: expansionBound)
        
        return (header: newHeader, expansion: newExpansion)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        (self.header, self.expansion) = updateChildBounds(header: header, expansion: expansion, with: bounds)
        
        header = header.update(with: cause)
        
        guard expanded else {
            return header.requiresRedraw
        }
        
        expansion = expansion.update(with: cause)
        
        return header.requiresRedraw || expansion.requiresRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        let headerSize = header.drawable.getMinimumSize()
        if expanded {
            let expansionSize = expansion.drawable.getMinimumSize()
            return DrawSize(width: max(headerSize.width, expansionSize.width), height: headerSize.height + expansionSize.height)
        } else {
            return headerSize
        }
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        let (header, expansion) = updateChildBounds(header: header, expansion: expansion, with: bounds)
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
