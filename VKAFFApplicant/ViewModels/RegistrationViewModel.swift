import SwiftUI
import Combine

class RegistrationViewModel: ObservableObject {
    // MARK: - Published State
    @Published var currentScreen: AppScreen = .welcome
    @Published var applicant = ApplicantData()
    @Published var navigatingForward = true
    @Published var showIdleWarning = false
    @Published var isSubmitting = false
    @Published var submissionError: String?
    @Published var idleCountdown: Int = 30

    // MARK: - Validation State
    @Published var fieldErrors: [String: String] = [:]
    @Published var validFields: Set<String> = []

    // MARK: - Admin
    @Published var showAdminPIN = false
    @Published var adminPINEntry = ""
    @Published var welcomeTapCount = 0

    // MARK: - Private
    private var idleTimer: IdleTimer?
    private var cancellables = Set<AnyCancellable>()
    private let submissionVM = SubmissionViewModel()

    init() {
        idleTimer = IdleTimer { [weak self] in
            self?.resetToWelcome()
        }

        // Sync idle timer warning state
        idleTimer?.$isWarningShown
            .receive(on: DispatchQueue.main)
            .assign(to: &$showIdleWarning)

        idleTimer?.$secondsRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: &$idleCountdown)
    }

    // MARK: - Navigation

    func navigateForward() {
        guard canProceed() else { return }
        navigatingForward = true
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        withAnimation(.easeInOut(duration: 0.35)) {
            switch currentScreen {
            case .welcome:
                currentScreen = .personalDetails
                idleTimer?.start()
            case .personalDetails:
                currentScreen = .education
            case .education:
                currentScreen = .workExperience
            case .workExperience:
                currentScreen = .positionAvailability
            case .positionAvailability:
                currentScreen = .declaration
            case .declaration:
                submitApplication()
            case .confirmation, .admin:
                break
            }
        }
    }

    func navigateBack() {
        navigatingForward = false
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        withAnimation(.easeInOut(duration: 0.35)) {
            switch currentScreen {
            case .welcome, .confirmation:
                break
            case .personalDetails:
                currentScreen = .welcome
                idleTimer?.stop()
            case .education:
                currentScreen = .personalDetails
            case .workExperience:
                currentScreen = .education
            case .positionAvailability:
                currentScreen = .workExperience
            case .declaration:
                currentScreen = .positionAvailability
            case .admin:
                currentScreen = .welcome
            }
        }
    }

    // MARK: - Validation

    func canProceed() -> Bool {
        fieldErrors.removeAll()
        validFields.removeAll()

        switch currentScreen {
        case .personalDetails:
            return validatePersonalDetails()
        case .education:
            return validateEducation()
        case .workExperience:
            return true // Work experience fields are more flexible
        case .positionAvailability:
            return validatePositionAvailability()
        case .declaration:
            return validateDeclaration()
        default:
            return true
        }
    }

    private func validatePersonalDetails() -> Bool {
        var isValid = true

        if !Validators.isNotEmpty(applicant.fullName) {
            fieldErrors["fullName"] = "Full name is required"
            isValid = false
        } else {
            validFields.insert("fullName")
        }

        if !Validators.isNotEmpty(applicant.preferredName) {
            fieldErrors["preferredName"] = "Preferred name is required"
            isValid = false
        } else {
            validFields.insert("preferredName")
        }

        if !Validators.isValidNRIC(applicant.nricFIN) {
            fieldErrors["nricFIN"] = "Enter a valid NRIC/FIN (e.g., S1234567A)"
            isValid = false
        } else {
            validFields.insert("nricFIN")
        }

        if !Validators.isValidPhone(applicant.contactNumber) {
            fieldErrors["contactNumber"] = "Enter a valid phone number"
            isValid = false
        } else {
            validFields.insert("contactNumber")
        }

        if !Validators.isValidEmail(applicant.emailAddress) {
            fieldErrors["emailAddress"] = "Enter a valid email address"
            isValid = false
        } else {
            validFields.insert("emailAddress")
        }

        if !Validators.isNotEmpty(applicant.residentialAddress) {
            fieldErrors["residentialAddress"] = "Address is required"
            isValid = false
        } else {
            validFields.insert("residentialAddress")
        }

        if !Validators.isValidPostalCode(applicant.postalCode) {
            fieldErrors["postalCode"] = "Enter a valid 6-digit postal code"
            isValid = false
        } else {
            validFields.insert("postalCode")
        }

        if !Validators.isNotEmpty(applicant.emergencyContactName) {
            fieldErrors["emergencyContactName"] = "Emergency contact name is required"
            isValid = false
        } else {
            validFields.insert("emergencyContactName")
        }

        if !Validators.isValidPhone(applicant.emergencyContactNumber) {
            fieldErrors["emergencyContactNumber"] = "Enter a valid phone number"
            isValid = false
        } else {
            validFields.insert("emergencyContactNumber")
        }

        return isValid
    }

    private func validateEducation() -> Bool {
        var isValid = true

        if !Validators.isNotEmpty(applicant.fieldOfStudy) {
            fieldErrors["fieldOfStudy"] = "Field of study is required"
            isValid = false
        } else {
            validFields.insert("fieldOfStudy")
        }

        if !Validators.isNotEmpty(applicant.institutionName) {
            fieldErrors["institutionName"] = "Institution name is required"
            isValid = false
        } else {
            validFields.insert("institutionName")
        }

        return isValid
    }

    private func validatePositionAvailability() -> Bool {
        var isValid = true

        if applicant.positionsAppliedFor.isEmpty {
            fieldErrors["positions"] = "Select at least one position"
            isValid = false
        }

        if !Validators.isNotEmpty(applicant.expectedSalary) {
            fieldErrors["expectedSalary"] = "Expected salary is required"
            isValid = false
        } else {
            validFields.insert("expectedSalary")
        }

        return isValid
    }

    private func validateDeclaration() -> Bool {
        return applicant.declarationAccuracy
            && applicant.pdpaConsent
            && applicant.backgroundCheckConsent
            && applicant.signatureData != nil
    }

    // MARK: - Submission

    private func submitApplication() {
        isSubmitting = true
        applicant.submissionDate = Date()
        applicant.referenceNumber = ReferenceNumberGenerator.generate()

        let haptic = UINotificationFeedbackGenerator()

        Task { @MainActor in
            let result = await submissionVM.submit(applicant: applicant)

            isSubmitting = false

            if result.success {
                haptic.notificationOccurred(.success)
                withAnimation(.easeInOut(duration: 0.35)) {
                    currentScreen = .confirmation
                }

                // Auto-return after 15 seconds
                try? await Task.sleep(nanoseconds: UInt64(AppConfig.confirmationAutoReturnSeconds * 1_000_000_000))
                if currentScreen == .confirmation {
                    resetToWelcome()
                }
            } else {
                haptic.notificationOccurred(.error)
                submissionError = result.errorMessage
            }
        }
    }

    // MARK: - Idle Timer

    func resetIdleTimer() {
        idleTimer?.resetActivity()
    }

    func confirmPresence() {
        idleTimer?.userConfirmedPresence()
    }

    // MARK: - Admin

    func handleWelcomeLogoTap() {
        welcomeTapCount += 1
        if welcomeTapCount >= 3 {
            welcomeTapCount = 0
            showAdminPIN = true
        }

        // Reset tap count after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.welcomeTapCount = 0
        }
    }

    func attemptAdminLogin() {
        if adminPINEntry == AppConfig.adminPIN {
            showAdminPIN = false
            adminPINEntry = ""
            withAnimation {
                currentScreen = .admin
            }
        } else {
            adminPINEntry = ""
        }
    }

    // MARK: - Reset

    func resetToWelcome() {
        idleTimer?.stop()
        applicant.reset()
        fieldErrors.removeAll()
        validFields.removeAll()
        submissionError = nil
        withAnimation(.easeInOut(duration: 0.35)) {
            currentScreen = .welcome
        }
    }
}
