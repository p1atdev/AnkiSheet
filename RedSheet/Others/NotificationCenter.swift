//
//  NotificationCenter.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/04/02.
//

import UIKit

extension Notification.Name {
    static let fileReceived = Notification.Name("fileReceived") //ファイルを受け取った
    static let willColorPickerBeCalled = Notification.Name("willColorPickerBeCalled") //カラーピッカーが呼ばれる
    static let colorPickerDismissed = Notification.Name("colorPickerDismissed") //カラーピッカーが閉じられた
    static let colorPickerCanceled = Notification.Name("colorPickerCanceled") //カラーピッカーがキャンセルされた
    
    /// ListCollectionを更新したいときに呼ぶ
    static let reloadListCollection = Notification.Name("reloadListCollection")
    
    /// シートが更新されたのでサイドを更新
    static let sheetUpdated = Notification.Name("sheetUpdated")
}
