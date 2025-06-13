import AlarmKit
import AppIntents

@available(iOS 26.0, *)
struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.pause(id: UUID(uuidString: alarmID)!)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

@available(iOS 26.0, *)
struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alert")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

@available(iOS 26.0, *)
struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.countdown(id: UUID(uuidString: alarmID)!)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Repeat a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

@available(iOS 26.0, *)
struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.resume(id: UUID(uuidString: alarmID)!)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

@available(iOS 26.0, *)
struct OpenAlarmAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Opens the Sample app")
    static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}
