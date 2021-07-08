//
//  ScanQRcodeViewController.swift
//  QRCodeModule
//
//  Created by 杜红星 on 2021/7/5.
//

import UIKit
import AVFoundation

class ScanQRcodeViewController: UIViewController {
    
    var qrcodeManager: ScanQRCodeManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        // Do any additional setup after loading the view.
        let qrcodePreview: ScanQRCodePreview = ScanQRCodePreview(view.bounds)
        let qrcodeManager: ScanQRCodeManager = ScanQRCodeManager(qrcodePreview, self) { [weak self] in
            self?.qrcodeManager?.startScaning(scanResult: { value in
                print(value)
            })
        }
        self.qrcodeManager = qrcodeManager
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.qrcodeManager?.stopScaning()
    }
}

