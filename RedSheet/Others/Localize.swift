//
//  Tutorial.swift
//  RedSheet
//
//  Created by 周　廷叡 on 2021/06/21.
//

import Foundation
import UIKit

/// ローカライズ
enum Localize {
    
    /// アラート用のテキストの構造体
    struct AlertText {
        var title: String
        var message: String
        var cancel: String
        
        /// もう一つの方のボタン
        var another: String
    }
    
    /// listVCの
    enum listVC {
        /// ソート
        enum sort {
            static let byName: String = NSLocalizedString("listVC.sort.byName", comment: "")
            static let byDate: String = NSLocalizedString("listVC.sort.byDate", comment: "")
            static let byCount: String = NSLocalizedString("listVC.sort.byCount", comment: "")
            static let reverse: String = NSLocalizedString("listVC.sort.reverse", comment: "")
        }
    }
    
    /// チュートリアル用メッセージ
    enum tutorial {
        
        /// リスト画面
        enum list {
            
        }
        
        /// プレビュー画面
        enum preview {
            
            static let list: String = NSLocalizedString("tutorial.preview.list", comment: "")
            
            static let lock: String = NSLocalizedString("tutorial.preview.lock", comment: "")
            
            static let nextDoc: String = NSLocalizedString("tutorial.preview.nextDoc", comment: "")
            
            static let prevDoc: String = NSLocalizedString("tutorial.preview.prevDoc", comment: "")
            
            static let doubleTap: String = NSLocalizedString("tutorial.preview.doubleTap", comment: "")
            
        }
        
    }
    
    /// デフォルト
    enum `default` {
        /// 設定画面
        enum settings {
            
            static let deleteCache: String = NSLocalizedString("tutorial.settings.deleteCache", comment: "")
            static let deleteCacheTips: String = NSLocalizedString("tutorial.settings.deleteCacheTips", comment: "")
            static let resetSettings: String = NSLocalizedString("tutorial.settings.resetSettings", comment: "")
            static let deleteAllSheet: String = NSLocalizedString("tutorial.settings.deleteAllSheet", comment: "")
            static let deleteAllDocument: String = NSLocalizedString("tutorial.settings.deleteAllDocument", comment: "")
            static let clearAllData: String = NSLocalizedString("tutorial.settings.clearAllData", comment: "")
            static let reset: String = NSLocalizedString("tutorial.settings.reset", comment: "")
            static let delete: String = NSLocalizedString("tutorial.settings.delete", comment: "")
            static let cannotBeUndone: String = NSLocalizedString("tutorial.settings.cannotBeUndone", comment: "")
            
        }
    }
    
    /// アラート用のメッセージ
    enum alert {
        /// デフォルトの
        enum `default` {
            static let cancel: String = NSLocalizedString("alert.default.cancel", comment: "")
            static let cannotBeUndone: String = NSLocalizedString("alert.default.cannotBeUndone", comment: "")
            static let areYouSure: String = NSLocalizedString("alert.default.areYouSure", comment: "whether to really delete this")
            static let delete: String = NSLocalizedString("alert.default.delete", comment: "")
        }
        
        /// リスト
        enum list {
            
            static let resume: AlertText = .init(title: NSLocalizedString("alert.list.resume.title", comment: ""),
                                                     message: NSLocalizedString("alert.list.resume.message", comment: ""),
                                                     cancel: alert.default.cancel,
                                                     another: NSLocalizedString("alert.list.resume.resume", comment: ""))
            
            static let isOkToDeleteFolder: String = NSLocalizedString("alert.list.delete.folder.isOk", comment: "")
        }
    }
    
    /// シートの名前
    enum sheet {
        static let orangeToWhite: String = NSLocalizedString("sheet.name.orange-white", comment: "")
        static let greenToBlack: String = NSLocalizedString("sheet.name.green-black", comment: "")

        static let blueToWhite: String = NSLocalizedString("sheet.name.blue-white", comment: "")
        static let blueToBlack: String = NSLocalizedString("sheet.name.blue-black", comment: "")
        static let purpleToWhite: String = NSLocalizedString("sheet.name.purple-white", comment: "")

    }

    /// クレジット
    enum credit {
        static let version = NSLocalizedString("credit.version", comment: "")
    }
    
    /// 設定画面
    enum settings {
        /// 色編集
        enum editColor {
            /// オリジナルフィルター作成
            static let createOriginalFilter = NSLocalizedString("settings.editColor.createOriginalFilter", comment: "")
        }
    }
}
