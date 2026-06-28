//
//  ScanViewModel.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation
import UIKit

@Observable
final class ScanViewModel {
    var selectedImage: UIImage?
    var conditions: [SkinCondition] = []
    var isClassifying = false
    var classifyError: String?

    // Untuk navigasi ke ResultView
    var currentSession: ScanSession?
    var showResult = false

    private let classifier = SkinClassifierService()

    func classify() async {
        guard let image = selectedImage else { return }

        isClassifying = true
        classifyError = nil
        conditions = []

        do {
            let results = try await classifier.classify(image: image)
            conditions = results

            if let top = results.first {
                let session = ScanSession(
                    condition: top,
                    imageData: image.jpegData(compressionQuality: 0.7),
                    scannedAt: Date()
                )
                await ScanHistoryStore.shared.add(session)
                currentSession = session
                showResult = true
            }
        } catch {
            classifyError = error.localizedDescription
        }

        isClassifying = false
    }

    func reset() {
        selectedImage = nil
        conditions = []
        classifyError = nil
        currentSession = nil
        showResult = false
    }
}
