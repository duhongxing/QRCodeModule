//
//  ViewController.swift
//  QRCodeModule
//
//  Created by 杜红星 on 2021/7/5.
//

import UIKit

//ScanQRCodePreviewDelegate
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
//        let scanPreview = ScanQRCodePreview(view.bounds, .zero, .clear)
//        self.view .addSubview(scanPreview)
//        self.navigationController?.navigationBar.isHidden = true
//        print(scanPreview.rectFrame)
//        scanPreview.delegate = self
     
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.navigationController?.pushViewController(ScanQRcodeViewController(), animated: true)
    }
    
//    func handleTorchClick(isLight: Bool) {
//        print("xxx ===>>> \(isLight)")
//    }
    
    
}

