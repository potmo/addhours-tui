import Foundation
import Signals

class DataDispatcher {
    public let commands = Signal<Void>()
    
    init() {
        
    }
    
    func execute<T>( _ executionBlock: @autoclosure @escaping () throws -> T, then completionBlock: @escaping (T) -> Void ) -> Void {
    
        DispatchQueue.global(qos: .background).async {
            do {
                let result = try executionBlock()
                
                DispatchQueue.main.async {
                    completionBlock(result)
                    self.commands.fire()
                }
                
            } catch {
                DispatchQueue.main.async {
                    log.error("executing block threw: \(error)")
                }
            }
        }
    }
}
