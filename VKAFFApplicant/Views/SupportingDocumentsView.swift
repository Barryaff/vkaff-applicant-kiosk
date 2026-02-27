import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct SupportingDocumentsView: View {
    @EnvironmentObject var vm: RegistrationViewModel
    @State private var showingSourcePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var canAddMore: Bool {
        vm.supportingDocuments.count < AppConfig.maxSupportingDocuments
    }

    var body: some View {
        FormScreenLayout(
            title: "Supporting Documents",
            stepIndex: 4,
            onBack: { vm.navigateBack() },
            onContinue: { vm.navigateForward() }
        ) {
            Text("Upload any relevant documents to support your application (optional).")
                .font(.system(size: 16))
                .foregroundColor(.mediumGray)
                .lineSpacing(4)

            Text("Accepted formats: PDF, JPEG, PNG — max \(AppConfig.maxDocumentSizeMB)MB per file")
                .font(.system(size: 14))
                .foregroundColor(.mediumGray.opacity(0.7))
                .padding(.bottom, 8)

            // Document cards
            ForEach($vm.supportingDocuments) { $doc in
                DocumentCard(
                    document: $doc,
                    onRemove: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.supportingDocuments.removeAll { $0.id == doc.id }
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95, anchor: .top)
                        .combined(with: .opacity),
                    removal: .scale(scale: 0.95, anchor: .top)
                        .combined(with: .opacity)
                ))
            }

            // Add document button
            if canAddMore {
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    showingSourcePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Document")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.vkaPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                            .foregroundColor(.vkaPurple.opacity(0.4))
                    )
                }
                .accessibilityLabel("Add Document")
                .accessibilityHint("Opens document source picker. \(vm.supportingDocuments.count) of \(AppConfig.maxSupportingDocuments) documents added.")
            } else {
                Text("Maximum \(AppConfig.maxSupportingDocuments) documents reached.")
                    .font(.system(size: 14))
                    .foregroundColor(.mediumGray)
                    .padding(.top, 4)
            }

            if vm.supportingDocuments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.mediumGray.opacity(0.4))
                    Text("No documents attached yet")
                        .font(.system(size: 15))
                        .foregroundColor(.mediumGray.opacity(0.6))
                    Text("You can proceed without uploading documents")
                        .font(.system(size: 13))
                        .foregroundColor(.mediumGray.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .accessibilityElement(children: .combine)
            }
        }
        .confirmationDialog("Add Document", isPresented: $showingSourcePicker, titleVisibility: .visible) {
            Button("Choose from Photos") {
                showingPhotoPicker = true
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    showingCamera = true
                }
            }
            Button("Choose File") {
                showingFilePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                await loadPhoto(from: item)
                selectedPhotoItem = nil
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                addImageDocument(image: image, fileName: "Photo_\(dateStamp()).jpg")
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentFilePicker { url in
                loadFile(from: url)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
                .foregroundColor(.affOrange)
            }
        }
    }

    // MARK: - Photo Loading

    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let image = UIImage(data: data) else { return }

        // Compress to JPEG to keep file size manageable
        let maxSize = AppConfig.maxDocumentSizeMB * 1024 * 1024
        var quality: CGFloat = 0.8
        var jpegData = image.jpegData(compressionQuality: quality) ?? data

        while jpegData.count > maxSize && quality > 0.1 {
            quality -= 0.1
            jpegData = image.jpegData(compressionQuality: quality) ?? jpegData
        }

        guard jpegData.count <= maxSize else { return }

        let fileName = "Photo_\(dateStamp()).jpg"
        let thumbnail = generateThumbnail(from: image)

        let doc = SupportingDocument(
            documentType: .others,
            fileName: fileName,
            fileData: jpegData,
            mimeType: "image/jpeg",
            thumbnailData: thumbnail
        )

        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                vm.supportingDocuments.append(doc)
            }
        }
    }

    private func addImageDocument(image: UIImage, fileName: String) {
        let maxSize = AppConfig.maxDocumentSizeMB * 1024 * 1024
        var quality: CGFloat = 0.8
        var jpegData = image.jpegData(compressionQuality: quality) ?? Data()

        while jpegData.count > maxSize && quality > 0.1 {
            quality -= 0.1
            jpegData = image.jpegData(compressionQuality: quality) ?? jpegData
        }

        guard jpegData.count <= maxSize else { return }

        let thumbnail = generateThumbnail(from: image)

        let doc = SupportingDocument(
            documentType: .others,
            fileName: fileName,
            fileData: jpegData,
            mimeType: "image/jpeg",
            thumbnailData: thumbnail
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            vm.supportingDocuments.append(doc)
        }
    }

    // MARK: - File Loading

    private func loadFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else { return }

        let maxSize = AppConfig.maxDocumentSizeMB * 1024 * 1024
        guard data.count <= maxSize else { return }

        let fileName = url.lastPathComponent
        let mimeType = mimeTypeFor(url: url)
        var thumbnail: Data?

        if mimeType.starts(with: "image/"), let image = UIImage(data: data) {
            thumbnail = generateThumbnail(from: image)
        }

        let doc = SupportingDocument(
            documentType: guessDocumentType(from: fileName),
            fileName: fileName,
            fileData: data,
            mimeType: mimeType,
            thumbnailData: thumbnail
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            vm.supportingDocuments.append(doc)
        }
    }

    // MARK: - Helpers

    private func generateThumbnail(from image: UIImage) -> Data? {
        let maxDimension: CGFloat = 120
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 2.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail?.jpegData(compressionQuality: 0.6)
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: Date())
    }

    private func mimeTypeFor(url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }

    private func guessDocumentType(from fileName: String) -> DocumentType {
        let lower = fileName.lowercased()
        if lower.contains("resume") || lower.contains("cv") {
            return .resume
        } else if lower.contains("cert") || lower.contains("license") || lower.contains("licence") {
            return .certificate
        } else if lower.contains("nric") || lower.contains("passport") || lower.contains("id") {
            return .idCopy
        } else if lower.contains("diploma") || lower.contains("degree") || lower.contains("transcript") {
            return .educationRecord
        }
        return .others
    }
}

// MARK: - Document Card

struct DocumentCard: View {
    @Binding var document: SupportingDocument
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail or icon
            Group {
                if let thumbData = document.thumbnailData, let image = UIImage(data: thumbData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.lightBackground)
                        Image(systemName: iconForMimeType(document.mimeType))
                            .font(.system(size: 22))
                            .foregroundColor(.vkaPurple)
                    }
                    .frame(width: 56, height: 56)
                }
            }
            .accessibilityHidden(true)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(document.fileName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.darkText)
                    .lineLimit(1)

                // Document type picker
                Menu {
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        Button(type.rawValue) {
                            document.documentType = type
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(document.documentType.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.vkaPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.purpleLight.opacity(0.3))
                    )
                }
                .accessibilityLabel("Document type: \(document.documentType.rawValue)")
                .accessibilityHint("Tap to change document type")

                Text(document.fileSizeFormatted)
                    .font(.system(size: 12))
                    .foregroundColor(.mediumGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mediumGray)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Remove \(document.fileName)")
            .accessibilityHint("Double tap to remove this document")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purpleLight)
                    .frame(width: 4)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dividerSubtle, lineWidth: 1)
        )
    }

    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType == "application/pdf" { return "doc.fill" }
        if mimeType.starts(with: "image/") { return "photo" }
        return "doc"
    }
}

// MARK: - Camera Capture

struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - File Picker

struct DocumentFilePicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.pdf, .jpeg, .png, .heic]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let dismiss: DismissAction

        init(onPick: @escaping (URL) -> Void, dismiss: DismissAction) {
            self.onPick = onPick
            self.dismiss = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismiss()
        }
    }
}
