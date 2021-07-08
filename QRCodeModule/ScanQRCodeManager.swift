//
//  ScanQRCodeManager.swift
//  QRCodeModule
//
//  Created by 杜红星 on 2021/7/6.
//

import Foundation
import AVFoundation
import UIKit

public typealias ScanQRCodeCompletion = (String) -> Void
public typealias InitialSuccessCompletion = () -> Void

class ScanQRCodeManager: NSObject {
    
    open var preView: ScanQRCodePreview?
    open var viewController: UIViewController?
    open var scanResult: ScanQRCodeCompletion?
    open var autoStopScan: Bool = true
    
   private let session: AVCaptureSession = AVCaptureSession()
   
    init(_ preView: ScanQRCodePreview?, _ viewController: UIViewController?, _ completion:InitialSuccessCompletion?) {
        super.init()
        
        self.preView = preView
        self.viewController = viewController
        self.autoStopScan = true
        
        // 添加视图 设置代理
        guard let preview = self.preView else { return }
        guard let viewController = self.viewController else { return }
        viewController.view.addSubview(preview)
        preview.delegate = self
        
        // 获取摄像机权限
        requestAccess(completion)
        // 添加监听
        addNotification()
        // 添加手势
        addGestureRecognizer()
    }
    
    //MARK: -- Private Method
    
    
    /// 请求相机权限 初始化CaptureSession
    /// - Parameter completion: 初始化成功操作
    private func requestAccess(_ completion:InitialSuccessCompletion?) {
        // 申请权限
        AVCaptureDevice.requestAccess(for: .video) { [self] granted in
            if granted {
                // 授权成功
                DispatchQueue.main.async {
                    // 初始化捕获会话
                    self.configSession(completion)
                }
                
                print("授权成功")
                
            } else {
                // 授权失败
                print("授权失败")
            }
        }
    }
        
    private func configSession(_ completion:InitialSuccessCompletion?) {
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return  }
    
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: .main)
        
        
        if UIScreen.main.bounds.size.height < 500 {
            session.sessionPreset = .vga640x480
        } else {
            session.sessionPreset = .high
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            if output.availableMetadataObjectTypes.contains(.qr) &&
                output.availableMetadataObjectTypes.contains(.code128) &&
                output.availableMetadataObjectTypes.contains(.ean13) &&
                output.availableMetadataObjectTypes.contains(.code93) {
                output.metadataObjectTypes = [ .qr, .code128, .ean13, .code93 ]
            }
        }
        
        try? captureDevice.lockForConfiguration()
        if captureDevice.isFocusPointOfInterestSupported &&
            captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            captureDevice.focusMode = .continuousAutoFocus
        }
        captureDevice.unlockForConfiguration()
        
        configPreviewLayer()
        
        guard let completion = completion else { return  }
        completion()
        
        //输入按钮显示状态
        self.preView?.inputSNButton?.isHidden = false
        
        // 设置扫码区域
        configScanArea(output: output)
    }
    
    private func configScanArea(output: AVCaptureMetadataOutput?) {
        let windowSize: CGSize = UIScreen.main.bounds.size;
        let scanSize: CGSize = CGSize(width: windowSize.width*3/4, height: windowSize.height*3/4)
        var scanRect: CGRect = CGRect(x: (windowSize.width-scanSize.width)/2, y: (windowSize.height-scanSize.height)/2, width: scanSize.width, height: scanSize.height)
        scanRect = CGRect(x: scanRect.origin.y/windowSize.height, y: scanRect.origin.x/windowSize.width, width: scanRect.size.height/windowSize.height, height: scanRect.size.height/windowSize.height)
        output?.rectOfInterest = scanRect
    }
    
    private func configPreviewLayer() {
        guard let preview = self.preView else { return }
        let preViewLayer = AVCaptureVideoPreviewLayer(session: session)
        preViewLayer.frame = preView?.layer.bounds ?? .zero
        preViewLayer.videoGravity = .resizeAspectFill
        preview.layer.insertSublayer(preViewLayer, at: 0)
    }
    
    
    /// 手电筒状态
    /// - Parameter on: on/off
    private func switchTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        let torchMode: AVCaptureDevice.TorchMode = on ? .on : .off
        if device.hasFlash && device.hasTorch && torchMode != device.torchMode {
            try? device.lockForConfiguration()
            device.torchMode = torchMode
            device.unlockForConfiguration()
        }
    }
    
    /// 监听前后台切换
    private func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    
    /// 进入前台操作
    @objc func didBecomeActive() {
        print("didBecomeActive")
    }
    
    
    /// 进入后台操作
    @objc func didEnterBackground() {
        print("didEnterBackground")
        // 关闭手电筒
        switchTorch(on: false)
        // 修改手电筒按钮状态
        self.preView?.torchButton?.isSelected = false
    }
    
    
    /// 添加手势
    private func addGestureRecognizer() {
        let pinchGesture: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchEvent(gesture:)))
        self.preView?.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePinchEvent(gesture: UIPinchGestureRecognizer) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        var minZoomFactor: CGFloat = 1.0
        var maxZoomFactor: CGFloat = device.activeFormat.videoMaxZoomFactor
        
        if #available(iOS 11.0, *) {
            minZoomFactor = device.minAvailableVideoZoomFactor
            maxZoomFactor = device.maxAvailableVideoZoomFactor
        }
        
        var lastZoomFactor: CGFloat = 1.0
        
        if gesture.state == .began {
            lastZoomFactor = device.videoZoomFactor
        } else if gesture.state == .changed {
            var zoomFactor: CGFloat = lastZoomFactor * gesture.scale
            zoomFactor = CGFloat(fmaxf(Float(fmin(zoomFactor, maxZoomFactor)), Float(minZoomFactor)))
            try? device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        }
    }
    
    //MARK: -- Public Method
    
    /// 开启扫描
    /// - Parameter scanResult: 返回结果
    func startScaning(scanResult: ScanQRCodeCompletion?) {
        session.startRunning()
        self.scanResult = scanResult
    }
    
    
    /// 停止扫描
    func stopScaning() {
        session.stopRunning()
    }
    
    func presentPhotoLibary(scanResult: ScanQRCodeCompletion?) {
        self.scanResult = scanResult
    }
    
}

//MARK: -- AVCaptureMetadataOutputObjectsDelegate
extension ScanQRCodeManager: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var stringValue: String?
        if metadataObjects.count > 0 {
            let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject
            stringValue = metadataObject?.stringValue
            if stringValue != nil {
                guard let scanResult = self.scanResult else { return }
                // 回传扫描结果
                scanResult("\(String(describing: stringValue))")
                if self.autoStopScan {
                    //停止扫描
                    stopScaning()
                }
            }
        }
        if self.autoStopScan {
            //停止扫描
            stopScaning()
        }
    }
}

extension ScanQRCodeManager: ScanQRCodePreviewDelegate {
    func handleTorchClick(isLight: Bool) {
        // 设置手电筒开关状态
        switchTorch(on: isLight)
    }
}
