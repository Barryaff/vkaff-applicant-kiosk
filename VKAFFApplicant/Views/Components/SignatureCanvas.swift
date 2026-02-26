import SwiftUI
import PencilKit

struct SignatureCanvas: UIViewRepresentable {
    @Binding var signatureData: Data?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .white
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1), width: 3)
        canvas.delegate = context.coordinator

        // Purple border
        canvas.layer.borderWidth = 2
        canvas.layer.borderColor = UIColor(red: 70/255, green: 46/255, blue: 140/255, alpha: 1).cgColor
        canvas.layer.cornerRadius = 8

        // Inner shadow effect
        canvas.layer.shadowColor = UIColor.black.cgColor
        canvas.layer.shadowOffset = CGSize(width: 0, height: 1)
        canvas.layer.shadowOpacity = 0.05
        canvas.layer.shadowRadius = 4

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(signatureData: $signatureData)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var signatureData: Data?

        init(signatureData: Binding<Data?>) {
            _signatureData = signatureData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let image = canvasView.drawing.image(from: canvasView.bounds, scale: 2.0)
            signatureData = image.pngData()
        }
    }
}

struct SignatureField: View {
    @Binding var signatureData: Data?
    @State private var canvasKey = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Applicant's Signature")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.vkaPurple)
                .accessibilityAddTraits(.isHeader)

            SignatureCanvas(signatureData: $signatureData)
                .id(canvasKey)
                .frame(height: 200)
                .frame(maxWidth: 600)
                .accessibilityLabel("Signature canvas. Draw your signature here")
                .accessibilityAddTraits(.allowsDirectInteraction)
                .accessibilityValue(signatureData != nil ? "Signature provided" : "No signature yet")
                .accessibilityHint("Use your finger or Apple Pencil to draw your signature")

            HStack {
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    signatureData = nil
                    canvasKey = UUID()
                } label: {
                    Text("Clear Signature")
                        .font(.system(size: 14))
                        .foregroundColor(.mediumGray)
                        .underline()
                }
                .accessibilityLabel("Clear Signature")
                .accessibilityHint("Removes your drawn signature so you can start over")

                Spacer()

                let formatter = DateFormatter()
                Text({
                    let f = DateFormatter()
                    f.dateFormat = "dd MMM yyyy"
                    return f.string(from: Date())
                }())
                .font(.system(size: 14))
                .foregroundColor(.mediumGray)
                .accessibilityLabel("Today's date: \({ let f = DateFormatter(); f.dateStyle = .long; return f.string(from: Date()) }())")
            }
            .frame(maxWidth: 600)
        }
    }
}
