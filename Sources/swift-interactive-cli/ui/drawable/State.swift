import Foundation
import Signals

@propertyWrapper
struct Binding<T:Equatable> {
    
    var wrappedValue: T {
        get { return valueBox.value }
        set {
            if valueBox.value != newValue {
                valueBox.value = newValue
                updatedSignal.fire(newValue)
            }
        }
    }
    
    let updatedSignal = Signal<T>()
    fileprivate var valueBox: Box<T>
    
    init(wrappedValue: T) {
        self.valueBox = Box(wrappedValue)
    }
    
    var projectedValue: T {
        valueBox.value
    }
    

}

class Box<T> {
    var value: T
    init(_ value:T){
        self.value = value
    }
}

@propertyWrapper
struct State<T: Equatable> {
    var wrappedValue: T {
        get { return valueBox.value }
        nonmutating set {
            if valueBox.value != newValue {
                valueBox.value = newValue
                updatedSignal.fire(newValue)
            }
        }
    }
    
    init(wrappedValue: T) {
        self.valueBox = Box(wrappedValue)
    }
    
    let updatedSignal = Signal<T>()
    private var valueBox: Box<T>
    
    var projectedValue: Binding<T> {
        var binding = Binding(wrappedValue: wrappedValue)
        binding.updatedSignal.subscribe(with: valueBox) { newValue in
            self.wrappedValue = newValue
        }
        
        updatedSignal.subscribe(with: valueBox){ newValue in
            binding.wrappedValue = newValue
        }
        return binding
    }
    
}
