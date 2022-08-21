import Foundation

class Expandable: BoundDrawable {
    
    private let header: BoundDrawable
    private let expansion: BoundDrawable
    @State private var buttonText: String
    @State private var expanded: Bool
    private var needsRedraw: RequiresRedraw
    
    init(title: String, @BoundDrawableBuilder _ content: () -> [BoundDrawable]) {
    
        self.expanded = false
        let buttonText = State(wrappedValue: "▸ \(title)")
        self._buttonText = buttonText
        let expandButton = BindableButton(text: buttonText.projectedValue)
        self.header = expandButton
        self.expansion = Margin(left: 1){
            BindableVStack(content)
        }
        
        needsRedraw = .yes
        
        expandButton.align(.start, .center)
            .onPush {
                self.expanded.toggle()
                self.buttonText = (self.expanded ? "▾" : "▸") + " \(title)"
            }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        guard forced || needsRedraw == .yes else {
            return .skippedDraw
        }
        let (headerBounds, expansionBounds) = getChildBounds(from: bounds)
        
        let headerDrew = header.draw(with: screenWriter.bound(to: headerBounds), in: headerBounds, force: forced)
        
        guard expanded else {
            return headerDrew
        }
        
        let expansionDrew = expansion.draw(with: screenWriter.bound(to: expansionBounds), in: expansionBounds, force: forced)
        
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
        
        guard expanded else {
            return headerUpdated
        }
        
        let expansionUpdated = expansion.update(with: cause, in: expansionBounds)
        
        return [expansionUpdated, headerUpdated].contains(.yes) ? .yes : .no
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
