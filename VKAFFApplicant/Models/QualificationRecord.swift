import Foundation

struct QualificationRecord: Identifiable, Codable {
    let id: UUID
    var qualification: HighestQualification
    var qualificationOther: String
    var fieldOfStudy: String
    var institution: String
    var year: Int

    init(
        id: UUID = UUID(),
        qualification: HighestQualification = .diploma,
        qualificationOther: String = "",
        fieldOfStudy: String = "",
        institution: String = "",
        year: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.id = id
        self.qualification = qualification
        self.qualificationOther = qualificationOther
        self.fieldOfStudy = fieldOfStudy
        self.institution = institution
        self.year = year
    }
}
