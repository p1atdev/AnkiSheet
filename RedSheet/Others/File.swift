//
//  File.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit

/// ファイル操作
enum File {
    
    /// ドキュメントパス
    static let documentPath = NSHomeDirectory() + "/Documents/"
    
    /// tmpパス
    static let tmpPath = NSTemporaryDirectory()
    
    /// Cacheパス
    static let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                               .userDomainMask,
                                                               true)[0]
    
    ///ファイル一覧
    static var fileListInDocumentPath: [String] = {
        let fileManager = FileManager.default
        var files: [String] = []
        do {
            files = try fileManager.contentsOfDirectory(atPath: documentPath)
        } catch {
            return files
        }
        
        files.removeAll( where: {$0.starts(with: ".")} )
        
        return files
    }()
    
    /// ファイルを削除
    static func removeFile(at path: String) -> Bool {
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
            
            //成功したらture
            return true
        } catch let error {
            print(error)
            
            //失敗したらfalse
            return false
        }
    }
    
    /**
     ファイルデータを読み込みます。
     
     Parameter filePath: ファイルパス
     Returns: ファイルデータ　読み込めない場合はnilを返却します。
     */
    static func getFileData(_ filePath: String) -> Data? {
        let fileData: Data?
        do {
            let fileUrl = URL(fileURLWithPath: filePath)
            fileData = try Data(contentsOf: fileUrl)
        } catch {
            // ファイルデータの取得でエラーの場合
            fileData = nil
        }
        return fileData
    }
    
    /**
     ファイルデータを読み込みます。
     
     Parameter filePath: ファイルパス
     Returns: ファイルデータ　読み込めない場合はnilを返却します。
     */
    static func getFileData(_ filePath: URL) -> Data? {
        let fileData: Data?
        do {
            fileData = try Data(contentsOf: filePath)
        } catch {
            // ファイルデータの取得でエラーの場合
            fileData = nil
        }
        return fileData
    }
    
    /**
     ディレクトリまたはファイルのコピーを行います。
     
     - Parameter atPathName: コピー元のディレクトリパス名またはファイルパス名
     - Parameter toPathName: コピー先のディレクトリパス名
     - Returns: 処理結果
     */
    static func copy(_ atPathName: String, toPathName: String) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: URL(fileURLWithPath: atPathName), to: URL(fileURLWithPath: toPathName))
        } catch {
            print(error)
            return false
        }
        return true
    }
    
    /**
     ディレクトリまたはファイルのコピーを行います。
     
     - Parameter atPathName: コピー元のディレクトリパスまたはファイルパス
     - Parameter toPathName: コピー先のディレクトリパス
     - Returns: 処理結果
     */
    static func copy(_ atPath: URL, toPath: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: atPath, to: toPath)
        } catch {
            print("｜コピー元:", atPath)
            print("｜コピー先:", toPath)
            print("｜copy() エラー:", error)
            print(error)
            return false
        }
        return true
    }
    
    /**
     ファイルを作成します。
     
     - Parameters :
     - filePath: ファイルパス名
     - Returns: ファイル作成結果(true:成功/false:失敗)
     */
    static func createFile(_ filePath: String) -> Bool {
        let fileManager = FileManager.default
        let result = fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
        return result
    }
    
    /**
     ディレクトリを作成します。
     
     - Parameter dirName: ディレクトリパス名
     - Returns: 作成結果(true:成功 / false:失敗)
     */
    static func createDir(_ dirPath: String) -> Bool {
        // ディレクトリを作成します。
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // エラーの場合
            return false
        }
        return true
    }
    
    /**
     ディレクトリを作成します。
     
     - Parameter dirName: ディレクトリパス名
     - Returns: 作成結果(true:成功 / false:失敗)
     */
    static func createDir(_ dirPath: URL) -> Bool {
        // ディレクトリを作成します。
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // エラーの場合
            return false
        }
        return true
    }
}
