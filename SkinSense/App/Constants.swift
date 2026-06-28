//
//  Constants.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

enum Constants {
    // AI API — OpenAI-compatible endpoint
    static let aiEndpoint  = "https://openrouter.ai/api/v1/chat/completions"
    static let aiModelName = "google/gemini-3.5-flash"
    static let aiAPIKey    = "YOUR_API_KEY" // Ganti dengan API key kamu

    // Core ML Model
    static let modelName      = "SkinDisease"
    static let modelExtension = "mlpackage"

    // Label → nama Indonesia
    static let diseaseNames: [String: String] = [
        "Acne":               "Jerawat",
        "Eczema":             "Eksim",
        "Infestations_Bites": "Gigitan / Infestasi",
        "Lupus":              "Lupus Kulit",
        "Moles":              "Tahi Lalat",
        "Rosacea":            "Rosacea",
        "Vitiligo":           "Vitiligo"
    ]
}
