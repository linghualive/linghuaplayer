import Flutter
import UIKit
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let audioOutputChannel = FlutterMethodChannel(
      name: "com.flamekit.flamekit/audio_output",
      binaryMessenger: controller.binaryMessenger
    )

    audioOutputChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "showRoutePicker":
        self?.showRoutePicker(controller: controller, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func showRoutePicker(controller: FlutterViewController, result: @escaping FlutterResult) {
    let routePickerView = AVRoutePickerView(frame: .zero)
    routePickerView.isHidden = true
    controller.view.addSubview(routePickerView)

    // Find the internal UIButton and trigger a tap to show the system picker
    for subview in routePickerView.subviews {
      if let button = subview as? UIButton {
        button.sendActions(for: .touchUpInside)
        break
      }
    }

    // Clean up after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      routePickerView.removeFromSuperview()
    }

    result(nil)
  }
}
