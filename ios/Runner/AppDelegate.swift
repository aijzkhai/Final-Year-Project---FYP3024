// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let timerChannel = FlutterMethodChannel(name: "com.example.pomodoro_app/timer",
                                      binaryMessenger: controller.binaryMessenger)
    
    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        print("Notification permission granted: \(granted)")
    }
    
    timerChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
        case "playSound":
          AudioServicesPlaySystemSound(1007) // Default notification sound
          result(nil)
        case "showNotification":
          guard let args = call.arguments as? [String: Any],
                let title = args["title"] as? String,
                let body = args["body"] as? String else {
              result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
              return
          }
          
          self.showNotification(title: title, body: body)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func showNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error showing notification: \(error)")
      }
    }
  }
}