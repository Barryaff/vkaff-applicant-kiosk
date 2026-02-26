import Foundation

struct QualificationRecord: Identifiable, Codable {
    let id: UUID
    var qualification: HighestQualification
    var institution: String
    var year: Int

    init(
        id: UUID = UUID(),
        qualification: HighestQualification = .diploma,
        institution: String = "",
        year: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.id = id
        self.qualification = qualification
        self.institution = institution
        self.year = year
    }
}
