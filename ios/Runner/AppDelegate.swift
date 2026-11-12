import Flutter
import UIKit
import UserNotifications
// Required for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show notifications while the app is in the foreground.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    WatchSync.shared.activate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Makes plugins available in the notification action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WatchSync") {
      WatchSync.shared.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ContactsPicker") {
      ContactsPicker.shared.register(with: registrar.messenger())
    }
  }
}
