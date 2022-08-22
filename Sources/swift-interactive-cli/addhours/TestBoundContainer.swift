import Foundation

class TestDynamicText: BindableLogic {
        
    @State var text: String = "Hello"
    @State var buttonText:String = "The Button"
    
    var children: [Drawable] {
        
        Button(text: $buttonText).minSize(minHeight: 3)
        
        Text(text: $text, style: .color(.ansi(.red)))
    }

    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) {
        switch cause {
            case .keyboard(.pressKey(code: "u",_)):
                text = "press updated \(Int.random(in: 1..<100))"
            case .keyboard(.pressKey(code: "w",_)):
                text = "wow\nhello"
            default:
                break
        }
    }
}
