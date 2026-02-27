import SwiftUI

struct PositionAvailabilityView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @FocusState private var focusedField: PositionFocus?

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
                        placeholder: "Enter position title",
                        maxLength: 200,
                        errorMessage: vm.fieldErrors["positionOther"],
                        isValid: vm.validFields.contains("positionOther"),
                        positionFocusBinding: $focusedField,
                        positionFocusValue: .positionOther
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
                DatePicker("", selection: $vm.applicant.earliestStartDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(.affOrange)
                    .labelsHidden()
                    .accessibilityLabel("Earliest Available Start Date")
            }

            // Salary
            FormField(
                label: "Expected Monthly Salary (SGD)",
                text: $vm.applicant.expectedSalary,
                placeholder: "e.g., 3,500",
                keyboardType: .numberPad,
                maxLength: 15,
                errorMessage: vm.fieldErrors["expectedSalary"],
                isValid: vm.validFields.contains("expectedSalary"),
                isSalaryField: true,
                positionFocusBinding: $focusedField,
                positionFocusValue: .expectedSalary
            )

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

            FormToggle(
                label: "Open to being considered for other positions?",
                isOn: $vm.applicant.openToOtherPositions
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
                    placeholder: "Who referred you?",
                    maxLength: 100,
                    positionFocusBinding: $focusedField,
                    positionFocusValue: .referrerName
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField != .referrerName {
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
        case .positionOther: focusedField = .expectedSalary
        case .expectedSalary: focusedField = .referrerName
        case .referrerName: focusedField = nil
        case nil: break
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(position.rawValue)
        .accessibilityValue(isSelected ? "checked" : "unchecked")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select") this position")
    }
}

