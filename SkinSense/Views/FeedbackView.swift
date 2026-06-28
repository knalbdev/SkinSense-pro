//
//  FeedbackView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI
import NaturalLanguage

// MARK: - Sentiment

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

private func analyzeSentiment(_ text: String) -> (score: Double, sentiment: Sentiment) {
    let tagger = NLTagger(tagSchemes: [.sentimentScore])
    tagger.string = text
    let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
    let score = Double(tag?.rawValue ?? "0") ?? 0
    let sentiment: Sentiment = score >= 0.3 ? .positive : (score <= -0.3 ? .negative : .neutral)
    return (score, sentiment)
}

// MARK: - View

struct FeedbackView: View {
    let conditionName: String
    let sessionID: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var rating = 0
    @State private var sentimentScore: Double = 0
    @State private var sentiment: Sentiment = .neutral
    @State private var submitted = false

    private var feedbacks: [Feedback] {
        ScanHistoryStore.shared.sessions.first(where: { $0.id == sessionID })?.feedbacks ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    context
                    ratingSection
                    textSection
                    if !text.isEmpty { sentimentPreview }
                    submitButton
                    if !feedbacks.isEmpty { historySection }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Umpan Balik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
            .alert("Terima Kasih! 🙏", isPresented: $submitted) {
                Button("OK") { dismiss() }
            } message: {
                Text("Ulasan kamu telah tersimpan.")
            }
        }
    }

    // MARK: - Subviews

    private var context: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.title2).foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ulasan untuk kondisi:")
                    .font(.caption).foregroundStyle(.secondary)
                Text(conditionName)
                    .font(.subheadline).fontWeight(.semibold)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Seberapa membantu rekomendasinya?")
                .font(.subheadline).fontWeight(.semibold)
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundStyle(i <= rating ? .yellow : .secondary)
                        .onTapGesture { withAnimation(.spring(duration: 0.2)) { rating = i } }
                }
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Komentar (opsional)")
                .font(.subheadline).fontWeight(.semibold)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: text) { _, val in
                        let result = analyzeSentiment(val)
                        sentimentScore = result.score
                        sentiment = result.sentiment
                    }
                if text.isEmpty {
                    Text("Tulis pengalamanmu setelah mengikuti rekomendasi ini...")
                        .font(.caption).foregroundStyle(.tertiary)
                        .padding(.horizontal, 12).padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var sentimentPreview: some View {
        HStack(spacing: 12) {
            Text(sentiment.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sentimen: \(sentiment.label)")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(sentiment.color)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 4)
                        Capsule()
                            .fill(sentiment.color)
                            .frame(width: g.size.width * CGFloat((sentimentScore + 1) / 2), height: 4)
                            .animation(.easeInOut, value: sentimentScore)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var submitButton: some View {
        Button {
            guard rating > 0 else { return }
            Task {
                await ScanHistoryStore.shared.addFeedback(
                    for: sessionID,
                    rating: rating,
                    comment: text,
                    sentimentScore: sentimentScore
                )
                text = ""
                rating = 0
                submitted = true
            }
        } label: {
            Text("Kirim Ulasan")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.teal)
        .disabled(rating == 0)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Riwayat Ulasan")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(feedbacks, id: \.id) { fb in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Show rating stars
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= fb.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(i <= fb.rating ? Color.yellow : Color.gray.opacity(0.3))
                            }
                        }
                        Spacer()
                        Text(fb.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    if !fb.comment.isEmpty {
                        Text(fb.comment)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    // Sentiment score bar
                    HStack(spacing: 4) {
                        let s: Sentiment = fb.sentimentScore >= 0.3 ? .positive : (fb.sentimentScore <= -0.3 ? .negative : .neutral)
                        Text(s.emoji).font(.caption2)
                        Text("\(String(format: "%.2f", fb.sentimentScore))")
                            .font(.caption2).foregroundStyle(s.color)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    FeedbackView(conditionName: "Jerawat", sessionID: UUID())
}
