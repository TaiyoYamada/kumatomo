import SwiftUI

struct TabNavigationHeader: View {
    let activeTab: TabType
    let selectedMunicipality: String?
    let onTabChange: (TabType) -> Void
    let onMunicipalityChange: (String) -> Void
    
    @State private var sheetDestination: SheetDestination?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveHeaderHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 48
        case .large:
            return 52
        case .xLarge:
            return 56
        case .xxLarge:
            return 60
        case .xxxLarge:
            return 64
        default:
            return 48
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 熊本県全体タブ
                TabButton(
                    title: "熊本県全体",
                    isActive: activeTab == .all,
                    action: { onTabChange(.all) }
                )
                
                // 市町村タブ
                TabButton(
                    title: selectedMunicipality ?? "市町村",
                    isActive: activeTab == .municipality,
                    action: {
                        onTabChange(.municipality)
                        sheetDestination = .municipalityPicker(selected: selectedMunicipality) { municipality in
                            onMunicipalityChange(municipality)
                            sheetDestination = nil
                        }
                    }
                )
                
                // フォロー中タブ
                TabButton(
                    title: "フォロー中",
                    isActive: activeTab == .following,
                    action: { onTabChange(.following) }
                )
            }
            .frame(height: adaptiveHeaderHeight)
            
            // Bottom border
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1)
        }
        .background(Color.white)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("タブナビゲーション")
        .accessibilityIdentifier("tab_navigation_header")
        .withSheetRouter(sheet: $sheetDestination)
    }
}

struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 13
        case .medium:
            return 15
        case .large:
            return 16
        case .xLarge:
            return 17
        case .xxLarge:
            return 18
        case .xxxLarge:
            return 20
        default:
            return 15
        }
    }
    
    private var adaptiveHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 46
        case .large:
            return 48
        case .xLarge:
            return 50
        case .xxLarge:
            return 52
        case .xxxLarge:
            return 56
        default:
            return 46
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: adaptiveFontSize, weight: .medium))
                    .foregroundColor(isActive ? Color(hex: "1DA1F2") : Color(hex: "6B7280"))
                    .frame(maxWidth: .infinity)
                    .frame(height: adaptiveHeight)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                // Active indicator
                Rectangle()
                    .fill(isActive ? Color(hex: "1DA1F2") : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 44) // Ensure minimum touch target
        .accessibilityLabel(title)
        .accessibilityHint(isActive ? "選択中のタブ" : "タップして\(title)タブに切り替え")
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityIdentifier("tab_button_\(title.replacingOccurrences(of: " ", with: "_"))")
    }
}

struct MunicipalityPickerView: View {
    let selectedMunicipality: String?
    let onSelection: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var searchText = ""
    @State private var selectedRegion: Region? = nil
    
    private var filteredMunicipalities: [Municipality] {
        let allMunicipalities = Municipality.allCases
        
        if !searchText.isEmpty {
            return allMunicipalities.filter { $0.displayName.contains(searchText) }
        }
        
        if let region = selectedRegion {
            return region.municipalities
        }
        
        return allMunicipalities
    }
    
    private var adaptiveFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 17
        case .xLarge:
            return 18
        case .xxLarge:
            return 20
        case .xxxLarge:
            return 22
        default:
            return 16
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                    
                    TextField("市町村を検索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: adaptiveFontSize))
                        .accessibilityLabel("市町村検索")
                        .accessibilityHint("市町村名を入力して検索")
                        .accessibilityIdentifier("municipality_search_field")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
                
                // Region filter (if no search text)
                if searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            RegionFilterButton(
                                title: "すべて",
                                isSelected: selectedRegion == nil,
                                action: { selectedRegion = nil }
                            )
                            
                            ForEach(Region.allCases, id: \.self) { region in
                                RegionFilterButton(
                                    title: region.rawValue,
                                    isSelected: selectedRegion == region,
                                    action: { selectedRegion = region }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .accessibilityLabel("地域フィルター")
                    .accessibilityIdentifier("region_filter_scroll")
                }
                
                // Municipality list
                List(filteredMunicipalities, id: \.self) { municipality in
                    Button(action: {
                        onSelection(municipality.displayName)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(municipality.displayName)
                                    .foregroundColor(.primary)
                                    .font(.system(size: adaptiveFontSize))
                                
                                if searchText.isEmpty && selectedRegion == nil {
                                    Text(municipality.region.rawValue)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: adaptiveFontSize - 4))
                                }
                            }
                            
                            Spacer()
                            
                            if selectedMunicipality == municipality.displayName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "1DA1F2"))
                                    .accessibilityLabel("選択中")
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(minHeight: 44) // Ensure minimum touch target
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("市町村を選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RegionFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 15
        case .xLarge:
            return 16
        case .xxLarge:
            return 17
        case .xxxLarge:
            return 18
        default:
            return 14
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: adaptiveFontSize, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "6B7280"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "1DA1F2") : Color.gray.opacity(0.1))
                .cornerRadius(20)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 44) // Ensure minimum touch target
    }
}
