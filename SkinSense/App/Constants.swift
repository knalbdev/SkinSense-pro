//
//  Constants.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

enum Constants {
    // Gemini API — ⚠️ pindahkan ke Config.plist sebelum push ke repo publik
    static let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-latest:generateContent"
    static let geminiAPIKey   = "AQ.Ab8RN6IPaiEDpordEFA5HdYokDbfazrsP1vmLvoNdfF65zaUbw"

    // Model
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
