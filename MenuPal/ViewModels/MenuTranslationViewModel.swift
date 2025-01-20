import SwiftUI

@MainActor
class MenuTranslationViewModel: ObservableObject {
    @Published var translations: [MenuTranslation] = []
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTranslation: MenuTranslation?
    @Published var selectedImages: [UIImage] = []
    
    private let storage = MenuStorage.shared
    private let service = MenuPalService()
    
    var settings: UserSettings {
        if let data = UserDefaults.standard.data(forKey: "UserSettings"),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return settings
        }
        return .defaultSettings
    }
    
    init() {
        Task {
            await loadSavedTranslations()
        }
        // 添加通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHistoryCleared),
            name: .menuHistoryCleared,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleHistoryCleared() {
        Task { @MainActor in
            translations.removeAll()
        }
    }
    
    // 清除所有历史数据
    func clearAllHistory() {
        Task {
            do {
                try await storage.clearAll()
                await MainActor.run {
                    translations.removeAll()
                    menuItems.removeAll()
                    selectedTranslation = nil
                    selectedImages.removeAll()
                }
            } catch {
                print("清除历史记录失败: \(error)")
                errorMessage = "清除历史记录失败"
            }
        }
    }
    
    // 删除指定的翻译记录
    func deleteTranslation(at indexSet: IndexSet) {
        Task {
            for index in indexSet {
                let translation = translations[index]
                do {
                    try await storage.deleteTranslation(id: translation.id.uuidString)
                    await MainActor.run {
                        translations.remove(at: index)
                    }
                } catch {
                    print("删除翻译记录失败: \(error)")
                    errorMessage = "删除翻译记录失败"
                }
            }
        }
    }
    
    // 添加选中的图片
    func addSelectedImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    // 移除选中的图片
    func removeSelectedImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    // 上传所有选中的图片
    func uploadSelectedImages() async {
        guard !selectedImages.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. 转换图片为数据
            var imageDataArray: [Data] = []
            for image in selectedImages {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    imageDataArray.append(imageData)
                }
            }
            
            // 2. 上传并获取菜单数据
            let menuData = try await service.uploadImages(
                selectedImages,
                targetLanguage: settings.preferredLanguage.rawValue
            )
            
            // 3. 获取菜单项
            let menuItems = menuData.getAllMenuItems()
            
            // 4. 创建新的翻译记录
            let translation = try MenuTranslation(
                images: imageDataArray,
                menuItems: menuItems,
                title: generateMenuTitle(from: menuItems)
            )
            
            // 5. 保存翻译记录
            try await storage.saveTranslation(translation)
            
            // 6. 更新状态
            await MainActor.run {
                translations.insert(translation, at: 0)
                self.menuItems = menuItems
                selectedImages.removeAll()
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                print("上传失败: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func generateMenuTitle(from items: [MenuItem]) -> String {
        let categories = Set(items.map { $0.category })
        if categories.count == 1, let category = categories.first {
            return category
        } else if let firstItem = items.first {
            return firstItem.name
        }
        return "未命名菜单"
    }
    
    private func loadSavedTranslations() async {
        do {
            let loadedTranslations = try await storage.loadTranslations()
            await MainActor.run {
                translations = loadedTranslations
            }
        } catch {
            print("加载翻译记录失败: \(error)")
            errorMessage = "加载翻译记录失败"
        }
    }
} 
