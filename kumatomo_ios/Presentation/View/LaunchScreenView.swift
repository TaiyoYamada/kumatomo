import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        VStack {
            Image("LaunchImage")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
