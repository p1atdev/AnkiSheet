//
//  EditColorPupupTableViewCell.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/07/20.
//

import UIKit

class EditColorPupupTableViewCell: UITableViewCell {
    
    /// フレームのビュー
    @IBOutlet weak var frameView: UIView!
    
    /// targetColorのビュー
    @IBOutlet weak var colorView: UIView!
    
    /// フィルターの名前のラベル
    @IBOutlet weak var nameLable: UILabel!
    
    /// プラスのイメージビュー
    @IBOutlet weak var plusImageView: UIImageView!
    
    
    
    /// セル識別子
    static var identifier: String { String(describing: self) }
    static var nib: UINib { UINib(nibName: String(describing: self), bundle: nil) }
    
    /// フィルター
    private var filter: FilterModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        drawColorView(filter)
        
    }
    
    /// データのセット
    func setData(filter: FilterModel) {
        self.filter = filter
        
        // 角丸
        adjustCorner()
        
        // カラービューを描画
        drawColorView(filter)
        
        // ラベルのセットアップ
        setupLabel(filter)
    }
    
    /// カラーの描画
    private func drawColorView(_ filter: FilterModel) {
        
        frameView.backgroundColor = filter.targetColor
        colorView.backgroundColor = filter.targetColor
        //マスク
        colorView.layer.masksToBounds = true
        
        //三角形の描画
        let insteadColor: UIColor = filter.insteadColor
        /* --- 三角形を描画 ---*/
        let triangleLayer = CAShapeLayer.init()
        let triangleFrame = colorView.frame
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
         
        // レイヤーを一度削除
        self.colorView.layer.sublayers?.removeAll()
        //レイヤーを追加
        self.colorView.layer.addSublayer(triangleLayer)
        
        
    }
    
    /// 角丸の調整
    private func adjustCorner() {
        
        colorView.layer.cornerRadius = min(2, self.frame.width / 6)
        frameView.layer.cornerRadius = min(4, self.frame.width / 4)
        
    }
    
    /// ラベルのセットアップ
    private func setupLabel(_ filter: FilterModel) {
        
        nameLable.text = filter.name
        
    }
}
