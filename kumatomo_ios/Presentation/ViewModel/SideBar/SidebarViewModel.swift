import Foundation
import Observation
import Resolver

@MainActor
@Observable
final class SidebarViewModel {
    @ObservationIgnored @Injected var signOutUseCase: SignOutUseCase

    func signOut() async {
        do {
            try await signOutUseCase.execute()
        } catch {
            // Silently ignore for now; surface via state if needed later
            #if DEBUG
            print("[SidebarViewModel] Sign out failed: \(error)")
            #endif
        }
    }
}

