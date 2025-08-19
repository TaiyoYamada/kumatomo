import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        VStack {
            Image("LaunchImage")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
