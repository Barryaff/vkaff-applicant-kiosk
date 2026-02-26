import UIKit

class PDFGenerator {

    // MARK: - Brand Colors
    private let purpleColor = UIColor(red: 70/255, green: 46/255, blue: 140/255, alpha: 1)   // #462E8C
    private let orangeColor = UIColor(red: 214/255, green: 76/255, blue: 1/255, alpha: 1)     // #D64C01
    private let grayColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)    // #6B7280
    private let darkColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)
    private let lightGrayBg = UIColor(red: 249/255, green: 250/255, blue: 251/255, alpha: 1)  // subtle bg for section headers

    // MARK: - Page Constants
    private let pageWidth: CGFloat = 595.2  // A4
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 50
    private let contentWidth: CGFloat = 495.2
    private let headerHeight: CGFloat = 85  // space reserved for header + logos + rule
    private let footerHeight: CGFloat = 50  // space reserved for footer
    private let usableBottom: CGFloat = 841.8 - 50  // pageHeight - footerHeight

    // MARK: - Page Tracking
    private var currentPage: Int = 0
    private var totalPages: Int = 1

    // MARK: - Public API

    func generate(from applicant: ApplicantData) -> Data {
        // Two-pass rendering: first pass counts pages, second pass renders with "Page X of Y"
        totalPages = countPages(from: applicant)
        return renderPDF(from: applicant)
    }

    // MARK: - First Pass (Page Counting)

    private func countPages(from applicant: ApplicantData) -> Int {
        var pageCount = 1
        var yPosition: CGFloat = headerHeight + 10 // after header
        yPosition = simulateTitle(at: yPosition, applicant: applicant)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"

        // Personal Details section
        yPosition = simulateCheckNewPage(y: yPosition, needed: 40, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)

        // Two-column rows
        let twoColPersonal: [((String, String), (String, String))] = [
            (("Full Name", applicant.fullName), ("Preferred Name", applicant.preferredName)),
            (("NRIC / FIN", applicant.nricFIN), ("Date of Birth", dateFormatter.string(from: applicant.dateOfBirth))),
            (("Gender", applicant.gender.rawValue), ("Nationality", applicant.nationality.rawValue)),
            (("Race", applicant.race == .others ? applicant.raceOther : applicant.race.rawValue), ("Contact Number", applicant.contactNumber))
        ]
        for _ in twoColPersonal {
            yPosition = simulateCheckNewPage(y: yPosition, needed: 24, pageCount: &pageCount)
            yPosition += 24
        }

        let singlePersonal: [(String, String)] = [
            ("Email", applicant.emailAddress),
            ("Address", applicant.residentialAddress),
            ("Postal Code", applicant.postalCode),
            ("Emergency Contact", "\(applicant.emergencyContactName) (\(applicant.emergencyContactRelationship.rawValue))"),
            ("Emergency Phone", applicant.emergencyContactNumber)
        ]
        for (_, value) in singlePersonal {
            yPosition = simulateCheckNewPage(y: yPosition, needed: 24, pageCount: &pageCount)
            let h = simulateFieldHeight(value: value)
            yPosition += h
        }

        // Education section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 40, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)

        let educationFields: [(String, String)] = [
            ("Highest Qualification", applicant.highestQualification.rawValue),
            ("Field of Study", applicant.fieldOfStudy),
            ("Institution", applicant.institutionName),
            ("Year of Graduation", "\(applicant.yearOfGraduation)"),
            ("Certifications", applicant.professionalCertifications.isEmpty ? "None" : applicant.professionalCertifications),
            ("Languages", applicant.selectedLanguages.map { "\($0.displayName) (\($0.proficiency.rawValue))" }.joined(separator: ", "))
        ]
        for (_, value) in educationFields {
            yPosition = simulateCheckNewPage(y: yPosition, needed: 24, pageCount: &pageCount)
            let h = simulateFieldHeight(value: value)
            yPosition += h
        }

        // Additional Qualifications
        if !applicant.additionalQualifications.isEmpty {
            yPosition += 6
            for (index, _) in applicant.additionalQualifications.enumerated() {
                yPosition = simulateCheckNewPage(y: yPosition, needed: 24, pageCount: &pageCount)
                yPosition += 24
                if index < applicant.additionalQualifications.count - 1 {
                    yPosition += 4
                }
            }
        }

        // Work Experience section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 40, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        // two fields
        yPosition = simulateCheckNewPage(y: yPosition, needed: 24, pageCount: &pageCount)
        yPosition += 24 // two-col row
        for _ in applicant.employmentHistory {
            yPosition += 8
            yPosition = simulateCheckNewPage(y: yPosition, needed: 100, pageCount: &pageCount)
            yPosition += 24 * 4 // 4 fields per employer
        }

        // Position & Availability section
        yPosition += 10
        yPosition = simulateCheckNewPage(y: yPosition, needed: 40, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        // position fields
        for (_, value) in buildPositionFields(from: applicant, dateFormatter: dateFormatter) {
            yPosition = simulateCheckNewPage(y: yPosition, needed: 24, pageCount: &pageCount)
            let h = simulateFieldHeight(value: value)
            yPosition += h
        }

        // Signature section
        yPosition += 20
        yPosition = simulateCheckNewPage(y: yPosition, needed: 200, pageCount: &pageCount)
        yPosition = simulateSectionHeader(at: yPosition)
        yPosition += 140 // signature + date + reference

        return pageCount
    }

    private func simulateTitle(at y: CGFloat, applicant: ApplicantData) -> CGFloat {
        // title + subtitle + ref + date row + spacing
        return y + 24 + 20 + 20
    }

    private func simulateSectionHeader(at y: CGFloat) -> CGFloat {
        return y + 8 + 20 + 12
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
            with: CGSize(width: contentWidth - 140, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)
        return max(20, valueSize.height + 8)
    }

    // MARK: - Second Pass (Actual Rendering)

    private func renderPDF(from applicant: ApplicantData) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            currentPage = 0
            var yPosition: CGFloat = 0

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy"

            // --- Start Page 1 ---
            yPosition = beginNewPage(context: context)
            yPosition = drawTitle(at: yPosition, referenceNumber: applicant.referenceNumber, date: dateFormatter.string(from: applicant.submissionDate))

            // =====================
            // PERSONAL DETAILS
            // =====================
            yPosition = checkPageBreak(y: yPosition, needed: 40, context: context)
            yPosition = drawSectionHeader("Personal Details", at: yPosition)

            // Two-column paired fields
            let twoColPersonal: [((String, String), (String, String))] = [
                (("Full Name", applicant.fullName), ("Preferred Name", applicant.preferredName)),
                (("NRIC / FIN", applicant.nricFIN), ("Date of Birth", dateFormatter.string(from: applicant.dateOfBirth))),
                (("Gender", applicant.gender.rawValue), ("Nationality", applicant.nationality.rawValue)),
                (("Race", applicant.race == .others ? applicant.raceOther : applicant.race.rawValue), ("Contact Number", applicant.contactNumber))
            ]
            for (left, right) in twoColPersonal {
                yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                yPosition = drawTwoColumnField(left: left, right: right, at: yPosition)
            }

            // Single-column fields (email, address, etc.)
            let singlePersonal: [(String, String)] = [
                ("Email", applicant.emailAddress),
                ("Address", applicant.residentialAddress),
                ("Postal Code", applicant.postalCode),
                ("Emergency Contact", "\(applicant.emergencyContactName) (\(applicant.emergencyContactRelationship.rawValue))"),
                ("Emergency Phone", applicant.emergencyContactNumber)
            ]
            for (label, value) in singlePersonal {
                yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // =====================
            // EDUCATION & QUALIFICATIONS
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 40, context: context)
            yPosition = drawSectionHeader("Education & Qualifications", at: yPosition)

            let educationFields: [(String, String)] = [
                ("Highest Qualification", applicant.highestQualification.rawValue),
                ("Field of Study", applicant.fieldOfStudy),
                ("Institution", applicant.institutionName),
                ("Year of Graduation", "\(applicant.yearOfGraduation)"),
                ("Certifications", applicant.professionalCertifications.isEmpty ? "None" : applicant.professionalCertifications),
                ("Languages", applicant.selectedLanguages.map { "\($0.displayName) (\($0.proficiency.rawValue))" }.joined(separator: ", "))
            ]

            for (label, value) in educationFields {
                yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // Additional Qualifications
            if !applicant.additionalQualifications.isEmpty {
                yPosition += 6
                yPosition = checkPageBreak(y: yPosition, needed: 30, context: context)
                yPosition = drawSubsectionLabel("Additional Qualifications", at: yPosition)

                for (index, qual) in applicant.additionalQualifications.enumerated() {
                    yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                    yPosition = drawTwoColumnField(
                        left: ("Qualification \(index + 1)", qual.qualification.rawValue),
                        right: ("Institution", "\(qual.institution) (\(qual.year))"),
                        at: yPosition
                    )
                }
            }

            // =====================
            // WORK EXPERIENCE
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 40, context: context)
            yPosition = drawSectionHeader("Work Experience", at: yPosition)

            // Two-col for total experience + currently employed
            yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
            yPosition = drawTwoColumnField(
                left: ("Total Experience", applicant.totalExperience.rawValue),
                right: ("Currently Employed", applicant.isCurrentlyEmployed ? "Yes (Notice: \(applicant.noticePeriod.rawValue))" : "No"),
                at: yPosition
            )

            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM yyyy"

            for (index, record) in applicant.employmentHistory.enumerated() {
                yPosition += 8
                yPosition = checkPageBreak(y: yPosition, needed: 100, context: context)

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
            // POSITION & AVAILABILITY
            // =====================
            yPosition += 10
            yPosition = checkPageBreak(y: yPosition, needed: 40, context: context)
            yPosition = drawSectionHeader("Position & Availability", at: yPosition)

            let positions = applicant.positionsAppliedFor.map(\.rawValue).joined(separator: ", ")
            yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
            yPosition = drawField(label: "Positions Applied", value: positions, at: yPosition)

            // Two-col pairs
            let twoColPosition: [((String, String), (String, String))] = [
                (("Employment Type", applicant.preferredEmploymentType.rawValue), ("Earliest Start", dateFormatter.string(from: applicant.earliestStartDate))),
                (("Expected Salary", applicant.expectedSalary.isEmpty ? "Not specified" : "SGD $\(applicant.expectedSalary)"), ("Last Drawn Salary", applicant.lastDrawnSalary.isEmpty ? "Not specified" : "SGD $\(applicant.lastDrawnSalary)")),
                (("Shifts", applicant.willingToWorkShifts.rawValue), ("Travel", applicant.willingToTravel.rawValue)),
                (("Own Transport", applicant.hasOwnTransport ? "Yes" : "No"), ("Source", applicant.howDidYouHear.rawValue))
            ]

            for (left, right) in twoColPosition {
                yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                yPosition = drawTwoColumnField(left: left, right: right, at: yPosition)
            }

            if applicant.howDidYouHear == .referral && !applicant.referrerName.isEmpty {
                yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                yPosition = drawField(label: "Referrer", value: applicant.referrerName, at: yPosition)
            }

            // =====================
            // DECLARATION & SIGNATURE
            // =====================
            yPosition += 20
            yPosition = checkPageBreak(y: yPosition, needed: 200, context: context)
            yPosition = drawSectionHeader("Declaration & Signature", at: yPosition)

            // Declaration checkmarks
            let declarations: [(String, Bool)] = [
                ("I declare that all information provided is true and accurate.", applicant.declarationAccuracy),
                ("I consent to the collection and use of my personal data (PDPA).", applicant.pdpaConsent),
                ("I consent to background verification checks.", applicant.backgroundCheckConsent)
            ]
            for (text, agreed) in declarations {
                yPosition = checkPageBreak(y: yPosition, needed: 18, context: context)
                yPosition = drawDeclarationItem(text: text, agreed: agreed, at: yPosition)
            }

            // Medical declaration
            if applicant.hasMedicalCondition == .yes {
                yPosition = checkPageBreak(y: yPosition, needed: 24, context: context)
                yPosition = drawField(label: "Medical Condition", value: applicant.medicalDetails.isEmpty ? "Yes (details not provided)" : applicant.medicalDetails, at: yPosition)
            }

            yPosition += 12

            // Signature image with 2pt purple border
            if let sigData = applicant.signatureData, let sigImage = UIImage(data: sigData) {
                yPosition = checkPageBreak(y: yPosition, needed: 160, context: context)

                let sigBoxRect = CGRect(x: margin, y: yPosition, width: 300, height: 100)

                // 2pt purple border
                let ctx = context.cgContext
                ctx.setStrokeColor(purpleColor.cgColor)
                ctx.setLineWidth(2)
                ctx.stroke(sigBoxRect.insetBy(dx: -6, dy: -6))

                sigImage.draw(in: sigBoxRect)
                yPosition += 118

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
        let logoY: CGFloat = 14

        // --- VKA Logo placeholder (left-aligned, 60pt height) ---
        let vkaLogoRect = CGRect(x: margin, y: logoY, width: 100, height: 60)
        context.setFillColor(purpleColor.withAlphaComponent(0.1).cgColor)
        context.fill(vkaLogoRect)
        context.setStrokeColor(purpleColor.cgColor)
        context.setLineWidth(1.5)
        context.stroke(vkaLogoRect)

        let vkaAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: purpleColor
        ]
        let vkaStr = "VKA" as NSString
        let vkaSize = vkaStr.size(withAttributes: vkaAttr)
        vkaStr.draw(at: CGPoint(
            x: vkaLogoRect.midX - vkaSize.width / 2,
            y: vkaLogoRect.midY - vkaSize.height / 2
        ), withAttributes: vkaAttr)

        // --- AFF Logo placeholder (right-aligned, 40pt height) ---
        let affLogoRect = CGRect(x: pageWidth - margin - 80, y: logoY + 10, width: 80, height: 40)
        context.setFillColor(orangeColor.withAlphaComponent(0.1).cgColor)
        context.fill(affLogoRect)
        context.setStrokeColor(orangeColor.cgColor)
        context.setLineWidth(1.5)
        context.stroke(affLogoRect)

        let affAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: orangeColor
        ]
        let affStr = "AFF" as NSString
        let affSize = affStr.size(withAttributes: affAttr)
        affStr.draw(at: CGPoint(
            x: affLogoRect.midX - affSize.width / 2,
            y: affLogoRect.midY - affSize.height / 2
        ), withAttributes: affAttr)

        // --- 2pt orange horizontal rule spanning full width below header ---
        let ruleY = logoY + 66
        context.setFillColor(orangeColor.cgColor)
        context.fill(CGRect(x: margin, y: ruleY, width: contentWidth, height: 2))

        return ruleY + 14 // return Y below the rule
    }

    // MARK: - Title

    private func drawTitle(at y: CGFloat, referenceNumber: String, date: String) -> CGFloat {
        var yPos = y

        // Title: 18pt semibold, purple
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: purpleColor
        ]
        let title = "Walk-In Applicant Registration Form"
        (title as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: titleAttr)

        // Right-aligned reference number in orange (same line as title)
        let refAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: orangeColor
        ]
        let refStr = referenceNumber as NSString
        let refSize = refStr.size(withAttributes: refAttr)
        refStr.draw(at: CGPoint(x: pageWidth - margin - refSize.width, y: yPos + 2), withAttributes: refAttr)

        yPos += 24

        // Subtitle: 12pt gray
        let subtitleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: grayColor
        ]
        ("Advanced Flavors & Fragrances Pte. Ltd." as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: subtitleAttr)

        // Right-aligned date in gray (same line as subtitle)
        let dateAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: grayColor
        ]
        let dateStr = date as NSString
        let dateSize = dateStr.size(withAttributes: dateAttr)
        dateStr.draw(at: CGPoint(x: pageWidth - margin - dateSize.width, y: yPos + 1), withAttributes: dateAttr)

        yPos += 26

        return yPos
    }

    // MARK: - Section Header

    private func drawSectionHeader(_ title: String, at y: CGFloat) -> CGFloat {
        var yPos = y + 8

        // Light background band
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(lightGrayBg.cgColor)
        ctx?.fill(CGRect(x: margin, y: yPos - 2, width: contentWidth, height: 22))

        // Purple text, 14pt semibold
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: purpleColor
        ]
        (title as NSString).draw(at: CGPoint(x: margin + 8, y: yPos), withAttributes: attr)
        yPos += 22

        // Orange underline accent (60pt wide, 2pt thick)
        ctx?.setFillColor(orangeColor.cgColor)
        ctx?.fill(CGRect(x: margin, y: yPos, width: 60, height: 2))
        yPos += 12

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

    // MARK: - Single Field (label-value, full width)

    private func drawField(label: String, value: String, at y: CGFloat, valueColor: UIColor? = nil) -> CGFloat {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: grayColor
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: valueColor ?? darkColor
        ]

        var yPos = y

        (label.uppercased() as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: labelAttr)

        // Value with text wrapping
        let valueX = margin + 150
        let valueWidth = contentWidth - 150
        let displayValue = value.isEmpty ? "-" : value
        let valueRect = CGRect(x: valueX, y: yPos, width: valueWidth, height: 80)
        (displayValue as NSString).draw(with: valueRect, options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)

        let valueSize = (displayValue as NSString).boundingRect(
            with: CGSize(width: valueWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)
        yPos += max(20, valueSize.height + 8)

        return yPos
    }

    // MARK: - Two-Column Field

    private func drawTwoColumnField(
        left: (String, String),
        right: (String, String),
        at y: CGFloat,
        rightColor: UIColor? = nil
    ) -> CGFloat {
        let colWidth = (contentWidth - 20) / 2  // 20pt gutter
        let leftX = margin
        let rightX = margin + colWidth + 20

        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
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

        var yPos = y

        // Left column
        (left.0.uppercased() as NSString).draw(at: CGPoint(x: leftX, y: yPos), withAttributes: labelAttr)
        let leftDisplay = left.1.isEmpty ? "-" : left.1
        let leftValueRect = CGRect(x: leftX, y: yPos + 12, width: colWidth, height: 40)
        (leftDisplay as NSString).draw(with: leftValueRect, options: .usesLineFragmentOrigin, attributes: leftValueAttr, context: nil)
        let leftSize = (leftDisplay as NSString).boundingRect(
            with: CGSize(width: colWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: leftValueAttr, context: nil)

        // Right column
        (right.0.uppercased() as NSString).draw(at: CGPoint(x: rightX, y: yPos), withAttributes: labelAttr)
        let rightDisplay = right.1.isEmpty ? "-" : right.1
        let rightValueRect = CGRect(x: rightX, y: yPos + 12, width: colWidth, height: 40)
        (rightDisplay as NSString).draw(with: rightValueRect, options: .usesLineFragmentOrigin, attributes: rightValueAttr, context: nil)
        let rightSize = (rightDisplay as NSString).boundingRect(
            with: CGSize(width: colWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: rightValueAttr, context: nil)

        let maxH = max(leftSize.height, rightSize.height)
        yPos += 12 + max(18, maxH + 8)

        return yPos
    }

    // MARK: - Declaration Item

    private func drawDeclarationItem(text: String, agreed: Bool, at y: CGFloat) -> CGFloat {
        let checkmark = agreed ? "\u{2713}" : "\u{2717}"
        let checkColor = agreed ? UIColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1) : UIColor.red

        let checkAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: checkColor
        ]
        let textAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: darkColor
        ]

        (checkmark as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: checkAttr)
        (text as NSString).draw(at: CGPoint(x: margin + 18, y: y + 1), withAttributes: textAttr)

        return y + 18
    }

    // MARK: - Footer

    private func drawFooter(in context: CGContext) {
        let footerY = pageHeight - 35

        // Thin gray rule above footer
        context.setFillColor(grayColor.withAlphaComponent(0.3).cgColor)
        context.fill(CGRect(x: margin, y: footerY - 6, width: contentWidth, height: 0.5))

        let leftAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .regular),
            .foregroundColor: grayColor
        ]
        let footer = "This document is auto-generated by the VKAFF Applicant Registration System. Confidential."
        (footer as NSString).draw(at: CGPoint(x: margin, y: footerY), withAttributes: leftAttr)

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
            ("Expected Salary", applicant.expectedSalary.isEmpty ? "Not specified" : "SGD $\(applicant.expectedSalary)"),
            ("Last Drawn Salary", applicant.lastDrawnSalary.isEmpty ? "Not specified" : "SGD $\(applicant.lastDrawnSalary)"),
            ("Shifts", applicant.willingToWorkShifts.rawValue),
            ("Travel", applicant.willingToTravel.rawValue),
            ("Own Transport", applicant.hasOwnTransport ? "Yes" : "No"),
            ("Source", applicant.howDidYouHear.rawValue)
        ]
    }
}
