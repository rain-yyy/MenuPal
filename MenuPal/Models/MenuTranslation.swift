import Foundation

struct MenuTranslation: Identifiable, Codable {
    let id: UUID
    let images: [ImageData]
    let title: String
    let date: Date
    
    var menuItems: [MenuItem] {
        images.flatMap { $0.menuItems }
    }
    
    struct ImageData: Codable {
        let imageFileName: String
        var menuItems: [MenuItem]
        var additionalImageFileNames: [String]
        
        init(imageData: Data, menuItems: [MenuItem], additionalImages: [Data] = []) throws {
            // 保存主图片
            self.imageFileName = try FileManager.saveImage(imageData, withName: "main")
            self.menuItems = menuItems
            
            // 保存额外的图片
            var fileNames: [String] = []
            for (index, data) in additionalImages.enumerated() {
                let fileName = try FileManager.saveImage(data, withName: "additional_\(index)")
                fileNames.append(fileName)
            }
            self.additionalImageFileNames = fileNames
        }
    }
    
    init(images: [Data], menuItems: [MenuItem], title: String) throws {
        self.id = UUID()
        if images.isEmpty {
            self.images = []
        } else {
            let mainImage = images[0]
            let additionalImages = Array(images.dropFirst())
            self.images = [try ImageData(imageData: mainImage, menuItems: menuItems, additionalImages: additionalImages)]
        }
        self.title = title
        self.date = Date()
    }
} 