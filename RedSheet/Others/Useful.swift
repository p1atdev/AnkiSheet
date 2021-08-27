//
//  Useful.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import Foundation
import UIKit
import RealmSwift
import PKHUD
import SwiftDate
import Firebase

//MARK: Screen
enum Screen {
    static let screenHeight: CGFloat = UIScreen.main.bounds.height
    static let screenWidth: CGFloat = UIScreen.main.bounds.width
    
    static let longLength: CGFloat = max(screenHeight, screenWidth)
    static let shortLength: CGFloat = min(screenHeight, screenWidth)
    
    //向き
    case horizontal //横
    case vertical   //縦
    
    static let orientation = screenHeight == longLength ? Screen.vertical : .horizontal
}


//MARK: ViewProcess
enum Process {
    /// まとめて角丸
    static func setCornerRadius(views: Array<UIView>, radius: CGFloat) {
        for view in views {
            view.layer.cornerRadius = radius
        }
    }
    
    /// 影と角丸を同時に行う
    static func setCornerWithShadow(view: UIView, cornerRadius: CGFloat,
                                    shadowColor: CGColor? = UIColor.black.cgColor, shadowRadius: CGFloat,
                                    shadowOpacity: Float? = 0.5,
                                    shadowOffset: CGSize? = .init(width: 0, height: 0),
                                    parentView: UIView?) {
        //親の角丸
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor = shadowColor!
        view.layer.shadowOpacity = shadowOpacity!
        view.layer.shadowRadius = shadowRadius
        view.layer.shadowOffset = shadowOffset!
        
        //shadowViewは影だけを表示するビュー
        let shadowView = UIView()
        shadowView.layer.frame = view.layer.frame
        
        shadowView.backgroundColor = .systemBackground //背景が透明だと影が表示されない
        shadowView.layer.cornerRadius = view.layer.cornerRadius
        shadowView.layer.maskedCorners = view.layer.maskedCorners
        shadowView.layer.shadowColor = shadowColor!
        shadowView.layer.shadowOpacity = shadowOpacity!
        shadowView.layer.shadowRadius = shadowRadius
        shadowView.layer.shadowOffset = shadowOffset!
        
        if let parent = parentView {
            parent.addSubview(shadowView)
        }
        
        shadowView.sendSubviewToBack(view) //viewはroundedViewとかの親ビュー
    }
    
    /// 影を一発で
    /// 影と角丸を同時に行う
    static func setShadow(view: UIView,
                          shadowColor: CGColor = UIColor.black.cgColor, shadowRadius: CGFloat = 4,
                          shadowOpacity: Float = 0.5,
                          shadowOffset: CGSize = .init(width: 0, height: 0)) {
        
        view.layer.shadowColor = shadowColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowRadius = shadowRadius
        view.layer.shadowOffset = shadowOffset
        
    }
    
    /**画像の色を入れ替える
     - Parameters:
     - color: source color, which is must be replaced,
     - withColor:  target color
     - tolerance: - value in range from 0 to 1
     */
    static func replaceColor(color: UIColor, withColor: UIColor, image: UIImage, tolerance: CGFloat) -> UIImage {
        
        // This function expects to get source color(color which is supposed to be replaced)
        // and target color in RGBA color space, hence we expect to get 4 color components: r, g, b, a
        assert(color.cgColor.numberOfComponents == 4 && withColor.cgColor.numberOfComponents == 4,
               "Must be RGBA colorspace")
        
        // Allocate bitmap in memory with the same width and size as source image
        let imageRef = image.cgImage!
        let width = imageRef.width
        let height = imageRef.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width;
        let bitsPerComponent = 8
        let bitmapByteCount = bytesPerRow * height
        
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
        
        let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: CGColorSpace(name: CGColorSpace.genericRGBLinear)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        
        
        let rc = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Draw source image on created context
        context!.draw(imageRef, in: rc)
        
        
        // Get color components from replacement color
        let withColorComponents = withColor.cgColor.components
        let r2 = UInt8(withColorComponents![0] * 255)
        let g2 = UInt8(withColorComponents![1] * 255)
        let b2 = UInt8(withColorComponents![2] * 255)
        let a2 = UInt8(withColorComponents![3] * 255)
        
        // Prepare to iterate over image pixels
        var byteIndex = 0
        
        while byteIndex < bitmapByteCount {
            
            // Get color of current pixel
            let red = CGFloat(rawData[byteIndex + 0]) / 255
            let green = CGFloat(rawData[byteIndex + 1]) / 255
            let blue = CGFloat(rawData[byteIndex + 2]) / 255
            let alpha = CGFloat(rawData[byteIndex + 3]) / 255
            
            let currentColor = UIColor(red: red, green: green, blue: blue, alpha: alpha);
            
            // Compare two colors using given tolerance value
            if compareColor(color: color, withColor: currentColor , withTolerance: tolerance) {
                
                // If the're 'similar', then replace pixel color with given target color
                rawData[byteIndex + 0] = r2
                rawData[byteIndex + 1] = g2
                rawData[byteIndex + 2] = b2
                rawData[byteIndex + 3] = a2
            }
            
            byteIndex = byteIndex + 4;
        }
        
        // Retrieve image from memory context
        let imgref = context!.makeImage()
        let result = UIImage(cgImage: imgref!, scale: 1.0, orientation: image.imageOrientation)
            .resized(toWidth: image.size.width)! //元画像と同じ大きさにリサイズ
        
        // Clean up a bit
        rawData.deallocate()
        
        return result
    }
    
    static func compareColor(color: UIColor, withColor: UIColor, withTolerance: CGFloat) -> Bool {
        
        var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0;
        var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0;
        
        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1);
        withColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2);
        
        return abs(r1 - r2) <= withTolerance &&
            abs(g1 - g2) <= withTolerance &&
            abs(b1 - b2) <= withTolerance &&
            abs(a1 - a2) <= withTolerance;
    }
    
    /// デフォルトのシートを作成する
    static func createDefaultSheet() {
        let realm = try! Realm()
        
        //デフォルトのシートを作成
        let redSheet = Sheet()
        redSheet.uuid = "DEFAULT-ORANGE-TO-WHITE"
        redSheet.colorHex = Color.sheet.default.orange.hex
        redSheet.insteadColorHex = "FFFFFF"
        redSheet.tolerance = 0.7
        
        let greenSheet = Sheet()
        greenSheet.uuid = "DEFAULT-GREEN-TO-BLACK"
        greenSheet.colorHex = Color.sheet.default.green.hex
        greenSheet.insteadColorHex = "000000"
        greenSheet.tolerance = 0.5
        
        try! realm.write {
            realm.add(redSheet)
            realm.add(greenSheet)
        }
    }
    
    /**
     PDFのファイルを保存する
     - Parameters:
        - path: PDFのファイルのパス
        - targetPath: 新しく作成するPDFの置かれるパス
        - completion: 保存が完了したら呼ばれる(デフォルトはなし)
     */
    static func savePDF(path: URL, targetPath: String ,completion finish: @escaping ()->()) {
        
        /// ファイル名
        let fileName: String = path.lastPathComponent
        
        /// 拡張子(pdf)
        let fileExtension: String = path.pathExtension
        
        /// PDFのデータ
        guard let pdfDocument = CGPDFDocument(path as CFURL) else { return }
        
        //非同期
        DispatchQueue(label: "background").async {
            autoreleasepool {
                DispatchQueue.main.async {
                    /// くるくるを表示
                    HUD.show(.progress)
                }
                
                // realmに保存する
                let realm = try! Realm()
                
                /// uuidを生成
                let uuid = UUID().uuidString
                
                // ドキュメントを作成
                let document = Document()
                //　タイトルはファイル名
                document.title = fileName.replacingOccurrences(of: "." + fileExtension,
                                                               with: "")
                //uuidをセット
                document.uid = uuid
                //タイプをpdfに
                document.type = "pdf"
                //パスを設定
                document.parentPathID = targetPath
                // 作成日を設定
                document.createdDate = Date().toString(.custom("yyyy/MM/dd"))
                
                /// pdfの全ページ
                var allPDFPageData: Array<PDFData> = []
                
                //ページごとにデータを作成
                for pageNum in 1...pdfDocument.numberOfPages {
                    let pdfData = PDFData()
                    pdfData.uuid = uuid     //uuid
                    pdfData.pageNum = pageNum
                    
                    //このページのデータ
                    guard let pageImage = UIImage.PDFImageWith(path, pageNumber: pageNum) else { return }
                    
                    print(pageImage.description.debugDescription)
                    
                    pdfData.data = pageImage.jpegData(compressionQuality: 0.5)
                    
                    // 追加
                    allPDFPageData.append(pdfData)
                    
                    //もし1枚目なら
                    if pageNum == 1 {
                        //documentに入れてサムネにする
                        document.imageData = pageImage.jpegData(compressionQuality: 0.5)
                    }
                    
                }
                
                // 書き込む
                try! realm.write {
                    realm.add(document)
                    realm.add(allPDFPageData)
                }
                
                print("PDFが保存された")
                
                DispatchQueue.main.async {
                    // くるくるを閉じる
                    HUD.hide()
                    
                    // なにかを実行する
                    finish()
                }
            }
            
        }
        
        // ログ
        logToAnalytics(title: "save_pdf_with_completion", id: "saved_pdf_completion")
    }
    
    /**
     PDFのファイルを保存する
     - Parameters:
     - path: PDFのファイルのパス
     */
    static func savePDF(path: URL) {
        
        /// ファイル名
        let fileName: String = path.lastPathComponent
        
        /// 拡張子(pdf)
        let fileExtension: String = path.pathExtension
        
        /// PDFのデータ
        guard let pdfDocument = CGPDFDocument(path as CFURL) else {
            print("｜PDFのパス:", path)
            print("｜エラー: PDFのデータを取得できません")
            return
        }
        
        // realmに保存する
        let realm = try! Realm()
        
        /// uuidを生成
        let uuid = UUID().uuidString
        
        // ドキュメントを作成
        let document = Document()
        //　タイトルはファイル名
        document.title = fileName.replacingOccurrences(of: "." + fileExtension,
                                                       with: "")
        //uuidをセット
        document.uid = uuid
        //タイプをpdfに
        document.type = "pdf"
        // 作成日を設定
        document.createdDate = Date().toString(.custom("yyyy/MM/dd"))
        document.parentPathID = "/"
        
        /// pdfの全ページ
        var allPDFPageData: Array<PDFData> = []
        
        //ページごとにデータを作成
        for pageNum in 1...pdfDocument.numberOfPages {
            let pdfData = PDFData()
            pdfData.uuid = uuid     //uuid
            pdfData.pageNum = pageNum
            
            //このページのデータ
            guard let pageImage = UIImage.PDFImageWith(path, pageNumber: pageNum) else { return }
            
            print(pageImage.description.debugDescription)
            
            pdfData.data = pageImage.jpegData(compressionQuality: 0.5)
            
            // 追加
            allPDFPageData.append(pdfData)
            
            //もし1枚目なら
            if pageNum == 1 {
                //documentに入れてサムネにする
                document.imageData = pageImage.jpegData(compressionQuality: 0.5)
            }
            
        }
        
        // 書き込む
        try! realm.write {
            realm.add(document)
            realm.add(allPDFPageData)
        }
        
        print("｜PDF保存完了")
        
        print("｜===:終了:savePDF===｜")
        
        // ログ
        logToAnalytics(title: "save_pdf_without_completion", id: "save_pdf")
    }
    
    // tmpファイルの作成
    static func createTmpFile(from filePath: URL) -> URL {
        print("｜====:createTmpFile:====｜")
        print("｜tmpファイルの作成")
        
        //ファイル名
        let fileName: String = filePath.lastPathComponent
        print("｜ファイル名:", fileName)
        
        // tmpの親ディレクトリパス
        let tmpDirPath = URL(fileURLWithPath: File.tmpPath.appending(UUID().uuidString+"/"))
        print("｜作成するtmpの親ディレクトリパス:", tmpDirPath)
        
        //ディレクトリを作成
        if File.createDir(tmpDirPath) {
            print("｜tmpの親パスの生成に成功")
        } else {
            print("｜エラー: tmpの親パスの生成に失敗しました")
        }
        
        // tmpのファイルパス
        let tmpPath = tmpDirPath.appendingPathComponent(fileName)
        print("｜作成するtmpのファイルパス:", tmpPath)

        
        // アクセス権限を取得してみる
        if !tmpPath.startAccessingSecurityScopedResource() {
            print("｜エラー: アクセス権限を得られませんでした")
        } else {
            print("｜アクセス権限あり")
        }
        
        //ファイルをコピー
        if File.copy(filePath, toPath: tmpPath) {
            print("｜ファイル->tmpコピー結果: 成功")
        } else {
            print("｜ファイル->tmpコピー結果: 失敗")
        }
        
        // アクセス権限の返却
        tmpPath.stopAccessingSecurityScopedResource()
        filePath.stopAccessingSecurityScopedResource()
        
        print("｜===:終了:createTmpFile===｜")
        
        // パスを返す
        return tmpPath
    }
    
    // tmpファイルを削除
    static func removeTmpFile(tmpFromPath: URL) {
        print("｜====:removeTmpFile:====｜")
        
        //ファイル名
        let fileName: String = tmpFromPath.lastPathComponent
        print("｜ファイル名:", fileName)
        
        // tmpのファイルパス
        let tmpPath = File.tmpPath.appending(fileName)
        print("｜削除するファイルパス:", fileName)
        
        //ファイルを削除
        if File.removeFile(at: tmpPath) {
            print("｜tmpファイル削除結果: 成功")
        } else {
            print("｜tmpファイル削除結果: 失敗")
        }
        
        print("｜===:終了:removeTmpFile==｜")
    }
    
    
    /// 対象のシートを使っているキャッシュを全て削除する
    static func deleteFileteredCache(target: Sheet) {
        
        let realm = try! Realm()
        for filteredImage in realm.objects(FilteredImage.self) {
            // キャッシュごとの、その保持しているシートをチェック
            let sheetIds = filteredImage.sheets.map({ $0.uuid })
            
            if sheetIds.contains(target.uuid) { //もし含まれていたら
                // realmからその画像を削除
                try! realm.write {
                    realm.delete(filteredImage)
                }
            }
            
        }
        
        // ログ
        logToAnalytics(title: "delete_filter_caches", id: "delete_filter_caches")
        
    }
    
    ///  Analyticsでロギングする
    static func logToAnalytics(title: String, id: String, type: String = "cont") {
        Analytics.logEvent(title,
                           parameters: [
                            AnalyticsParameterItemID: "id-\(id)",
                            AnalyticsParameterItemName: id,
                            AnalyticsParameterContentType: type
                           ])
    }
    
    /// フォルダーの色の名前から画像を返す
    /// - returns: (upper, lower)
    static func getFolderImage(color: String) -> (UIImage, UIImage) {
        return (UIImage(named: "folder-\(color)-upper")!, UIImage(named: "folder-\(color)-lower")!)
    }

    /// フォルダーの中身を再起的に削除する
    static func deleteFolderInside(folder: Folder) {
        
        let realm = try! Realm()
        
        // 中のフォルダー
        let insideFolders = realm.objects(Folder.self).filter("parentPathID == %@", folder.uid)
        // 中のドキュメント
        let insideDocuments = realm.objects(Document.self).filter("parentPathID == %@", folder.uid)
        
        // まずはドキュメントを削除
        for insideDocument in insideDocuments {
            try! realm.write {
                realm.delete(insideDocument)
            }
        }
        
        // 次にフォルダーが存在すればそれぞれ削除
        for insideFolder in insideFolders {
            deleteFolderInside(folder: insideFolder)
        }
        
        // 中身がなくなったら自身を削除
        try! realm.write {
            realm.delete(folder)
        }
        
    }

}

