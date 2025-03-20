import Foundation

class TimeMeasurementDecorator<T: Command>: Command {
    typealias Result = T.Result
    
    private let wrappedCommand: T
    private let commandName: String
    
    init(wrappedCommand: T, commandName: String) {
        self.wrappedCommand = wrappedCommand
        self.commandName = commandName
    }
    
    func execute() -> T.Result {
        let startTime = Date()
        let result = wrappedCommand.execute()
        let executionTime = Date().timeIntervalSince(startTime)
        
        print("Время выполнения команды '\(commandName)': \(String(format: "%.4f", executionTime)) секунд")
        
        return result
    }
}

class VoidTimeMeasurementDecorator<T: VoidCommand>: VoidCommand {
    private let wrappedCommand: T
    private let commandName: String
    
    init(wrappedCommand: T, commandName: String) {
        self.wrappedCommand = wrappedCommand
        self.commandName = commandName
    }
    
    func execute() {
        let startTime = Date()
        wrappedCommand.execute()
        let executionTime = Date().timeIntervalSince(startTime)
        
        print("Время выполнения команды '\(commandName)': \(String(format: "%.4f", executionTime)) секунд")
    }
}
