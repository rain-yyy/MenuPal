import SwiftUI

struct TranslatedMenuView: View {
    @ObservedObject var viewModel: MenuTranslationViewModel
    @State private var selectedCategory: String?
    
    // 将复杂的计算属性拆分成更小的函数
    private func getUncategorizedItems() -> [MenuItem] {
        viewModel.menuItems.filter { $0.category == "未分类" }
    }
    
    private func shouldShowCategory(_ category: String) -> Bool {
        if category != "未分类" {
            return true
        }
        return !getUncategorizedItems().isEmpty
    }
    
    private var categories: [String] {
        let allCategories = Set(viewModel.menuItems.map { $0.category })
        return allCategories.sorted().filter { shouldShowCategory($0) }
    }
    
    private var filteredItems: [MenuItem] {
        guard let selectedCategory = selectedCategory else {
            return viewModel.menuItems
        }
        return viewModel.menuItems.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类选择器
            CategorySelector(
                categories: categories,
                selectedCategory: $selectedCategory
            )
            
            // 菜单项列表
            MenuItemsList(items: filteredItems)
        }
        .navigationTitle("翻译结果")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 将分类选择器抽取为单独的视图
private struct CategorySelector: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: category == selectedCategory,
                        action: {
                            withAnimation {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// 将分类按钮抽取为单独的视图
private struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                )
        }
    }
}

// 将菜单项列表抽取为单独的视图
private struct MenuItemsList: View {
    let items: [MenuItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    MenuItemRow(item: item)
                }
            }
            .padding()
        }
    }
}

// 将菜单项行抽取为单独的视图
private struct MenuItemRow: View {
    let item: MenuItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.translation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let price = item.price {
                    Text("¥\(price)")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview("分类选择器") {
    CategorySelector(
        categories: ["分类1", "分类2", "分类3"],
        selectedCategory: .constant("分类1")
    )
}

#Preview("分类按钮") {
    VStack {
        CategoryButton(
            category: "测试分类",
            isSelected: true,
            action: {}
        )
        CategoryButton(
            category: "测试分类",
            isSelected: false,
            action: {}
        )
    }
}

#Preview("菜单项列表") {
    MenuItemsList(items: [
        MenuItem(
            id: "1",
            name: "Test Item 1",
            translation: "测试项目1",
            price: 100,
            category: "测试分类"
        ),
        MenuItem(
            id: "2",
            name: "Test Item 2",
            translation: "测试项目2",
            price: nil,
            category: "测试分类"
        )
    ])
}

#Preview("菜单项行") {
    VStack {
        MenuItemRow(item: MenuItem(
            id: "1",
            name: "Test Item 1",
            translation: "测试项目1",
            price: 100,
            category: "测试分类"
        ))
        MenuItemRow(item: MenuItem(
            id: "2",
            name: "Test Item 2",
            translation: "测试项目2",
            price: nil,
            category: "测试分类"
        ))
    }
    .padding()
}

#Preview("完整翻译视图") {
    NavigationStack {
        TranslatedMenuView(viewModel: {
            let viewModel = MenuTranslationViewModel()
            viewModel.menuItems = [
                MenuItem(
                    id: "1",
                    name: "Test Item 1",
                    translation: "测试项目1",
                    price: 100,
                    category: "分类1"
                ),
                MenuItem(
                    id: "2",
                    name: "Test Item 2",
                    translation: "测试项目2",
                    price: nil,
                    category: "分类2"
                )
            ]
            return viewModel
        }())
    }
} 
