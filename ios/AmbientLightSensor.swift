import Foundation
import UIKit
import AVFoundation
import React

@objc(AmbientLightSensor)
class AmbientLightSensor: RCTEventEmitter, AVCaptureVideoDataOutputSampleBufferDelegate {
    let queue = DispatchQueue(label: "AmbientLightSensor")
    let eventName = "LightSensor"

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    private var isSetup = false
    private var isObserving = false

    override init() {
        super.init()

    }

    override func supportedEvents() -> [String]! {
        return ["LightSensor"]
    }
    
    @objc func hasLightSensor(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        resolve(true)
    }
    
    @objc func startLightSensor() -> Void {
        isObserving = true;

        if (!isSetup) {
          isSetup = true
          setupCaptureSession();
        }
    }
    
    @objc func stopLightSensor() -> Void {
        isObserving = false
    }

    // Private methods

    func setupCaptureSession() {
        guard let camera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first else { return }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(cameraInput)
            
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            captureSession.startRunning()
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if let metadata = CMGetAttachment(sampleBuffer, key: kCGImagePropertyExifDictionary, attachmentModeOut: nil) {
            if let FNumber = metadata["FNumber"] as? Double, let ExposureTime = metadata["ExposureTime"] as? Double, let ISOSpeedRatingsArray = metadata["ISOSpeedRatings"] as? [Double] {
                
                let CalibrationConstant = 1000.0
                
                let ISOSpeedRatings = ISOSpeedRatingsArray[0]
                let luminosity: Double = (CalibrationConstant * FNumber * FNumber) / (ExposureTime * ISOSpeedRatings)
                
                if (isObserving) {
                  sendEvent(withName: eventName, body: ["lightValue": luminosity])
                }
            }
        }
    }
    
}