//
//  HistoryView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI

struct HistoryView: View {
    @State private var store = ScanHistoryStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            NavigationLink(destination: ResultView(session: session)) {
                                HistoryRow(session: session)
                            }
                            .listRowBackground(Color(.secondarySystemGroupedBackground))
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Riwayat Scan")
            .toolbar {
                if !store.sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Hapus Semua", role: .destructive) {
                            store.clear()
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Belum Ada Riwayat")
                .font(.headline)
            Text("Hasil scan akan muncul di sini")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct HistoryRow: View {
    let session: ScanSession

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            Group {
                if let data = session.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(session.condition.localizedName)
                    .font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 6) {
                    TreatmentBadge(level: session.condition.treatmentLevel)
                    Text(session.condition.confidencePercentage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(session.scannedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview { HistoryView() }
