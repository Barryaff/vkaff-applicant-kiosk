import SwiftUI

struct DeclarationConsentView: View {
    @Environment(RegistrationViewModel.self) var vm
    @State private var showSubmitGuidance: Bool = false

    private var canSubmit: Bool {
        if AppConfig.skipValidation { return true }
        guard vm.applicant.declarationAccuracy,
              vm.applicant.pdpaConsent,
              vm.applicant.signatureData != nil else { return false }

        // Validate conditional detail fields are filled when user answered "Yes"
        if vm.applicant.hasConnectionsAtAFF && vm.applicant.connectionsDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if vm.applicant.hasConflictOfInterest && vm.applicant.conflictDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if vm.applicant.hasBankruptcy && vm.applicant.bankruptcyDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if vm.applicant.hasLegalProceedings && vm.applicant.legalDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        if vm.applicant.hasMedicalCondition == .yes && vm.applicant.medicalDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }

        return true
    }

    var body: some View {
        @Bindable var vm = vm
        FormScreenLayout(
            title: "Declaration & Consent",
            stepIndex: 5,
            onBack: { vm.navigateBack() },
            onContinue: { vm.navigateForward() },
            continueTitle: "Submit Application",
            isContinueEnabled: canSubmit
        ) {
            // General Information
            Text("General Information")
                .subheadingStyle()

            YesNoQuestion(
                question: "Have you previously applied to Advanced Flavors & Fragrances?",
                value: $vm.applicant.previouslyApplied
            )

            YesNoQuestion(
                question: "Do you have any friends or relatives currently employed at AFF?",
                value: $vm.applicant.hasConnectionsAtAFF
            )

            if vm.applicant.hasConnectionsAtAFF {
                FormField(
                    label: "Please provide name(s) and relationship",
                    text: $vm.applicant.connectionsDetails,
                    placeholder: "e.g., John Tan — cousin",
                    maxLength: 500,
                    errorMessage: vm.fieldErrors["connectionsDetails"]
                )
            }

            YesNoQuestion(
                question: "Do you have any conflict of interest with AFF or its subsidiaries?",
                value: $vm.applicant.hasConflictOfInterest
            )

            if vm.applicant.hasConflictOfInterest {
                FormField(
                    label: "Please provide details",
                    text: $vm.applicant.conflictDetails,
                    placeholder: "Describe the conflict of interest",
                    maxLength: 500,
                    errorMessage: vm.fieldErrors["conflictDetails"]
                )
            }

            YesNoQuestion(
                question: "Have you ever been declared bankrupt or are currently an undischarged bankrupt?",
                value: $vm.applicant.hasBankruptcy
            )

            if vm.applicant.hasBankruptcy {
                FormField(
                    label: "Please provide details",
                    text: $vm.applicant.bankruptcyDetails,
                    placeholder: "Provide relevant details",
                    maxLength: 500,
                    errorMessage: vm.fieldErrors["bankruptcyDetails"]
                )
            }

            YesNoQuestion(
                question: "Are you currently involved in any legal proceedings?",
                value: $vm.applicant.hasLegalProceedings
            )

            if vm.applicant.hasLegalProceedings {
                FormField(
                    label: "Please provide details",
                    text: $vm.applicant.legalDetails,
                    placeholder: "Provide relevant details",
                    maxLength: 500,
                    errorMessage: vm.fieldErrors["legalDetails"]
                )
            }

            Divider().padding(.vertical, 12)

            // 1. Declaration of Accuracy (Required)
            ConsentBlock(
                isChecked: $vm.applicant.declarationAccuracy,
                title: "Declaration of Accuracy",
                isRequired: true,
                consentText: "I declare that all information provided in this application is true, complete, and accurate to the best of my knowledge. I understand that any misrepresentation or omission of facts may result in the rejection of my application or termination of employment if discovered after hiring.",
                checkboxLabel: "I agree"
            )

            // 2. PDPA Consent (Required)
            ConsentBlock(
                isChecked: $vm.applicant.pdpaConsent,
                title: "PDPA Consent",
                isRequired: true,
                consentText: "I consent to Advanced Flavors & Fragrances Pte. Ltd. collecting, using, and disclosing my personal data provided in this form for the purposes of recruitment, employment evaluation, and related HR administration, in accordance with the Personal Data Protection Act 2012 (PDPA) of Singapore. I understand that my data will be retained for a period of up to 2 years from the date of this application, after which it will be securely disposed of unless I am offered employment.",
                checkboxLabel: "I consent"
            )

            // 3. Medical Declaration
            VStack(alignment: .leading, spacing: 12) {
                Text("Medical Declaration")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vkaPurple)

                Text("Do you have any pre-existing medical conditions, disabilities, or special needs that may affect your ability to perform the role(s) applied for?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.darkText)
                    .lineSpacing(4)

                ForEach(MedicalDeclaration.allCases, id: \.self) { option in
                    Button {
                        vm.applicant.hasMedicalCondition = option
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: vm.applicant.hasMedicalCondition == option ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(vm.applicant.hasMedicalCondition == option ? .vkaPurple : .mediumGray)
                            Text(option.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(.darkText)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Medical condition: \(option.rawValue)")
                    .accessibilityValue(vm.applicant.hasMedicalCondition == option ? "selected" : "not selected")
                    .accessibilityAddTraits(vm.applicant.hasMedicalCondition == option ? [.isButton, .isSelected] : [.isButton])
                    .accessibilityHint("Double tap to select \(option.rawValue)")
                }

                if vm.applicant.hasMedicalCondition == .yes {
                    FormField(
                        label: "Please provide details (strictly confidential)",
                        text: $vm.applicant.medicalDetails,
                        placeholder: "Describe any relevant conditions",
                        isMultiline: true,
                        maxLength: 1000,
                        errorMessage: vm.fieldErrors["medicalDetails"]
                    )
                }
            }

            // Signature
            Divider().padding(.vertical, 12)

            SignatureField(signatureData: $vm.applicant.signatureData)

            if showSubmitGuidance && !canSubmit {
                Text("Please complete all required fields: declaration checkbox, PDPA consent, and signature.")
                    .font(.system(size: 14))
                    .foregroundColor(.errorRed)
                    .padding(.top, 8)
                    .accessibilityLabel("Please complete all required fields: declaration checkbox, PDPA consent, and signature.")
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSubmitGuidance = true
            }
        }
        .onChange(of: canSubmit) { _, newValue in
            if newValue {
                showSubmitGuidance = false
            }
        }
    }
}

// MARK: - Consent Block

struct ConsentBlock: View {
    @Binding var isChecked: Bool
    let title: String
    var isRequired: Bool = false
    let consentText: String
    var checkboxLabel: String = "I agree"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vkaPurple)
                    .accessibilityAddTraits(.isHeader)

                if isRequired {
                    Text("Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.affOrange)
                        )
                }
            }

            Text(consentText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.darkText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isChecked.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundColor(isChecked ? .vkaPurple : .mediumGray)

                    Text(checkboxLabel)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.darkText)

                    if isRequired {
                        Text("*")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.errorRed)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title): \(checkboxLabel). Required.")
            .accessibilityValue(isChecked ? "checked" : "unchecked")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to \(isChecked ? "uncheck" : "check")")
        }
        .padding(.bottom, 16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Yes/No Question

struct YesNoQuestion: View {
    let question: String
    @Binding var value: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.darkText)

            HStack(spacing: 16) {
                ForEach([true, false], id: \.self) { option in
                    Button {
                        value = option
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: value == option ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(value == option ? .vkaPurple : .mediumGray)
                            Text(option ? "Yes" : "No")
                                .font(.system(size: 16))
                                .foregroundColor(.darkText)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(question): \(option ? "Yes" : "No")")
                    .accessibilityValue(value == option ? "selected" : "not selected")
                    .accessibilityAddTraits(value == option ? [.isButton, .isSelected] : [.isButton])
                    .accessibilityHint("Double tap to select \(option ? "Yes" : "No")")
                }
            }
        }
        .padding(.vertical, 4)
    }
}
