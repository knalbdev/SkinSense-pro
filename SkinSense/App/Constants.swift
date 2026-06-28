//
//  Constants.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

enum Constants {
    // Gemini API — ⚠️ pindahkan ke Config.plist sebelum push ke repo publik

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
