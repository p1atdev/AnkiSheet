//
//  PDF.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/30.
//

import UIKit
import PDFKit
import RealmSwift

class PDFData: Object {
    
    /// Documentに対応するUUID
    @objc dynamic var uuid: String = ""
    
    /// ページナンバー
    @objc dynamic var pageNum: Int = 0
    
    /// データ
    @objc dynamic var data: Data!
    
}
