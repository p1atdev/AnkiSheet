//
//  SideColorTableViewCell.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/16.
//

import UIKit

class SideColorTableViewCell: UITableViewCell {
    
    /// 自身の色を表すビュー
    @IBOutlet weak var selfColorView: UIView!
    
    /// 枠のビュー
    @IBOutlet weak var frameView: UIView!
    
    /// プラスボタンの画像
    @IBOutlet weak var plusImageView: UIImageView!
    
    /// チェックマークの画像
    @IBOutlet weak var checkMarkImageView: UIImageView!
    
    /// 追加ボタンかどうか
    var isAddButton: Bool = false
    
    /// このシートが選択されているかいないか
    var isThisSheetEnabled: Bool = false
    
    /// シートの対象の色
    var targetColor: UIColor = UIColor.red
    
    /// 色の厳しさ
    var colorTolerance: CGFloat = 0.6
    
    /// 自身のシート
    var sheet = Sheet()

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    //選択されたら
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    //再利用される前に
    override func prepareForReuse() {
        
        isAddButton = false
            
        plusImageView.isHidden = false
        
        selfColorView.isHidden = false
        frameView.isHidden = false
        
        isThisSheetEnabled = false
        
        //色をつける //多分これいらない
//        selfColorView.backgroundColor = targetColor
//        frameView.backgroundColor = targetColor
        
        //角丸
        selfColorView.layer.cornerRadius = min(8, self.frame.width / 10)
        frameView.layer.cornerRadius = min(16, self.frame.width / 8)
        
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        //MARK: 三角形を描画する
        drawTriangle(sheet: sheet)
    }
    
    /// データをセット
    func setData(sheetData: Sheet) {
        //シート
        self.sheet = sheetData
        
        //色
        targetColor = UIColor(hex: sheetData.colorHex)
        
        //厳しさ
        colorTolerance = CGFloat(sheetData.tolerance)
        
        //色をつける
        selfColorView.backgroundColor = targetColor
        frameView.backgroundColor = targetColor
        
        //マスク
        selfColorView.layer.masksToBounds = true
        
        //チェックマークをつけるとか
        checkMarkImageView.isHidden = !isThisSheetEnabled
        
        //角丸
        selfColorView.layer.cornerRadius = min(8, self.frame.width / 10)
        frameView.layer.cornerRadius = min(16, self.frame.width / 8)
        
        plusImageView.isHidden = true
    }
    
    /// 追加ボタン
    func createAddButton() {
        isAddButton = true
        
        selfColorView.isHidden = true
        frameView.isHidden = true
        
        checkMarkImageView.isHidden = true
        
    }
    
    /** 選択状態にする
     - Parameters:
            - state: 選択されてるならtrue、選択されてなければfalse
     */
    func setSelectedState(state: Bool) {
        isThisSheetEnabled = state
        
        checkMarkImageView.isHidden = !state
        
    }
    
    /// 選択状態を切り替え
    func changeSelectedState() {
        if isThisSheetEnabled { //すでに選択されてたら
            checkMarkImageView.isHidden = true
        } else { // 選択されてなかったら
            checkMarkImageView.isHidden = false
        }
        
        //更新
        isThisSheetEnabled = !isThisSheetEnabled
        
    }
    
    //MARK:  三角形を描画する
    func drawTriangle(sheet: Sheet) {
        
        let insteadColor: UIColor = UIColor(hex: sheet.insteadColorHex)
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
        frameView.backgroundColor = targetColor
         
        // レイヤーを一度削除
        self.selfColorView.layer.sublayers?.removeAll()
        //レイヤーを追加
        self.selfColorView.layer.addSublayer(triangleLayer)
        
    }
}
