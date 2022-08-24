import Foundation

class Expandable: Drawable {
    
    private let header: Drawable
    private let expansion: Drawable
    @State private var buttonText: String
    @State private var expanded: Bool
    private var needsRedraw: (header: RequiresRedraw, expansion: RequiresRedraw)
    
    init(title: String, @DrawableBuilder _ content: () -> [Drawable]) {
    
        self.expanded = false
        let buttonText = State(wrappedValue: "▸ \(title)")
        self._buttonText = buttonText
        let expandButton = Button(text: buttonText.projectedValue)
        self.header = expandButton
        self.expansion = Margin(style: .backgroundColor(.brightBlack), left: 2){
            VStack(content)
        }
        
        needsRedraw = (header: .yes, expansion: .yes)
        
        expandButton.align(.start, .center)
            .onPush {
                self.expanded.toggle()
                self.buttonText = (self.expanded ? "▾" : "▸") + " \(title)"
                self.needsRedraw = (header: .yes, expansion: .yes)
            }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
   
        let (headerBounds, expansionBounds) = getChildBounds(from: bounds)
        
        let headerDrew: DidRedraw
        if needsRedraw.header == .yes || forced{
            headerDrew = header.draw(with: screenWriter.bound(to: headerBounds), in: headerBounds, force: forced)
        }else {
            headerDrew = .skippedDraw
        }
        
        guard expanded else {
            self.needsRedraw = (header: .no, expansion: .no)
            return headerDrew
        }
        
        let expansionDrew: DidRedraw
        if needsRedraw.expansion == .yes || forced {
            expansionDrew = expansion.draw(with: screenWriter.bound(to: expansionBounds), in: expansionBounds, force: forced)
        }else{
            expansionDrew = .skippedDraw
        }
        
        self.needsRedraw = (header: .no, expansion: .no)
        
        return [expansionDrew, headerDrew].contains(.drew) ? .drew : .skippedDraw
    }
    
    func getChildBounds(from bounds: GlobalDrawBounds) -> (header: GlobalDrawBounds, expansion: GlobalDrawBounds) {
        var availableBounds = bounds
        let headerBounds = header.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
        availableBounds = availableBounds.offsetSize(columns: 0, rows: -headerBounds.height)
            .offset(columns: 0, rows: headerBounds.height)
        
        let expansionBound = expansion.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
        
        return (header: headerBounds, expansion: expansionBound)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        let (headerBounds, expansionBounds) = getChildBounds(from: bounds)
        
        let headerUpdated = header.update(with: cause, in: headerBounds)
    
        needsRedraw = (header: headerUpdated || needsRedraw.header, expansion: .no || needsRedraw.expansion)
                       
        guard expanded else {
            return headerUpdated
        }
        
        let expansionUpdated = expansion.update(with: cause, in: expansionBounds)
        
        needsRedraw = (header: headerUpdated || needsRedraw.header, expansion: expansionUpdated || needsRedraw.expansion)
        
        return needsRedraw.header || needsRedraw.expansion
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
        let (headerBounds, expansionBounds) = getChildBounds(from: bounds)
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
