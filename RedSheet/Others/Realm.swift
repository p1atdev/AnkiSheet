//
//  Realm.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/15.
//

import UIKit
import RealmSwift

/// シートの色とかの情報
class Sheet: Object {
    
    /// UUID
    @objc dynamic var uuid: String = "FFFF-FFFF-FFFF-FFFF"
    
    /// 入れ替える元の色(16進数で)
    @objc dynamic var colorHex: String = "F09819"
    
    /// 入れ替える対象の色
    @objc dynamic var insteadColorHex: String = "FFFFFF"
    
    /// 色の判定の厳しさ(CGFloatに変換しろ)
    @objc dynamic var tolerance: Float = 0.6
    
}

/// フラグ情報
class Flag: Object {
    
    /// previewから戻った回数
    @objc dynamic var numberOfReturnFromPreview: Int = 0
    
    /// listを初めて開いた
    @objc dynamic var isFirstOpenList: Bool = true
    
    /// メニューを初めて開く
    @objc dynamic var isFirstOpenMenu: Bool = true
    
    /// previewを初めて開いた
    @objc dynamic var isFirstOpenPreview: Bool = true
    
    /// checkを初めて開いた
    @objc dynamic var isFirstOpenCheck: Bool = true
    
    /// 色の追加を初めて使った
    @objc dynamic var isFirstOpenNewColor: Bool = true
    
    /// さっきドキュメントを他のアプリから追加したよというフラグ
    @objc dynamic var didAddDocument: Bool = false
}

/// フィルターのかかった画像
class FilteredImage: Object {
    
    /// ドキュメントUUID
    @objc dynamic var uuid: String = "FFFF-FFFF-FFFF-FFFF"
    
    /// PDFの場合、ページ数(通常の画像なら1)
    @objc dynamic var pageNum: Int = 1
    
    /// かかってるフィルターのリスト
    var sheets = List<Sheet>()
    
    /// 画像データ
    @objc dynamic var data: Data!
    
}

/// バインダー(ドキュメントをまとめてるやつ)
class Binder: Object {
    
    /// バインダーのUUID
    @objc dynamic var uuid: String = UUID().uuidString
    
    /// バインダーの中のドキュメントの数
    @objc dynamic var numberOfContainDocument: Int = 0
    
}
