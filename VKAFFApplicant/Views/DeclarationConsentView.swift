import SwiftUI

struct DeclarationConsentView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    private var canSubmit: Bool {
        vm.applicant.declarationAccuracy
            && vm.applicant.pdpaConsent
            && vm.applicant.backgroundCheckConsent
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
            // Orange rule
            Rectangle()
                .fill(Color.affOrange)
                .frame(height: 1)
                .padding(.bottom, 8)

            // 1. Declaration of Accuracy
            ConsentBlock(
                isChecked: $vm.applicant.declarationAccuracy,
                title: "Declaration of Accuracy",
                consentText: "I declare that all information provided in this application is true, complete, and accurate to the best of my knowledge. I understand that any misrepresentation or omission of facts may result in the rejection of my application or termination of employment if discovered after hiring."
            )

            // 2. PDPA Consent
            ConsentBlock(
                isChecked: $vm.applicant.pdpaConsent,
                title: "PDPA Consent",
                consentText: "I consent to Advanced Flavors & Fragrances Pte. Ltd. collecting, using, and disclosing my personal data provided in this form for the purposes of recruitment, employment evaluation, and related HR administration, in accordance with the Personal Data Protection Act 2012 (PDPA) of Singapore. I understand that my data will be retained for a period of up to 2 years from the date of this application, after which it will be securely disposed of unless I am offered employment."
            )

            // 3. Background Checks
            ConsentBlock(
                isChecked: $vm.applicant.backgroundCheckConsent,
                title: "Background Checks",
                consentText: "I understand that Advanced Flavors & Fragrances Pte. Ltd. may conduct background verification checks, including but not limited to employment history, educational qualifications, and criminal record checks, as part of the recruitment process. I consent to such checks being carried out."
            )

            // 4. Medical Declaration
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
                Text("Please complete all declarations and provide your signature to submit.")
                    .font(.system(size: 14))
                    .foregroundColor(.mediumGray)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Consent Block

struct ConsentBlock: View {
    @Binding var isChecked: Bool
    let title: String
    let consentText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.vkaPurple)

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

                    Text(title.contains("PDPA") ? "I consent" : "I agree")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.darkText)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 16)
    }
}
