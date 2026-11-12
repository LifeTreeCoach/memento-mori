import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// Re-sends the widget inputs to the Apple Watch whenever the app comes to the foreground.
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    WatchSync.shared.sync()
  }
}
