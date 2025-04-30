//
//  MemoryEditView.swift
//  CoupleMate
//
//  Created by 山田大陽 on 2025/04/30.
//


import SwiftUI
import PhotosUI

/**
 * MemoryEditView - メモリー編集/作成画面
 * 
 * 新しいメモリーの作成、または既存のメモリーの編集に使用します。
 * 写真の選択、基本情報の入力、メモの記入が可能です。
 */
struct MemoryEditView: View {
    // MARK: - プロパティ
    
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
    @State private var isShowingCamera = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    // MARK: - 初期化
    
    init(memory: Memory? = nil, isNewMemory: Bool) {
        self.memory = memory
        self.isNewMemory = isNewMemory
        
        // 状態プロパティの初期化
        _title = State(initialValue: memory?.title ?? "")
        _date = State(initialValue: memory?.date ?? Date())
        _location = State(initialValue: memory?.location ?? "")
        _notes = State(initialValue: memory?.notes ?? "")
    }
    
    // MARK: - ボディ
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報セクション
                Section(header: Text("基本情報")) {
                    TextField("タイトル", text: $title)
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    TextField("場所", text: $location)
                }
                
                // メモセクション
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // 写真セクション
                Section(header: Text("写真")) {
                    photoGrid
                }
                
                // エラーメッセージ表示
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
    
    // MARK: - コンポーネント
    
    /// 写真グリッド
    private var photoGrid: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // 選択した写真を表示
                    ForEach(0..<selectedPhotos.count, id: \.self) { index in
                        photoThumbnail(for: selectedPhotos[index], at: index)
                    }
                    
                    // 写真追加ボタン
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        addPhotoButton
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    /// 写真サムネイル
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
    
    /// 写真追加ボタン
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
    
    /// キャンセルボタン
    private var cancelButton: some View {
        Button("キャンセル") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// 保存ボタン
    private var saveButton: some View {
        Button(isNewMemory ? "保存" : "更新") {
            saveMemory()
        }
        .disabled(title.isEmpty || isLoading)
    }
    
    /// 読み込み中のオーバーレイ
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            
                            Text("処理中...")
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                    )
            }
        }
    }
    
    // MARK: - メソッド
    
    /// メモリーを保存する
    private func saveMemory() {
        // 入力検証
        guard !title.isEmpty else {
            errorMessage = "タイトルを入力してください"
            showErrorAlert = true
            return
        }
        
        // 写真が選択されていない場合の確認（オプション）
        if selectedPhotos.isEmpty && isNewMemory {
            // 写真なしで続行するか確認することもできる
            // ここではシンプルに続行
        }
        
        isLoading = true
        
        if isNewMemory {
            // 新規作成
            viewModel.addMemory(
                title: title,
                date: date,
                location: location,
                notes: notes,
                images: selectedPhotos
            ) { error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                    showErrorAlert = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else if let memory = memory {
            // 更新
            viewModel.updateMemory(
                memory,
                newTitle: title,
                newDate: date,
                newLocation: location,
                newNotes: notes,
                newImages: selectedPhotos.isEmpty ? nil : selectedPhotos
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
