import Foundation

class List: Drawable {
    
    init(){
        self.vstack = VStack()
    }
    
    func addLine(text: String, style: TextStyle) {
        //TODO: Here we should pop children that are outside the drawing area
        // maybe we can restrict to single line elements or something so that we know
        // when we sefely can pop them from the list
        
        //TODO: We should not hardcode the line width
        let lineText = text.components(withMaxLength: 90).joined(separator: "\n")
        let line = StyledText(text: lineText, style: style)
        vstack.addChild(child: line, at: 0)
        
    }
    
    func addLine(line: Drawable) {
        vstack.addChild(child: line, at: 0)
    }
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        return vstack.draw(cause: cause,
                           in: bounds,
                           with: screenWriter,
                           horizontally: horizontalDirective,
                           vertically: verticalDirective)
    }
    
    func getMinimumSize() -> DrawSize {
        vstack.getMinimumSize()
    }
    
    let vstack: VStack
}
