//
//  GeminiModels.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

// MARK: - OpenAI-compatible Chat Request

struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

// MARK: - OpenAI-compatible Chat Response

struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String?
        }
    }

    var firstContent: String? { choices.first?.message.content }
}

// MARK: - Parsed explanation payload

struct ExplanationPayload: Decodable {
    let overview: String
    let symptoms: [String]
    let recommendations: [String]
    let medicines: [Medicine]
}
