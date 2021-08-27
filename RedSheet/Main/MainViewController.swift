//
//  MainViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/04/03.
//

import UIKit

class MainViewController: UIViewController {
    
    // アプリアイコンの画像
    @IBOutlet var appIconImageView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    // 画面が表示されたら
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        // アニメーションして遷移する
//        UIView.animate(withDuration: 0.4,
//                       animations: {
//                        
//                        //
//                        self.appIconImageView.transform = CGAffineTransform(rotationAngle: -120 * .pi / 180)
//                        
//                       })
//        
//        // アニメーションして遷移する
//        UIView.animate(withDuration: 0.1,
//                       delay: 0.4,
//                       animations: {
//                        
//                        self.appIconImageView.transform = .identity
//                        
//                       })
//        
//        // アニメーションして遷移する
//        UIView.animate(withDuration: 0.15,
//                       delay: 0.5,
//                       animations: {
//                        
//                        //
//                        self.appIconImageView.transform = CGAffineTransform(rotationAngle: 179.999 * .pi / 180)
//                        
//                        
//                       })
//        
//        
//        // アニメーションして遷移する
//        UIView.animate(withDuration: 0.15,
//                       delay: 0,
//                       animations: {
//                        
//                        //
//                        self.appIconImageView.transform = CGAffineTransform(rotationAngle: 179.999 * .pi / 180)
//                        
//                        
//                       }, completion: { _ in
//                        
//                        //遷移
//                        let rootSB = UIStoryboard(name: "Root", bundle: nil)
//                        let rootVC = rootSB.instantiateViewController(identifier: "root")
//                        
//                        rootVC.modalPresentationStyle = .fullScreen
//                        
//                        
//                        self.present(rootVC, animated: false, completion: {
//                        })
//                        
//                       })
        
    }
    
}
