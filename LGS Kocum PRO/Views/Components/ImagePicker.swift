import PhotosUI
import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotosPicker = false
    @State private var showingActionSheet = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedPhotoPickerItem: PhotosPickerItem?

    var body: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 20, height: 20)
                            )
                            .offset(x: 20, y: 20)
                    )
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Fotoğraf")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
        }
        .confirmationDialog(
            "Fotoğraf Seç", isPresented: $showingActionSheet, titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Fotoğraf Çek") {
                    imageSourceType = .camera
                    showingImagePicker = true
                }
            }

            Button("Galeriden Seç") {
                showingPhotosPicker = true
            }

            if selectedImage != nil {
                Button("Fotoğrafı Kaldır", role: .destructive) {
                    selectedImage = nil
                }
            }

            Button("İptal", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: imageSourceType)
        }
        .photosPicker(
            isPresented: $showingPhotosPicker,
            selection: $selectedPhotoPickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoPickerItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
        }
    }
}

struct StudentProfileImageView: View {
    let student: Student?
    var size: CGFloat = 40
    var showBorder: Bool = true

    var body: some View {
        Group {
            if let student = student, let image = student.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    showBorder ? Color(.systemGray4) : Color.clear, lineWidth: showBorder ? 1 : 0)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        PhotoPickerView(selectedImage: .constant(nil))

        StudentProfileImageView(student: nil, size: 60)

        StudentProfileImageView(student: nil, size: 40)
    }
    .padding()
}
