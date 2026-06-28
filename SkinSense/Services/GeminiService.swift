//
//  GeminiService.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

enum AIError: LocalizedError {
    case invalidURL
    case encodingFailed
    case httpError(Int)
    case emptyResponse
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "URL AI tidak valid"
        case .encodingFailed:         return "Gagal encode request"
        case .httpError(let code):    return "HTTP Error \(code) dari server AI"
        case .emptyResponse:          return "Server AI tidak memberikan respons"
        case .decodingFailed(let msg): return "Gagal membaca respons: \(msg)"
        }
    }
}

final class AIService {

    func fetchExplanation(for condition: SkinCondition) async throws -> AIExplanation {
        guard let url = URL(string: Constants.aiEndpoint) else {
            throw AIError.invalidURL
        }

        let body = ChatRequest(
            model: Constants.aiModelName,
            messages: [
                .init(role: "system", content: "Kamu adalah dokter spesialis kulit yang ramah dan edukatif. Kembalikan HANYA JSON valid tanpa markdown, tanpa teks lain."),
                .init(role: "user", content: buildPrompt(condition))
            ],
            temperature: 0.7,
            maxTokens: 4096
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Constants.aiAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        guard let bodyData = try? JSONEncoder().encode(body) else {
            throw AIError.encodingFailed
        }
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw AIError.httpError(http.statusCode)
        }

        let chatResp = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard let rawText = chatResp.firstContent else {
            throw AIError.emptyResponse
        }

        // Bersihkan markdown code block jika ada
        let cleaned = rawText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AIError.emptyResponse
        }

        do {
            let payload = try JSONDecoder().decode(ExplanationPayload.self, from: jsonData)
            return AIExplanation(
                overview: payload.overview,
                symptoms: payload.symptoms,
                recommendations: payload.recommendations,
                medicines: payload.medicines
            )
        } catch {
            throw AIError.decodingFailed(error.localizedDescription)
        }
    }

    private func buildPrompt(_ condition: SkinCondition) -> String {
        let needsMeds = condition.treatmentLevel == .selfMedication
        let medsJSON = needsMeds ? """
        [{"name":"Nama obat","type":"Obat Oles/Obat Minum","dosage":"dosis","how_to_use":"cara pakai"}]
        """ : "[]"

        return """
        Kamu adalah dokter spesialis kulit yang ramah dan edukatif. \
        Pasien terdeteksi mengidap \(condition.localizedName) (\(condition.modelLabel)) \
        dengan keyakinan \(condition.confidencePercentage). \
        Level penanganan: \(condition.treatmentLevel.rawValue).

        Buatkan penjelasan yang mudah dipahami masyarakat awam dalam Bahasa Indonesia. \
        Kembalikan HANYA JSON valid dengan format ini (tanpa markdown):
        {
          "overview": "penjelasan 2-3 paragraf, hangat dan tidak menakutkan",
          "symptoms": ["gejala 1", "gejala 2", "gejala 3", "gejala 4"],
          "recommendations": ["rekomendasi 1", "rekomendasi 2", "rekomendasi 3"],
          "medicines": \(medsJSON)
        }
        """
    }
}
