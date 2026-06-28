//
//  ScanHistoryStore.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation
import SwiftData

// MARK: - SwiftData Model

@Model
final class ScanRecord {
    @Attribute(.unique) var id: UUID
    var conditionLabel: String
    var conditionConfidence: Double
    @Attribute(.externalStorage) var imageData: Data?
    var scannedAt: Date

    // AI Explanation — stored as JSON Data (SwiftData-friendly for Codable structs)
    var aiOverview: String?
    var aiSymptomsData: Data?
    var aiRecommendationsData: Data?
    var aiMedicinesData: Data?

    // Feedback
    var feedbacksData: Data?

    init(id: UUID, condition: SkinCondition, imageData: Data?, scannedAt: Date) {
        self.id = id
        self.conditionLabel = condition.modelLabel
        self.conditionConfidence = condition.confidence
        self.imageData = imageData
        self.scannedAt = scannedAt
    }
}

extension ScanRecord {
    /// Create a ScanRecord from a ScanSession (for saving)
    convenience init(from session: ScanSession) {
        self.init(
            id: session.id,
            condition: session.condition,
            imageData: session.imageData,
            scannedAt: session.scannedAt
        )
        if let exp = session.aiExplanation {
            aiOverview = exp.overview
            aiSymptomsData = try? JSONEncoder().encode(exp.symptoms)
            aiRecommendationsData = try? JSONEncoder().encode(exp.recommendations)
            aiMedicinesData = try? JSONEncoder().encode(exp.medicines)
        }
        if !session.feedbacks.isEmpty {
            feedbacksData = try? JSONEncoder().encode(session.feedbacks)
        }
    }

    /// Convert back to a ScanSession (for reading)
    var toSession: ScanSession {
        let condition = SkinCondition(modelLabel: conditionLabel, confidence: conditionConfidence)
        let explanation: AIExplanation?

        if let overview = aiOverview {
            let symptoms = (try? JSONDecoder().decode([String].self, from: aiSymptomsData ?? Data())) ?? []
            let recommendations = (try? JSONDecoder().decode([String].self, from: aiRecommendationsData ?? Data())) ?? []
            let medicines = (try? JSONDecoder().decode([Medicine].self, from: aiMedicinesData ?? Data())) ?? []
            explanation = AIExplanation(
                overview: overview,
                symptoms: symptoms,
                recommendations: recommendations,
                medicines: medicines
            )
        } else {
            explanation = nil
        }

        let feedbacks = (try? JSONDecoder().decode([Feedback].self, from: feedbacksData ?? Data())) ?? []

        return ScanSession(
            id: id,
            condition: condition,
            imageData: imageData,
            scannedAt: scannedAt,
            aiExplanation: explanation,
            feedbacks: feedbacks
        )
    }
}

// MARK: - Store

@Observable
@MainActor
final class ScanHistoryStore {
    static let shared = ScanHistoryStore()
    private(set) var sessions: [ScanSession] = []

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private init() {
        self.modelContainer = try! ModelContainer(for: ScanRecord.self)
        self.modelContext = modelContainer.mainContext
        self.sessions = loadAll()
    }

    // MARK: - Disk I/O

    private func loadAll() -> [ScanSession] {
        let descriptor = FetchDescriptor<ScanRecord>(sortBy: [.init(\.scannedAt, order: .reverse)])
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.map(\.toSession)
    }

    private func save() async {
        try? await modelContext.save()
    }

    // MARK: - Public API

    func add(_ session: ScanSession) async {
        sessions.insert(session, at: 0)
        modelContext.insert(ScanRecord(from: session))
        await save()
    }

    func updateExplanation(for sessionID: UUID, with explanation: AIExplanation) async {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].aiExplanation = explanation

        let pred = #Predicate<ScanRecord> { $0.id == sessionID }
        let descriptor = FetchDescriptor<ScanRecord>(predicate: pred)
        guard let record = try? modelContext.fetch(descriptor).first else { return }

        record.aiOverview = explanation.overview
        record.aiSymptomsData = try? JSONEncoder().encode(explanation.symptoms)
        record.aiRecommendationsData = try? JSONEncoder().encode(explanation.recommendations)
        record.aiMedicinesData = try? JSONEncoder().encode(explanation.medicines)
        await save()
    }

    func addFeedback(for sessionID: UUID, rating: Int, comment: String, sentimentScore: Double) async {
        let feedback = Feedback(rating: rating, comment: comment, sentimentScore: sentimentScore)

        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].feedbacks.insert(feedback, at: 0)

        let pred = #Predicate<ScanRecord> { $0.id == sessionID }
        let descriptor = FetchDescriptor<ScanRecord>(predicate: pred)
        guard let record = try? modelContext.fetch(descriptor).first else { return }

        record.feedbacksData = try? JSONEncoder().encode(sessions[index].feedbacks)
        await save()
    }

    func clear() async {
        sessions.removeAll()
        try? modelContext.delete(model: ScanRecord.self)
        await save()
    }
}
