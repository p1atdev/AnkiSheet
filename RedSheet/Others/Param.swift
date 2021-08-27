//
//  Param.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit

///　パラメーター
enum Param {
    
    /// バージョン
    static let version: Float = 3.94
    
}

/// viewの情報
class ViewInfo {
    
    /// 横の長さ
    var width: CGFloat = 0
    
    /// 縦の長さ
    var height: CGFloat = 0
    
    /// x座標
    var posX: CGFloat = 0
    
    /// y座標
    var posY: CGFloat = 0
    
    
    init() {
        
    }
    
}

/// リストの表示順
enum ListSortType {
    /// 名前順
    case name
    
    /// 日付順
    case date
    
    /// 開いた回数順
    case opened
    
}
