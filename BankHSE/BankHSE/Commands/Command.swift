import Foundation

protocol Command {
    associatedtype Result
    
    func execute() -> Result
}

protocol VoidCommand: Command where Result == Void {
    func execute()
}
