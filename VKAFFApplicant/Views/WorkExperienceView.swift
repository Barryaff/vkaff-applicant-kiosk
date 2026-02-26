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
                    placeholder: "Company name"
                )

                FormField(
                    label: "Job Title",
                    text: $record.jobTitle,
                    placeholder: "Your role"
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
                        DatePicker("", selection: $record.fromDate, displayedComponents: .date)
                            .labelsHidden()
                    }

                    if !record.isCurrentPosition {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("To")
                                .formLabelStyle()
                            DatePicker("", selection: $record.toDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                }

                FormToggle(label: "Currently working here", isOn: $record.isCurrentPosition)

                FormDropdown(
                    label: "Reason for Leaving",
                    selection: $record.reasonForLeaving
                )

                FormField(
                    label: "Key Responsibilities (optional)",
                    text: $record.keyResponsibilities,
                    placeholder: "Brief description of your role",
                    isMultiline: true,
                    maxLength: 200
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
        }
    }
}
