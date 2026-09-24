import Testing
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import GymRat

struct PoseDetectorTests {
    @Test func samplePhotoReturns33FiniteLandmarks() throws {
        let url = try #require(Bundle.main.url(forResource: "pose_sample", withExtension: "jpg"))
        let image = try #require(UIImage(contentsOfFile: url.path))
        let result = try PoseDetector().detect(in: image)
        #expect(result.count == 33)
        #expect(result.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
        // Regression check for axis swaps: the shoulders should be above the hips.
        #expect(result[11].y < result[23].y)
        #expect(result[12].y < result[24].y)
    }

    @Test func blankImageReturnsNoPerson() throws {
        #expect(try PoseDetector().detect(in: Self.blankImage()).isEmpty)
    }

    @Test func missingModelThrows() {
        #expect(throws: PoseError.self) {
            try PoseDetector(modelURL: nil).detect(in: Self.blankImage())
        }
    }

    @Test func imagePreparationAppliesEXIFRotation() async throws {
        let original = Self.blankImage(size: CGSize(width: 120, height: 80))
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try #require(original.cgImage),
                                  [kCGImagePropertyOrientation: 6] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let worker = PoseAnalysisWorker(detector: PoseDetector())
        let prepared = try await worker.prepare(data as Data)
        #expect(prepared.imageOrientation == .up)
        #expect(prepared.size.width == 80)
        #expect(prepared.size.height == 120)
    }

    @MainActor @Test func emptyAndInvalidPhotoHaveDistinctStates() async throws {
        let model = PoseTestViewModel(detector: EmptyPoseDetector())
        await model.load { Self.blankImage().pngData() }
        #expect(model.messageKey == "pose_not_found")
        #expect(model.image != nil)
        #expect(!model.isBusy)
        await model.load { Data([0, 1, 2]) }
        #expect(model.messageKey == "pose_failed")
        #expect(model.image == nil)
        #expect(model.landmarks.isEmpty)
        #expect(!model.isBusy)
    }

    private static func blankImage(size: CGSize = CGSize(width: 640, height: 480)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

private struct EmptyPoseDetector: PoseDetectorType {
    func detect(in image: UIImage) throws -> [PoseLandmark] { [] }
}
