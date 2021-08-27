//
//  EditColorTableViewCell.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/18.
//

import UIKit
import SwipeCellKit


class EditColorTableViewCell: SwipeTableViewCell {
    
    /// 自身の色を表すビュー
    @IBOutlet weak var selfColorView: UIView!
    
    /// 枠のビュー
    @IBOutlet weak var frameView: UIView!
    
    /// 厳しさのビュー
    @IBOutlet weak var toleranceLabel: UILabel!
    
    /// 自身のシート
    var selfSheet: Sheet?
    
    /// ターゲットの色
    private var targetColor: UIColor = .clear
    
    /// 置き換える色
    private var insteadColor: UIColor = .clear
    
    /// 厳しさ
    private var tolerance: Float = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    /// データのセット
    func setData(sheet: Sheet) {
        
        self.selfSheet = sheet
        
        //MARK: UIの更新
        
        //色のセット
        targetColor = UIColor(hex: sheet.colorHex)
        insteadColor = UIColor(hex: sheet.insteadColorHex)
        tolerance = sheet.tolerance
        
        selfColorView.backgroundColor = targetColor
        
        //厳しさのセット
        toleranceLabel.text = String(Int(round(selfSheet!.tolerance * 100))) + " %"   //四捨五入してから
        
        //角丸
        selfColorView.layer.cornerRadius = 12
        frameView.layer.cornerRadius = 16
        
        //マスク
        selfColorView.layer.masksToBounds = true
        
        //右下の三角形を描画
        /* --- 三角形を描画 ---*/
        let triangleLayer = CAShapeLayer.init()
        let triangleFrame = selfColorView.frame
        triangleLayer.frame = triangleFrame
        
        // 三角形の中の色
        triangleLayer.fillColor = insteadColor.cgColor
         
        // 三角形を描画
        let triangleLine = UIBezierPath()
        triangleLine.move(to: .init(x: triangleFrame.size.width, y: 0))
        triangleLine.addLine(to: .init(x: triangleFrame.size.width,
                                       y: triangleFrame.size.height))
        triangleLine.addLine(to: .init(x: 0,
                                       y: triangleFrame.size.height))
        triangleLine.close()
        
        // 三角形を描画
        triangleLayer.path = triangleLine.cgPath
        frameView.backgroundColor = targetColor //枠線の色を変更
         
        //レイヤーを追加
        self.selfColorView.layer.addSublayer(triangleLayer)
        
    }
}
