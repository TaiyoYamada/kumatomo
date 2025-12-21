import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        VStack {
            Image("LaunchImage")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
