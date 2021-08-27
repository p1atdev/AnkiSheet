//
//  AppDelegate.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import RealmSwift
import Firebase
import SwiftDate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //アプリ情報の表示
        print("==================================================")
        print("アプリバージョン:", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
        print("Paramバージョン:", Param.version)
        print("ビルド番号:", Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)
        print("Realmスキーマバージョン: ", UInt64(Param.version * 1000))
        print("==================================================")
        
        //MARK: マイグレーション
        var realmConfig = Realm.Configuration()
        realmConfig.migrationBlock = { migration, oldSchemaVersion in
            
            // 作成日時を設定
            if(oldSchemaVersion < 3400) {
                migration.enumerateObjects(ofType: Document.className()) { _ , new in
                    new!["createdDate"] = Date().toFormat("yyyy/MM/dd")
                }
            } else if(oldSchemaVersion < 3800) {
                // 何かしらのミスでyyyy/MM/ddとなってしまっていたものを修正
                migration.enumerateObjects(ofType: Document.className()) { old , new in
                    if old!["createdDate"] as! String == "yyyy/MM/dd" {
                        new!["createdDate"] = Date().toFormat("yyyy/MM/dd")
                    }
                }
            } else if(oldSchemaVersion > 3900) {
                // parentPathIDをセットする
                migration.enumerateObjects(ofType: Document.className()) { old , new in
                    // もしparentPathIDが存在したら
                    guard let oldParentPathID = old!["parentPathID"] else { return }

                    if oldParentPathID as! String == "" {
                        new!["parentPathID"] = "/"
                    }

                }
            }
            
        }
        
        realmConfig.schemaVersion = UInt64(Param.version * 1000)
        Realm.Configuration.defaultConfiguration = realmConfig
        
        //Realm
        let realm = try! Realm()
        
        if realm.objects(Config.self).count == 0 {
            //configの設定がないので作成
            let config = Config()
            config.version = Param.version
            
            try! realm.write {
                //追加
                realm.add(config)
            }
        }
        
        if realm.objects(Sheet.self).count == 0 {
            //デフォルトのシートを作成
            Process.createDefaultSheet()
        }
        
        if realm.objects(Flag.self).count == 0 {
            //フラグを作成
            let flag = Flag()
            
            try! realm.write {
                realm.add(flag)
            }
        }
        
        //ドキュメントディレクトリにあるデータたちをrealmに変換する
        /// 画像のファイル名
        for imageFileName in File.fileListInDocumentPath {
            
            if !imageFileName.hasSuffix(".png") { continue }
            
            /// 画像のパス
            let targetImagePath = File.documentPath + imageFileName
            
            /// その画像をUIImageで取得
            let targetImage = UIImage(contentsOfFile: targetImagePath)
            
            print(targetImagePath)
            
            //まずはrealm用のオブジェを作る
            let document = Document()
            
            // データ化したものをぶち込む
            document.imageData = targetImage!.pngData()!
            
            //名前をセットする
            document.title = String(imageFileName.split(separator: ".").first!) //拡張子を取り除く
            
            //書き込む
            try! realm.write {
                //追加
                realm.add(document)
            }
            
            //ファイルを削除
            let _ = File.removeFile(at: targetImagePath)
            //                }
            
        }
        
        //Firebaseの設定
        FirebaseApp.configure()
        
        // テーマカラーの設定
        
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
}

