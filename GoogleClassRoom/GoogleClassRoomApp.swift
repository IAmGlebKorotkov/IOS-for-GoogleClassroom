
import SwiftUI

@main
struct GoogleClassRoomApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authVM.isLoggedIn {
                MainTabView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
    }
}
