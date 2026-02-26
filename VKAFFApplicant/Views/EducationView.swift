import SwiftUI

struct EducationView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @FocusState private var focusedField: EducationFocus?

    var body: some View {
        FormScreenLayout(
            title: "Education & Qualifications",
            stepIndex: 1,
            onBack: { vm.navigateBack() },
            onContinue: { vm.navigateForward() }
        ) {
            // Highest Qualification
            FormDropdown(
                label: "Highest Qualification",
                selection: $vm.applicant.highestQualification
            )

            // Field of Study
            FormField(
                label: "Field of Study",
                text: $vm.applicant.fieldOfStudy,
                placeholder: "e.g., Chemistry, Food Science",
                errorMessage: vm.fieldErrors["fieldOfStudy"],
                isValid: vm.validFields.contains("fieldOfStudy"),
                educationFocusBinding: $focusedField,
                educationFocusValue: .fieldOfStudy
            )

            // Institution
            FormField(
                label: "Institution Name",
                text: $vm.applicant.institutionName,
                placeholder: "e.g., Singapore Polytechnic",
                errorMessage: vm.fieldErrors["institutionName"],
                isValid: vm.validFields.contains("institutionName"),
                educationFocusBinding: $focusedField,
                educationFocusValue: .institutionName
            )

            // Year of Graduation
            VStack(alignment: .leading, spacing: 6) {
                Text("Year of Graduation")
                    .formLabelStyle()

                Picker("", selection: $vm.applicant.yearOfGraduation) {
                    ForEach(1970...2026, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.lightBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.dividerSubtle, lineWidth: 1)
                )
            }

            // Additional Qualifications
            Divider().padding(.vertical, 8)

            Text("Additional Qualifications")
                .subheadingStyle()

            RepeatableCardSection(
                title: "Qualification",
                items: $vm.applicant.additionalQualifications,
                maxItems: AppConfig.maxQualifications,
                createNew: { QualificationRecord() }
            ) { $qual in
                FormDropdown(
                    label: "Qualification",
                    selection: $qual.qualification
                )
                FormField(
                    label: "Institution",
                    text: $qual.institution,
                    placeholder: "Institution name"
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("Year")
                        .formLabelStyle()
                    Picker("", selection: $qual.year) {
                        ForEach(1970...2026, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Professional Certifications
            FormField(
                label: "Professional Certifications / Licenses (optional)",
                text: $vm.applicant.professionalCertifications,
                placeholder: "e.g., WSQ certifications, food safety, forklift license, ISO auditor, etc.",
                isMultiline: true,
                educationFocusBinding: $focusedField,
                educationFocusValue: .certifications
            )

            // Language Proficiency
            Divider().padding(.vertical, 8)

            LanguageChipSelector(selectedLanguages: $vm.applicant.selectedLanguages)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField != .certifications {
                    Button("Next") {
                        advanceFocus()
                    }
                    .foregroundColor(.affOrange)
                }
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
                .foregroundColor(.affOrange)
            }
        }
    }

    private func advanceFocus() {
        switch focusedField {
        case .fieldOfStudy: focusedField = .institutionName
        case .institutionName: focusedField = .certifications
        case .certifications: focusedField = nil
        case nil: break
        }
    }
}
