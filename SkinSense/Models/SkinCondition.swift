//
//  SkinCondition.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation
import SwiftUI

// MARK: - Treatment Level

enum TreatmentLevel: String {
    case none           = "Tidak Perlu Penanganan"
    case selfMedication = "Penanganan Mandiri"
    case doctor         = "Butuh Dokter"

    var icon: String {
        switch self {
        case .none:           return "checkmark.seal.fill"
        case .selfMedication: return "cross.case.fill"
        case .doctor:         return "stethoscope"
        }
    }

    var color: Color {
        switch self {
        case .none:           return .green
        case .selfMedication: return .orange
        case .doctor:         return .red
        }
    }
}

// MARK: - Skin Condition (hasil klasifikasi model)

struct SkinCondition: Identifiable, Hashable {
    let id = UUID()
    let modelLabel: String
    let confidence: Double

    var localizedName: String {
        Constants.diseaseNames[modelLabel] ?? modelLabel
    }

    var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }

    var treatmentLevel: TreatmentLevel {
        switch modelLabel {
        case "Acne", "Infestations_Bites": return .selfMedication
        case "Moles":                      return .none
        default:                           return .doctor
        }
    }
}

// MARK: - Scan Session (satu sesi scan lengkap)

struct ScanSession: Identifiable {
    let id: UUID
    let condition: SkinCondition
    let imageData: Data?
    let scannedAt: Date
    var aiExplanation: AIExplanation?
    var feedback: Feedback?

    init(id: UUID = UUID(), condition: SkinCondition, imageData: Data?, scannedAt: Date, aiExplanation: AIExplanation? = nil, feedback: Feedback? = nil) {
        self.id = id
        self.condition = condition
        self.imageData = imageData
        self.scannedAt = scannedAt
        self.aiExplanation = aiExplanation
        self.feedback = feedback
    }
}

// MARK: - AI Explanation (hasil dari Gemini)

struct AIExplanation: Identifiable, Codable {
    let id = UUID()
    let overview: String
    let symptoms: [String]
    let recommendations: [String]
    let medicines: [Medicine]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(overview, forKey: .overview)
        try container.encode(symptoms, forKey: .symptoms)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(medicines, forKey: .medicines)
    }

    enum CodingKeys: CodingKey {
        case overview, symptoms, recommendations, medicines
    }
}

// MARK: - Medicine

struct Medicine: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: String
    let dosage: String
    let howToUse: String

    enum CodingKeys: String, CodingKey {
        case name, type, dosage
        case howToUse = "how_to_use"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(dosage, forKey: .dosage)
        try container.encode(howToUse, forKey: .howToUse)
    }
}

// MARK: - Feedback

struct Feedback: Codable, Equatable {
    let id: UUID
    let rating: Int
    let comment: String
    let sentimentScore: Double
    let date: Date

    init(rating: Int, comment: String, sentimentScore: Double, date: Date = Date()) {
        self.id = UUID()
        self.rating = rating
        self.comment = comment
        self.sentimentScore = sentimentScore
        self.date = date
    }
}
