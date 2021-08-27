//
//  AnimateGradientView.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/22.
//

import UIKit

class AnimateGradientView: UIView,  CAAnimationDelegate {
    
    let gradientLayer = CAGradientLayer()
    
    // colorsプロパティを追加する。
    // 色の配列を用意。indexの順番にグラデーションが変化していくようにする。
    // https://designpieces.com/palette/instagram-new-logo-2016-color-palette/ の各色
    let colors: [CGColor] = [
        #colorLiteral(red: 0.007843137255, green: 0.4784313725, blue: 1, alpha: 1),
        #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),
        #colorLiteral(red: 0, green: 0.3142115794, blue: 0.9406329304, alpha: 1),
        #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1),
        #colorLiteral(red: 0.476841867, green: 0.5048075914, blue: 1, alpha: 1),
        #colorLiteral(red: 0.2078431373, green: 0.3371909005, blue: 0.9176470588, alpha: 1)
    ].map { $0.cgColor }
    
    // currentIndexプロパティを追加する。
    // 現在のグラデーションがcolorsのどのIndexであるかを保存する。
    // 右上から左下にかけて変化させていきたので、開始位置が終了位置より１つ上のIndexになるようにする
    var currentIndex = (start: 1, end: 0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        
        // 最初のcurrentIndexが設定されるように変更する
        gradientLayer.colors = [colors[currentIndex.start], colors[currentIndex.end]]
        
        gradientLayer.drawsAsynchronously = true
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func aniamte() {
        // 次の色が指定されるようにindexをそれぞれ１進める。
        // Indexが配列サイズを超えそうになったらまた0の位置からループされるように剰余計算をする。
        currentIndex = ((currentIndex.start + 1) % colors.count, (currentIndex.end + 1) % colors.count)
        
        let fromColors = gradientLayer.colors
        let anim = CABasicAnimation(keyPath: "colors")
        anim.fromValue = fromColors
        
        // １進めたIndexが設定されるように変更する
        anim.toValue =  [colors[currentIndex.start], colors[currentIndex.end]]
        
        anim.duration = 5
        
        // anim.fillMode = kCAFillModeForwards <- animationDidStopで終了状態の値を入れるのでこれはもういらない
        // anim.isRemovedOnCompletion = false <- animationDidStopで終了状態の値を入れるのでこれはもういらない
        
        // CAAnimationDelegateを設定する
        anim.delegate = self
        gradientLayer.add(anim, forKey: "colors")
    }
    
    // animationDidStopを新たに実装する。
    // CABasicアニメーションが完了したら、次のアニメーションが再帰的に呼ばれるようにして、永遠とアニメーションを行う
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        gradientLayer.colors = [colors[currentIndex.start], colors[currentIndex.end]]
        aniamte()
    }
    
}
