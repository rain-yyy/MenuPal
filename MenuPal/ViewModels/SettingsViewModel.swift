import SwiftUI
import CoreLocation

@MainActor
class SettingsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var settings: UserSettings
    @Published var isLoadingLocation = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "UserSettings"
    private let storage = MenuStorage.shared
    
    override init() {
        // 从 UserDefaults 加载设置或使用默认设置
        if let data = UserDefaults.standard.data(forKey: "UserSettings"),
           let savedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = savedSettings
        } else {
            self.settings = .defaultSettings
        }
        
        super.init()
        locationManager.delegate = self
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func clearAllHistory() {
        Task {
            do {
                try await storage.clearAll()
                // 发送通知以更新其他视图
                NotificationCenter.default.post(name: .menuHistoryCleared, object: nil)
            } catch {
                errorMessage = "清除历史记录失败: \(error.localizedDescription)"
            }
        }
    }
    
    func requestLocation() {
        isLoadingLocation = true
        errorMessage = nil
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "请在设置中允许访问位置信息"
            isLoadingLocation = false
        @unknown default:
            errorMessage = "未知的位置权限状态"
            isLoadingLocation = false
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoadingLocation = false
        if let location = locations.first {
            settings.location = location.coordinate
            updateCurrencyForLocation(location)
            saveSettings()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
        errorMessage = "获取位置失败: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "请在设置中允许访问位置信息"
            isLoadingLocation = false
        default:
            break
        }
    }
    
    private func updateCurrencyForLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "获取地理位置信息失败: \(error.localizedDescription)"
                return
            }
            
            if let countryCode = placemarks?.first?.isoCountryCode {
                let currencyCode = self.getCurrencyCode(for: countryCode)
                if let currency = Currency(rawValue: currencyCode) {
                    self.settings.currency = currency
                    self.saveSettings()
                }
            }
        }
    }
    
    private func getCurrencyCode(for countryCode: String) -> String {
        switch countryCode.uppercased() {
        case "CN": return "CNY"
        case "US": return "USD"
        case "JP": return "JPY"
        case "KR": return "KRW"
        case "EU", "DE", "FR", "IT", "ES": return "EUR"
        default: return "USD"
        }
    }
}

#Preview {
    SettingsView()
}

// 添加通知名称
extension Notification.Name {
    static let menuHistoryCleared = Notification.Name("menuHistoryCleared")
} 