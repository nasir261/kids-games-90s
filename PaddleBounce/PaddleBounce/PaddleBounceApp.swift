import SwiftUI

@main
struct PaddleBounceApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack { PongView() }
        }
    }
}
