import UIKit

class PDFGenerator {

    // MARK: - Brand Colors
    private let purpleColor = UIColor(red: 70/255, green: 46/255, blue: 140/255, alpha: 1)   // #462E8C
    private let orangeColor = UIColor(red: 214/255, green: 76/255, blue: 1/255, alpha: 1)     // #D64C01
    private let grayColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)    // #6B7280
    private let darkColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)       // #1A1A1A
    private let lightGrayBg = UIColor(red: 249/255, green: 250/255, blue: 251/255, alpha: 1)  // #F9FAFB
    private let greenColor = UIColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)
    private let separatorColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1) // #E5E7EB

    // MARK: - Page Constants
    private let pageWidth: CGFloat = 595.2  // A4
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 50
    private let contentWidth: CGFloat = 495.2
    private let headerHeight: CGFloat = 85
    private let footerHeight: CGFloat = 50
    private let usableBottom: CGFloat = 841.8 - 50

    // MARK: - Layout Constants
    private let sectionHeaderBandHeight: CGFloat = 24
    private let fieldRowPadding: CGFloat = 6
    private let labelValueSpacing: CGFloat = 2
    private let rowSeparatorHeight: CGFloat = 0.5

    // MARK: - Page Tracking
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private var globalFieldIndex: Int = 0  // for alternating row shading

    // MARK: - Public API

    func generate(from applicant: ApplicantData) -> Data {
        totalPages = countPages(from: applicant)
        return renderPDF(from: applicant)
    }

    // MARK: - First Pass (Page Counting)

    private func countPages(from applicant: ApplicantData) -> Int {
        var pageCount = 1
        var yPosition: CGFloat = headerHeight + 10
        yPosition = simulateTitle(at: yPosition)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"

        // Personal Details section
        yPosition = simulateCheckNewPage(y: yPosition, needed: 44, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)

        let countNatDisplay = applicant.nationality == .others
            ? applicant.nationalityOther.isEmpty ? "Others" : applicant.nationalityOther
            : applicant.nationality.rawValue

        let twoColPersonal: [((String, String), (String, String))] = [
            (("Full Name", applicant.fullName), ("Preferred Name", applicant.preferredName)),
            (("NRIC / FIN", applicant.nricFIN), ("Date of Birth", dateFormatter.string(from: applicant.dateOfBirth))),
            (("Gender", applicant.gender.rawValue), ("Nationality", countNatDisplay)),
            (("Race", applicant.race == .others ? applicant.raceOther : applicant.race.rawValue), ("Contact Number", applicant.contactNumber))
        ]
        for _ in twoColPersonal {
            yPosition = simulateCheckNewPage(y: yPosition, needed: 36, pageCount: &pageCount)
            yPosition += 36
        }

        var singlePersonal: [(String, String)] = [
            ("Email", applicant.emailAddress),
            ("Address", applicant.residentialAddress),
            ("Postal Code", applicant.postalCode)
        ]
        if !applicant.passportNumber.isEmpty {
            singlePersonal.append(("Passport Number", applicant.passportNumber))
        }
        if !applicant.drivingLicenseClass.isEmpty {
            singlePersonal.append(("Driving License", applicant.drivingLicenseClass))
        }
        if !applicant.nationality.isSingaporean {
            singlePersonal.append(("Worked in Singapore Before", applicant.hasWorkedInSingapore ? "Yes" : "No"))
        }
        for (_, value) in singlePersonal {
            let h = simulateFieldHeight(value: value)
            yPosition = simulateCheckNewPage(y: yPosition, needed: h, pageCount: &pageCount)
            yPosition += h
        }
        // Emergency contacts
        for ec in applicant.emergencyContacts {
            yPosition = simulateCheckNewPage(y: yPosition, needed: 36, pageCount: &pageCount)
            yPosition += 36
            if !ec.email.isEmpty {
                yPosition = simulateCheckNewPage(y: yPosition, needed: 32, pageCount: &pageCount)
                yPosition += 32
            }
            if !ec.address.isEmpty {
                let h = simulateFieldHeight(value: ec.address)
                yPosition = simulateCheckNewPage(y: yPosition, needed: h, pageCount: &pageCount)
                yPosition += h
            }
        }

        // Education section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 44, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)

        let countQualDisplay = applicant.highestQualification == .others
            ? applicant.highestQualificationOther.isEmpty ? "Others" : applicant.highestQualificationOther
            : applicant.highestQualification.rawValue

        let educationFields: [(String, String)] = [
            ("Highest Qualification", countQualDisplay),
            ("Field of Study", applicant.fieldOfStudy),
            ("Institution", applicant.institutionName),
            ("Year of Graduation", "\(applicant.yearOfGraduation)"),
            ("Certifications", applicant.professionalCertifications.isEmpty ? "None" : applicant.professionalCertifications),
            ("Languages", applicant.selectedLanguages.map { "\($0.displayName) (\($0.proficiency.rawValue))" }.joined(separator: ", "))
        ]
        for (_, value) in educationFields {
            let h = simulateFieldHeight(value: value)
            yPosition = simulateCheckNewPage(y: yPosition, needed: h, pageCount: &pageCount)
            yPosition += h
        }

        // Additional Qualifications
        if !applicant.additionalQualifications.isEmpty {
            yPosition += 6
            yPosition += 18 // subsection label
            for (index, _) in applicant.additionalQualifications.enumerated() {
                yPosition = simulateCheckNewPage(y: yPosition, needed: 36, pageCount: &pageCount)
                yPosition += 36
                if index < applicant.additionalQualifications.count - 1 {
                    yPosition += 4
                }
            }
        }

        // Work Experience section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 44, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        yPosition = simulateCheckNewPage(y: yPosition, needed: 36, pageCount: &pageCount)
        yPosition += 36 // two-col row
        for _ in applicant.employmentHistory {
            yPosition += 8
            yPosition = simulateCheckNewPage(y: yPosition, needed: 120, pageCount: &pageCount)
            yPosition += 36 * 4 // 4 fields per employer
        }

        // References section
        if !applicant.references.isEmpty {
            yPosition += 10
            yPosition = simulateCheckNewPage(y: yPosition, needed: 44, pageCount: &pageCount)
            yPosition = simulateSectionHeader(at: yPosition)
            for _ in applicant.references {
                yPosition += 8
                yPosition = simulateCheckNewPage(y: yPosition, needed: 100, pageCount: &pageCount)
                yPosition += 36 * 3
            }
        }

        // Position & Availability section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 44, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        for (_, value) in buildPositionFields(from: applicant, dateFormatter: dateFormatter) {
            let h = simulateFieldHeight(value: value)
            yPosition = simulateCheckNewPage(y: yPosition, needed: h, pageCount: &pageCount)
            yPosition += h
        }

        // General Information section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 44, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        yPosition += 36 * 5 // 5 yes/no questions
        if applicant.hasConnectionsAtAFF { yPosition += 36 }
        if applicant.hasConflictOfInterest { yPosition += 36 }
        if applicant.hasBankruptcy { yPosition += 36 }
        if applicant.hasLegalProceedings { yPosition += 36 }

        // Signature section
        yPosition += 20
        yPosition = simulateCheckNewPage(y: yPosition, needed: 220, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        yPosition += 160

        return pageCount
    }

    private func simulateTitle(at y: CGFloat) -> CGFloat {
        return y + 22 + 20  // title + ref/date line
    }

    private func simulateSectionHeader(at y: CGFloat) -> CGFloat {
        return y + 8 + 16 + 10  // gap + text + rule + gap
    }

    private func simulateCheckNewPage(y: CGFloat, needed: CGFloat, pageCount: inout Int) -> CGFloat {
        if y + needed > usableBottom {
            pageCount += 1
            return headerHeight + 10
        }
        return y
    }

    private func simulateFieldHeight(value: String) -> CGFloat {
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular)
        ]
        let displayValue = value.isEmpty ? "-" : value
        let valueSize = (displayValue as NSString).boundingRect(
            with: CGSize(width: contentWidth - 10, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)
        // label (8pt) + spacing(2) + value height + row padding
        return max(32, 12 + labelValueSpacing + valueSize.height + fieldRowPadding * 2)
    }

    // MARK: - Second Pass (Actual Rendering)

    private func renderPDF(from applicant: ApplicantData) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            currentPage = 0
            globalFieldIndex = 0
            var yPosition: CGFloat = 0

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy"

            // --- Start Page 1 ---
            yPosition = beginNewPage(context: context)
            yPosition = drawTitle(at: yPosition, referenceNumber: applicant.referenceNumber, date: dateFormatter.string(from: applicant.submissionDate))

            // =====================
            // PERSONAL DETAILS
            // =====================
            yPosition = checkPageBreak(y: yPosition, needed: 44, context: context)
            yPosition = drawSectionHeader("Personal Details", at: yPosition)

            let nationalityDisplay = applicant.nationality == .others
                ? applicant.nationalityOther.isEmpty ? "Others" : applicant.nationalityOther
                : applicant.nationality.rawValue

            let contactDisplay = "\(applicant.contactCountryCode) \(applicant.contactNumber)"

            let maskedNRIC = NRICMasker.mask(applicant.nricFIN)

            let twoColPersonal: [((String, String), (String, String))] = [
                (("Full Name", applicant.fullName), ("Preferred Name", applicant.preferredName)),
                (("NRIC / FIN", maskedNRIC), ("Date of Birth", dateFormatter.string(from: applicant.dateOfBirth))),
                (("Gender", applicant.gender.rawValue), ("Nationality", nationalityDisplay)),
                (("Race", applicant.race == .others ? applicant.raceOther : applicant.race.rawValue), ("Contact Number", contactDisplay))
            ]
            for (left, right) in twoColPersonal {
                yPosition = checkPageBreak(y: yPosition, needed: 36, context: context)
                yPosition = drawTwoColumnField(left: left, right: right, at: yPosition)
            }

            var singlePersonal: [(String, String)] = [
                ("Email", applicant.emailAddress),
                ("Address", applicant.residentialAddress),
                ("Postal Code", applicant.postalCode)
            ]
            if !applicant.passportNumber.isEmpty {
                singlePersonal.append(("Passport Number", applicant.passportNumber))
            }
            if !applicant.drivingLicenseClass.isEmpty {
                singlePersonal.append(("Driving License", applicant.drivingLicenseClass))
            }
            if !applicant.nationality.isSingaporean {
                singlePersonal.append(("Worked in Singapore Before", applicant.hasWorkedInSingapore ? "Yes" : "No"))
            }
            for (label, value) in singlePersonal {
                yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // Emergency Contacts
            for (index, ec) in applicant.emergencyContacts.enumerated() {
                yPosition += 4
                let relDisplay = ec.relationship == .others
                    ? ec.relationshipOther.isEmpty ? "Others" : ec.relationshipOther
                    : ec.relationship.rawValue
                let ecPhoneDisplay = "\(ec.countryCode) \(ec.phoneNumber)"
                yPosition = checkPageBreak(y: yPosition, needed: 36, context: context)
                yPosition = drawTwoColumnField(
                    left: ("Emergency Contact \(index + 1)", "\(ec.name) (\(relDisplay))"),
                    right: ("Phone", ecPhoneDisplay),
                    at: yPosition
                )
                if !ec.email.isEmpty || !ec.address.isEmpty {
                    var ecExtra: [(String, String)] = []
                    if !ec.email.isEmpty { ecExtra.append(("Email", ec.email)) }
                    if !ec.address.isEmpty { ecExtra.append(("Address", ec.address)) }
                    for (label, value) in ecExtra {
                        yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                        yPosition = drawField(label: label, value: value, at: yPosition)
                    }
                }
            }

            // =====================
            // EDUCATION & QUALIFICATIONS
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 44, context: context)
            yPosition = drawSectionHeader("Education & Qualifications", at: yPosition)

            let qualificationDisplay = applicant.highestQualification == .others
                ? applicant.highestQualificationOther.isEmpty ? "Others" : applicant.highestQualificationOther
                : applicant.highestQualification.rawValue

            let educationFields: [(String, String)] = [
                ("Highest Qualification", qualificationDisplay),
                ("Field of Study", applicant.fieldOfStudy),
                ("Institution", applicant.institutionName),
                ("Year of Graduation", "\(applicant.yearOfGraduation)"),
                ("Certifications", applicant.professionalCertifications.isEmpty ? "None" : applicant.professionalCertifications),
                ("Languages", applicant.selectedLanguages.map { "\($0.displayName) (\($0.proficiency.rawValue))" }.joined(separator: ", "))
            ]

            for (label, value) in educationFields {
                yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // Additional Qualifications
            if !applicant.additionalQualifications.isEmpty {
                yPosition += 6
                yPosition = checkPageBreak(y: yPosition, needed: 30, context: context)
                yPosition = drawSubsectionLabel("Additional Qualifications", at: yPosition)

                for (index, qual) in applicant.additionalQualifications.enumerated() {
                    let qualDisplay = qual.qualification == .others
                        ? qual.qualificationOther.isEmpty ? "Others" : qual.qualificationOther
                        : qual.qualification.rawValue
                    yPosition = checkPageBreak(y: yPosition, needed: 36, context: context)
                    yPosition = drawTwoColumnField(
                        left: ("Qualification \(index + 1)", qualDisplay),
                        right: ("Institution", "\(qual.institution) (\(qual.year))"),
                        at: yPosition
                    )
                }
            }

            // =====================
            // WORK EXPERIENCE
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 44, context: context)
            yPosition = drawSectionHeader("Work Experience", at: yPosition)

            yPosition = checkPageBreak(y: yPosition, needed: 36, context: context)
            yPosition = drawTwoColumnField(
                left: ("Total Experience", applicant.totalExperience.rawValue),
                right: ("Currently Employed", applicant.isCurrentlyEmployed ? "Yes (Notice: \(applicant.noticePeriod.rawValue))" : "No"),
                at: yPosition
            )

            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM yyyy"

            for (index, record) in applicant.employmentHistory.enumerated() {
                yPosition += 8
                yPosition = checkPageBreak(y: yPosition, needed: 120, context: context)

                let period = record.isCurrentPosition
                    ? "\(monthFormatter.string(from: record.fromDate)) - Present"
                    : "\(monthFormatter.string(from: record.fromDate)) - \(monthFormatter.string(from: record.toDate))"

                yPosition = drawField(label: "Employer \(index + 1)", value: "\(record.companyName) | \(record.jobTitle)", at: yPosition)
                yPosition = drawTwoColumnField(
                    left: ("Industry", record.industry.rawValue),
                    right: ("Period", period),
                    at: yPosition
                )
                yPosition = drawField(label: "Reason for Leaving", value: record.reasonForLeaving.rawValue, at: yPosition)
                if !record.keyResponsibilities.isEmpty {
                    yPosition = drawField(label: "Key Responsibilities", value: record.keyResponsibilities, at: yPosition)
                }
            }

            // =====================
            // REFERENCES
            // =====================
            if !applicant.references.isEmpty {
                yPosition += 10
                yPosition = checkPageBreak(y: yPosition, needed: 44, context: context)
                yPosition = drawSectionHeader("References", at: yPosition)

                for (index, ref) in applicant.references.enumerated() {
                    yPosition += 8
                    yPosition = checkPageBreak(y: yPosition, needed: 100, context: context)
                    yPosition = drawTwoColumnField(
                        left: ("Reference \(index + 1)", ref.name),
                        right: ("Relationship", ref.relationship),
                        at: yPosition
                    )
                    let refPhoneDisplay = "\(ref.contactCountryCode) \(ref.contactNumber)"
                    yPosition = drawTwoColumnField(
                        left: ("Contact", refPhoneDisplay),
                        right: ("Email", ref.email),
                        at: yPosition
                    )
                    yPosition = drawField(label: "Years Known", value: ref.yearsKnown, at: yPosition)
                }
            }

            // =====================
            // POSITION & AVAILABILITY
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 44, context: context)
            yPosition = drawSectionHeader("Position & Availability", at: yPosition)

            let positions = applicant.positionsAppliedFor.map(\.rawValue).joined(separator: ", ")
            yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
            yPosition = drawField(label: "Positions Applied", value: positions, at: yPosition)

            let twoColPosition: [((String, String), (String, String))] = [
                (("Employment Type", applicant.preferredEmploymentType.rawValue), ("Earliest Start", dateFormatter.string(from: applicant.earliestStartDate))),
                (("Expected Salary", applicant.expectedSalary.isEmpty ? "-" : "SGD $\(applicant.expectedSalary)"), ("Last Drawn Salary", applicant.lastDrawnSalary.isEmpty ? "-" : "SGD $\(applicant.lastDrawnSalary)")),
                (("Shifts", applicant.willingToWorkShifts.rawValue), ("Travel", applicant.willingToTravel.rawValue)),
                (("Own Transport", applicant.hasOwnTransport ? "Yes" : "No"), ("Source", applicant.howDidYouHear.rawValue))
            ]

            for (left, right) in twoColPosition {
                yPosition = checkPageBreak(y: yPosition, needed: 36, context: context)
                yPosition = drawTwoColumnField(left: left, right: right, at: yPosition)
            }

            if applicant.howDidYouHear == .referral && !applicant.referrerName.isEmpty {
                yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                yPosition = drawField(label: "Referrer", value: applicant.referrerName, at: yPosition)
            }

            yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
            yPosition = drawField(label: "Open to Other Positions", value: applicant.openToOtherPositions ? "Yes" : "No", at: yPosition)

            // =====================
            // GENERAL INFORMATION
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 44, context: context)
            yPosition = drawSectionHeader("General Information", at: yPosition)

            let generalInfoItems: [(String, Bool, String)] = [
                ("Previously Applied to AFF", applicant.previouslyApplied, ""),
                ("Friends / Relatives at AFF", applicant.hasConnectionsAtAFF, applicant.connectionsDetails),
                ("Conflict of Interest", applicant.hasConflictOfInterest, applicant.conflictDetails),
                ("Bankruptcy", applicant.hasBankruptcy, applicant.bankruptcyDetails),
                ("Legal Proceedings", applicant.hasLegalProceedings, applicant.legalDetails)
            ]

            for (label, value, details) in generalInfoItems {
                yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                yPosition = drawField(label: label, value: value ? "Yes" : "No", at: yPosition)
                if value && !details.isEmpty {
                    yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                    yPosition = drawField(label: "  Details", value: details, at: yPosition)
                }
            }

            // =====================
            // DECLARATION & SIGNATURE
            // =====================
            yPosition += 20
            yPosition = checkPageBreak(y: yPosition, needed: 220, context: context)
            yPosition = drawSectionHeader("Declaration & Signature", at: yPosition)

            // Declaration checkmarks
            let declarations: [(String, Bool)] = [
                ("I declare that all information provided is true and accurate.", applicant.declarationAccuracy),
                ("I consent to the collection and use of my personal data (PDPA).", applicant.pdpaConsent)
            ]
            for (text, agreed) in declarations {
                yPosition = checkPageBreak(y: yPosition, needed: 22, context: context)
                yPosition = drawDeclarationItem(text: text, agreed: agreed, at: yPosition)
            }

            // Medical declaration
            if applicant.hasMedicalCondition == .yes {
                yPosition = checkPageBreak(y: yPosition, needed: 32, context: context)
                yPosition = drawField(label: "Medical Condition", value: applicant.medicalDetails.isEmpty ? "Yes (details not provided)" : applicant.medicalDetails, at: yPosition)
            }

            yPosition += 16

            // Signature image
            if let sigData = applicant.signatureData, let sigImage = UIImage(data: sigData) {
                yPosition = checkPageBreak(y: yPosition, needed: 170, context: context)

                // "Applicant's Signature" label above
                let sigLabelAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .semibold),
                    .foregroundColor: grayColor
                ]
                ("APPLICANT'S SIGNATURE" as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sigLabelAttr)
                yPosition += 14

                let sigBoxRect = CGRect(x: margin, y: yPosition, width: 300, height: 100)

                // Thin 1pt gray border
                let ctx = context.cgContext
                ctx.setStrokeColor(separatorColor.cgColor)
                ctx.setLineWidth(1)
                ctx.stroke(sigBoxRect)

                // Draw signature inside with slight padding
                let sigInset = sigBoxRect.insetBy(dx: 8, dy: 8)
                sigImage.draw(in: sigInset)
                yPosition += 110

                let signedDate = dateFormatter.string(from: applicant.submissionDate)
                yPosition = drawTwoColumnField(
                    left: ("Date Signed", signedDate),
                    right: ("Reference", applicant.referenceNumber),
                    at: yPosition,
                    rightColor: orangeColor
                )
            } else {
                yPosition = drawTwoColumnField(
                    left: ("Date", dateFormatter.string(from: applicant.submissionDate)),
                    right: ("Reference", applicant.referenceNumber),
                    at: yPosition,
                    rightColor: orangeColor
                )
            }

            // Final footer for last page
            drawFooter(in: context.cgContext)
        }

        return data
    }

    // MARK: - Page Management

    private func beginNewPage(context: UIGraphicsPDFRendererContext) -> CGFloat {
        currentPage += 1
        context.beginPage()
        return drawHeader(in: context.cgContext)
    }

    private func checkPageBreak(y: CGFloat, needed: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        if y + needed > usableBottom {
            drawFooter(in: context.cgContext)
            return beginNewPage(context: context)
        }
        return y
    }

    // MARK: - Header

    private func drawHeader(in context: CGContext) -> CGFloat {
        let headerTopPad: CGFloat = 18

        // --- VKA Logo (left-aligned) from asset catalog ---
        if let vkaLogo = UIImage(named: "vka_logo_purple") {
            let logoHeight: CGFloat = 28
            let aspectRatio = vkaLogo.size.width / vkaLogo.size.height
            let logoWidth = min(logoHeight * aspectRatio, 75)
            let vkaLogoRect = CGRect(x: margin, y: headerTopPad + 12, width: logoWidth, height: logoHeight)
            vkaLogo.draw(in: vkaLogoRect)
        }

        // --- AFF company name (right-aligned) ---
        let affNameAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: darkColor
        ]
        let affSubAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: grayColor
        ]

        let affName = "Advanced Flavors & Fragrances Pte. Ltd." as NSString
        let affSub = "Singapore" as NSString
        let affNameSize = affName.size(withAttributes: affNameAttr)
        let affSubSize = affSub.size(withAttributes: affSubAttr)

        let affNameX = pageWidth - margin - affNameSize.width
        let affNameY = headerTopPad + 14
        affName.draw(at: CGPoint(x: affNameX, y: affNameY), withAttributes: affNameAttr)

        let affSubX = pageWidth - margin - affSubSize.width
        let affSubY = affNameY + affNameSize.height + 2
        affSub.draw(at: CGPoint(x: affSubX, y: affSubY), withAttributes: affSubAttr)

        // --- Thin dark rule with orange accent strip ---
        let ruleY = headerTopPad + 58
        context.setFillColor(darkColor.cgColor)
        context.fill(CGRect(x: margin, y: ruleY, width: contentWidth, height: 1))
        context.setFillColor(orangeColor.cgColor)
        context.fill(CGRect(x: margin, y: ruleY, width: 50, height: 2))

        return ruleY + 14
    }

    // MARK: - Title

    private func drawTitle(at y: CGFloat, referenceNumber: String, date: String) -> CGFloat {
        var yPos = y

        // Title: uppercase, tracked, corporate
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: darkColor,
            .kern: 1.5 as NSNumber
        ]
        let title = "REGISTRATION FORM"
        (title as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: titleAttr)

        yPos += 22

        // Reference and date on same line
        let metaAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: grayColor
        ]
        let refAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: orangeColor
        ]

        ("Ref: " as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: metaAttr)
        let refLabelWidth = ("Ref: " as NSString).size(withAttributes: metaAttr).width
        (referenceNumber as NSString).draw(at: CGPoint(x: margin + refLabelWidth, y: yPos), withAttributes: refAttr)

        let dateStr = "Date: \(date)" as NSString
        let dateSize = dateStr.size(withAttributes: metaAttr)
        dateStr.draw(at: CGPoint(x: pageWidth - margin - dateSize.width, y: yPos), withAttributes: metaAttr)

        yPos += 20

        return yPos
    }

    // MARK: - Section Header

    private func drawSectionHeader(_ title: String, at y: CGFloat) -> CGFloat {
        var yPos = y + 8
        globalFieldIndex = 0  // reset alternating row index per section

        let ctx = UIGraphicsGetCurrentContext()

        // Section title — uppercase, dark, tracked
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: darkColor,
            .kern: 1.2 as NSNumber
        ]
        (title.uppercased() as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: attr)

        yPos += 16

        // Full-width dark rule with short orange accent
        ctx?.setFillColor(separatorColor.cgColor)
        ctx?.fill(CGRect(x: margin, y: yPos, width: contentWidth, height: 1))
        ctx?.setFillColor(orangeColor.cgColor)
        ctx?.fill(CGRect(x: margin, y: yPos, width: 30, height: 2))
        yPos += 10

        return yPos
    }

    // MARK: - Subsection Label

    private func drawSubsectionLabel(_ title: String, at y: CGFloat) -> CGFloat {
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: purpleColor
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attr)
        return y + 18
    }

    // MARK: - Row Background & Separator

    private func drawRowBackground(at y: CGFloat, height: CGFloat) {
        let ctx = UIGraphicsGetCurrentContext()

        // Alternating row shading
        if globalFieldIndex % 2 == 1 {
            ctx?.setFillColor(lightGrayBg.cgColor)
            ctx?.fill(CGRect(x: margin, y: y, width: contentWidth, height: height))
        }

        // Bottom separator line
        ctx?.setFillColor(separatorColor.cgColor)
        ctx?.fill(CGRect(x: margin, y: y + height - rowSeparatorHeight, width: contentWidth, height: rowSeparatorHeight))

        globalFieldIndex += 1
    }

    // MARK: - Single Field (label-above-value, full width)

    private func drawField(label: String, value: String, at y: CGFloat, valueColor: UIColor? = nil) -> CGFloat {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: grayColor
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: valueColor ?? darkColor
        ]

        let displayValue = value.isEmpty ? "-" : value
        let valueSize = (displayValue as NSString).boundingRect(
            with: CGSize(width: contentWidth - 16, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)

        // Label height (8pt font ~ 10pt) + spacing + value height + padding
        let labelHeight: CGFloat = 12
        let totalRowHeight = max(32, fieldRowPadding + labelHeight + labelValueSpacing + valueSize.height + fieldRowPadding)

        // Draw row background and separator
        drawRowBackground(at: y, height: totalRowHeight)

        // Label (uppercase, 8pt semibold gray)
        let labelY = y + fieldRowPadding
        (label.uppercased() as NSString).draw(at: CGPoint(x: margin + 8, y: labelY), withAttributes: labelAttr)

        // Value below label
        let valueY = labelY + labelHeight + labelValueSpacing
        let valueRect = CGRect(x: margin + 8, y: valueY, width: contentWidth - 16, height: valueSize.height + 4)
        (displayValue as NSString).draw(with: valueRect, options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)

        return y + totalRowHeight
    }

    // MARK: - Two-Column Field (labels above values)

    private func drawTwoColumnField(
        left: (String, String),
        right: (String, String),
        at y: CGFloat,
        rightColor: UIColor? = nil
    ) -> CGFloat {
        let colWidth = (contentWidth - 20 - 16) / 2  // minus gutter and side padding
        let leftX = margin + 8
        let rightX = margin + 8 + colWidth + 20

        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: grayColor
        ]
        let leftValueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: darkColor
        ]
        let rightValueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: rightColor ?? darkColor
        ]

        let leftDisplay = left.1.isEmpty ? "-" : left.1
        let rightDisplay = right.1.isEmpty ? "-" : right.1

        let leftSize = (leftDisplay as NSString).boundingRect(
            with: CGSize(width: colWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: leftValueAttr, context: nil)
        let rightSize = (rightDisplay as NSString).boundingRect(
            with: CGSize(width: colWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: rightValueAttr, context: nil)

        let labelHeight: CGFloat = 12
        let maxValueHeight = max(leftSize.height, rightSize.height)
        let totalRowHeight = max(36, fieldRowPadding + labelHeight + labelValueSpacing + maxValueHeight + fieldRowPadding)

        // Draw row background and separator
        drawRowBackground(at: y, height: totalRowHeight)

        let labelY = y + fieldRowPadding
        let valueY = labelY + labelHeight + labelValueSpacing

        // Left column: label above value
        (left.0.uppercased() as NSString).draw(at: CGPoint(x: leftX, y: labelY), withAttributes: labelAttr)
        let leftValueRect = CGRect(x: leftX, y: valueY, width: colWidth, height: maxValueHeight + 4)
        (leftDisplay as NSString).draw(with: leftValueRect, options: .usesLineFragmentOrigin, attributes: leftValueAttr, context: nil)

        // Right column: label above value
        (right.0.uppercased() as NSString).draw(at: CGPoint(x: rightX, y: labelY), withAttributes: labelAttr)
        let rightValueRect = CGRect(x: rightX, y: valueY, width: colWidth, height: maxValueHeight + 4)
        (rightDisplay as NSString).draw(with: rightValueRect, options: .usesLineFragmentOrigin, attributes: rightValueAttr, context: nil)

        return y + totalRowHeight
    }

    // MARK: - Declaration Item

    private func drawDeclarationItem(text: String, agreed: Bool, at y: CGFloat) -> CGFloat {
        // Green checkmark or gray empty box
        let checkmark = agreed ? "\u{2713}" : "\u{25A1}"
        let checkColor = agreed ? greenColor : grayColor

        let checkAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: checkColor
        ]
        let textAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: darkColor
        ]

        (checkmark as NSString).draw(at: CGPoint(x: margin + 8, y: y), withAttributes: checkAttr)
        (text as NSString).draw(at: CGPoint(x: margin + 26, y: y + 2), withAttributes: textAttr)

        return y + 22
    }

    // MARK: - Footer

    private func drawFooter(in context: CGContext) {
        let footerY = pageHeight - 35

        // Thin gray rule above footer
        context.setFillColor(grayColor.withAlphaComponent(0.3).cgColor)
        context.fill(CGRect(x: margin, y: footerY - 6, width: contentWidth, height: 0.5))

        // "CONFIDENTIAL" small caps left side
        let confidentialAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .semibold),
            .foregroundColor: grayColor.withAlphaComponent(0.6)
        ]
        ("CONFIDENTIAL" as NSString).draw(at: CGPoint(x: margin, y: footerY), withAttributes: confidentialAttr)

        // Center: auto-generated notice
        let centerAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .regular),
            .foregroundColor: grayColor
        ]
        let centerText = "AFF Registration System" as NSString
        let centerSize = centerText.size(withAttributes: centerAttr)
        let centerX = margin + (contentWidth - centerSize.width) / 2
        centerText.draw(at: CGPoint(x: centerX, y: footerY), withAttributes: centerAttr)

        // Page X of Y right-aligned
        let pageAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: grayColor
        ]
        let pageStr = "Page \(currentPage) of \(totalPages)" as NSString
        let pageSize = pageStr.size(withAttributes: pageAttr)
        pageStr.draw(at: CGPoint(x: pageWidth - margin - pageSize.width, y: footerY), withAttributes: pageAttr)
    }

    // MARK: - Helpers

    private func buildPositionFields(from applicant: ApplicantData, dateFormatter: DateFormatter) -> [(String, String)] {
        let positions = applicant.positionsAppliedFor.map(\.rawValue).joined(separator: ", ")
        return [
            ("Positions Applied", positions),
            ("Employment Type", applicant.preferredEmploymentType.rawValue),
            ("Earliest Start", dateFormatter.string(from: applicant.earliestStartDate)),
            ("Expected Salary", applicant.expectedSalary.isEmpty ? "-" : "SGD $\(applicant.expectedSalary)"),
            ("Last Drawn Salary", applicant.lastDrawnSalary.isEmpty ? "-" : "SGD $\(applicant.lastDrawnSalary)"),
            ("Shifts", applicant.willingToWorkShifts.rawValue),
            ("Travel", applicant.willingToTravel.rawValue),
            ("Own Transport", applicant.hasOwnTransport ? "Yes" : "No"),
            ("Source", applicant.howDidYouHear.rawValue),
            ("Open to Other Positions", applicant.openToOtherPositions ? "Yes" : "No")
        ]
    }
}
