//
//  AboutView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI

private func treatmentLevel(for label: String) -> TreatmentLevel {
    switch label {
    case "Acne", "Infestations_Bites": return .selfMedication
    case "Moles":                      return .none
    default:                           return .doctor
    }
}

private var version: String {
    let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(ver) (\(build))"
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                // App branding
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

                // App info
                Section("Informasi Aplikasi") {
                    InfoRow(icon: "tag.fill", color: .teal, label: "Versi", value: version)
                    InfoRow(icon: "building.2.fill", color: .blue, label: "Perusahaan", value: "Dicoding")
                    InfoRow(icon: "person.2.fill", color: .purple, label: "Author", value: "Setianing B., Pandawa B. S.")
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                // Model info
                Section("Model AI") {
                    InfoRow(icon: "cpu.fill", color: .teal, label: "Model", value: "\(Constants.modelName).\(Constants.modelExtension)")
                    InfoRow(icon: "brain", color: .purple, label: "Framework", value: "Core ML + Vision")
                    InfoRow(icon: "sparkles", color: .orange, label: "LLM Provider", value: "OpenAI-compatible")
                    InfoRow(icon: "antenna.radiowaves.left.and.right", color: .green, label: "LLM Model", value: Constants.aiModelName)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                // Stats
                Section("Statistik") {
                    InfoRow(icon: "number.circle.fill", color: .teal, label: "Total Scan", value: "\(ScanHistoryStore.shared.sessions.count)")
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                // Conditions
                Section("Kondisi yang Dapat Dideteksi") {
                    ForEach(Array(Constants.diseaseNames.keys.sorted()), id: \.self) { key in
                        let name = Constants.diseaseNames[key]!
                        let level = treatmentLevel(for: key)
                        HStack {
                            Image(systemName: level.icon)
                                .foregroundStyle(level.color)
                                .frame(width: 28)
                            Text(name)
                                .font(.subheadline)
                            Spacer()
                            Text(level.rawValue)
                                .font(.caption2)
                                .foregroundStyle(level.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(level.color.opacity(0.1))
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
