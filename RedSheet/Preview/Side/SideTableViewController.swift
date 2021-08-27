//
//  SideTableViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/16.
//

import UIKit
import RealmSwift
import ContextMenuSwift
import Alertift
import SwiftMessages

protocol SideTableViewControllerDelegate: AnyObject {
    func reloadTable()
    func refreshFilter()
    //    func leaveColorSelectingProcess(sheetData: EditingSheetData)   //カラーピッカーの表示をここで行う
}

class SideTableViewController: UITableViewController, UIGestureRecognizerDelegate {
    
    
    //シートのリスト
    var sheetList: Array<Sheet> = []
    
    // 有効のリスト
    var enabledSheetList: Array<Sheet> = []
    
    //デリゲート
    weak var delegate: PreviewViewControllerDelegate?
    
    // newColorから渡される情報の集合体
    var editingSheetData: EditingSheetData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //realmから色を取得
        let realm = try! Realm()
        
        for sheet in realm.objects(Sheet.self) {
            sheetList.append(sheet) //ぶち込む
        }
        
        //一番最初のをぶち込む
        enabledSheetList.append(sheetList.first!)
        
        //セルの登録
        tableView.register(UINib(nibName: "SideColorTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "sideCell")
        
        //長押し時の判定
        // UILongPressGestureRecognizer宣言
        let longPressRecognizer = UILongPressGestureRecognizer(target: self,
                                                               action: #selector(SideTableViewController.cellLongPressed(_ :)))
        
        // `UIGestureRecognizerDelegate`を設定するのをお忘れなく
        longPressRecognizer.delegate = self
        
        // tableViewにrecognizerを設定
        tableView.addGestureRecognizer(longPressRecognizer)
        
        
        // 通知の登録
        // ピッカーを開く
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(leaveColorSelectingProcess(notification:)),
                                               name: .willColorPickerBeCalled,
                                               object: nil)
        
        // シートが更新されたら実行
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sheetUpdated),
                                               name: .sheetUpdated,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sheetList.count + 1  //一番下は追加ボタンなので
    }
    
    //セルの生成
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        ///ロー
        let row = indexPath.row
        
        ///せる
        let cell = tableView.dequeueReusableCell(withIdentifier: "sideCell") as! SideColorTableViewCell
        
        //普通の色ボタン
        if row < sheetList.count {
            
            
            let realm = try! Realm()
            
            //            enabledSheetList.forEach({ item in
            //                print("uuid: ", item.uuid)
            //            })
            //
            //            print("self uuid: ", realm.objects(Sheet.self)[row].uuid)
            
            //リストに入ってればチェックマークをオンにする
            cell.isThisSheetEnabled = enabledSheetList.filter({$0.uuid == realm.objects(Sheet.self)[row].uuid}).count > 0
            
            /*
             上のフィルターの内容:
             それぞれのuuidがrealmの[row]のシートと一致したものだけのarrayを作って、その数が0よりも多ければ(1になる)一致する判定
             */
            
            cell.setData(sheetData: sheetList[row])
            
        } else {
            //追加ボタン
            cell.createAddButton()
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width
    }
    
    //選択された
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        /// セル
        let cell = tableView.cellForRow(at: indexPath) as! SideColorTableViewCell
        
        if indexPath.row < sheetList.count {
            //通常の色ボタン
            
            print("enabledSheetList:", enabledSheetList)
            
            //有効リストを更新する
            if enabledSheetList.contains(where: {$0.uuid == sheetList[indexPath.row].uuid}) {    //含んでたら
                //消す
                enabledSheetList.removeAll(where: {$0.uuid == sheetList[indexPath.row].uuid})
            } else {    //なかったら追加
                enabledSheetList.append(sheetList[indexPath.row])
            }
            
            //フィルターを更新
            delegate?.makeImageFiltered(sheet: sheetList[indexPath.row])
            
            //セルを選択状態に
            cell.changeSelectedState()
            
        } else {
            //追加ボタン
            
            //newcolorに遷移
            let newColorSB = UIStoryboard(name: "NewColor", bundle: nil)
            let newColorVC = newColorSB.instantiateViewController(identifier: "newColor") as! NewColorViewController
            
            newColorVC.sideDelegate = self
            newColorVC.isAdding = true
            
            //遷移
            self.present(newColorVC, animated: true, completion: nil)
            
            //選択状態の表示を解除
            cell.setSelected(false, animated: true)
        }
        
    }
    
    /// セルが長押しした際に呼ばれるメソッド
    @objc func cellLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        
        // 押された位置でcellのPathを取得
        let point = recognizer.location(in: tableView)
        // 押された位置に対応するindexPath
        let indexPath = tableView.indexPathForRow(at: point)
        
        if indexPath == nil {  //indexPathがなかったら
            
            return  //すぐに返り、後の処理はしない
            
        } else if recognizer.state == UIGestureRecognizer.State.began  {
            // 長押しされた場合の処理
            
            //コンテキストメニューの内容を作成します
            let edit = ContextMenuItemWithImage(title: "編集", image: UIImage(systemName: "square.and.pencil")!)
            let delete = ContextMenuItemWithImage(title: "削除", image: UIImage(systemName: "trash")!)
            
            //コンテキストメニューに表示するアイテムを決定します
            CM.items = [edit, delete]
            //表示します
            CM.showMenu(viewTargeted: tableView.cellForRow(at: indexPath!)!,
                        delegate: self,
                        animated: true)
            
        }
    }
    
    /// デフォルトのシートを追加したことを表すアラート
    private func showAlertAddedDefaultSheet() {
        
        // 表示するビュー
        let view = MessageView.viewFromNib(layout: .cardView)
        
        // テンプレなのでテーマも用意されています
        // .error, .info, .success, .warning
        view.configureTheme(.info)
        
        // 影をつけることができます
        view.configureDropShadow()
        
        //非表示
        view.titleLabel?.isHidden = true
        view.iconLabel?.isHidden = true
        view.button?.isHidden = true
        
        // タイトル、メッセージ本文、アイコンとなる絵文字をセットします
        view.configureContent(title: "",
                              body: "シートがなくなったのでデフォルトのシートを追加しました",
                              iconText: "ℹ️")
        
        // 角丸を指定します
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 8
        
        // アラートを表示します
        SwiftMessages.show(view: view)
        
    }
    
    /// カラーピッカーの表示、データの受け渡し
    @objc func leaveColorSelectingProcess(notification: NSNotification?) {
        
        // データを取り出す
        editingSheetData = notification?.userInfo!["data"] as? EditingSheetData
        
        //カラーピッカーを表示する
        showColorPicker()
        
    }
    
    /// カラーピッカーを表示
    func showColorPicker() {
        
        //遷移
        let colorPicker = UIColorPickerViewController()
        
        colorPicker.delegate = self
        
        colorPicker.supportsAlpha = false
        
        //色をセットする
        colorPicker.selectedColor = {
            switch editingSheetData!.editingColorType  {
            case .target:
                return UIColor(hex: editingSheetData!.targetSheet.colorHex)
            case .instead:
                return UIColor(hex: editingSheetData!.targetSheet.insteadColorHex)
            }
        }()
        
        self.present(colorPicker, animated: true, completion: nil)
        
    }
    
    /// シートが更新されたら更新
    @objc func sheetUpdated() {
        //        reloadTable()
        //TODO: ここの処理
        // 右下の三角形のアップデート(SwiftUIに移行するかも)
    }
}

// MARK: 自身のデリゲート
extension SideTableViewController: SideTableViewControllerDelegate {
    
    /// テーブルの更新
    func reloadTable() {
        
        //古いの
        let oldList = sheetList
        
        //一回初期化
        sheetList = []
        
        //realmから色を取得
        let realm = try! Realm()
        
        for sheet in realm.objects(Sheet.self) {
            sheetList.append(sheet) //ぶち込む
        }
        
        //比較
        let isDiffrent: Bool = {
            var result: Bool = false
            oldList.forEach({ item in
                if !sheetList.contains(where:
                                        {
                                            $0.uuid == item.uuid &&
                                                $0.colorHex == item.colorHex &&
                                                $0.insteadColorHex == item.insteadColorHex &&
                                                $0.tolerance == item.tolerance
                                        }) {
                    result = true
                }
            })
            return result
        }()
        
        //更新
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if isDiffrent {
                self.refreshFilter()
            }
        }
    }
    
    /// フィルターを更新
    @objc func refreshFilter() {
        //フィルターを更新
        self.delegate?.refreshFilter()
    }
    
}

// MARK: ContextMenuDelegate
extension SideTableViewController: ContextMenuDelegate {
    
    /**
     コンテキストメニューの選択肢が選択された時に実行される
     - Parameters:
     - contextMenu: そのコンテキストメニューだと思われる
     - cell: **選択されたコンテキストメニューの**セル
     - targetView: コンテキストメニューの発生源のビュー
     - item: 選択されたコンテキストのアイテム(タイトルとか画像とかが入ってる)
     - index: **選択されたコンテキストのアイテムの**座標
     - Returns: よくわからない(多分成功したらtrue...?)
     */
    func contextMenuDidSelect(_ contextMenu: ContextMenu,
                              cell: ContextMenuCell,
                              targetedView: UIView,
                              didSelect item: ContextMenuItem,
                              forRowAt index: Int) -> Bool {
        
        //セル
        let cell = targetedView as! SideColorTableViewCell
        let cellIndexPath = tableView.indexPathForRow(at: targetedView.frame.origin)
        //シートを取得
        let sheet = cell.sheet
        
        //indexで分岐
        switch index {
        case 0:
            //NewColorに編集で遷移
            let newColorSB = UIStoryboard(name: "NewColor", bundle: nil)
            let newColorVC = newColorSB.instantiateViewController(identifier: "newColor") as! NewColorViewController
            
            newColorVC.isAdding = false
            
            newColorVC.setData(sheet: sheet)
            
            newColorVC.sideDelegate = self
            
            self.present(newColorVC,
                         animated: true,
                         completion: nil)
            
        case 1:
            
            let alert: UIAlertController = UIAlertController(title: "確認",
                                                             message: "本当に削除しますか？",
                                                             preferredStyle:  .alert)
            // 通常のアクション
            let defaultAction: UIAlertAction = UIAlertAction(title: "削除",
                                                             style: .destructive,
                                                             handler: { (action: UIAlertAction!) -> Void in
                                                                
                                                                //リストから削除
                                                                self.enabledSheetList.removeAll(where: {$0.uuid == sheet.uuid})
                                                                
                                                                //フィルターを削除して更新
                                                                self.delegate?.removeFilter(sheet: sheet)
                                                                
                                                                let realm = try! Realm()
                                                                
                                                                //もし0こなら
                                                                if realm.objects(Sheet.self).count == 0 {
                                                                    
                                                                    //デフォルトのシートを追加
                                                                    Process.createDefaultSheet()
                                                                    
                                                                    //一覧を更新
                                                                    self.sheetList = []
                                                                    for item in realm.objects(Sheet.self) {
                                                                        self.sheetList.append(item)
                                                                    }
                                                                    
                                                                    //tableを更新
                                                                    self.tableView.reloadData()
                                                                    
                                                                    //アラートを表示
                                                                    self.showAlertAddedDefaultSheet()
                                                                    
                                                                } else {
                                                                    
                                                                    //一覧を更新
                                                                    self.sheetList = []
                                                                    for item in realm.objects(Sheet.self) {
                                                                        self.sheetList.append(item)
                                                                    }
                                                                    
                                                                    //セルを削除
                                                                    self.tableView.deleteRows(at: [cellIndexPath!], with: .fade)
                                                                    
                                                                }
                                                                
                                                                
                                                             })
            // キャンセルアクション
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル",
                                                            style: .cancel,
                                                            handler:{ (action: UIAlertAction!) -> Void in
                                                                
                                                                
                                                            })
            
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            
            // Alertを表示
            present(alert, animated: true, completion: nil)
            
            
        default:
            break   //何もしない
        }
        
        
        
        //サンプルではtrueを返していたのでとりあえずtrueを返してみる
        return true
        
    }
    
    /**
     コンテキストメニューの選択肢が選択された時に実行される
     - Parameters:
     - contextMenu: そのコンテキストメニューだと思われる
     - cell: **選択されたコンテキストメニューの**セル
     - targetView: コンテキストメニューの発生源のビュー
     - item: 選択されたコンテキストのアイテム(タイトルとか画像とかが入ってる)
     - index: **選択されたコンテキストのアイテムの**座標
     こちらは値を返さない方
     (値を返す方との違いがよくわからないが、サンプルでは返す方を使っていたのでそちらを使うことを推奨)
     */
    func contextMenuDidDeselect(_ contextMenu: ContextMenu,
                                cell: ContextMenuCell,
                                targetedView: UIView,
                                didSelect item: ContextMenuItem,
                                forRowAt index: Int) {
    }
    
    /**
     コンテキストメニューが表示されたら呼ばれる
     */
    func contextMenuDidAppear(_ contextMenu: ContextMenu) {
    }
    
    /**
     コンテキストメニューが消えたら呼ばれる
     */
    func contextMenuDidDisappear(_ contextMenu: ContextMenu) {
    }
    
    
}

// MARK: カラーピッカー
extension SideTableViewController: UIColorPickerViewControllerDelegate {
    
    // 選択肢終わったら
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        //        print("Color picker has been closed")
        
        guard let editingSheetData = editingSheetData else { return }
        //        let realm = try! Realm()
        
        //        try! realm.write {
        switch editingSheetData.editingColorType {
        case .target:
            editingSheetData.targetSheet.colorHex = viewController.selectedColor.hex()
            
        case .instead:
            editingSheetData.targetSheet.insteadColorHex = viewController.selectedColor.hex()
            
        }
        //        }
        
        //値をセットし、再びNewColorに遷移する
        //newcolorに遷移
        let newColorSB = UIStoryboard(name: "NewColor", bundle: nil)
        let newColorVC = newColorSB.instantiateViewController(identifier: "newColor") as! NewColorViewController
        
        newColorVC.sideDelegate = self
        newColorVC.isAdding = editingSheetData.sheetStatus == .adding
        
        newColorVC.setDataAgain(sheetData: editingSheetData)    //データを一応際設定
        
        //遷移
        self.present(newColorVC, animated: true, completion: nil)
        
    }
}
