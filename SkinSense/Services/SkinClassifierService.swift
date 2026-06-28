//
//  SkinClassifierService.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

@preconcurrency import Vision
import CoreML
import UIKit

enum ClassifierError: LocalizedError {
    case modelNotFound
    case modelLoadFailed(Error)
    case classificationFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound:          return "Model tidak ditemukan di bundle"
        case .modelLoadFailed(let e): return "Gagal memuat model: \(e.localizedDescription)"
        case .classificationFailed:   return "Klasifikasi gambar gagal"
        }
    }
}

final class SkinClassifierService {
    private var model: VNCoreMLModel?

    init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly

            // Xcode compile .mlpackage → .mlmodelc di bundle
            guard let modelURL = Bundle.main.url(
                forResource: "SkinDisease",
                withExtension: "mlmodelc"
            ) else {
                print("SkinClassifierService: SkinDisease.mlmodelc tidak ditemukan")
                return
            }

            let coreMLModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: coreMLModel)
            print("SkinClassifierService: model berhasil dimuat ✓")
        } catch {
            print("SkinClassifierService: gagal memuat model — \(error)")
        }
    }

//    private func loadModel() {
//        guard let url = Bundle.main.url(
//            forResource: Constants.modelName,
//            withExtension: Constants.modelExtension
//        ) else {
//            print("SkinClassifierService: \(Constants.modelName).\(Constants.modelExtension) tidak ditemukan di bundle")
//            return
//        }
//
//        do {
//            let config = MLModelConfiguration()
//#if targetEnvironment(simulator)
//            config.computeUnits = .cpuOnly
//#else
//            config.computeUnits = .all
//#endif
//            let coreMLModel = try MLModel(contentsOf: url, configuration: config)
//            model = try VNCoreMLModel(for: coreMLModel)
//            print("SkinClassifierService: model berhasil dimuat ✓")
//        } catch {
//            print("SkinClassifierService: gagal memuat model — \(error)")
//        }
//    }

    // Klasifikasi gambar, kembalikan top-3 hasil
    func classify(image: UIImage) async throws -> [SkinCondition] {
        guard let model = model else {
            throw ClassifierError.modelNotFound
        }

        guard let cgImage = normalized(image) else {
            throw ClassifierError.classificationFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if error != nil {
                    continuation.resume(throwing: ClassifierError.classificationFailed)
                    return
                }
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ClassifierError.classificationFailed)
                    return
                }
                let top3 = observations
                    .sorted { $0.confidence > $1.confidence }
                    .prefix(3)
                    .map { SkinCondition(modelLabel: $0.identifier, confidence: Double($0.confidence)) }
                continuation.resume(returning: Array(top3))
            }

            request.imageCropAndScaleOption = .centerCrop
#if targetEnvironment(simulator)
            request.usesCPUOnly = true
#endif

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ClassifierError.classificationFailed)
                }
            }
        }
    }

    // Normalisasi orientasi gambar sebelum dikirim ke model
    private func normalized(_ image: UIImage) -> CGImage? {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result?.cgImage
    }
}
