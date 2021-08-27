//
//  EditDocViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/18.
//

import UIKit
import Hero
import RealmSwift

class EditDocViewController: UIViewController {
    
    /// ドキュメントの画像
    @IBOutlet weak var documentImageView: UIImageView!
    
    /// ドキュメントのタイトルのフィールド
    @IBOutlet weak var documentTitleField: UITextField!
    
    /// タイトルの親ビュー
    @IBOutlet weak var titleFieldParentView: UIView!
    
    /// 保存ボタン
    @IBOutlet weak var saveButton: UIButton!
    
    /// 表示中のドキュメント
    var selfDocument: Document?
    
    /// リストのデリゲート
    var delegate: ListCollectionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        //UIを構築
        documentImageView.image = UIImage(data: selfDocument!.imageData)!
        documentTitleField.text = selfDocument?.title
        
        titleFieldParentView.layer.cornerRadius = 8.0
        
        saveButton.layer.cornerRadius = 4.0
        
        documentTitleField.clearButtonMode = .whileEditing
        
        //ブラー
        // ブラーエフェクトを作成
        let blurEffect = UIBlurEffect(style: .regular)
        
        // ブラーエフェクトからエフェクトビューを作成
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        // エフェクトビューのサイズを画面に合わせる
        visualEffectView.frame = self.view.frame
        
        // エフェクトビューを初期viewに追加
        self.view.addSubview(visualEffectView)
        
        //一番後ろに
        self.view.sendSubviewToBack(visualEffectView)
        
        //全てのalphaを0に
        self.view.alpha = 0
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //アニメーションでalphaを1に
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.view.alpha = 1.0
            
        })
        
    }
    
    
    /// 外側の方をタップした
    @IBAction func outsideTapped(_ sender: Any) {
        
        //もし編集中ならキーボードを閉じる
        if documentTitleField.isEditing {
            
            //閉じる
            documentTitleField.endEditing(false)
            
        } else {
            
            //そうでなかったら帰る
            //保存せずに帰る
            //alphaを0に
            UIView.animate(withDuration: 0.4, animations: {
                
                self.view.alpha = 0.0
                
            }, completion: { _ in
                
                //帰る
                self.dismiss(animated: false, completion: nil)
                
            })
            
        }
        
    }
    
    /// 保存
    @IBAction func saveButtonTapped(_ sender: Any) {
        
        //データを更新してから戻る
        let realm = try! Realm()
        
        try! realm.write {
            selfDocument?.title = documentTitleField.text!
        }
        
        //親のテーブルを更新
        delegate?.reloadCollection()
        
        //alphaを0に
        UIView.animate(withDuration: 0.4, animations: {
            
            self.view.alpha = 0.0
            
        }, completion: { _ in
            
            //帰る
            self.dismiss(animated: false, completion: nil)
            
        })
    }
    
    
    /// データをセット
    func setData(document doc: Document) {
        
        self.selfDocument = doc
        
    }

}
