//
//  GeminiService.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

enum GeminiError: LocalizedError {
    case invalidURL
    case encodingFailed
    case httpError(Int)
    case emptyResponse
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "URL Gemini tidak valid"
        case .encodingFailed:         return "Gagal encode request"
        case .httpError(let code):    return "HTTP Error \(code) dari Gemini"
        case .emptyResponse:          return "Gemini tidak memberikan respons"
        case .decodingFailed(let msg): return "Gagal membaca respons: \(msg)"
        }
    }
}

final class GeminiService {

    func fetchExplanation(for condition: SkinCondition) async throws -> AIExplanation {
        guard let url = URL(string: Constants.geminiEndpoint) else {
            throw GeminiError.invalidURL
        }

        let body = GeminiRequest(
            contents: [.init(parts: [.init(text: buildPrompt(condition))])],
            generationConfig: .init(temperature: 0.7, maxOutputTokens: 1024)
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.geminiAPIKey, forHTTPHeaderField: "X-goog-api-key")
        request.timeoutInterval = 30

        guard let bodyData = try? JSONEncoder().encode(body) else {
            throw GeminiError.encodingFailed
        }
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw GeminiError.httpError(http.statusCode)
        }

        let geminiResp = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let rawText = geminiResp.firstText else {
            throw GeminiError.emptyResponse
        }

        // Bersihkan markdown code block jika ada
        let cleaned = rawText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw GeminiError.emptyResponse
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
            throw GeminiError.decodingFailed(error.localizedDescription)
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
