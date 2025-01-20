import Foundation

extension FileManager {
    static let menuImagesDirectory = "menu_images"
    
    static func saveImage(_ imageData: Data, withName name: String) throws -> String {
        let fileManager = FileManager.default
        
        // 获取应用的文档目录
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw MenuPalError.parsingError("无法访问文档目录")
        }
        
        // 创建图片存储目录
        let imagesDirectory = documentsDirectory.appendingPathComponent(menuImagesDirectory)
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
        
        // 生成唯一的文件名
        let fileName = "\(name)_\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        // 保存图片
        try imageData.write(to: fileURL)
        
        return fileName
    }
    
    static func loadImage(named fileName: String) -> Data? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory
            .appendingPathComponent(menuImagesDirectory)
            .appendingPathComponent(fileName)
        
        return try? Data(contentsOf: fileURL)
    }
    
    static func deleteImage(named fileName: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory
            .appendingPathComponent(menuImagesDirectory)
            .appendingPathComponent(fileName)
        
        try? fileManager.removeItem(at: fileURL)
    }
} 