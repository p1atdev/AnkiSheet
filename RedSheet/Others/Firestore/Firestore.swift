//
//  Firestore.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/06/21.
//

import Foundation
import SwiftUI
import FirebaseFirestore

/// バージョンの最新情報のデータの構造体
class VersionInfoViewModel: ObservableObject {
    
    @Published var versions = [VersionInfo]()
    
    // データベース
//    private var db = Firestore.firestore()
//    
//    // データを取得
//    func fetchData() {
//        
//        db.collection("versions").addSnapshotListener { (querySnapshot, error) in
//          guard let documents = querySnapshot?.documents else {
//            print("No documents")
//            return
//          }
//
//          self.versions = documents.map { queryDocumentSnapshot -> VersionInfo in
//            let data = queryDocumentSnapshot.data()
//            let title = data["title"] as? String ?? ""
//            let image = data["image"] as? String ?? ""
//            let body = data["body"] as? String ?? ""
//
//            return VersionInfo(image: image)
//          }
//        }
//      }
}
