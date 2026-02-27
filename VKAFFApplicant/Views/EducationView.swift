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
            // Highest Qualification (filtered by nationality)
            FormDropdown(
                label: "Highest Qualification",
                selection: $vm.applicant.highestQualification,
                options: HighestQualification.options(for: vm.applicant.nationality)
            )

            if vm.applicant.highestQualification == .others {
                FormField(
                    label: "Please specify your qualification",
                    text: $vm.applicant.highestQualificationOther,
                    placeholder: "e.g., Diploma in Engineering",
                    maxLength: 200,
                    errorMessage: vm.fieldErrors["highestQualificationOther"],
                    isValid: vm.validFields.contains("highestQualificationOther")
                )
            }

            // Field of Study
            FormField(
                label: "Field of Study",
                text: $vm.applicant.fieldOfStudy,
                placeholder: "e.g., Chemistry, Food Science",
                maxLength: 200,
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
                maxLength: 200,
                errorMessage: vm.fieldErrors["institutionName"],
                isValid: vm.validFields.contains("institutionName"),
                educationFocusBinding: $focusedField,
                educationFocusValue: .institutionName
            )

            // Year of Graduation (or expected graduation)
            VStack(alignment: .leading, spacing: 6) {
                Text("Year of Graduation (or Expected)")
                    .formLabelStyle()

                let currentYear = Calendar.current.component(.year, from: Date())
                Picker("", selection: $vm.applicant.yearOfGraduation) {
                    ForEach(1970...(currentYear + 6), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Year of Graduation")
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
                    selection: $qual.qualification,
                    options: HighestQualification.options(for: vm.applicant.nationality)
                )
                if qual.qualification == .others {
                    FormField(
                        label: "Please specify",
                        text: $qual.qualificationOther,
                        placeholder: "e.g., Trade Certificate",
                        maxLength: 200
                    )
                }
                FormField(
                    label: "Institution",
                    text: $qual.institution,
                    placeholder: "Institution name",
                    maxLength: 200
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("Year")
                        .formLabelStyle()
                    Picker("", selection: $qual.year) {
                        ForEach(1970...(Calendar.current.component(.year, from: Date()) + 6), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Year of qualification")
                }
            }

            // Professional Certifications
            FormField(
                label: "Professional Certifications / Licenses (optional)",
                text: $vm.applicant.professionalCertifications,
                placeholder: "e.g., WSQ certifications, food safety, forklift license, ISO auditor, etc.",
                isMultiline: true,
                maxLength: 1000,
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
