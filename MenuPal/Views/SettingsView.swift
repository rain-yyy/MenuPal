import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("语言设置")) {
                    Picker("首选语言", selection: $viewModel.settings.preferredLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                }
                
                Section(header: Text("货币设置")) {
                    Picker("货币单位", selection: $viewModel.settings.currency) {
                        ForEach(Currency.allCases) { currency in
                            Text(currency.displayName)
                                .tag(currency)
                        }
                    }
                    
                    HStack {
                        Text("当前位置")
                        Spacer()
                        Text(viewModel.settings.locationDisplay)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        viewModel.requestLocation()
                    }) {
                        HStack {
                            Text("更新位置")
                            if viewModel.isLoadingLocation {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isLoadingLocation)
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除所有历史记录")
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
            .alert("清除历史记录", isPresented: $showClearConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    viewModel.clearAllHistory()
                }
            } message: {
                Text("确定要清除所有历史记录吗？此操作无法撤销。")
            }
        }
    }
}

#Preview {
    SettingsView()
} 
