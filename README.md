# VKAFF Walk-In Applicant Registration

iPad kiosk app for walk-in job applicant registration at Advanced Flavors & Fragrances (VKAFF), Singapore.

## Requirements

- iOS 17+
- iPad Air 13-inch (optimized, works on all iPads)
- Xcode 15+
- Swift 5.9+

## Setup

1. Clone the repo
2. Open `VKAFFApplicant.xcodeproj` in Xcode
3. Add logo assets to `Resources/Assets.xcassets/`:
   - `vka_logo_purple` - VKA wordmark in purple
   - `vka_logo_white` - VKA wordmark in white (for dark backgrounds)
   - `aff_logo_orange` - AFF mark in orange
4. Configure credentials:
   - Replace `VKAFFApplicant/Resources/service-account-key.json` with your Google Cloud service account key
   - Update `Config/GoogleDriveConfig.swift` with your Drive folder ID
   - Update `Config/SlackConfig.swift` with your Slack webhook URL
5. Build and run on iPad

## Architecture

- **SwiftUI** - Primary UI framework
- **UIKit** - Signature canvas (PencilKit), PDF generation
- **Zero third-party dependencies** - All networking via URLSession, PDF via UIGraphicsPDFRenderer

## Integrations

- **Google Drive** - Uploads branded PDF + JSON per applicant
- **Slack** - Sends notification with applicant summary via webhook
- **Offline backup** - Encrypted local storage with admin retry panel

## Kiosk Mode

Deploy with Guided Access or Single App Mode for unattended kiosk use. The app handles idle timeout (90s warning, 120s auto-reset) and clears all data from memory after each submission.
