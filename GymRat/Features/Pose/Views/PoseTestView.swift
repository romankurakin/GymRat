import PhotosUI
import SwiftUI

struct PoseTestView: View {
    @State var viewModel: PoseTestViewModel
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay {
                            PoseSkeletonOverlay(landmarks: viewModel.landmarks)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ContentUnavailableView("pose_choose_photo", systemImage: "figure.stand",
                                           description: Text("pose_photo_hint"))
                }

                if viewModel.isBusy { ProgressView() }
                Text(LocalizedStringKey(viewModel.messageKey))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("poseStatus")

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("pose_choose_photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("posePhotoPicker")
                .disabled(viewModel.isBusy)

                Button("pose_try_sample") {
                    Task { await viewModel.loadSample() }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("poseSampleButton")
                .disabled(viewModel.isBusy)

                Text("pose_privacy_note")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("pose_title")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            await viewModel.load { try await selectedPhoto.loadTransferable(type: Data.self) }
        }
    }
}

struct PoseSkeletonOverlay: View {
    let landmarks: [PoseLandmark]

    // MediaPipe's 33-landmark topology (left and right refer to the person).
    private static let connections: [(Int, Int)] = [
        (0,1), (1,2), (2,3), (3,7), (0,4), (4,5), (5,6), (6,8), (9,10),
        (11,12), (11,13), (13,15), (15,17), (15,19), (15,21), (17,19),
        (12,14), (14,16), (16,18), (16,20), (16,22), (18,20),
        (11,23), (12,24), (23,24), (23,25), (24,26), (25,27), (26,28),
        (27,29), (28,30), (29,31), (30,32), (27,31), (28,32)
    ]

    var body: some View {
        Canvas { context, size in
            func point(_ index: Int) -> CGPoint {
                CGPoint(x: CGFloat(landmarks[index].x) * size.width,
                        y: CGFloat(landmarks[index].y) * size.height)
            }
            guard landmarks.count == 33,
                  landmarks.allSatisfy({ $0.x.isFinite && $0.y.isFinite }) else { return }
            var lines = Path()
            for (start, end) in Self.connections {
                lines.move(to: point(start))
                lines.addLine(to: point(end))
            }
            context.stroke(lines, with: .color(.black.opacity(0.65)), lineWidth: 5)
            context.stroke(lines, with: .color(.cyan), lineWidth: 2.5)
            for index in landmarks.indices {
                let p = point(index)
                let circle = Path(ellipseIn: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7))
                context.fill(circle, with: .color(.yellow))
                context.stroke(circle, with: .color(.black), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(Text("pose_skeleton"))
        .accessibilityValue(Text(verbatim: "\(landmarks.count)"))
        .accessibilityIdentifier("poseSkeletonOverlay")
    }
}
