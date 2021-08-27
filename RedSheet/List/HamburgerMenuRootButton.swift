//
//  HamburgerMenuRootButton.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/25.
//

import UIKit

/// ハンバーガーメニューのルートのボタン
class HamburgerMenuRootButton: UIButton {
    
    /// プラスのレイヤー
    private let plusMarkLayer = CAShapeLayer()
    
    /// 回転のトランスフォーム
    private var transRotate = CGAffineTransform()
    
    // ボタンのパラメーター
    /// 内側の塗りつぶす色
    var fillColor: CGColor = UIColor.systemBlue.cgColor
    
    /// 枠線の色
    var lineColor: CGColor = UIColor.tertiarySystemBackground.cgColor
    
    /// 枠線の太さ
    var lineWidth: CGFloat = Screen.shortLength / 128
    
    /// 影をつけるかどうか
    var isShadowEnabled: Bool = true
    
    /// プラスボタンかどうか
    var isPlusButton: Bool = false
    
    /// 表示する画像
    var image: UIImage? = nil
    
    /// 画像の色
    var imageColor: UIColor = .white
    
    /// カスタムのレイヤー
    var customLayer: CALayer?
    
    /// 描画ずみかどうか
    private var isDrawn: Bool = false
    
    /// 描画
    override func draw(_ rect: CGRect) {
        
        //すでに描画ずみならすぐ返る
        if isDrawn { return }
        
        //自身の縦と横の長さ
        ///たて
        let buttonHeight: CGFloat = self.layer.frame.height
        ///横
        let buttonWidth: CGFloat = self.layer.frame.width
        
        /// 背景の円
        let backgroundOval = CAShapeLayer()
        backgroundOval.strokeColor = lineColor
        backgroundOval.fillColor = fillColor
        backgroundOval.lineWidth = lineWidth
        backgroundOval.path = UIBezierPath(ovalIn: CGRect(x: 4,
                                                          y: 4,
                                                          width: buttonWidth - 8,
                                                          height: buttonHeight - 8)).cgPath
        
        //影をつける
        if isShadowEnabled {
            
            backgroundOval.shadowPath = UIBezierPath(ovalIn: .init(x: 4,
                                                                   y: 4,
                                                                   width: buttonWidth,
                                                                   height: buttonHeight)).cgPath
            backgroundOval.shadowColor = UIColor.black.cgColor
            backgroundOval.shadowRadius = 4
            backgroundOval.shadowOpacity = 0.1
            
        }
        
        self.layer.addSublayer(backgroundOval)
        
        
        //プラスを描画
        if isPlusButton {
            /// 縦のレイヤー
            let verRectLayer = CAShapeLayer()
            /// 横のレイヤー
            let horRectLayer = CAShapeLayer()
            
            //　角丸四角を描画
            verRectLayer.path = UIBezierPath(roundedRect: CGRect(x: buttonWidth / 2 - (buttonWidth / 20),
                                                                 y: buttonHeight / 4,
                                                                 width: buttonWidth / 10,
                                                                 height: buttonHeight / 2),
                                             cornerRadius: buttonWidth / 10 / 2).cgPath
            //　角丸四角を描画
            horRectLayer.path = UIBezierPath(roundedRect: CGRect(x: buttonWidth / 4,
                                                                 y: buttonHeight / 2 - (buttonHeight / 20),
                                                                 width: buttonWidth / 2,
                                                                 height: buttonHeight / 10),
                                             cornerRadius: buttonHeight / 10 / 2).cgPath
            
            //色の指定
            verRectLayer.fillColor = UIColor.tertiarySystemBackground.cgColor
            horRectLayer.fillColor = UIColor.tertiarySystemBackground.cgColor
            
            
            //セットして描画
            plusMarkLayer.addSublayer(verRectLayer)
            plusMarkLayer.addSublayer(horRectLayer)
            
            //サブビューに追加
            self.layer.addSublayer(plusMarkLayer)
            
        }
        
        //画像を表示
        
        if image != nil {
            /// 画像レイヤー
            let imageLayer = CALayer()
            
            //サイズを指定
            imageLayer.frame = CGRect(x: self.frame.width / 4,
                                      y: self.frame.height / 4,
                                      width: self.frame.width / 2,
                                      height: self.frame.height / 2)
            
            //マスクする画像をセット
            imageLayer.contents = image?.cgImage
            imageLayer.contentsGravity = CALayerContentsGravity.resizeAspect
            
            ///画像をマスクするレイヤー
            let imageMaskLayer = CALayer()
            imageMaskLayer.frame = self.layer.bounds
            imageMaskLayer.mask = imageLayer
            
            imageMaskLayer.backgroundColor = imageColor.cgColor
            
            //追加
            self.layer.addSublayer(imageMaskLayer)

        }
        
        //カスタムレイヤーがあるなら
        if customLayer != nil {
            self.layer.addSublayer(customLayer!)
        }
        
        //描画済みフラグをオンにする
        isDrawn = true
        
    }
    
    
    /// 回転する
    func rotate(angle: CGFloat) {
        
        /// 回転のラジアン
        let rad: CGFloat = angle * CGFloat.pi / 180
        
        //角度をセット
        transRotate = CGAffineTransform(rotationAngle: rad)
        
        //アニメーション
        UIView.animate(withDuration: 0.2, animations: {
            
            //回転
            self.transform = self.transRotate
            
        })
        
    }
}
