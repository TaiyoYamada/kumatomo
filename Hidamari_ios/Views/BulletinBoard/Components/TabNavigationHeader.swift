import SwiftUI

struct TabNavigationHeader: View {
    let activeTab: TabType
    let selectedMunicipality: String?
    let onTabChange: (TabType) -> Void
    let onMunicipalityChange: (String) -> Void
    
    @State private var showMunicipalityPicker = false
    
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
                        showMunicipalityPicker = true
                    }
                )
                
                // フォロー中タブ
                TabButton(
                    title: "フォロー中",
                    isActive: activeTab == .following,
                    action: { onTabChange(.following) }
                )
            }
            .frame(height: 48)
            
            // Bottom border
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1)
        }
        .background(Color.white)
        .sheet(isPresented: $showMunicipalityPicker) {
            MunicipalityPickerView(
                selectedMunicipality: selectedMunicipality,
                onSelection: { municipality in
                    onMunicipalityChange(municipality)
                    showMunicipalityPicker = false
                }
            )
        }
    }
}

struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isActive ? Color(hex: "1DA1F2") : Color(hex: "6B7280"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                
                // Active indicator
                Rectangle()
                    .fill(isActive ? Color(hex: "1DA1F2") : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MunicipalityPickerView: View {
    let selectedMunicipality: String?
    let onSelection: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("市町村を検索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
                                    .font(.system(size: 16))
                                
                                if searchText.isEmpty && selectedRegion == nil {
                                    Text(municipality.region.rawValue)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                }
                            }
                            
                            Spacer()
                            
                            if selectedMunicipality == municipality.displayName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "1DA1F2"))
                            }
                        }
                        .padding(.vertical, 4)
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
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "6B7280"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "1DA1F2") : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TabNavigationHeader(
        activeTab: .all,
        selectedMunicipality: nil,
        onTabChange: { _ in },
        onMunicipalityChange: { _ in }
    )
}