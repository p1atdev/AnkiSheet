//
//  CreditViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/22.
//

import UIKit

class CreditViewController: UIViewController {
    
    //アイコン
    @IBOutlet weak var iconImageView: UIImageView!
    
    //グラデーションビュー
    @IBOutlet weak var gradientView: AnimateGradientView!
    
    // バージョンラベル
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //角丸
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 8
        
        //アニメーション
        gradientView.aniamte()
        
        //ビューを奥に
        self.view.sendSubviewToBack(gradientView)
        
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        versionLabel.text = "\(Localize.credit.version): \(version)"
    }
    
}
