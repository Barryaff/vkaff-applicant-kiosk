import Foundation

struct LanguageProficiency: Identifiable, Codable, Hashable {
    let id: UUID
    var language: Language
    var proficiency: ProficiencyLevel
    var customLanguage: String

    init(
        id: UUID = UUID(),
        language: Language = .english,
        proficiency: ProficiencyLevel = .conversational,
        customLanguage: String = ""
    ) {
        self.id = id
        self.language = language
        self.proficiency = proficiency
        self.customLanguage = customLanguage
    }

    var displayName: String {
        language == .others ? customLanguage : language.rawValue
    }
}

enum Language: String, Codable, CaseIterable, Hashable {
    case english = "English"
    case mandarin = "Mandarin"
    case malay = "Malay"
    case tamil = "Tamil"
    case japanese = "Japanese"
    case korean = "Korean"
    case bahasaIndonesia = "Bahasa Indonesia"
    case thai = "Thai"
    case vietnamese = "Vietnamese"
    case others = "Others"
}

enum ProficiencyLevel: String, Codable, CaseIterable, Hashable {
    case basic = "Basic"
    case conversational = "Conversational"
    case fluent = "Fluent"
    case native = "Native"
}
