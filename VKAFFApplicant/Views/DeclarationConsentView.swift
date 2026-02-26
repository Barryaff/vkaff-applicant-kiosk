import SwiftUI

struct DeclarationConsentView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    private var canSubmit: Bool {
        if AppConfig.skipValidation { return true }
        return vm.applicant.declarationAccuracy
            && vm.applicant.pdpaConsent
            && vm.applicant.signatureData != nil
    }

    var body: some View {
        FormScreenLayout(
            title: "Declaration & Consent",
            stepIndex: 4,
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
                    placeholder: "e.g., John Tan — cousin"
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
                    placeholder: "Describe the conflict of interest"
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
                    placeholder: "Provide relevant details"
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
                    placeholder: "Provide relevant details"
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
                        .padding(.vertical, 4)
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
                        isMultiline: true
                    )
                }
            }

            // Signature
            Divider().padding(.vertical, 12)

            SignatureField(signatureData: $vm.applicant.signatureData)

            if !canSubmit {
                Text("Please complete all required declarations and provide your signature to submit.")
                    .font(.system(size: 14))
                    .foregroundColor(.mediumGray)
                    .padding(.top, 8)
                    .accessibilityLabel("Please complete all required declarations and provide your signature to submit.")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
                .foregroundColor(.affOrange)
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
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
