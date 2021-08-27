//
//  ListCollectionViewCell.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import SnapKit
import DeviceKit
import RealmSwift

class ListCollectionViewCell: UICollectionViewCell {

    /// サムネの画像ビュー
    @IBOutlet weak var samuneImageView: UIImageView!
    
    /// タイトルのラベル
    @IBOutlet weak var titleLabel: UILabel!
    
    /// 背景のビュー
    @IBOutlet weak var background: UIView!
    
    /// 画像の後ろの影のビュー
    @IBOutlet weak var shadowView: UIView!
    
    /// PDFのとき、ページ数を表すラベル
    @IBOutlet weak var numberOfPageLabel: UILabel!
    
    /// 開いた回数をカウントする
    @IBOutlet weak var numberOfOpenedLabel: UILabel!
    
    /// 作成日のラベル
    @IBOutlet weak var createdDateLabel: UILabel!
    
    /// タイトルなどが入るビュー
    @IBOutlet weak var labelsView: UIView!
    
    /// フォルダーの時のサムネ
    @IBOutlet weak var folderThumbnailImageView: UIImageView!
    
    /// フォルダーのアッパーの画像
    @IBOutlet weak var folderUpperImageView: UIImageView!
    
    
    /// 自身の持つデータ
    var documentData: DocumentData!
    
    deinit {
        print("cell deinit")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //影
        Process.setShadow(view: shadowView,
                          shadowRadius: 4,
                          shadowOpacity: 0.2,
                          shadowOffset: .init(width: 2, height: 2))
        Process.setShadow(view: labelsView,
                          shadowRadius: 8,
                          shadowOpacity: 0.2,
                          shadowOffset: .init(width: 0, height: -16))
        
        /// ipadじゃなかったら
        if !Device.current.isPad {
            titleLabel.font = titleLabel.font.withSize(16.0)
        }
        
    }
    
    // レイアウト決定
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 再レイアウト
        //角丸
//        samuneImageView.layer.cornerRadius = 4.0
        background.layer.cornerRadius = 8.0
        background.clipsToBounds = true
        shadowView.layer.cornerRadius = 8.0
        numberOfPageLabel.layer.cornerRadius = 2.0
        numberOfPageLabel.layer.masksToBounds = true
        numberOfPageLabel.layer.maskedCorners = [.layerMinXMinYCorner,
                                                 .layerMinXMaxYCorner]
    
    }

    override func prepareForReuse() {
        folderUpperImageView.image = nil
        folderThumbnailImageView.image = nil
        samuneImageView.image = nil
    }
    
    /// データのセット
    func setData(documentData: Document) {
        
        self.documentData = documentData
        
        self.samuneImageView.image = UIImage(data: documentData.imageData)
        self.titleLabel.text = documentData.title != "" ? documentData.title : NSLocalizedString("document.default.title", comment: "No name document")
        self.numberOfOpenedLabel.text = "開いた回数: \(documentData.countOfOpened)"
        self.createdDateLabel.text = "作成日: \(documentData.createdDate)"
        self.folderThumbnailImageView.isHidden = true
        self.folderUpperImageView.isHidden = true
        
        switch documentData.type {
        case "pdf":
            numberOfPageLabel.isHidden = false
            
        default:
            numberOfPageLabel.isHidden = true
            
        }
    }
    
    /// データのセット
    func setData(folderData: Folder) {
        
        self.documentData = folderData
        
        let realm = try! Realm()
        let samePathObjects = realm.objects(Document.self).filter("parentPathID = %@", folderData.uid)
        let numberOfContents = samePathObjects.count
        
        self.titleLabel.text = folderData.title
        self.numberOfOpenedLabel.text = "\(numberOfContents) 項目"
        self.createdDateLabel.text = "作成日: \(folderData.createdDate)"
        self.folderThumbnailImageView.isHidden = false
        self.folderUpperImageView.isHidden = false
        
        // 適当に一枚画像を取得する
        let thumbnailImage: UIImage? = {
            if let firstObj = samePathObjects.first {
                return UIImage(data: firstObj.imageData)
            } else {
                return nil
            }
        }()
        
        // フォルダーの画像を取得して配置
        let (upper, lower): (UIImage, UIImage) = Process.getFolderImage(color: folderData.color)
        self.samuneImageView.image = lower
        self.folderThumbnailImageView.image = thumbnailImage
        self.folderUpperImageView.image = upper
        
        // 制約
        self.folderUpperImageView.snp.makeConstraints { make in
            make.top.equalTo(self)
                .offset(32)
            make.bottom.equalTo(samuneImageView)
            make.width.equalTo(samuneImageView)
            make.left.right.equalTo(samuneImageView)
        }
        
        numberOfPageLabel.isHidden = true
    }
    
    /// heroを有効化
    func enableHero() {
        
        self.samuneImageView.isHeroEnabled = true
        
    }
    
    /// heroを無効化
    func disableHero() {
        self.samuneImageView.isHeroEnabled = false
    }
    
}
