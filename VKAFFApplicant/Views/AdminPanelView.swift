import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var pendingReferences: [String] = []
    @State private var isRetrying = false
    @State private var statusMessage = ""

    private let backupService = EncryptedBackupService()
    private let driveService = GoogleDriveService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Admin Panel")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.darkText)

                Spacer()

                Button("Back to Welcome") {
                    vm.resetToWelcome()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(24)
            .background(Color.white)

            Divider()

            if pendingReferences.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.successGreen)
                    Text("No pending uploads")
                        .font(.system(size: 18))
                        .foregroundColor(.mediumGray)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(pendingReferences, id: \.self) { ref in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ref)
                                        .font(.system(size: 16, weight: .medium).monospacedDigit())
                                        .foregroundColor(.darkText)
                                    Text("Pending upload")
                                        .font(.system(size: 13))
                                        .foregroundColor(.mediumGray)
                                }
                                Spacer()
                                Image(systemName: "clock")
                                    .foregroundColor(.affOrange)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.lightBackground)
                            )
                        }
                    }
                    .padding(24)
                }

                HStack(spacing: 16) {
                    Button {
                        retryAll()
                    } label: {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Retry All")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isRetrying)

                    Button("Export to Files") {
                        exportAll()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(24)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.mediumGray)
                    .padding(.bottom, 16)
            }
        }
        .background(Color.lightBackground)
        .onAppear {
            pendingReferences = backupService.getPendingReferences()
        }
    }

    private func retryAll() {
        isRetrying = true
        statusMessage = "Retrying uploads..."

        Task {
            for ref in pendingReferences {
                if let data = backupService.getPendingData(for: ref) {
                    do {
                        try await driveService.uploadFile(
                            data: data.pdf,
                            fileName: "\(ref).pdf",
                            mimeType: "application/pdf"
                        )
                        try await driveService.uploadFile(
                            data: data.json,
                            fileName: "\(ref).json",
                            mimeType: "application/json"
                        )
                        backupService.removeBackup(for: ref)
                    } catch {
                        // Continue with next
                    }
                }
            }

            await MainActor.run {
                pendingReferences = backupService.getPendingReferences()
                isRetrying = false
                statusMessage = pendingReferences.isEmpty ? "All uploads complete!" : "Some uploads still pending."
            }
        }
    }

    private func exportAll() {
        if let exportURL = backupService.exportAll() {
            statusMessage = "Exported to: \(exportURL.path)"
        }
    }
}
