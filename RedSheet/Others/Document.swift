//
//  Document.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import RealmSwift

/// ドキュメントやフォルダーの共通要素
protocol DocumentData {
    /// UUID。識別用
    var uid: String { get set }
    
    /// タイトル、名前
    var title: String { get set }
    
    /// 作成日
    var createdDate: String { get set }
    
    /// このドキュメント開かれた回数
    var countOfOpened: Int { get set }
    
    /// 親のパス
    var parentPathID: String { get set }
}

/// 旧プリント。写真と名前とUIDが入ってる
class Document: Object, DocumentData {
    
    /// タイプ(pdf or image)
    @objc dynamic var type: String = "image"
    
    /// ページ数
    @objc dynamic var numberOfPages: Int = 0
    
    /// 画像データ
    @objc dynamic var imageData: Data!
    
    /// タイトル
    @objc dynamic var title: String = NSLocalizedString("document.default.title", comment: "No name folder")
    
    /// UUID。識別用
    @objc dynamic var uid: String = UUID().uuidString
    
    /// バインダーに収容されているか
    @objc dynamic var isContainedInBinder: Bool = false
    
    /// このドキュメント開かれた回数
    @objc dynamic var countOfOpened: Int = 0
    
    /// 作成日(yyyy/MM/dd)
    @objc dynamic var createdDate: String = "yyyy/MM/dd"
    
    /// もし、これがバインダーに入ってるならUUIDが指定される
    @objc dynamic var binderId: String = "FFFF-FFFF-FFFF-FFFF"
    
    /// 親パス(ルートは"/"でフォルダ内ならUUID)
    @objc dynamic var parentPathID: String = "/"
    
}

/// フォルダー
class Folder: Object, DocumentData {
    
    /// uuid
    @objc dynamic var uid: String = UUID().uuidString
    
    /// 親のパス
    @objc dynamic var parentPathID: String = "/"
    
    /// フォルダー名
    @objc dynamic var title: String = NSLocalizedString("folder.default.title", comment: "No name folder")
    
    /// 作成日(yyyy/MM/dd)
    @objc dynamic var createdDate: String = "yyyy/MM/dd"
    
    /// 開かれた回数
    @objc dynamic var countOfOpened: Int = -1
    
    /// フォルダーの色
    /// blue, red, green, orange
    @objc dynamic var color: String = "blue"
}
