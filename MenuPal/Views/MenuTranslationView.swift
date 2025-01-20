import SwiftUI
import PhotosUI

// MARK: - 图片选择按钮视图
struct ImageSelectionButtons: View {
    let onCameraSelect: () -> Void
    @Binding var selectedItems: [PhotosPickerItem]
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onCameraSelect) {
                VStack {
                    Image(systemName: "camera")
                        .font(.largeTitle)
                    Text("拍照")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            PhotosPicker(selection: $selectedItems,
                        maxSelectionCount: 4,
                        matching: .images,
                        photoLibrary: .shared()) {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.largeTitle)
                    Text("选择照片")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - 选中图片预览视图
struct SelectedImagesPreview: View {
    @ObservedObject var viewModel: MenuTranslationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已选择 \(viewModel.selectedImages.count) 张图片")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        SelectedImageThumbnail(
                            image: viewModel.selectedImages[index],
                            onDelete: { viewModel.removeSelectedImage(at: index) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
            
            Button(action: {
                Task {
                    await viewModel.uploadSelectedImages()
                }
            }) {
                Text("开始翻译")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading)
        }
        .padding(.vertical)
    }
}

// MARK: - 单个图片缩略图视图
struct SelectedImageThumbnail: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
}

// MARK: - 主视图
struct MenuTranslationView: View {
    @StateObject private var viewModel = MenuTranslationViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showTranslatedMenu = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ImageSelectionButtons(
                    onCameraSelect: { showCamera = true },
                    selectedItems: $selectedItems
                )
                
                if !viewModel.selectedImages.isEmpty {
                    SelectedImagesPreview(viewModel: viewModel)
                }
                
                if viewModel.translations.isEmpty {
                    ContentUnavailableView(
                        "暂无历史记录",
                        systemImage: "doc.text.image",
                        description: Text("拍照或选择图片开始翻译菜单")
                    )
                } else {
                    List {
                        ForEach(viewModel.translations) { translation in
                            NavigationLink {
                                TranslatedMenuView(viewModel: viewModel)
                            } label: {
                                TranslationHistoryRow(translation: translation)
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.deleteTranslation(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("菜单翻译")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showTranslatedMenu) {
                NavigationStack {
                    TranslatedMenuView(viewModel: viewModel)
                }
            }
            .onChange(of: selectedImage) { oldValue, newImage in
                if let image = newImage {
                    viewModel.addSelectedImage(image)
                    selectedImage = nil
                }
            }
            .onChange(of: selectedItems) { oldValue, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.addSelectedImage(image)
                            }
                        }
                    }
                    await MainActor.run {
                        selectedItems.removeAll()
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - 历史记录行视图
struct TranslationHistoryRow: View {
    let translation: MenuTranslation
    
    var body: some View {
        HStack(spacing: 12) {
            if let firstImage = translation.images.first,
               let imageData = FileManager.loadImage(named: firstImage.imageFileName),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.title)
                    .font(.headline)
                
                HStack {
                    Text("\(translation.images.count) 张图片")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(translation.menuItems.count) 个菜品")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(translation.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("图片选择按钮") {
    ImageSelectionButtons(
        onCameraSelect: {},
        selectedItems: .constant([])
    )
}

#Preview("选中图片预览") {
    SelectedImagesPreview(viewModel: {
        let viewModel = MenuTranslationViewModel()
        viewModel.addSelectedImage(UIImage(systemName: "photo")!)
        return viewModel
    }())
}

#Preview("图片缩略图") {
    SelectedImageThumbnail(
        image: UIImage(systemName: "photo")!,
        onDelete: {}
    )
}

#Preview("历史记录行") {
    let testImage = UIImage(systemName: "photo")!.pngData()!
    let menuItems = [
        MenuItem(
            id: "test",
            name: "Test Item",
            translation: "测试项目",
            price: 10, category: "test"
        )
    ]
    
    let translation = try! MenuTranslation(
        images: [testImage],
        menuItems: menuItems,
        title: "测试菜单"
    )
    
    TranslationHistoryRow(translation: translation)
} 
