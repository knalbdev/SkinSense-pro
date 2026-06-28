//
//  ResultViewModel.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

@Observable
final class ResultViewModel {
    var explanation: AIExplanation?
    var isLoading = false
    var errorMessage: String?

    private let ai = AIService()

    func fetchExplanation(for condition: SkinCondition, sessionID: UUID) async {
        guard explanation == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            let exp = try await ai.fetchExplanation(for: condition)
            explanation = exp
            await ScanHistoryStore.shared.updateExplanation(for: sessionID, with: exp)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func retry(condition: SkinCondition, sessionID: UUID) async {
        explanation = nil
        errorMessage = nil
        await fetchExplanation(for: condition, sessionID: sessionID)
    }
}
