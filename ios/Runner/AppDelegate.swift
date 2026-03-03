import Flutter
import UIKit
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyCi2oClQ7otjaZ8VaXj0nAeASA0m8chH-Y")
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
