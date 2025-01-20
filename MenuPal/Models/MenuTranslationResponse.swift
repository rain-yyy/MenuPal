import Foundation

// API 响应的外层结构
struct APIResponse: Codable {
    let raw_response: String
}

// 菜单数据结构
struct MenuData: Codable {
    var categories: [Category]
    
    init(jsonData: Data) throws {
        print("开始解析菜单数据...")
        
        // 1. 先解码外层响应
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(APIResponse.self, from: jsonData)
        print("成功解码 API 响应")
        
        // 2. 清理 raw_response 字符串
        var cleanedJSON = apiResponse.raw_response
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除可能的 BOM 标记和其他不可见字符
        cleanedJSON = cleanedJSON.components(separatedBy: CharacterSet.controlCharacters).joined()
        if cleanedJSON.hasPrefix("\u{FEFF}") {
            cleanedJSON = String(cleanedJSON.dropFirst())
        }
        
        print("清理后的 JSON 字符串: \(String(cleanedJSON.prefix(100)))...")
        
        // 3. 将清理后的 JSON 字符串转换为数据
        guard let menuData = cleanedJSON.data(using: .utf8) else {
            print("错误：无法将清理后的 JSON 转换为数据")
            throw MenuPalError.parsingError("无法将清理后的 JSON 转换为数据")
        }
        
        // 4. 验证 JSON 格式
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: menuData, options: []) as? [String: Any]
            print("JSON 格式验证通过")
            
            // 检查是否存在 categories 键
            guard let _ = jsonObject?["categories"] as? [[String: Any]] else {
                throw MenuPalError.parsingError("JSON 中缺少 categories 字段")
            }
        } catch {
            print("JSON 格式验证失败: \(error)")
            throw MenuPalError.parsingError("JSON 格式无效: \(error.localizedDescription)")
        }
        
        // 5. 解码菜单数据
        do {
            let menuResponse = try decoder.decode(MenuResponse.self, from: menuData)
            self.categories = menuResponse.categories
            
            print("成功解析菜单数据，共 \(categories.count) 个分类")
            categories.forEach { category in
                print("分类: \(category.translated_name), 包含 \(category.items.count) 个菜品")
            }
        } catch let error as DecodingError {
            print("解码错误: \(error)")
            switch error {
            case .dataCorrupted(let context):
                print("数据损坏：\(context.debugDescription)")
                if let underlyingError = context.underlyingError {
                    print("底层错误：\(underlyingError)")
                }
                throw MenuPalError.parsingError("JSON 数据损坏: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("未找到键：\(key.stringValue)，路径：\(context.codingPath)")
                throw MenuPalError.parsingError("缺少必要字段 '\(key.stringValue)'")
            case .typeMismatch(let type, let context):
                print("类型不匹配：期望 \(type)，路径：\(context.codingPath)")
                throw MenuPalError.parsingError("数据类型不匹配，字段：\(context.codingPath.last?.stringValue ?? "unknown")")
            case .valueNotFound(let type, let context):
                print("值未找到：类型 \(type)，路径：\(context.codingPath)")
                throw MenuPalError.parsingError("必需值缺失，字段：\(context.codingPath.last?.stringValue ?? "unknown")")
            @unknown default:
                throw MenuPalError.parsingError("未知解码错误: \(error.localizedDescription)")
            }
        } catch {
            print("其他解析错误: \(error)")
            throw MenuPalError.parsingError("JSON 解析失败: \(error.localizedDescription)")
        }
    }
}

// 菜单响应结构
struct MenuResponse: Codable {
    let categories: [Category]
}

// 分类结构
struct Category: Codable {
    let original_name: String
    let translated_name: String
    let items: [Item]
}

// 菜品结构
struct Item: Codable {
    let original_name: String
    let translated_name: String
    let price: Int?
}

extension MenuData {
    func getAllMenuItems() -> [MenuItem] {
        print("开始提取所有菜品...")
        var result: [MenuItem] = []
        
        for category in categories {
            for item in category.items {
                let menuItem = MenuItem(
                    id: "\(category.original_name)_\(item.original_name)",
                    name: item.original_name,
                    translation: item.translated_name,
                    price: item.price,
                    category: category.translated_name
                )
                result.append(menuItem)
            }
        }
        
        print("共提取 \(result.count) 个菜品")
        return result
    }
} 