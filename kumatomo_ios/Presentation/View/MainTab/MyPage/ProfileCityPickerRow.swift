import SwiftUI

struct ProfileCityPickerRow: View {
    @Binding var selectedCity: City?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("出身地")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            Picker("出身地を選択", selection: $selectedCity) {
                Text("未選択")
                    .tag(nil as City?)

                ForEach(City.allCases, id: \.self) { city in
                    Text(city.displayName)
                        .tag(city as City?)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("熊本県内の市町村から選択してください")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ProfileCityPickerRow(selectedCity: .constant(.kumamoto))
        ProfileCityPickerRow(selectedCity: .constant(nil))
    }
}
