import SwiftUI
import Combine

@MainActor
class RegistrationViewModel: ObservableObject {
    // MARK: - Published State
    @Published var currentScreen: AppScreen = .welcome
    @Published var applicant = ApplicantData()
    @Published var navigatingForward = true
    @Published var showIdleWarning = false
    @Published var supportingDocuments: [SupportingDocument] = []
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
    private var autoReturnTask: Task<Void, Never>?

    private static let adminLockoutEndTimeKey = "adminLockoutEndTime"

    init() {
        // Restore admin lockout state if persisted
        let lockoutEndTime = UserDefaults.standard.double(forKey: Self.adminLockoutEndTimeKey)
        if lockoutEndTime > Date().timeIntervalSince1970 {
            adminLocked = true
            adminFailedAttempts = maxAdminAttempts
            let remaining = lockoutEndTime - Date().timeIntervalSince1970
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                self?.adminLocked = false
                self?.adminFailedAttempts = 0
                UserDefaults.standard.removeObject(forKey: Self.adminLockoutEndTimeKey)
            }
        }

        idleTimer = IdleTimer { [weak self] in
            self?.resetToWelcome()
        }

        // Sync idle timer warning state (no .receive needed — IdleTimer is @MainActor)
        idleTimer?.$isWarningShown
            .sink { [weak self] value in
                guard self?.showIdleWarning != value else { return }
                self?.showIdleWarning = value
            }
            .store(in: &cancellables)

        idleTimer?.$secondsRemaining
            .sink { [weak self] value in
                guard self?.idleCountdown != value else { return }
                self?.idleCountdown = value
            }
            .store(in: &cancellables)

        setupFieldObservers()
    }

    // MARK: - Real-Time Field Validation Observers

    /// Sets up observers on applicant fields so that:
    /// - When a field changes, its error is cleared immediately (forgiving)
    /// - If the new value is valid, a green checkmark appears right away
    /// - Errors only appear when the user presses Continue
    private func setupFieldObservers() {
        // Single debounced subscription per field using struct key paths.
        // With ApplicantData as a struct, $applicant emits on every mutation.
        // .map(keyPath).removeDuplicates() ensures we only fire when THIS field changes.
        // A short 100ms debounce clears errors quickly while avoiding per-keystroke storms.

        func observe<T: Equatable>(
            _ keyPath: KeyPath<ApplicantData, T>,
            key: String,
            validate: @escaping (T) -> Bool
        ) {
            $applicant
                .map(keyPath)
                .removeDuplicates()
                .dropFirst()
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { [weak self] value in
                    guard let self else { return }
                    // Clear error if present
                    if self.fieldErrors[key] != nil {
                        self.fieldErrors.removeValue(forKey: key)
                    }
                    // Update valid state (guarded to prevent no-op objectWillChange)
                    let isCurrentlyValid = validate(value)
                    if isCurrentlyValid {
                        if !self.validFields.contains(key) {
                            self.validFields.insert(key)
                        }
                    } else {
                        if self.validFields.contains(key) {
                            self.validFields.remove(key)
                        }
                    }
                }
                .store(in: &cancellables)
        }

        observe(\.fullName, key: "fullName") { Validators.isNotEmpty($0) }
        observe(\.preferredName, key: "preferredName") { Validators.isNotEmpty($0) }
        observe(\.nricFIN, key: "nricFIN") { [weak self] value in
            Validators.isValidNRIC(value) || Validators.isNotEmpty(self?.applicant.passportNumber ?? "")
        }
        observe(\.passportNumber, key: "passportNumber") { [weak self] value in
            Validators.isNotEmpty(value) || Validators.isValidNRIC(self?.applicant.nricFIN ?? "")
        }
        observe(\.contactNumber, key: "contactNumber") { Validators.isValidPhone($0) }
        observe(\.emailAddress, key: "emailAddress") { Validators.isValidEmail($0) }
        observe(\.residentialAddress, key: "residentialAddress") { Validators.isNotEmpty($0) }
        observe(\.postalCode, key: "postalCode") { Validators.isValidPostalCode($0) }
        observe(\.fieldOfStudy, key: "fieldOfStudy") { [weak self] value in
            !(self?.applicant.highestQualification.hasFieldOfStudy ?? true) || Validators.isNotEmpty(value)
        }
        observe(\.institutionName, key: "institutionName") { Validators.isNotEmpty($0) }
        observe(\.expectedSalary, key: "expectedSalary") { Validators.isNotEmpty($0) }
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
                currentScreen = .supportingDocuments
            case .supportingDocuments:
                currentScreen = .declaration
            case .declaration:
                guard !isSubmitting else { return }
                submitApplication()
            case .confirmation, .admin:
                break
            }
        }
    }

    func navigateBack() {
        guard !isSubmitting else { return }
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
            case .supportingDocuments:
                currentScreen = .positionAvailability
            case .declaration:
                currentScreen = .supportingDocuments
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

        let hasValidNRIC = Validators.isValidNRIC(applicant.nricFIN)
        let hasPassport = Validators.isNotEmpty(applicant.passportNumber)

        if !hasValidNRIC && !hasPassport {
            // Neither provided — show error on both
            if applicant.nricFIN.isEmpty {
                fieldErrors["nricFIN"] = "Provide either NRIC/FIN or Passport Number"
            } else if Validators.isValidNRICFormat(applicant.nricFIN) {
                fieldErrors["nricFIN"] = "NRIC/FIN checksum is invalid. Please double-check the number."
            } else {
                fieldErrors["nricFIN"] = "Enter a valid NRIC/FIN (e.g., S1234567A)"
            }
            fieldErrors["passportNumber"] = "Provide either NRIC/FIN or Passport Number"
            isValid = false
        } else {
            // At least one is provided
            if hasValidNRIC { validFields.insert("nricFIN") }
            if hasPassport { validFields.insert("passportNumber") }
            // If NRIC was entered but is invalid, still warn (even if passport is provided)
            if !applicant.nricFIN.isEmpty && !hasValidNRIC {
                if Validators.isValidNRICFormat(applicant.nricFIN) {
                    fieldErrors["nricFIN"] = "NRIC/FIN checksum is invalid. Please double-check the number."
                } else {
                    fieldErrors["nricFIN"] = "Invalid NRIC/FIN format"
                }
                // Don't block submission — passport is sufficient
            }
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

        // Validate "Others" specify fields
        if applicant.nationality == .others && !Validators.isNotEmpty(applicant.nationalityOther) {
            fieldErrors["nationalityOther"] = "Please specify your nationality"
            isValid = false
        } else if applicant.nationality == .others {
            validFields.insert("nationalityOther")
        }

        if applicant.race == .others && !Validators.isNotEmpty(applicant.raceOther) {
            fieldErrors["raceOther"] = "Please specify your race"
            isValid = false
        } else if applicant.race == .others {
            validFields.insert("raceOther")
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

        if applicant.highestQualification == .others && !Validators.isNotEmpty(applicant.highestQualificationOther) {
            fieldErrors["highestQualificationOther"] = "Please specify your qualification"
            isValid = false
        } else if applicant.highestQualification == .others {
            validFields.insert("highestQualificationOther")
        }

        if applicant.highestQualification.hasFieldOfStudy {
            if !Validators.isNotEmpty(applicant.fieldOfStudy) {
                fieldErrors["fieldOfStudy"] = "Field of study is required"
                isValid = false
            } else {
                validFields.insert("fieldOfStudy")
            }
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

        if applicant.positionsAppliedFor.contains(.others) && !Validators.isNotEmpty(applicant.positionOther) {
            fieldErrors["positionOther"] = "Please specify the position"
            isValid = false
        } else if applicant.positionsAppliedFor.contains(.others) {
            validFields.insert("positionOther")
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
            && applicant.signatureData != nil
    }

    // MARK: - Submission

    private func submitApplication() {
        isSubmitting = true
        applicant.submissionDate = Date()
        applicant.referenceNumber = ReferenceNumberGenerator.generate()

        let haptic = UINotificationFeedbackGenerator()

        Task { @MainActor in
            let result = await submissionVM.submit(applicant: applicant, supportingDocuments: supportingDocuments)

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

            // Auto-return after confirmation (stored so it can be cancelled on manual reset)
            autoReturnTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(AppConfig.confirmationAutoReturnSeconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                if self?.currentScreen == .confirmation {
                    self?.resetToWelcome()
                }
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
                UserDefaults.standard.set(Date().timeIntervalSince1970 + adminLockoutSeconds, forKey: Self.adminLockoutEndTimeKey)
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64((self?.adminLockoutSeconds ?? 60) * 1_000_000_000))
                    self?.adminLocked = false
                    self?.adminFailedAttempts = 0
                    UserDefaults.standard.removeObject(forKey: Self.adminLockoutEndTimeKey)
                }
            }
        }
    }

    // MARK: - Reset

    func resetToWelcome() {
        // Cancel any pending auto-return task from previous submission
        autoReturnTask?.cancel()
        autoReturnTask = nil

        // Dismiss any active keyboard before resetting
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )

        idleTimer?.stop()
        applicant = ApplicantData()
        supportingDocuments.removeAll()
        fieldErrors.removeAll()
        validFields.removeAll()
        submissionError = nil

        // Re-setup observers for the new struct value
        cancellables.removeAll()

        setupFieldObservers()

        // Re-bind idle timer publishers (no .receive needed — IdleTimer is @MainActor)
        idleTimer?.$isWarningShown
            .sink { [weak self] value in
                guard self?.showIdleWarning != value else { return }
                self?.showIdleWarning = value
            }
            .store(in: &cancellables)

        idleTimer?.$secondsRemaining
            .sink { [weak self] value in
                guard self?.idleCountdown != value else { return }
                self?.idleCountdown = value
            }
            .store(in: &cancellables)

        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35)) {
            currentScreen = .welcome
        }
    }
}
