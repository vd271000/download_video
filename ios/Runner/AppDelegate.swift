import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let galleryChannel = FlutterMethodChannel(
        name: "com.example.save_video/gallery",
        binaryMessenger: controller.binaryMessenger
      )

      galleryChannel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "saveVideoToGallery" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterError(
            code: "INVALID_ARGUMENT",
            message: "Missing video path",
            details: nil
          ))
          return
        }

        self?.saveVideoToGallery(path: path, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveVideoToGallery(path: String, result: @escaping FlutterResult) {
    guard FileManager.default.fileExists(atPath: path) else {
      result(FlutterError(
        code: "FILE_NOT_FOUND",
        message: "Video file does not exist",
        details: path
      ))
      return
    }

    let save = {
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAssetFromVideo(
          atFileURL: URL(fileURLWithPath: path)
        )
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(FlutterError(
              code: "SAVE_FAILED",
              message: error?.localizedDescription ?? "Could not save video",
              details: nil
            ))
          }
        }
      }
    }

    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        save()
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
          if newStatus == .authorized || newStatus == .limited {
            save()
          } else {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "PERMISSION_DENIED",
                message: "Photo library permission denied",
                details: nil
              ))
            }
          }
        }
      default:
        result(FlutterError(
          code: "PERMISSION_DENIED",
          message: "Photo library permission denied",
          details: nil
        ))
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        save()
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization { newStatus in
          if newStatus == .authorized {
            save()
          } else {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "PERMISSION_DENIED",
                message: "Photo library permission denied",
                details: nil
              ))
            }
          }
        }
      default:
        result(FlutterError(
          code: "PERMISSION_DENIED",
          message: "Photo library permission denied",
          details: nil
        ))
      }
    }
  }
}
