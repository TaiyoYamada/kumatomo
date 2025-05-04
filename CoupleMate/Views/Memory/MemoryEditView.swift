import SwiftUI
import PhotosUI
import FirebaseAuth

struct MemoryEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MemoriesViewModel

    var memory: Memory?
    var isNewMemory: Bool

    @State private var title: String
    @State private var date: Date
    @State private var location: String
    @State private var notes: String
    @State private var selectedPhotos: [UIImage] = []

    @State private var isShowingImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    init(memory: Memory? = nil, isNewMemory: Bool) {
        self.memory = memory
        self.isNewMemory = isNewMemory

        _title = State(initialValue: memory?.title ?? "")
        _date = State(initialValue: memory?.date ?? Date())
        _location = State(initialValue: memory?.location ?? "")
        _notes = State(initialValue: memory?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("タイトル", text: $title)
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    TextField("場所", text: $location)
                }

                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section(header: Text("写真")) {
                    photoGrid
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle(isNewMemory ? "新しい思い出" : "編集", displayMode: .inline)
            .navigationBarItems(
                leading: cancelButton,
                trailing: saveButton
            )
            .sheet(isPresented: $isShowingImagePicker) {
                PhotoPicker(selectedImages: $selectedPhotos)
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text(errorMessage ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay(loadingOverlay)
        }
    }

    private var photoGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<selectedPhotos.count, id: \.self) { index in
                    photoThumbnail(for: selectedPhotos[index], at: index)
                }

                Button {
                    isShowingImagePicker = true
                } label: {
                    addPhotoButton
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func photoThumbnail(for image: UIImage, at index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Button(action: {
                    selectedPhotos.remove(at: index)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding(4),
                alignment: .topTrailing
            )
    }

    private var addPhotoButton: some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 30))
            Text("追加")
                .font(.caption)
        }
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var cancelButton: some View {
        Button("キャンセル") {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var saveButton: some View {
        Button(isNewMemory ? "保存" : "更新") {
            saveMemory()
        }
        .disabled(title.isEmpty || isLoading)
    }

    private var loadingOverlay: some View {
        Group {
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("処理中...")
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                    )
            }
        }
    }

    private func saveMemory() {
        guard !title.isEmpty else {
            errorMessage = "タイトルを入力してください"
            showErrorAlert = true
            return
        }

        isLoading = true

        if isNewMemory {
            let authorId = Auth.auth().currentUser?.uid ?? ""

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)

            let request = MemoryRequest(
                author_id: authorId,
                title: title,
                date: dateString,
                location: location,
                notes: notes,
                photos: []
            )

            MemoryAPIService.shared.createMemory(request) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                        showErrorAlert = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } else if let memory = memory {
            viewModel.updateMemory(
                memory,
                newTitle: title,
                newDate: date,
                newLocation: location,
                newNotes: notes
            ) { error in
                isLoading = false
                if let error = error {
                    errorMessage = "更新に失敗しました: \(error.localizedDescription)"
                    showErrorAlert = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

/**
 * PhotoPicker - 写真選択のためのUIViewControllerRepresentable
 * 
 * システムの写真ピッカーを使用して、ユーザーが複数の写真を選択できるようにします。
 */
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10 // 最大10枚まで選択可能
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // 更新は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // 選択完了時
            picker.dismiss(animated: true)
            
            // 選択された各画像を処理
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}
