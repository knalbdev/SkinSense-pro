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

    func fetchExplanation(for condition: SkinCondition) async {
        guard explanation == nil else { return } // sudah ada, skip

        isLoading = true
        errorMessage = nil

        do {
            explanation = try await ai.fetchExplanation(for: condition)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func retry(condition: SkinCondition) async {
        explanation = nil
        errorMessage = nil
        await fetchExplanation(for: condition)
    }
}
