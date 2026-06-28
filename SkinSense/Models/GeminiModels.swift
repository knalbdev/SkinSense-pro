//
//  GeminiModels.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

// MARK: - Request

struct GeminiRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig

    struct Content: Encodable {
        let parts: [Part]
        struct Part: Encodable { let text: String }
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
        let maxOutputTokens: Int
    }
}

// MARK: - Response

struct GeminiResponse: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content
        struct Content: Decodable {
            let parts: [Part]
            struct Part: Decodable { let text: String }
        }
    }

    var firstText: String? { candidates.first?.content.parts.first?.text }
}

// MARK: - Parsed explanation payload

struct ExplanationPayload: Decodable {
    let overview: String
    let symptoms: [String]
    let recommendations: [String]
    let medicines: [Medicine]
}
