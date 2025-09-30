import SwiftUI

@main
struct YourWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    _ = WCSessionManager.shared
                }
        }
    }
}
