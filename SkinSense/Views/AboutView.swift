//
//  AboutView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI

struct AboutView: View {
    private let conditions: [(label: String, treatment: TreatmentLevel)] = [
        ("Jerawat",              .selfMedication),
        ("Eksim",                .doctor),
        ("Gigitan / Infestasi",  .selfMedication),
        ("Lupus Kulit",          .doctor),
        ("Tahi Lalat",           .none),
        ("Rosacea",              .doctor),
        ("Vitiligo",             .doctor),
    ]

    var body: some View {
        NavigationStack {
            List {
                // App info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.teal.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.teal)
                            }
                            Text("SkinSense")
                                .font(.title3).fontWeight(.bold)
                            Text("Deteksi kondisi kulit dengan AI")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                }

                // Model info
                Section("Model AI") {
                    InfoRow(icon: "cpu.fill", color: .teal, label: "Model", value: "SkinDisease.mlpackage")
                    InfoRow(icon: "brain", color: .purple, label: "Framework", value: "Core ML + Vision")
                    InfoRow(icon: "sparkles", color: .orange, label: "Generative AI", value: "Gemini Flash")
                    InfoRow(icon: "person.fill", color: .blue, label: "Trained by", value: "Setianing Budi")
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                // 7 conditions
                Section("Kondisi yang Dapat Dideteksi") {
                    ForEach(conditions, id: \.label) { item in
                        HStack {
                            Image(systemName: item.treatment.icon)
                                .foregroundStyle(item.treatment.color)
                                .frame(width: 28)
                            Text(item.label)
                                .font(.subheadline)
                            Spacer()
                            Text(item.treatment.rawValue)
                                .font(.caption2)
                                .foregroundStyle(item.treatment.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(item.treatment.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                // Disclaimer
                Section("Penting") {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Aplikasi ini hanya untuk tujuan edukasi dan bukan pengganti diagnosis medis profesional. Selalu konsultasikan kondisi kulit Anda kepada dokter spesialis.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.orange.opacity(0.06))
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tentang")
        }
    }
}

struct InfoRow: View {
    let icon: String; let color: Color; let label: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 28)
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.caption).foregroundStyle(.secondary)
        }
    }
}

#Preview { AboutView() }
