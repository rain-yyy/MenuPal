import Foundation
import UIKit

/// 图片数据结构
struct ImagePayload: Codable {
    let filename: String
    let image: String
}

/// 请求数据结构
struct RequestPayload: Codable {
    let target_language: String
    let images: [ImagePayload]
}

class MenuPalService {
    private let cloudFunctionURL = "https://us-central1-menupal-446313.cloudfunctions.net/latest"
    
    init() {}
    
    /// 上传多个图片并获取菜单分析结果
    func uploadImages(_ images: [UIImage], targetLanguage: String) async throws -> MenuData {
        var imagePayloads: [ImagePayload] = []
        
        // Convert images to base64
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw MenuPalError.invalidData
            }
            
            let base64String = imageData.base64EncodedString()
            let filename = "menu_\(index + 1).jpg"
            
            imagePayloads.append(ImagePayload(
                filename: filename,
                image: base64String
            ))
        }
        
        // Create request payload
        let requestPayload = RequestPayload(
            target_language: targetLanguage,
            images: imagePayloads
        )
        
        // Create URL request
        var request = URLRequest(url: URL(string: cloudFunctionURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode payload
        let jsonData = try JSONEncoder().encode(requestPayload)
        request.httpBody = jsonData
        
        print("开始上传图片...")
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MenuPalError.networkError("Invalid response")
        }
        
        print("服务器响应状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            throw MenuPalError.serverError(httpResponse.statusCode)
        }
        
        // Print response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("收到响应: \(jsonString)")
        }
        
        // 使用 MenuData 的初始化方法来处理响应
        return try MenuData(jsonData: data)
    }
} 