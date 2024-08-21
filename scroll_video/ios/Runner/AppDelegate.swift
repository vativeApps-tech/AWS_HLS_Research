import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var videoProxyManager: VideoProxyManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let reverseProxyChannel = FlutterMethodChannel(name: "com.example/reverse_proxy",
                                                       binaryMessenger: controller.binaryMessenger)

        // Initialize the VideoProxyManager
        videoProxyManager = VideoProxyManager()

        reverseProxyChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }

            if call.method == "getProxyUrl" {
                guard let args = call.arguments as? [String: Any],
                      let urlString = args["url"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a URL", details: nil))
                    return
                }

                // Get the proxy URL using VideoProxyManager
                if let proxyUrl = self.videoProxyManager?.getProxyURL(originalURL: urlString) {
                    result(proxyUrl)
                } else {
                    result(FlutterError(code: "PROXY_ERROR", message: "Failed to generate proxy URL", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

//import Flutter
//import UIKit
//
//@UIApplicationMain
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//
//    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
//    let reverseProxyChannel = FlutterMethodChannel(name: "com.example/reverse_proxy",
//                                                    binaryMessenger: controller.binaryMessenger)
//
//    reverseProxyChannel.setMethodCallHandler({
//      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
//      if call.method == "getProxyUrl" {
//        guard let args = call.arguments as? [String: Any],
//              let urlString = args["url"] as? String else {
//          result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a URL", details: nil))
//          return
//        }
//
//        // Get the proxy URL from HLSProxyServerManager
//        if let proxyUrl = HLSProxyServerManager.shared.getProxyUrl(for: urlString) {
//          result(proxyUrl)
//        } else {
//          result(FlutterError(code: "PROXY_ERROR", message: "Failed to generate proxy URL", details: nil))
//        }
//      }
//        
//        
//        else {
//        result(FlutterMethodNotImplemented)
//      }
//    })
//
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}
