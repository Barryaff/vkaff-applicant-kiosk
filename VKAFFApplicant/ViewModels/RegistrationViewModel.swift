import SwiftUI
import Combine

@MainActor
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
    @Published var adminLocked = false
    private var adminFailedAttempts = 0
    private let maxAdminAttempts = 5
    private let adminLockoutSeconds: TimeInterval = 60

    // MARK: - Computed Properties

    /// Whether the app is currently on the welcome screen (used for conditional idle timer behavior)
    var isOnWelcomeScreen: Bool {
        currentScreen == .welcome
    }

    // MARK: - Private
    private var idleTimer: IdleTimer?
    private var cancellables = Set<AnyCancellable>()
    private let submissionVM = SubmissionViewModel()

    init() {
        idleTimer = IdleTimer { [weak self] in
            self?.resetToWelcome()
        }

        // Forward ApplicantData changes to RegistrationViewModel so SwiftUI detects updates
        applicant.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Sync idle timer warning state
        idleTimer?.$isWarningShown
            .receive(on: DispatchQueue.main)
            .assign(to: &$showIdleWarning)

        idleTimer?.$secondsRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: &$idleCountdown)

        setupFieldObservers()
    }

    // MARK: - Real-Time Field Validation Observers

    /// Sets up observers on applicant fields so that:
    /// - When a field changes, its error is cleared immediately (forgiving)
    /// - If the new value is valid, a green checkmark appears right away
    /// - Errors only appear when the user presses Continue
    private func setupFieldObservers() {
        // Full Name
        applicant.$fullName
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("fullName", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)

        // Preferred Name
        applicant.$preferredName
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("preferredName", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)

        // NRIC / FIN - show checkmark only when fully valid (including checksum)
        applicant.$nricFIN
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("nricFIN", isValid: Validators.isValidNRIC(value))
            }
            .store(in: &cancellables)

        // Contact Number
        applicant.$contactNumber
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("contactNumber", isValid: Validators.isValidPhone(value))
            }
            .store(in: &cancellables)

        // Email Address
        applicant.$emailAddress
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("emailAddress", isValid: Validators.isValidEmail(value))
            }
            .store(in: &cancellables)

        // Residential Address
        applicant.$residentialAddress
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("residentialAddress", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)

        // Postal Code
        applicant.$postalCode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("postalCode", isValid: Validators.isValidPostalCode(value))
            }
            .store(in: &cancellables)

        // Field of Study
        applicant.$fieldOfStudy
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("fieldOfStudy", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)

        // Institution Name
        applicant.$institutionName
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("institutionName", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)

        // Expected Salary
        applicant.$expectedSalary
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("expectedSalary", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)

        // Last Drawn Salary
        applicant.$lastDrawnSalary
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onFieldChanged("lastDrawnSalary", isValid: Validators.isNotEmpty(value))
            }
            .store(in: &cancellables)
    }

    /// Called when any field changes. Clears the error for that field immediately
    /// and updates the valid checkmark status.
    private func onFieldChanged(_ fieldKey: String, isValid: Bool) {
        // Always clear the error when the user starts typing (forgiving behavior)
        fieldErrors.removeValue(forKey: fieldKey)

        // Show green checkmark if the current value is valid
        if isValid {
            validFields.insert(fieldKey)
        } else {
            validFields.remove(fieldKey)
        }
    }

    // MARK: - Navigation

    func navigateForward() {
        guard canProceed() else { return }
        navigatingForward = true
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35)) {
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

        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35)) {
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

    /// Only shows errors when user presses Continue. Does NOT clear validFields
    /// so checkmarks persist from real-time validation.
    func canProceed() -> Bool {
        // Skip all validation when testing
        if AppConfig.skipValidation { return true }

        // Only clear errors (not valid fields) - errors are shown on Continue press
        fieldErrors.removeAll()

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
            if Validators.isValidNRICFormat(applicant.nricFIN) {
                fieldErrors["nricFIN"] = "NRIC/FIN checksum is invalid. Please double-check the number."
            } else {
                fieldErrors["nricFIN"] = "Enter a valid NRIC/FIN (e.g., S1234567A)"
            }
            isValid = false
        } else {
            validFields.insert("nricFIN")
        }

        if !Validators.isValidPhone(applicant.contactNumber) {
            fieldErrors["contactNumber"] = "Enter a valid phone number with country code (e.g., +65 8123 4567)"
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
            fieldErrors["postalCode"] = "Enter a valid postal / zip code"
            isValid = false
        } else {
            validFields.insert("postalCode")
        }

        // At least one emergency contact with name and phone required
        if applicant.emergencyContacts.isEmpty || !Validators.isNotEmpty(applicant.emergencyContacts[0].name) {
            fieldErrors["emergencyContactName"] = "At least one emergency contact is required"
            isValid = false
        } else {
            validFields.insert("emergencyContactName")
        }

        if applicant.emergencyContacts.isEmpty || !Validators.isValidPhone(applicant.emergencyContacts[0].phoneNumber) {
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

        if !Validators.isNotEmpty(applicant.lastDrawnSalary) {
            fieldErrors["lastDrawnSalary"] = "Last drawn salary is required"
            isValid = false
        } else {
            validFields.insert("lastDrawnSalary")
        }

        return isValid
    }

    private func validateDeclaration() -> Bool {
        return applicant.declarationAccuracy
            && applicant.pdpaConsent
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
            } else {
                // Upload failed but data is saved locally as encrypted backup.
                // Still proceed to confirmation so the applicant isn't stuck.
                haptic.notificationOccurred(.warning)
                submissionError = result.errorMessage
            }

            withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35)) {
                currentScreen = .confirmation
            }

            // Auto-return after confirmation
            try? await Task.sleep(nanoseconds: UInt64(AppConfig.confirmationAutoReturnSeconds * 1_000_000_000))
            if currentScreen == .confirmation {
                resetToWelcome()
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

    func pauseIdleTimer() {
        idleTimer?.pause()
    }

    func resumeIdleTimer() {
        idleTimer?.resume()
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
        guard !adminLocked else {
            adminPINEntry = ""
            return
        }

        if adminPINEntry == AppConfig.adminPIN {
            showAdminPIN = false
            adminPINEntry = ""
            adminFailedAttempts = 0
            // Pause idle timer while admin panel is active
            pauseIdleTimer()
            withAnimation {
                currentScreen = .admin
            }
        } else {
            adminPINEntry = ""
            adminFailedAttempts += 1
            if adminFailedAttempts >= maxAdminAttempts {
                adminLocked = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(adminLockoutSeconds * 1_000_000_000))
                    adminLocked = false
                    adminFailedAttempts = 0
                }
            }
        }
    }

    // MARK: - Reset

    func resetToWelcome() {
        // Dismiss any active keyboard before resetting
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )

        idleTimer?.stop()
        applicant.reset()
        fieldErrors.removeAll()
        validFields.removeAll()
        submissionError = nil

        // Re-setup observers since the applicant object was reset
        cancellables.removeAll()

        // Re-forward ApplicantData changes
        applicant.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        setupFieldObservers()

        // Re-bind idle timer publishers
        idleTimer?.$isWarningShown
            .receive(on: DispatchQueue.main)
		            .assign(to: &$showIdleWarning)

        idleTimer?.$secondsRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: &$idleCountdown)

        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35)) {
            currentScreen = .welcome
        }
    }
}
