import SwiftUI

struct PersonalDetailsView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @FocusState private var focusedField: PersonalDetailsFocus?

    var body: some View {
        FormScreenLayout(
            title: "Personal Details",
            stepIndex: 0,
            onBack: { vm.navigateBack() },
            onContinue: { vm.navigateForward() }
        ) {
            // Full Name
            FormField(
                label: "Full Name (as in NRIC/FIN)",
                text: $vm.applicant.fullName,
                placeholder: "Enter your full name",
                errorMessage: vm.fieldErrors["fullName"],
                isValid: vm.validFields.contains("fullName"),
                focusBinding: $focusedField,
                focusValue: .fullName
            )

            // Preferred Name
            FormField(
                label: "Preferred Name",
                text: $vm.applicant.preferredName,
                placeholder: "What should we call you?",
                errorMessage: vm.fieldErrors["preferredName"],
                isValid: vm.validFields.contains("preferredName"),
                focusBinding: $focusedField,
                focusValue: .preferredName
            )

            // NRIC / FIN
            NRICField(
                label: "NRIC / FIN Number",
                text: $vm.applicant.nricFIN,
                errorMessage: vm.fieldErrors["nricFIN"],
                isValid: vm.validFields.contains("nricFIN"),
                focusBinding: $focusedField,
                focusValue: .nricFIN
            )

            // Date of Birth
            VStack(alignment: .leading, spacing: 6) {
                Text("Date of Birth")
                    .formLabelStyle()
                DatePicker("", selection: $vm.applicant.dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .tint(.affOrange)
                    .labelsHidden()
                    .frame(height: 120)
                    .clipped()
            }

            // Gender
            FormSegmented(label: "Gender", selection: $vm.applicant.gender)

            // Nationality
            FormDropdown(label: "Nationality", selection: $vm.applicant.nationality)

            // Race
            FormDropdown(label: "Race", selection: $vm.applicant.race)

            if vm.applicant.race == .others {
                FormField(
                    label: "Please specify",
                    text: $vm.applicant.raceOther,
                    placeholder: "Enter your race"
                )
            }

            // Contact Info (two column on iPad)
            HStack(spacing: 16) {
                FormField(
                    label: "Contact Number",
                    text: $vm.applicant.contactNumber,
                    placeholder: "+65",
                    keyboardType: .phonePad,
                    errorMessage: vm.fieldErrors["contactNumber"],
                    isValid: vm.validFields.contains("contactNumber"),
                    focusBinding: $focusedField,
                    focusValue: .contactNumber
                )

                FormField(
                    label: "Email Address",
                    text: $vm.applicant.emailAddress,
                    placeholder: "your@email.com",
                    keyboardType: .emailAddress,
                    errorMessage: vm.fieldErrors["emailAddress"],
                    isValid: vm.validFields.contains("emailAddress"),
                    focusBinding: $focusedField,
                    focusValue: .emailAddress
                )
            }

            // Address
            FormField(
                label: "Residential Address",
                text: $vm.applicant.residentialAddress,
                placeholder: "Block, street, unit number",
                isMultiline: true,
                errorMessage: vm.fieldErrors["residentialAddress"],
                isValid: vm.validFields.contains("residentialAddress"),
                focusBinding: $focusedField,
                focusValue: .residentialAddress
            )

            // Postal Code
            FormField(
                label: "Postal Code",
                text: $vm.applicant.postalCode,
                placeholder: "e.g., 408832",
                keyboardType: .numberPad,
                errorMessage: vm.fieldErrors["postalCode"],
                isValid: vm.validFields.contains("postalCode"),
                focusBinding: $focusedField,
                focusValue: .postalCode
            )

            // Emergency Contact
            Divider().padding(.vertical, 8)

            Text("Emergency Contact")
                .subheadingStyle()

            FormField(
                label: "Emergency Contact Name",
                text: $vm.applicant.emergencyContactName,
                placeholder: "Full name",
                errorMessage: vm.fieldErrors["emergencyContactName"],
                isValid: vm.validFields.contains("emergencyContactName"),
                focusBinding: $focusedField,
                focusValue: .emergencyContactName
            )

            HStack(spacing: 16) {
                FormField(
                    label: "Emergency Contact Number",
                    text: $vm.applicant.emergencyContactNumber,
                    placeholder: "+65",
                    keyboardType: .phonePad,
                    errorMessage: vm.fieldErrors["emergencyContactNumber"],
                    isValid: vm.validFields.contains("emergencyContactNumber"),
                    focusBinding: $focusedField,
                    focusValue: .emergencyContactNumber
                )

                FormDropdown(
                    label: "Relationship",
                    selection: $vm.applicant.emergencyContactRelationship
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField != .emergencyContactNumber {
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
        case .fullName: focusedField = .preferredName
        case .preferredName: focusedField = .nricFIN
        case .nricFIN: focusedField = .contactNumber
        case .contactNumber: focusedField = .emailAddress
        case .emailAddress: focusedField = .residentialAddress
        case .residentialAddress: focusedField = .postalCode
        case .postalCode: focusedField = .emergencyContactName
        case .emergencyContactName: focusedField = .emergencyContactNumber
        case .emergencyContactNumber: focusedField = nil
        case nil: break
        }
    }
}

// MARK: - Reusable Form Screen Layout

struct FormScreenLayout<Content: View>: View {
    let title: String
    let stepIndex: Int
    let onBack: (() -> Void)?
    let onContinue: () -> Void
    var continueTitle: String = "Continue"
    var isContinueEnabled: Bool = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(alignment: .center) {
                Image("aff_logo_orange")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .accessibilityHidden(true)

                Spacer().frame(width: 24)

                ProgressBar(currentStep: stepIndex)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.lightBackground)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Section title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .headingStyle()
                            .accessibilityAddTraits(.isHeader)
                        Rectangle()
                            .fill(Color.affOrange)
                            .frame(width: 40, height: 2)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 24)

                    // Form card
                    FormCard {
                        content
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color.lightBackground)
            .scrollDismissesKeyboard(.interactively)
            .dynamicTypeSize(.large ... .accessibility3)

            // Bottom navigation
            FormNavigationBar(
                onBack: onBack,
                onContinue: onContinue,
                continueTitle: continueTitle,
                isEnabled: isContinueEnabled
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
