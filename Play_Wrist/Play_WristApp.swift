import SwiftUI
import FirebaseCore

#if os(iOS)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // 앱 종료 시 WebSocket 연결 해제
    print("🔌 [AppDelegate] 앱 종료 - WebSocket 연결 해제")
    // RoomViewModel이 싱글톤이 아니므로 여기서 직접 처리하지 않고
    // NotificationCenter를 통해 각 뷰에서 처리하도록 함
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    print("📱 [AppDelegate] 앱이 백그라운드로 전환됨")
    // NotificationCenter를 통해 각 뷰에서 처리
  }
}
#endif

@main
struct YourApp: App {
  #if os(iOS)
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  #endif


  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
