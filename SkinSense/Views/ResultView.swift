//
//  ResultView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI

struct ResultView: View {
    let session: ScanSession
    @State private var vm = ResultViewModel()
    @State private var showFeedback = false
    @State private var currentFeedback: Feedback?

    var condition: SkinCondition { session.condition }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Foto hasil scan
                if let data = session.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 20)
                }

                // Detection card
                detectionCard
                    .padding(.horizontal, 20)

                // AI Explanation
                aiSection
                    .padding(.horizontal, 20)

                // Ulasan
                if let fb = currentFeedback {
                    feedbackCard(fb)
                }
                feedbackButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Hasil Deteksi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFeedback) {
            FeedbackView(conditionName: condition.localizedName, sessionID: session.id)
        }
        .task {
            currentFeedback = session.feedback
            if let cached = session.aiExplanation {
                vm.explanation = cached
            } else {
                await vm.fetchExplanation(for: condition, sessionID: session.id)
            }
        }
        .onChange(of: showFeedback) { _, showing in
            if !showing {
                currentFeedback = ScanHistoryStore.shared.sessions.first(where: { $0.id == session.id })?.feedback
            }
        }
    }

    // MARK: - Detection Card

    private var detectionCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(condition.localizedName)
                        .font(.title3).fontWeight(.bold)
                    Text(condition.modelLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TreatmentBadge(level: condition.treatmentLevel)
            }

            // Confidence bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Keyakinan Model")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(condition.confidencePercentage)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(confidenceColor)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(confidenceColor)
                            .frame(width: g.size.width * condition.confidence, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private var confidenceColor: Color {
        switch condition.confidence {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    // MARK: - AI Section

    @ViewBuilder
    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Penjelasan AI", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.teal)
                Spacer()
                if vm.isLoading {
                    ProgressView().tint(.teal)
                }
            }

            if vm.isLoading {
                loadingPlaceholder
            } else if let err = vm.errorMessage {
                errorCard(err)
            } else if let exp = vm.explanation {
                explanationContent(exp)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                    .opacity(0.6)
            }
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 180, height: 14)
                .opacity(0.4)
        }
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash").foregroundStyle(.orange)
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            Button("Coba Lagi") {
                Task { await vm.retry(condition: condition, sessionID: session.id) }
            }
            .font(.subheadline).fontWeight(.semibold)
            .foregroundStyle(.teal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func explanationContent(_ exp: AIExplanation) -> some View {
        VStack(alignment: .leading, spacing: 18) {

            // Overview
            Text(exp.overview)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineSpacing(4)

            Divider()

            // Gejala
            if !exp.symptoms.isEmpty {
                infoSection(title: "Gejala Umum", icon: "list.bullet.clipboard", color: .blue) {
                    ForEach(exp.symptoms, id: \.self) { s in
                        BulletRow(text: s, color: .blue)
                    }
                }
                Divider()
            }

            // Rekomendasi
            if !exp.recommendations.isEmpty {
                infoSection(title: "Yang Bisa Dilakukan", icon: "checklist", color: .green) {
                    ForEach(exp.recommendations, id: \.self) { r in
                        BulletRow(text: r, color: .green)
                    }
                }
            }

            // Obat (hanya selfMedication)
            if !exp.medicines.isEmpty {
                Divider()
                infoSection(title: "Rekomendasi Obat", icon: "cross.case.fill", color: .orange) {
                    ForEach(exp.medicines) { med in
                        MedicineRow(medicine: med)
                    }
                }
            }

            // Doctor referral banner
            if condition.treatmentLevel == .doctor {
                Divider()
                DoctorReferralBanner()
            }
        }
    }

    private func infoSection<Content: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(color)
            content()
        }
    }

    // MARK: - Feedback

    private var feedbackButton: some View {
        Button {
            showFeedback = true
        } label: {
            Label(currentFeedback == nil ? "Beri Ulasan Penanganan" : "Ubah Ulasan", systemImage: "text.bubble")
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.purple.opacity(0.12))
                .foregroundStyle(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func feedbackCard(_ fb: Feedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ulasan Kamu", systemImage: "text.bubble.fill")
                .font(.headline)
                .foregroundStyle(.purple)

            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= fb.rating ? "star.fill" : "star")
                        .font(.subheadline)
                        .foregroundStyle(i <= fb.rating ? .yellow : Color.gray.opacity(0.3))
                }
                Spacer()
                Text(fb.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Comment
            if !fb.comment.isEmpty {
                Text(fb.comment)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            // Sentiment
            let s: Sentiment = fb.sentimentScore >= 0.3 ? .positive : (fb.sentimentScore <= -0.3 ? .negative : .neutral)
            HStack(spacing: 4) {
                Text(s.emoji).font(.caption)
                Text("\(s.label) (\(String(format: "%.2f", fb.sentimentScore)))")
                    .font(.caption2)
                    .foregroundStyle(s.color)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
    }
}

// MARK: - Sentiment (local copy for display)

private enum Sentiment {
    case positive, neutral, negative
    var emoji: String {
        switch self { case .positive: "😍"; case .neutral: "😐"; case .negative: "😕" }
    }
    var label: String {
        switch self { case .positive: "Positif"; case .neutral: "Netral"; case .negative: "Negatif" }
    }
    var color: Color {
        switch self { case .positive: .green; case .neutral: .orange; case .negative: .red }
    }
}

// MARK: - Supporting Views

struct TreatmentBadge: View {
    let level: TreatmentLevel
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon).font(.caption2)
            Text(level.rawValue).font(.caption2).fontWeight(.semibold)
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(level.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct BulletRow: View {
    let text: String; let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(color.opacity(0.6)).frame(width: 6, height: 6).padding(.top, 5)
            Text(text).font(.caption).foregroundStyle(.primary)
        }
    }
}

struct MedicineRow: View {
    let medicine: Medicine
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "pills.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(medicine.name).font(.caption).fontWeight(.semibold)
                Text("\(medicine.type) · \(medicine.dosage)").font(.caption2).foregroundStyle(.secondary)
                Text(medicine.howToUse).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct DoctorReferralBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "stethoscope")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Segera Konsultasi ke Dokter")
                    .font(.subheadline).fontWeight(.semibold)
                Text("Kondisi ini memerlukan diagnosis dari dokter spesialis kulit & kelamin.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ResultView(session: ScanSession(
            condition: SkinCondition(modelLabel: "Acne", confidence: 0.91),
            imageData: nil,
            scannedAt: Date()
        ))
    }
}
