import SwiftUI

struct WorkExperienceView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    var body: some View {
        FormScreenLayout(
            title: "Work Experience",
            stepIndex: 2,
            onBack: { vm.navigateBack() },
            onContinue: { vm.navigateForward() }
        ) {
            // Total Experience
            FormSegmented(
                label: "Total Years of Work Experience",
                selection: $vm.applicant.totalExperience
            )

            // Employment History
            Divider().padding(.vertical, 8)

            Text("Employment History")
                .subheadingStyle()

            RepeatableCardSection(
                title: "Employment Record",
                items: $vm.applicant.employmentHistory,
                maxItems: AppConfig.maxEmploymentRecords,
                createNew: { EmploymentRecord() }
            ) { $record in
                FormField(
                    label: "Company Name",
                    text: $record.companyName,
                    placeholder: "Company name",
                    maxLength: 200
                )

                FormField(
                    label: "Job Title",
                    text: $record.jobTitle,
                    placeholder: "Your role",
                    maxLength: 200
                )

                FormDropdown(
                    label: "Industry",
                    selection: $record.industry
                )

                // Employment Period
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("From")
                            .formLabelStyle()
                        DatePicker("", selection: $record.fromDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(.affOrange)
                            .labelsHidden()
                            .accessibilityLabel("Employment start date")
                            .onChange(of: record.fromDate) { _, newFromDate in
                                if record.toDate < newFromDate {
                                    record.toDate = newFromDate
                                }
                            }
                    }

                    if !record.isCurrentPosition {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("To")
                                .formLabelStyle()
                            DatePicker("", selection: $record.toDate, in: record.fromDate..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(.affOrange)
                                .labelsHidden()
                                .accessibilityLabel("Employment end date")
                        }
                    }
                }

                FormToggle(label: "Currently working here", isOn: $record.isCurrentPosition)

                FormField(
                    label: "Last Drawn Salary (SGD)",
                    text: $record.lastDrawnSalary,
                    placeholder: "e.g., 3,500",
                    keyboardType: .numberPad,
                    maxLength: 15,
                    isSalaryField: true
                )

                FormDropdown(
                    label: "Reason for Leaving",
                    selection: $record.reasonForLeaving
                )
            }

            // Currently Employed
            Divider().padding(.vertical, 8)

            FormToggle(
                label: "Are you currently employed?",
                isOn: $vm.applicant.isCurrentlyEmployed
            )

            if vm.applicant.isCurrentlyEmployed {
                FormDropdown(
                    label: "Notice Period Required",
                    selection: $vm.applicant.noticePeriod
                )
            }

            // References
            Divider().padding(.vertical, 8)

            Text("References")
                .subheadingStyle()

            Text("Please provide up to 2 references (non-family members preferred)")
                .font(.system(size: 14))
                .foregroundColor(.mediumGray)

            RepeatableCardSection(
                title: "Reference",
                items: $vm.applicant.references,
                maxItems: AppConfig.maxReferences,
                createNew: { ReferenceRecord() }
            ) { $record in
                FormField(
                    label: "Full Name",
                    text: $record.name,
                    placeholder: "Reference's full name",
                    maxLength: 100
                )

                FormField(
                    label: "Relationship",
                    text: $record.relationship,
                    placeholder: "e.g., Former Supervisor, Colleague",
                    maxLength: 200
                )

                HStack(spacing: 16) {
                    PhoneFieldWithCode(
                        label: "Contact Number",
                        countryCode: $record.contactCountryCode,
                        phoneNumber: $record.contactNumber,
                        placeholder: "9123 4567"
                    )

                    FormField(
                        label: "Email Address (optional)",
                        text: $record.email,
                        placeholder: "reference@email.com",
                        keyboardType: .emailAddress,
                        maxLength: 254
                    )
                }

                FormField(
                    label: "Years Known",
                    text: $record.yearsKnown,
                    placeholder: "e.g., 3 years",
                    keyboardType: .numberPad,
                    maxLength: 10
                )
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
