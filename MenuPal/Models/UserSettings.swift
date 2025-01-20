import Foundation
import CoreLocation

enum Language: String, Codable, CaseIterable, Identifiable {
    case chinese = "zh"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }
}

enum Currency: String, Codable, CaseIterable, Identifiable {
    case cny = "CNY"
    case usd = "USD"
    case jpy = "JPY"
    case krw = "KRW"
    case eur = "EUR"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .cny: return "¥"
        case .usd: return "$"
        case .jpy: return "¥"
        case .krw: return "₩"
        case .eur: return "€"
        }
    }
    
    var displayName: String {
        switch self {
        case .cny: return "人民币 (CNY)"
        case .usd: return "美元 (USD)"
        case .jpy: return "日元 (JPY)"
        case .krw: return "韩元 (KRW)"
        case .eur: return "欧元 (EUR)"
        }
    }
}

struct UserSettings: Codable {
    var preferredLanguage: Language
    var currency: Currency
    var location: CLLocationCoordinate2D?
    
    var locationDisplay: String {
        if let location = location {
            return String(format: "%.4f, %.4f", location.latitude, location.longitude)
        }
        return "未知"
    }
    
    static let defaultSettings = UserSettings(
        preferredLanguage: .chinese,
        currency: .cny,
        location: nil
    )
}

// 扩展CLLocationCoordinate2D以支持Codable
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
} 