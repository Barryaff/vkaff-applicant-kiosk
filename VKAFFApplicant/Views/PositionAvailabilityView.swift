import SwiftUI

struct PositionAvailabilityView: View {
    @EnvironmentObject var vm: RegistrationViewModel

    var body: some View {
        FormScreenLayout(
            title: "Position & Availability",
            stepIndex: 3,
            onBack: { vm.navigateBack() },
            onContinue: { vm.navigateForward() }
        ) {
            // Positions Applied For
            VStack(alignment: .leading, spacing: 8) {
                Text("Position(s) Applied For")
                    .formLabelStyle()

                if let error = vm.fieldErrors["positions"] {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.errorRed)
                }

                ForEach(Position.allCases, id: \.self) { position in
                    PositionCheckbox(
                        position: position,
                        isSelected: vm.applicant.positionsAppliedFor.contains(position),
                        onToggle: {
                            if vm.applicant.positionsAppliedFor.contains(position) {
                                vm.applicant.positionsAppliedFor.remove(position)
                            } else {
                                vm.applicant.positionsAppliedFor.insert(position)
                            }
                        }
                    )
                }

                if vm.applicant.positionsAppliedFor.contains(.others) {
                    FormField(
                        label: "Please specify",
                        text: $vm.applicant.positionOther,
                        placeholder: "Enter position title"
                    )
                }
            }

            Divider().padding(.vertical, 8)

            // Employment Type
            FormSegmented(
                label: "Preferred Employment Type",
                selection: $vm.applicant.preferredEmploymentType
            )

            // Start Date
            VStack(alignment: .leading, spacing: 6) {
                Text("Earliest Available Start Date")
                    .formLabelStyle()
                DatePicker("", selection: $vm.applicant.earliestStartDate, displayedComponents: .date)
                    .labelsHidden()
            }

            // Salary
            HStack(spacing: 16) {
                FormField(
                    label: "Expected Monthly Salary (SGD)",
                    text: $vm.applicant.expectedSalary,
                    placeholder: "e.g., 3,500",
                    keyboardType: .numberPad,
                    errorMessage: vm.fieldErrors["expectedSalary"],
                    isValid: vm.validFields.contains("expectedSalary")
                )

                FormField(
                    label: "Last Drawn Salary (optional)",
                    text: $vm.applicant.lastDrawnSalary,
                    placeholder: "e.g., 3,000",
                    keyboardType: .numberPad
                )
            }

            Divider().padding(.vertical, 8)

            // Willingness questions
            FormSegmented(
                label: "Willing to work shifts?",
                selection: $vm.applicant.willingToWorkShifts
            )

            FormSegmented(
                label: "Willing to travel for work?",
                selection: $vm.applicant.willingToTravel
            )

            FormSegmented(
                label: "Do you have your own transport?",
                selection: Binding(
                    get: { vm.applicant.hasOwnTransport ? BoolOption.yes : BoolOption.no },
                    set: { vm.applicant.hasOwnTransport = $0 == .yes }
                )
            )

            // How did you hear
            FormDropdown(
                label: "How did you hear about this position?",
                selection: $vm.applicant.howDidYouHear
            )

            if vm.applicant.howDidYouHear == .referral {
                FormField(
                    label: "Referrer's Name",
                    text: $vm.applicant.referrerName,
                    placeholder: "Who referred you?"
                )
            }
        }
    }
}

// MARK: - Position Checkbox

struct PositionCheckbox: View {
    let position: Position
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .affOrange : .mediumGray)

                Text(position.rawValue)
                    .font(.system(size: 17))
                    .foregroundColor(.darkText)

                Spacer()
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bool segmented helper

enum BoolOption: String, CaseIterable {
    case yes = "Yes"
    case no = "No"
}
