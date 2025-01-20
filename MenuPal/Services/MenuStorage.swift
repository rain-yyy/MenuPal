import Foundation

actor MenuStorage {
    static let shared = MenuStorage()
    
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var translationsDirectory: URL {
        documentsDirectory.appendingPathComponent("translations", isDirectory: true)
    }
    
    private var translationsMetadataURL: URL {
        documentsDirectory.appendingPathComponent("translations_metadata.json")
    }
    
    private init() {
        do {
            // 创建翻译数据目录
            if !fileManager.fileExists(atPath: translationsDirectory.path) {
                try fileManager.createDirectory(at: translationsDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("初始化存储失败: \(error)")
        }
    }
    
    // 保存翻译记录
    func saveTranslation(_ translation: MenuTranslation) throws {
        // 1. 为翻译创建唯一目录
        let translationDir = translationsDirectory.appendingPathComponent(translation.id.uuidString)
        if !fileManager.fileExists(atPath: translationDir.path) {
            try fileManager.createDirectory(at: translationDir, withIntermediateDirectories: true)
        }
        
        // 2. 保存翻译元数据
        let metadataURL = translationDir.appendingPathComponent("metadata.json")
        let data = try encoder.encode(translation)
        try data.write(to: metadataURL)
        
        // 3. 更新翻译列表元数据
        try updateTranslationsMetadata(adding: translation)
    }
    
    // 加载所有翻译记录
    func loadTranslations() throws -> [MenuTranslation] {
        guard fileManager.fileExists(atPath: translationsMetadataURL.path),
              let data = try? Data(contentsOf: translationsMetadataURL),
              let metadata = try? decoder.decode([String: Date].self, from: data) else {
            return []
        }
        
        var translations: [MenuTranslation] = []
        for (id, _) in metadata {
            if let translation = try? loadTranslation(id: id) {
                translations.append(translation)
            }
        }
        
        return translations.sorted { $0.date > $1.date }
    }
    
    // 删除翻译记录
    func deleteTranslation(id: String) throws {
        let translationDir = translationsDirectory.appendingPathComponent(id)
        if fileManager.fileExists(atPath: translationDir.path) {
            try fileManager.removeItem(at: translationDir)
        }
        
        try updateTranslationsMetadata(removing: id)
    }
    
    // 清除所有数据
    func clearAll() throws {
        if fileManager.fileExists(atPath: translationsDirectory.path) {
            try fileManager.removeItem(at: translationsDirectory)
            try fileManager.createDirectory(at: translationsDirectory, withIntermediateDirectories: true)
        }
        
        if fileManager.fileExists(atPath: translationsMetadataURL.path) {
            try fileManager.removeItem(at: translationsMetadataURL)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTranslation(id: String) throws -> MenuTranslation? {
        let translationDir = translationsDirectory.appendingPathComponent(id)
        let metadataURL = translationDir.appendingPathComponent("metadata.json")
        
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL) else {
            return nil
        }
        
        return try decoder.decode(MenuTranslation.self, from: data)
    }
    
    private func updateTranslationsMetadata(adding translation: MenuTranslation? = nil, removing id: String? = nil) throws {
        var metadata: [String: Date] = [:]
        
        // 加载现有元数据
        if fileManager.fileExists(atPath: translationsMetadataURL.path),
           let data = try? Data(contentsOf: translationsMetadataURL) {
            metadata = (try? decoder.decode([String: Date].self, from: data)) ?? [:]
        }
        
        // 添加新翻译
        if let translation = translation {
            metadata[translation.id.uuidString] = translation.date
        }
        
        // 移除翻译
        if let id = id {
            metadata.removeValue(forKey: id)
        }
        
        // 保存更新后的元数据
        let data = try encoder.encode(metadata)
        try data.write(to: translationsMetadataURL)
    }
} 