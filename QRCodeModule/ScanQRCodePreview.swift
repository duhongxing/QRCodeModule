//
//  ScanQRCodePreview.swift
//  QRCodeModule
//
//  Created by 杜红星 on 2021/7/6.
//

import UIKit

protocol ScanQRCodePreviewDelegate: NSObjectProtocol {
    /// 处理手电筒按钮事件
    func handleTorchClick(isLight:Bool)
}


let kScreenW: CGFloat = UIScreen.main.bounds.size.width

class ScanQRCodePreview: UIView {
    
    var rectFrame: CGRect = .zero
    var scanView: UIImageView?
    var torchButton: UIButton?
    var inputSNButton: UIButton?
    
    var tipsLab: UILabel?
    
    
    weak var delegate: ScanQRCodePreviewDelegate?
    
    init(_ frame: CGRect, _ rectFrame: CGRect = .zero, _ rectColor: UIColor = .clear) {
        super.init(frame: frame)
        self.rectFrame = rectFrame
        addScanRectView()
        addTorchView()
        addTipsView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// 添加扫描框
    private func addScanRectView() {
        let orgin_x = designSize(53)
        let orgin_y = designSize(156)
        let width = designSize(254)
        let scanView = UIImageView(frame: CGRect(x: orgin_x, y: orgin_y, width: width, height: width))
        let imgSource = UIImage(named: "scan_rect.png")
        scanView.image = imgSource
        self.addSubview(scanView)
        self.rectFrame = scanView.frame
        self.scanView = scanView
    }
    
    
    /// 添加手电筒
    private func addTorchView() {
        let orgin_x = designSize(160)
        let orgin_y = designSize(437)
        let width = designSize(40)
        let torchButton = UIButton(frame: CGRect(x: orgin_x, y: orgin_y, width: width, height: width))
        torchButton.setImage(UIImage(named: "torch_unselected.png"), for: .normal)
        torchButton.setImage(UIImage(named: "torch_selected.png"), for: .selected)
        torchButton.addTarget(self, action: #selector(clickTorchButton(sender:)), for: .touchUpInside)
        self.addSubview(torchButton)
        self.torchButton = torchButton
    }
    
    
    /// 添加提示
    private func addTipsView() {
        let orgin_x = designSize(40)
        let orgin_y = designSize(560)
        let width = kScreenW - orgin_x * 2
        let height = designSize(20)
        let tipsLab = UILabel(frame: CGRect(x: orgin_x, y: orgin_y, width: width, height: height))
        tipsLab.text = "将二维码/条形码收入框内，即可扫描"
        tipsLab.textAlignment = .center
        tipsLab.textColor = .white
        self.addSubview(tipsLab)
        self.tipsLab = tipsLab
    }
    
    private func designSize(_ designNumber: CGFloat) -> CGFloat {
        let screenW: CGFloat = UIScreen.main.bounds.size.width
        let designW: CGFloat = 360
        return screenW * designNumber / designW
    }
    
    //MARK: -- Event handle
    
    @objc func clickTorchButton(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        guard let delegate = self.delegate else { return }
        delegate.handleTorchClick(isLight: sender.isSelected)
    }
    
}
