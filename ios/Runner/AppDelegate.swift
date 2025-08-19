import UIKit
import Flutter
import FirebaseMessaging
//import google_maps_flutter_ios


@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
             if #available(iOS 10.0, *) {
               UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
             }
        //    GMSServices.provideAPIKey("AIzaSyARGfWwXIIJwhHfMrxJntOuBBjWxieN5Ng")
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

      @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                       willPresent notification: UNNotification, 
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound, .badge])
  }
    
}
