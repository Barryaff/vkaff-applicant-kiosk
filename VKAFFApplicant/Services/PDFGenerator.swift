import UIKit

class PDFGenerator {

    // MARK: - Colors
    private let purpleColor = UIColor(red: 70/255, green: 46/255, blue: 140/255, alpha: 1)
    private let orangeColor = UIColor(red: 214/255, green: 76/255, blue: 1/255, alpha: 1)
    private let grayColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
    private let darkColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)

    // MARK: - Page Constants
    private let pageWidth: CGFloat = 595.2  // A4
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 50
    private let contentWidth: CGFloat = 495.2

    func generate(from applicant: ApplicantData) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            var yPosition: CGFloat = 0

            // MARK: - Page 1
            context.beginPage()
            yPosition = drawHeader(in: context.cgContext)
            yPosition = drawTitle(at: yPosition, referenceNumber: applicant.referenceNumber)
            yPosition = drawSectionHeader("Personal Details", at: yPosition)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy"

            let personalFields: [(String, String)] = [
                ("Full Name", applicant.fullName),
                ("Preferred Name", applicant.preferredName),
                ("NRIC / FIN", applicant.nricFIN),
                ("Date of Birth", dateFormatter.string(from: applicant.dateOfBirth)),
                ("Gender", applicant.gender.rawValue),
                ("Nationality", applicant.nationality.rawValue),
                ("Race", applicant.race == .others ? applicant.raceOther : applicant.race.rawValue),
                ("Contact Number", applicant.contactNumber),
                ("Email", applicant.emailAddress),
                ("Address", applicant.residentialAddress),
                ("Postal Code", applicant.postalCode),
                ("Emergency Contact", "\(applicant.emergencyContactName) (\(applicant.emergencyContactRelationship.rawValue))"),
                ("Emergency Phone", applicant.emergencyContactNumber)
            ]

            for (label, value) in personalFields {
                if yPosition > pageHeight - 80 {
                    drawFooter(in: context.cgContext, pageNumber: 1)
                    context.beginPage()
                    yPosition = drawHeader(in: context.cgContext)
                }
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // Education
            yPosition += 10
            if yPosition > pageHeight - 120 {
                drawFooter(in: context.cgContext, pageNumber: 1)
                context.beginPage()
                yPosition = drawHeader(in: context.cgContext)
            }
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
                if yPosition > pageHeight - 80 {
                    drawFooter(in: context.cgContext, pageNumber: 1)
                    context.beginPage()
                    yPosition = drawHeader(in: context.cgContext)
                }
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // Work Experience
            yPosition += 10
            if yPosition > pageHeight - 120 {
                drawFooter(in: context.cgContext, pageNumber: 1)
                context.beginPage()
                yPosition = drawHeader(in: context.cgContext)
            }
            yPosition = drawSectionHeader("Work Experience", at: yPosition)
            yPosition = drawField(label: "Total Experience", value: applicant.totalExperience.rawValue, at: yPosition)
            yPosition = drawField(label: "Currently Employed", value: applicant.isCurrentlyEmployed ? "Yes (Notice: \(applicant.noticePeriod.rawValue))" : "No", at: yPosition)

            for (index, record) in applicant.employmentHistory.enumerated() {
                if yPosition > pageHeight - 120 {
                    drawFooter(in: context.cgContext, pageNumber: 1)
                    context.beginPage()
                    yPosition = drawHeader(in: context.cgContext)
                }
                yPosition += 8
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMM yyyy"
                let period = record.isCurrentPosition
                    ? "\(monthFormatter.string(from: record.fromDate)) - Present"
                    : "\(monthFormatter.string(from: record.fromDate)) - \(monthFormatter.string(from: record.toDate))"

                yPosition = drawField(label: "Employer \(index + 1)", value: "\(record.companyName) | \(record.jobTitle)", at: yPosition)
                yPosition = drawField(label: "Industry", value: record.industry.rawValue, at: yPosition)
                yPosition = drawField(label: "Period", value: period, at: yPosition)
                yPosition = drawField(label: "Reason for Leaving", value: record.reasonForLeaving.rawValue, at: yPosition)
            }

            // Position & Availability
            yPosition += 10
            if yPosition > pageHeight - 120 {
                drawFooter(in: context.cgContext, pageNumber: 1)
                context.beginPage()
                yPosition = drawHeader(in: context.cgContext)
            }
            yPosition = drawSectionHeader("Position & Availability", at: yPosition)

            let positions = applicant.positionsAppliedFor.map(\.rawValue).joined(separator: ", ")
            let positionFields: [(String, String)] = [
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

            for (label, value) in positionFields {
                if yPosition > pageHeight - 80 {
                    drawFooter(in: context.cgContext, pageNumber: 1)
                    context.beginPage()
                    yPosition = drawHeader(in: context.cgContext)
                }
                yPosition = drawField(label: label, value: value, at: yPosition)
            }

            // Signature
            yPosition += 20
            if yPosition > pageHeight - 180 {
                drawFooter(in: context.cgContext, pageNumber: 1)
                context.beginPage()
                yPosition = drawHeader(in: context.cgContext)
            }
            yPosition = drawSectionHeader("Declaration & Signature", at: yPosition)

            // Draw signature image
            if let sigData = applicant.signatureData, let sigImage = UIImage(data: sigData) {
                let sigRect = CGRect(x: margin, y: yPosition, width: 300, height: 100)

                // Purple border
                context.cgContext.setStrokeColor(purpleColor.cgColor)
                context.cgContext.setLineWidth(1)
                context.cgContext.stroke(sigRect.insetBy(dx: -4, dy: -4))

                sigImage.draw(in: sigRect)
                yPosition += 116

                let signedDate = dateFormatter.string(from: applicant.submissionDate)
                yPosition = drawField(label: "Date", value: signedDate, at: yPosition)
            }

            yPosition = drawField(label: "Reference", value: applicant.referenceNumber, at: yPosition, valueColor: orangeColor)

            // Footer
            drawFooter(in: context.cgContext, pageNumber: 1)
        }

        return data
    }

    // MARK: - Drawing Helpers

    private func drawHeader(in context: CGContext) -> CGFloat {
        // Orange rule below header area
        context.setFillColor(orangeColor.cgColor)
        context.fill(CGRect(x: margin, y: 70, width: contentWidth, height: 2))
        return 90
    }

    private func drawTitle(at y: CGFloat, referenceNumber: String) -> CGFloat {
        var yPos = y

        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: purpleColor
        ]
        let title = "Walk-In Applicant Registration Form"
        (title as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: titleAttr)
        yPos += 24

        let subtitleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: grayColor
        ]
        ("Advanced Flavors & Fragrances Pte. Ltd." as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: subtitleAttr)

        // Reference number right-aligned
        let refAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: orangeColor
        ]
        let refStr = referenceNumber as NSString
        let refSize = refStr.size(withAttributes: refAttr)
        refStr.draw(at: CGPoint(x: pageWidth - margin - refSize.width, y: yPos), withAttributes: refAttr)
        yPos += 30

        return yPos
    }

    private func drawSectionHeader(_ title: String, at y: CGFloat) -> CGFloat {
        var yPos = y + 8

        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: purpleColor
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: attr)
        yPos += 20

        // Orange underline
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(orangeColor.cgColor)
        ctx?.fill(CGRect(x: margin, y: yPos, width: 40, height: 1.5))
        yPos += 12

        return yPos
    }

    private func drawField(label: String, value: String, at y: CGFloat, valueColor: UIColor? = nil) -> CGFloat {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: grayColor
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: valueColor ?? darkColor
        ]

        var yPos = y

        (label as NSString).draw(at: CGPoint(x: margin, y: yPos), withAttributes: labelAttr)

        // Value with text wrapping
        let valueRect = CGRect(x: margin + 140, y: yPos, width: contentWidth - 140, height: 60)
        let displayValue = value.isEmpty ? "-" : value
        (displayValue as NSString).draw(with: valueRect, options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)

        let valueSize = (displayValue as NSString).boundingRect(with: CGSize(width: contentWidth - 140, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: valueAttr, context: nil)
        yPos += max(18, valueSize.height + 6)

        return yPos
    }

    private func drawFooter(in context: CGContext, pageNumber: Int) {
        let footerY = pageHeight - 30
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: grayColor
        ]
        let footer = "This document is auto-generated by the VKAFF Applicant Registration System. Confidential."
        let footerSize = (footer as NSString).size(withAttributes: attr)
        let x = (pageWidth - footerSize.width) / 2
        (footer as NSString).draw(at: CGPoint(x: x, y: footerY), withAttributes: attr)
    }
}
