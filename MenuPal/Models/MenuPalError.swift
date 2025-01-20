import Foundation

/// 应用程序错误类型
enum MenuPalError: LocalizedError {
    case invalidData
    case parsingError(String)
    case networkError(String)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "无效的数据格式"
        case .parsingError(let message):
            return "解析错误：\(message)"
        case .networkError(let message):
            return "网络错误：\(message)"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        }
    }
}
