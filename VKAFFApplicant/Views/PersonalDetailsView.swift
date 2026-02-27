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
                label: "Full Name (as in NRIC/Passport)",
                text: $vm.applicant.fullName,
                placeholder: "Enter your full name",
                maxLength: 100,
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
                maxLength: 100,
                errorMessage: vm.fieldErrors["preferredName"],
                isValid: vm.validFields.contains("preferredName"),
                focusBinding: $focusedField,
                focusValue: .preferredName
            )

            // NRIC / FIN or Passport — at least one required
            Text("Please provide either your NRIC/FIN or Passport Number (or both).")
                .font(.system(size: 13))
                .foregroundColor(.mediumGray)
                .padding(.top, 4)

            NRICField(
                label: "NRIC / FIN Number",
                text: $vm.applicant.nricFIN,
                errorMessage: vm.fieldErrors["nricFIN"],
                isValid: vm.validFields.contains("nricFIN"),
                focusBinding: $focusedField,
                focusValue: .nricFIN
            )

            FormField(
                label: "Passport Number",
                text: $vm.applicant.passportNumber,
                placeholder: "e.g., E12345678",
                maxLength: 20,
                errorMessage: vm.fieldErrors["passportNumber"],
                isValid: vm.validFields.contains("passportNumber")
            )

            // Driving License Class (optional)
            FormField(
                label: "Driving License Class (if any)",
                text: $vm.applicant.drivingLicenseClass,
                placeholder: "e.g., Class 3, Class 4",
                maxLength: 50
            )

            // Date of Birth
            VStack(alignment: .leading, spacing: 6) {
                Text("Date of Birth")
                    .formLabelStyle()
                DatePicker("", selection: $vm.applicant.dateOfBirth, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .tint(.affOrange)
                    .labelsHidden()
                    .frame(height: 120)
                    .clipped()
                    .accessibilityLabel("Date of Birth")
            }

            // Gender
            FormSegmented(label: "Gender", selection: $vm.applicant.gender)

            // Nationality
            FormDropdown(label: "Nationality", selection: $vm.applicant.nationality)

            if vm.applicant.nationality == .others {
                FormField(
                    label: "Please specify your nationality",
                    text: $vm.applicant.nationalityOther,
                    placeholder: "Enter your nationality",
                    maxLength: 100,
                    errorMessage: vm.fieldErrors["nationalityOther"],
                    isValid: vm.validFields.contains("nationalityOther")
                )
            }

            // Have you worked in Singapore before? (shown for non-Singaporeans)
            if !vm.applicant.nationality.isSingaporean {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Have you worked in Singapore before?")
                        .formLabelStyle()

                    HStack(spacing: 16) {
                        ForEach([true, false], id: \.self) { option in
                            Button {
                                vm.applicant.hasWorkedInSingapore = option
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: vm.applicant.hasWorkedInSingapore == option ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(vm.applicant.hasWorkedInSingapore == option ? .vkaPurple : .mediumGray)
                                    Text(option ? "Yes" : "No")
                                        .font(.system(size: 16))
                                        .foregroundColor(.darkText)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Have you worked in Singapore before: \(option ? "Yes" : "No")")
                            .accessibilityValue(vm.applicant.hasWorkedInSingapore == option ? "selected" : "not selected")
                            .accessibilityAddTraits(vm.applicant.hasWorkedInSingapore == option ? [.isButton, .isSelected] : [.isButton])
                            .accessibilityHint("Double tap to select \(option ? "Yes" : "No")")
                        }
                    }
                }
            }

            // Race
            FormDropdown(label: "Race", selection: $vm.applicant.race)

            if vm.applicant.race == .others {
                FormField(
                    label: "Please specify",
                    text: $vm.applicant.raceOther,
                    placeholder: "Enter your race",
                    maxLength: 100,
                    errorMessage: vm.fieldErrors["raceOther"],
                    isValid: vm.validFields.contains("raceOther")
                )
            }

            // Contact Number with country code
            HStack(spacing: 16) {
                PhoneFieldWithCode(
                    label: "Contact Number",
                    countryCode: $vm.applicant.contactCountryCode,
                    phoneNumber: $vm.applicant.contactNumber,
                    placeholder: "8123 4567",
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
                    maxLength: 254,
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
                maxLength: 500,
                errorMessage: vm.fieldErrors["residentialAddress"],
                isValid: vm.validFields.contains("residentialAddress"),
                focusBinding: $focusedField,
                focusValue: .residentialAddress
            )

            // Postal Code
            FormField(
                label: "Postal / Zip Code",
                text: $vm.applicant.postalCode,
                placeholder: "e.g., 408832",
                maxLength: 6,
                errorMessage: vm.fieldErrors["postalCode"],
                isValid: vm.validFields.contains("postalCode"),
                focusBinding: $focusedField,
                focusValue: .postalCode
            )

            // Emergency Contacts
            Divider().padding(.vertical, 8)

            Text("Emergency Contacts")
                .subheadingStyle()

            Text("Please provide at least 1 emergency contact")
                .font(.system(size: 14))
                .foregroundColor(.mediumGray)

            RepeatableCardSection(
                title: "Emergency Contact",
                items: $vm.applicant.emergencyContacts,
                maxItems: AppConfig.maxEmergencyContacts,
                createNew: { EmergencyContact() }
            ) { $contact in
                FormField(
                    label: "Full Name",
                    text: $contact.name,
                    placeholder: "Emergency contact's full name",
                    maxLength: 100
                )

                HStack(spacing: 16) {
                    PhoneFieldWithCode(
                        label: "Phone Number",
                        countryCode: $contact.countryCode,
                        phoneNumber: $contact.phoneNumber,
                        placeholder: "9123 4567"
                    )

                    FormDropdown(
                        label: "Relationship",
                        selection: $contact.relationship
                    )
                }

                if contact.relationship == .others {
                    FormField(
                        label: "Please specify relationship",
                        text: $contact.relationshipOther,
                        placeholder: "e.g., Colleague, Roommate",
                        maxLength: 100
                    )
                }

                FormField(
                    label: "Email (optional)",
                    text: $contact.email,
                    placeholder: "contact@email.com",
                    keyboardType: .emailAddress,
                    maxLength: 254
                )

                FormField(
                    label: "Address (optional)",
                    text: $contact.address,
                    placeholder: "Block, street, unit number",
                    isMultiline: true,
                    maxLength: 500
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
            // Premium top bar
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    // VKA logo (compact for form screens)
                    Image("vka_logo_purple")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                        .accessibilityHidden(true)

                    Spacer().frame(width: 32)

                    ProgressBar(currentStep: stepIndex)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 48)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Subtle bottom border
                Rectangle()
                    .fill(Color.dividerSubtle)
                    .frame(height: 1)
            }
            .background(Color.white)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Section label + title
                    VStack(alignment: .leading, spacing: 10) {
                        // Gold uppercase section label
                        Text("STEP \(stepIndex + 1)")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(3)
                            .foregroundColor(.gold)
                            .accessibilityHidden(true)

                        Text(title)
                            .headingStyle(size: 32)
                            .accessibilityAddTraits(.isHeader)

                        Rectangle()
                            .fill(Color.affOrange)
                            .frame(width: 48, height: 2)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 32)

                    // Form card
                    FormCard {
                        content
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity, alignment: .leading)
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
