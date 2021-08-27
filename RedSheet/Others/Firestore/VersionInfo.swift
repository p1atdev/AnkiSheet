//
//  VersionInfo.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/06/21.
//

import Foundation
import SwiftUI
import FirebaseFirestore

/// バージョンのデータの構造体
class VersionInfo: ObservableObject {
    
    /// 画像
    @Published var image: UIImage? = nil
    
    /// タイトル
    @Published var title: String = "No-title"
    
    /// ボディ
    @Published var body: String = "Lorem ipsum..."
    
}
