import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // This app does not use UIKit/Flutter state restoration. Disabling the
  // restoration callbacks avoids a Flutter assertion when the Simulator
  // destroys the scene during app termination.
  override func application(
    _ application: UIApplication,
    shouldSaveSecureApplicationState coder: NSCoder
  ) -> Bool {
    return false
  }

  override func application(
    _ application: UIApplication,
    shouldRestoreSecureApplicationState coder: NSCoder
  ) -> Bool {
    return false
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let ocrChannel = FlutterMethodChannel(
      name: "cwms_mobile/vision_ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    ocrChannel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.recognizeText(at: path, result: result)
    }
  }

  private func recognizeText(at path: String, result: @escaping FlutterResult) {
    let imageUrl = URL(fileURLWithPath: path)
    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
        return
      }

      let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
      let recognized = observations.compactMap { observation -> [String: Any]? in
        guard let candidate = observation.topCandidates(1).first else { return nil }
        return [
          "text": candidate.string,
          "confidence": candidate.confidence,
          "x": observation.boundingBox.origin.x,
          "y": observation.boundingBox.origin.y,
          "width": observation.boundingBox.size.width,
          "height": observation.boundingBox.size.height
        ]
      }
      result(recognized)
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["en-US"]

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try VNImageRequestHandler(url: imageUrl, options: [:]).perform([request])
      } catch {
        result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
      }
    }
  }
}
