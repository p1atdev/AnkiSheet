//
//  ListCollectionViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import RealmSwift
import ContextMenuSwift
import Alertift
import DeviceKit

private let reuseIdentifier = "listCollectionCell"

protocol ListCollectionViewControllerDelegate: AnyObject {
    func reloadCollection()
    func reloadCollectionWith(sort: ListSortType, isReversed: Bool)
    func setFolder(folder: Folder)
}

class ListCollectionViewController: UICollectionViewController, UIGestureRecognizerDelegate {
    
    /// realmのデータが入る
    var documentsData: Array<DocumentData>!
    
    //これから色々と操作されるデータのインデックスパス
    var willEditDocIndexPathRow: Int = -1
    
    /// ソートの方式
    var sortStyle: ListSortType = .name
    
    /// ソートが逆向きかどうか
    var isSortReversed: Bool = false
    
    /// この画面のパス
    var currentPath: String = "/"
    
    /// レイアウト
    private var layout: UICollectionViewFlowLayout!
    
    deinit {
        print("collection deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //セルを登録
        self.collectionView!.register(UINib(nibName: "ListCollectionViewCell",
                                            bundle: nil),
                                      forCellWithReuseIdentifier: reuseIdentifier)
        
        //入れる
        reloadDocumentDatas()
        sortCollection()
        
        //長押し時の判定
        // UILongPressGestureRecognizer宣言
        let longPressRecognizer = UILongPressGestureRecognizer(target: self,
                                                               action: #selector(ListCollectionViewController.cellLongPressed(_ :)))
        
        // `UIGestureRecognizerDelegate`を設定するのをお忘れなく
        longPressRecognizer.delegate = self
        
        // tableViewにrecognizerを設定
        collectionView.addGestureRecognizer(longPressRecognizer)
        
        
        // NotificationCenterを登録
        // ファイルが追加されたという通知がきた時に実行するものを設定
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fileReceived),
                                               name: .fileReceived, object: nil)
        
        // リロードしたいときの関数を呼び出し
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadListCollection),
                                               name: .reloadListCollection, object: nil)
        
        // UICollectionViewFlowLayoutをインスタンス化
        layout = UICollectionViewFlowLayout()
        // レイアウトを指定
        collectionView.collectionViewLayout = layout
        
    }
    
    // レイアウトの設定
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        //サイズを指定
        layout.itemSize = {
            if Device.current.isPad {   //iPadの場合
                if Screen.screenHeight == Screen.longLength {   //縦の場合
                    return .init(width: Screen.screenWidth / 3 - 2,
                                 height: Screen.screenWidth / 3 - 2)
                } else {    //横の場合
                    return .init(width: Screen.screenWidth / 4 - 2,
                                 height: Screen.screenWidth / 4 - 2)
                }
            } else {    //iPhone系の場合
                if Screen.screenHeight == Screen.longLength {   //縦の場合
                    return .init(width: Screen.screenWidth / 2 - 2,
                                 height: (Screen.screenWidth / 2 - 2) * 1.2)
                } else {    //横の場合
                    return .init(width: Screen.screenWidth / 4 - 2,
                                 height: (Screen.screenWidth / 4 - 2) * 1.2)
                }
            }
        }()
        
        
        // スペーシング
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 0
        
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        // サイズ調整のために無理やり更新
        collectionView.reloadData()
        
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return documentsData.count
    }
    
    // セルの作成
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        /// セル
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListCollectionViewCell
        
        ///このセル用のdocument
        let targetCellDocumentData = documentsData[indexPath.row] //as! Document
        
        switch targetCellDocumentData {
        case is Document:
            //データをセット
            cell.setData(documentData: targetCellDocumentData as! Document)
        case is Folder:
            //データをセット
            cell.setData(folderData: targetCellDocumentData as! Folder)
        default:
            break
        }
        
        //角丸
        cell.layer.cornerRadius = 8.0
        
        //hero無効化
        cell.disableHero()
        
        return cell
    }
    
    //選択されたら
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //タップされたセル番号
        let row = indexPath.row
        
        /// タップされたセル
        let selectedCell = collectionView.cellForItem(at: indexPath) as! ListCollectionViewCell
        
        //preview
        let previewSB = UIStoryboard(name: "Preview", bundle: nil)
        let previewVC = previewSB.instantiateViewController(identifier: "preview") as! PreviewViewController
        
        print("セルのrow:", row)
        
        // 選択したセルのデータを取得する
        let targetDocumentData = selectedCell.documentData
        
        switch targetDocumentData {
        case is Document:
            
            let documents = documentsData.filter({$0 is Document}) as! [Document]
            let documentsRow = documents.firstIndex(of: targetDocumentData as! Document)!
            
            
            //セット
            previewVC.setData(imageData: (targetDocumentData as! Document).imageData,
                              realmIndex: documentsRow,
                              documentsData: documents)
            
            //ボトムバーを隠す
            previewVC.hidesBottomBarWhenPushed = true
            
            // セルのheroを有効化
            selectedCell.enableHero()
            
            // ログをとる
            Process.logToAnalytics(title: "open_document_from_list", id: "open_document_from_list")
            
            //遷移
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true, completion: nil)
            
        case is Folder:
            
            // ログをとる
            Process.logToAnalytics(title: "open_folder", id: "open_folder")
            
            //開く
            openFolder(folder: targetDocumentData! as! Folder)
            
        default:
            break
        }
    }
    
    // 画面が回転したらレイアウトし直す
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    /// リロード
//    func reloadData() {
//
//        // 表示データを更新
//        reloadDocumentDatas()
//
//        //リロード
//        collectionView.reloadData()
//    }
    
    /* 長押しした際に呼ばれるメソッド */
    @objc func cellLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        
        // 押された位置でcellのPathを取得
        let point = recognizer.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: point)
        
        if indexPath == nil {
            
            return
            
        } else if recognizer.state == UIGestureRecognizer.State.began  {
            // 長押しされた場合の処理
            
            //コンテキストメニューを表示
            let edit = ContextMenuItemWithImage(title: "編集", image: UIImage(systemName: "square.and.pencil")!)
            let delete = ContextMenuItemWithImage(title: "削除", image: UIImage(systemName: "trash")!)
            
            CM.items = [edit, delete]
            CM.showMenu(viewTargeted: collectionView.cellForItem(at: indexPath!)!,
                        delegate: self,
                        animated: true)
            
            //これから削除される可能性があるリストにぶち込む
            willEditDocIndexPathRow = indexPath!.row
            
        }
    }
    
    /// ファイルを受け取ったときに呼ばれる
    @objc func fileReceived() {
        
        //コレクションビューを更新
        reloadCollection()
    }
    
    /// ソートする
    private func sortCollection() {
        switch sortStyle {
        case .name:
            documentsData = documentsData.sorted(by: {(first, second) -> Bool in
                return first.title < second.title
            })
            
        case .date:
            documentsData = documentsData.sorted(by: {(first, second) -> Bool in
                return first.createdDate < second.createdDate
            })
            
        case .opened:
            documentsData = documentsData.sorted(by: {(first, second) -> Bool in
                return first.countOfOpened > second.countOfOpened
            })
            
        }
    }
    
    /// リロードしたいときに呼ばれる
    @objc func reloadListCollection() {
        collectionView.reloadData()
    }
    
    /// 表示するデータを更新する
    private func reloadDocumentDatas() {
        let realm = try! Realm()
        
        // 更新
        documentsData = Array(realm.objects(Document.self).filter("parentPathID = %@", currentPath))
        documentsData += Array(realm.objects(Folder.self).filter("parentPathID = %@", currentPath))
        
    }
    
    ///  フォルダーを開く
    private func openFolder(folder: Folder) {
        
        // TODO: セルがクリックされたらフォルダの中身のが表示される画面に遷移するようにする
        let listSB = UIStoryboard(name: "List", bundle: nil)
        let listVC = listSB.instantiateViewController(identifier: "list") as! ListViewController
        
        listVC.setFolderData(folder: folder)
        
        self.show(listVC, sender: folder)
        
    }
}

// MARK: Extension
extension ListCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    //サイズの変更
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//
//        if Device.current.isPad {   //iPadの場合
//            if Screen.screenHeight == Screen.longLength {   //縦の場合
//                return .init(width: Screen.screenWidth / 4 - 2,
//                             height: Screen.screenHeight / 6 - 2)
//            } else {    //横の場合
//                return .init(width: Screen.screenWidth / 6 - 2,
//                             height: Screen.screenHeight / 3 - 2)
//            }
//        } else {    //iPhone系の場合
//            if Screen.screenHeight == Screen.longLength {   //縦の場合
//                return .init(width: Screen.screenWidth / 4 - 2,
//                             height: Screen.screenHeight / 8 - 2)
//            } else {    //横の場合
//                return .init(width: Screen.screenWidth / 8 - 2,
//                             height: Screen.screenHeight / 2 - 2)
//            }
//        }
//    }
    
}

extension ListCollectionViewController: ContextMenuDelegate {
    
    /**
     コンテキストメニューの選択肢が選択された時に実行される
     - Parameters:
        - contextMenu: そのコンテキストメニューだと思われる
        - cell: **選択されたコンテキストメニューの**セル
        - targetView: コンテキストメニューの発生源のビュー
        - item: 選択されたコンテキストのアイテム(タイトルとか画像とかが入ってる)
        - index: **選択されたコンテキストのアイテムの**座標
     */
    func contextMenuDidSelect(_ contextMenu: ContextMenu,
                              cell: ContextMenuCell,
                              targetedView: UIView,
                              didSelect item: ContextMenuItem,
                              forRowAt index: Int) -> Bool {
        
        // ターゲットのセルを取得
        guard let targetListCell = targetedView as? ListCollectionViewCell else {
            print("targetViewをcellとして取得できなかった")
            return false
        }
        
        //選択された選択肢で分岐
        switch item.title {
        case "編集":
            //TODO: 編集画面に遷移する
            let editDocSB = UIStoryboard(name: "EditDoc", bundle: nil)
            let editDocVC = editDocSB.instantiateViewController(identifier: "editDoc") as! EditDocViewController
            
            editDocVC.delegate = self
            
            let targetDocumentData = documentsData[willEditDocIndexPathRow]
            
            switch targetDocumentData {
            case is Document:
                
                editDocVC.setData(document: targetDocumentData as! Document)
                //モーダルのタイプ
                editDocVC.modalPresentationStyle = .overFullScreen
                
                //遷移
                self.present(editDocVC,
                             animated: false,
                             completion: nil)
            case is Folder:
                //TODO: フォルダーが編集されるときの
                break
            default:
                break
            }
            
        case "削除":
            //削除する
            if self.willEditDocIndexPathRow == -1 { break }     //-1の時はおかしいので帰る
            
            
            let realm = try! Realm()
            
            // ターゲットが書類かフォルダかを判定する
            switch targetListCell.documentData {
            case is Document:
                
                //アラートで聞く
                Alertift.alert(title: Localize.alert.default.areYouSure,
                               message: Localize.alert.default.cannotBeUndone)
                    .action(.destructive(Localize.alert.default.delete)) {
                        
                        //問題のドキュメント
                        let targetDocument = targetListCell.documentData as! Document
                                                          
                        try! realm.write {
                            //もしPDFならPDFのデータも消す
                            if targetDocument.type == "pdf" {
                                //uidで指定して削除
                                realm.delete(realm.objects(PDFData.self).filter({ $0.uuid == targetDocument.uid }))
                            }
                            //ターゲットを排除
                            realm.delete(targetDocument)
                        }
                        
                        //リストを更新
                        self.reloadDocumentDatas()
                        
                        DispatchQueue.main.async {
                            
                            //UIの更新
                            self.collectionView.deleteItems(at: [IndexPath(row: self.willEditDocIndexPathRow,
                                                                           section: 0)])
                            
                            //willEditDocIndexPathRowを-1に
                            self.willEditDocIndexPathRow = -1
                            
                        }
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
                
            case is Folder:
                
                // 中身も消えるけどいいか聞く
                Alertift.alert(title: Localize.alert.list.isOkToDeleteFolder,
                               message: Localize.alert.default.areYouSure)
                    .action(.destructive(Localize.alert.default.delete)) {
                        //対象のフォルダー
                        let targetFolder = targetListCell.documentData as! Folder
                                                 
                        // フォルダーを削除
                        Process.deleteFolderInside(folder: targetFolder)
                        
                        //リストを更新
                        self.reloadDocumentDatas()
                        
                        DispatchQueue.main.async {
                            
                            //UIの更新
                            self.collectionView.deleteItems(at: [IndexPath(row: self.willEditDocIndexPathRow,
                                                                           section: 0)])
                            
                            //willEditDocIndexPathRowを-1に
                            self.willEditDocIndexPathRow = -1
                            
                        }
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
                
            default:
                print("絶対発生しないはず in ListCollectionViewCellのcontextMenuDidSelect(_:)")
            }
            
            
            // 中身も消えるけどいいか聞く
            Alertift.alert(title: Localize.alert.list.isOkToDeleteFolder,
                           message: Localize.alert.default.areYouSure)
                .action(.destructive(Localize.alert.default.delete)) {
                    //対象のフォルダー
                    let targetFolder = targetListCell.documentData as! Folder
                                             
                    // フォルダーを削除
                    Process.deleteFolderInside(folder: targetFolder)
                }
            
        default:
            break
        }
        
        
        
        
        return true
    }
    
    func contextMenuDidDeselect(_ contextMenu: ContextMenu, cell: ContextMenuCell, targetedView: UIView, didSelect item: ContextMenuItem, forRowAt index: Int) {
        
    }
    
    func contextMenuDidAppear(_ contextMenu: ContextMenu) {
        
    }
    
    func contextMenuDidDisappear(_ contextMenu: ContextMenu) {
        
    }
    
    
}

extension ListCollectionViewController: ListCollectionViewControllerDelegate {
    
    //コレクションをリロード
    func reloadCollection() {
        
        reloadDocumentDatas()
        sortCollection()
        
        //更新したのでUIも更新
        collectionView.reloadData()
        
    }
    
    /// ソート付きでリロード
    func reloadCollectionWith(sort: ListSortType, isReversed: Bool) {
        
        //ソートのスタイルを更新
        sortStyle = sort
        
        self.isSortReversed = isReversed
        
        // リロード
        reloadCollection()
    }
    
    /// フォルダーをセットする
    func setFolder(folder: Folder) {
        self.currentPath = folder.uid
        
        // データ更新してリロード
        self.reloadDocumentDatas()
        self.collectionView.reloadData()
    }
    
}


