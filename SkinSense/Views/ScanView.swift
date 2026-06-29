//
//  ScanView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI
import PhotosUI

struct ScanView: View {
    @State private var vm = ScanViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    imagePreviewCard
                    actionButtons
                    if vm.isClassifying { analyzingIndicator }
                    if let err = vm.classifyError { errorBanner(err) }
                    tipCards
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SkinSense")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        vm.selectedImage = img
                    }
                }
            }
            .onChange(of: cameraImage) { _, img in
                if let img = img { vm.selectedImage = img }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(image: $cameraImage)
            }
            .navigationDestination(isPresented: $vm.showResult) {
                if let session = vm.currentSession {
                    ResultView(session: session)
                }
            }
        }
    }

    // MARK: - Subviews

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Deteksi Kondisi Kulit")
                .font(.title2).fontWeight(.bold)
            Text("Ambil atau pilih foto area kulit yang ingin diperiksa")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var imagePreviewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 280)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)

            if let img = vm.selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                if vm.isClassifying {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.black.opacity(0.4))
                        .frame(height: 280)
                }
            } else {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 36))
                            .foregroundStyle(.teal)
                    }
                    Text("Foto belum dipilih")
                        .font(.subheadline).fontWeight(.medium)
                    Text("Gunakan kamera atau pilih dari galeri")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.selectedImage != nil)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Pilih dari galeri
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.body)
                    Text("Pilih dari Galeri")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.teal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Kamera
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Buka Kamera")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.teal.opacity(0.4), lineWidth: 1.5)
                )
            }

            // Tombol deteksi
            Button {
                Task { await vm.classify() }
            } label: {
                HStack(spacing: 8) {
                    if vm.isClassifying {
                        ProgressView().tint(.white)
                        Text("Menganalisis...").fontWeight(.semibold)
                    } else {
                        Image(systemName: "sparkles")
                        Text("Deteksi Sekarang").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(vm.selectedImage == nil ? Color.gray.opacity(0.3) : Color.teal)
                .foregroundStyle(vm.selectedImage == nil ? Color.secondary : .white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(vm.selectedImage == nil || vm.isClassifying)
        }
    }

    private var analyzingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView().tint(.teal)
            Text("Sedang menganalisis foto kulit kamu...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tipCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips Foto yang Baik")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "sun.max.fill",      color: .yellow, text: "Gunakan pencahayaan alami yang terang")
                TipRow(icon: "camera.macro",      color: .teal,   text: "Dekatkan kamera 10–15 cm dari kulit")
                TipRow(icon: "checkmark.circle",  color: .green,  text: "Fokus pada area yang bermasalah")
                TipRow(icon: "xmark.circle",      color: .red,    text: "Hindari bayangan dan flash langsung")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = (info[.originalImage] as? UIImage)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct TipRow: View {
    let icon: String; let color: Color; let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview { ScanView() }
