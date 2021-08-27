//
//  Config.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import RealmSwift

/// 設定など
class Config: Object {
    
    /// バージョン情報
    @objc dynamic var version: Float = 0.0
    
    /// 角丸にするかどうか
    @objc dynamic var sheetRounded: Bool = false
    
    /// シートの見た目の色
    @objc dynamic var sheetAppearanceHex: String = "7C7CFF"
    
    /// シートの見た目の色の透明度
    @objc dynamic var sheetAppearanceAlpha: Float = 0.5
    
    /// 最後に開いていたドキュメントのuuid
    @objc dynamic var lastWatchedDocumentId: String = ""
    
}

/// 作成中のシートの情報群
class EditingSheetData {
    
    /// 対象のシートがあるならそれが入る
    var targetSheet: Sheet
    
    /// いま編集中の色は、normalかinsteadか
    var editingColorType: Color.sheet.editing
    
    /// シートの状態
    enum SheetStatus {
        case adding
        case editing
    }
    
    /// 追加状態か、編集状態なのか
    var sheetStatus: SheetStatus
    
    /// データを入れる
    init (sheet: Sheet, type: Color.sheet.editing, status: SheetStatus) {
        
        self.editingColorType = type
        
        //値をコピーしてくる
        self.targetSheet = Sheet()
        targetSheet.colorHex = sheet.colorHex
        targetSheet.uuid = sheet.uuid
        targetSheet.insteadColorHex = sheet.insteadColorHex
        targetSheet.tolerance = sheet.tolerance
        
        self.sheetStatus = status
    }
    
}
