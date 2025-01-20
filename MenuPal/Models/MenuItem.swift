import Foundation

struct MenuItem: Identifiable, Codable {
    let id: String
    let name: String           // 原文名称
    let translation: String    // 中文翻译
    let price: Int?           // 价格（可选）
    let category: String      // 分类（使用中文名称）
    
    init(id: String, name: String, translation: String, price: Int?, category: String) {
        self.id = id
        self.name = name
        self.translation = translation
        self.price = price
        self.category = category
    }
} 