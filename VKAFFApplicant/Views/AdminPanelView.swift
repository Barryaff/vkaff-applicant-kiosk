import SwiftUI
import Network

struct AdminPanelView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var pendingReferences: [String] = []
    @State private var backupMetadata: [String: BackupMetadata] = [:]
    @State private var isRetrying = false
    @State private var retryingReference: String? = nil
    @State private var statusMessage = ""
    @State private var showClearAllConfirmation = false
    @State private var lastSuccessfulUpload: Date? = nil
    @State private var isOnline = true

    @StateObject private var networkMonitor = NetworkMonitor()

    private let backupService = EncryptedBackupService()
    private let driveService = GoogleDriveService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Network status bar
            networkStatusBar

            if pendingReferences.isEmpty {
                emptyStateView
            } else {
                pendingListView
                actionButtonsSection
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.mediumGray)
                    .padding(.bottom, 8)
            }

            Divider()

            // Footer with app info
            footerSection
        }
        .background(Color.lightBackground)
        .onAppear {
            loadPendingData()
            loadLastSuccessfulUpload()
            isOnline = networkMonitor.isConnected
            // Pause idle timer while admin panel is active
            vm.pauseIdleTimer()
        }
        .onDisappear {
            // Resume idle timer when leaving admin panel
            vm.resumeIdleTimer()
        }
        .onChange(of: networkMonitor.isConnected) { newValue in
            isOnline = newValue
        }
        .alert("Clear All Pending Uploads", isPresented: $showClearAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllBackups()
            }
        } message: {
            Text("This will permanently delete \(pendingReferences.count) pending upload(s). This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 12) {
                Text("Admin Panel")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.darkText)

                if !pendingReferences.isEmpty {
                    Text("\(pendingReferences.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.affOrange)
                        )
                }
            }

            Spacer()

            Button("Back to Welcome") {
                vm.resetToWelcome()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .background(Color.white)
    }

    // MARK: - Network Status Bar

    private var networkStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isOnline ? Color.successGreen : Color.errorRed)
                .frame(width: 10, height: 10)

            Text(isOnline ? "Online" : "Offline")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isOnline ? .successGreen : .errorRed)

            Spacer()

            if let lastUpload = lastSuccessfulUpload {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.successGreen)
                    Text("Last upload: \(formattedDate(lastUpload))")
                        .font(.system(size: 12))
                        .foregroundColor(.mediumGray)
                }
            }

            if !pendingReferences.isEmpty {
                Text(backupService.formattedTotalPendingSize())
                    .font(.system(size: 12))
                    .foregroundColor(.mediumGray)
                    .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.7))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
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
    }

    // MARK: - Pending List

    private var pendingListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(pendingReferences, id: \.self) { ref in
                    pendingItemCard(for: ref)
                }
            }
            .padding(24)
        }
    }

    private func pendingItemCard(for ref: String) -> some View {
        let metadata = backupMetadata[ref]
        let isRetryingThis = retryingReference == ref

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ref)
                    .font(.system(size: 16, weight: .medium).monospacedDigit())
                    .foregroundColor(.darkText)

                if let meta = metadata {
                    Text(meta.applicantName)
                        .font(.system(size: 14))
                        .foregroundColor(.mediumGray)

                    HStack(spacing: 12) {
                        Text(formattedDate(meta.creationDate))
                            .font(.system(size: 12))
                            .foregroundColor(.mediumGray)

                        Text(formattedFileSize(meta.totalSize))
                            .font(.system(size: 12))
                            .foregroundColor(.mediumGray)
                    }
                } else {
                    Text("Pending upload")
                        .font(.system(size: 13))
                        .foregroundColor(.mediumGray)
                }
            }

            Spacer()

            // Individual retry button
            Button {
                retrySingle(ref)
            } label: {
                if isRetryingThis {
                    ProgressView()
                        .tint(.affOrange)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.affOrange)
                }
            }
            .disabled(isRetrying)

            Image(systemName: "clock")
                .foregroundColor(.affOrange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dividerSubtle, lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button {
                retryAll()
            } label: {
                HStack {
                    if isRetrying && retryingReference == nil {
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

            Button("Clear All") {
                showClearAllConfirmation = true
            }
            .buttonStyle(DestructiveButtonStyle())
            .disabled(isRetrying)
        }
        .padding(24)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("VKAFF Kiosk v\(AppConfig.appVersion)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.mediumGray)
                Text(deviceInfo())
                    .font(.system(size: 11))
                    .foregroundColor(.mediumGray.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.5))
    }

    // MARK: - Actions

    private func loadPendingData() {
        pendingReferences = backupService.getPendingReferences()
        backupMetadata.removeAll()
        for ref in pendingReferences {
            if let meta = backupService.getBackupMetadata(for: ref) {
                backupMetadata[ref] = meta
            }
        }
    }

    private func loadLastSuccessfulUpload() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSuccessfulUploadTimestamp") as? Date {
            lastSuccessfulUpload = timestamp
        }
    }

    private func saveLastSuccessfulUpload() {
        lastSuccessfulUpload = Date()
        UserDefaults.standard.set(lastSuccessfulUpload, forKey: "lastSuccessfulUploadTimestamp")
    }

    private func retrySingle(_ ref: String) {
        guard !isRetrying else { return }
        isRetrying = true
        retryingReference = ref
        statusMessage = "Retrying \(ref)..."

        Task {
            var success = false
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
                    success = true
                } catch {
                    // Upload failed
                }
            }

            await MainActor.run {
                if success {
                    saveLastSuccessfulUpload()
                }
                loadPendingData()
                isRetrying = false
                retryingReference = nil
                statusMessage = success ? "Upload complete for \(ref)." : "Upload failed for \(ref)."
            }
        }
    }

    private func retryAll() {
        isRetrying = true
        retryingReference = nil
        statusMessage = "Retrying uploads..."

        Task {
            var anySuccess = false
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
                        anySuccess = true
                    } catch {
                        // Continue with next
                    }
                }
            }

            await MainActor.run {
                if anySuccess {
                    saveLastSuccessfulUpload()
                }
                loadPendingData()
                isRetrying = false
                retryingReference = nil
                statusMessage = pendingReferences.isEmpty ? "All uploads complete!" : "Some uploads still pending."
            }
        }
    }

    private func clearAllBackups() {
        let count = backupService.removeAllBackups()
        loadPendingData()
        statusMessage = "Cleared \(count) pending upload(s)."
    }

    private func exportAll() {
        if let exportURL = backupService.exportAll() {
            statusMessage = "Exported to: \(exportURL.path)"
        }
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }

    private func formattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func deviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.name) - \(device.systemName) \(device.systemVersion)"
    }
}

// MARK: - Network Monitor

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.vkaff.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
