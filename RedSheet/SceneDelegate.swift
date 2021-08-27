//
//  SceneDelegate.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import UTIKit
import RealmSwift
import PKHUD

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    // MARK: 他のアプリからのファイル共有
    
    // バックグラウンドで存在する場合、こちらが呼ばれる
    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        if URLContexts.count == 0 { return }  //なにも受け取ってないなら帰る
        
        print("｜====:scene(openURLContexts:):====｜")
        
        print("｜NumberOfURLContexts:", URLContexts.count)
        
        DispatchQueue.global().async {
            
            for urlContent in URLContexts {
                print(urlContent.url)
                
                //ファイルを保存
                self.recievedDocument(url: urlContent.url)
                
            }
            
            DispatchQueue.main.async {
                //ファイルを送ったという通知を送信
                NotificationCenter.default.post(name: .fileReceived, object: nil)
                print("｜通知送信: .fileRecieved")
            }
        }
        
        print("｜===:終了:scene(openURLContexts:)===｜")
        
    }
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if connectionOptions.urlContexts.count == 0 { return }  //なにも受け取ってないなら帰る
        
        print("｜====:scene(willConnectTo:):====｜")
        
        print("｜NumberOfURLContexts:", connectionOptions.urlContexts.count)
        
        DispatchQueue.global().async {
            
            for urlContent in connectionOptions.urlContexts {
                print(urlContent.url)
                
                //ファイルを保存
                self.recievedDocument(url: urlContent.url)
                
            }
            
            DispatchQueue.main.async {
                //ファイルを送ったという通知を送信
                NotificationCenter.default.post(name: .fileReceived, object: nil)
                print("｜通知送信: .fileRecieved")
            }
        }
        
        print("｜===:終了:scene(willConnectTo:)===｜")
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // MARK: 他のアプリから書類を受け取った時の処理
    /// ファイルをその形式に沿って保存する
    private func recievedDocument(url: URL) {
        print("｜====:recievedDocument:====｜")
        print("｜フルパス:", url.absoluteString)
        print("｜ファイルタイプ:", UTI(filenameExtension: url.pathExtension)!)
        
        // tmpファイルのパスを作る
        let tmpPath: URL = Process.createTmpFile(from: url)
        
        print("｜tmpのフルパス:", tmpPath.absoluteURL)
        print("｜ファイル名:", tmpPath.lastPathComponent)
        
        //ファイルの形式を判定
        switch UTI(filenameExtension: url.pathExtension) {
        case UTI("public.image"), UTI("public.jpeg"), UTI("public.png"), UTI("public.heic"):    //画像を受け取った
            print("｜画像を受け取った")
            saveImage(url: tmpPath)
            
        case UTI("com.adobe.pdf"):  //PDFを受け取った
            print("｜PDFを受け取った")
            savePDF(url: tmpPath)
            
        case let ext:
            print("｜他の拡張子のファイルを受け取った:", ext!)
            
        }
        
        print("｜===:終了:recievedDocument===｜")
    }
    
    /// 画像を受け取って保存する処理
    private func saveImage(url: URL) {
        print("｜===saveImage===｜")
        print("｜- 画像を保存する")
        
        do {
            //アクセス権限を取得する
            if !url.startAccessingSecurityScopedResource() {
                print("｜エラー: アクセス権限を取得できませんでした｜")
            }
            
            // 画像を取得
            let image: UIImage = try UIImage(contentsOfFile: String(contentsOf: url))!
            // 名前を取得
            let name: String = url.lastPathComponent.title
            
            //realmを起動して保存
            let realm = try! Realm()
            let document = Document()
            
            document.uid = UUID().uuidString
            document.title = name
            document.imageData = image.jpegData(compressionQuality: 0.5)
            document.parentPathID = "/"
            document.type = "image"
            
            //書き込み
            try! realm.write {
                realm.add(document)
            }
            
            //権限を破棄
            url.stopAccessingSecurityScopedResource()
            
        } catch {
            
            print("｜エラー: 画像を保存できませんでした｜")
            print(error)
            
        }
        
        print("｜===:終了:saveImage===｜")
        
    }
    
    /// PDFを受け取って保存する処理
    private func savePDF(url: URL) {
        
        print("｜- PDFを保存する")
        
        //アクセス権限を取得する
        if !url.startAccessingSecurityScopedResource() {
            print("｜エラー: アクセス権限を取得できませんでした｜")
        }
        
        // PDFを保存
        Process.savePDF(path: url)
        
        //権限を破棄
        url.stopAccessingSecurityScopedResource()
        
        print("｜===:終了:savePDF===｜")
    }
    
}


