//
//  EditColorTableViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/18.
//

import UIKit
import RealmSwift
import Hero
import SwipeCellKit
import SwiftMessages

protocol EditColorTableViewControllerDelegate {
    func updateColor()
    func updateTable()
}

class EditColorTableViewController: UITableViewController {
    
    /// シート一覧
    var sheetList: Array<Sheet> = []
    
    /// 最後にタップされたセル
    var lastTappedCellIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //セルを登録
        tableView.register(UINib(nibName: "EditColorTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: "editColorCell")
        
        // realmからデータを
        refreshDataFromRealm()
        
        // 下の方にできる謎のセルを削除
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sheetList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        /// ロー
        let row = indexPath.row
        
        ///セル
        let cell = tableView.dequeueReusableCell(withIdentifier: "editColorCell") as! EditColorTableViewCell
        
        //シートをセットする
        cell.setData(sheet: sheetList[row])
        
        //スワイプセルキット用のデリゲート
        cell.delegate = self
        
        //返す
        return cell
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //セルが選択されたら...
        //シートを取得して遷移
        let sheet = sheetList[indexPath.row]
        
        //
        let newColorSB = UIStoryboard(name: "NewColor", bundle: nil)
        let newColorVC = newColorSB.instantiateViewController(identifier: "newColor") as! NewColorViewController
        
        newColorVC.isAdding = false     //更新モードに
        newColorVC.editDelegate = self
        newColorVC.isFromShow = true
        
        //最後にタップされたセルを記録
        lastTappedCellIndex = indexPath.row
        
        //データを渡す
        newColorVC.setData(sheet: sheet)
        
        //遷移
        self.show(newColorVC, sender: nil)
        
    }
    
    /// 追加ボタンを押した
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        // 参考: https://qiita.com/am10/items/cf5101cd7777da9d0113
        // https://developer.apple.com/forums/thread/87823 (BarBottomItemからviewを取得する)
        // https://qiita.com/orimomo/items/1a44337de974a72b6266 (sourceRectへの言及)
        
        // ポップアップを表示する
        
        let popupVC = EditColorPopupTableViewController() //popoverで表示するViewController
        popupVC.modalPresentationStyle = .popover
        popupVC.preferredContentSize = popupVC.view.frame.size
        popupVC.preferredContentSize.height = 32 * 7 + 28 * 2    // ここの7はセルの数、2はセクションの数
        popupVC.popoverPresentationController?.sourceView = (sender.value(forKey: "view") as! UIView)
        popupVC.popoverPresentationController?.sourceRect = (sender.value(forKey: "view") as! UIView).frame
        
        let presentationController = popupVC.popoverPresentationController
        presentationController?.delegate = self
        presentationController?.permittedArrowDirections = .up
        presentationController?.barButtonItem = sender
        
        // デリゲートを実行
        popupVC.delegate = self
        
        present(popupVC, animated: true, completion: nil)
        
    }
    
    ///  デフォルトのカラーを追加する
    private func addDefaultColor() {
        
        //
        let newColorSB = UIStoryboard(name: "NewColor", bundle: nil)
        let newColorVC = newColorSB.instantiateViewController(identifier: "newColor") as! NewColorViewController
        
        newColorVC.isAdding = true     //更新モードに
        newColorVC.isFromShow = true
        newColorVC.editDelegate = self
        
        //データを渡す
        newColorVC.setData(color: UIColor.systemOrange)
        
        //遷移
        self.show(newColorVC, sender: nil)
        
    }
    
    /// realmからデータを取得して更新する
    private func refreshDataFromRealm() {
        
        //realmからシートを取得
        let realm = try! Realm()
        let sheets = realm.objects(Sheet.self)
        
        // 空に
        sheetList = []
        
        for sheet in sheets {
            sheetList.append(sheet) //ぶち込む
        }
        
    }
    
}

extension EditColorTableViewController: EditColorTableViewControllerDelegate {
    
    /// 更新されたセルをアニメーション付きで更新
    func updateColor() {
        
        //リストを更新
        sheetList = []
        
        let realm = try! Realm()
        let sheets = realm.objects(Sheet.self)
        
        for sheet in sheets {
            sheetList.append(sheet)
        }
        
        //アニメーション
        tableView.reloadRows(at: [IndexPath(row: lastTappedCellIndex,
                                            section: 0)],
                             with: .fade)
        
        
    }
    
    /// テーブルを更新
    func updateTable() {
        
        //リストを更新
        sheetList = []
        
        let realm = try! Realm()
        let sheets = realm.objects(Sheet.self)
        
        for sheet in sheets {
            sheetList.append(sheet)
        }
        
        //テーブル更新
        tableView.reloadData()
        
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
    
}

extension EditColorTableViewController: SwipeTableViewCellDelegate {
    
    /// スワイプ時に出るアクション
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        switch orientation {
        case .right:
            
            let deleteAction = SwipeAction(style: .destructive, title: "削除") { action, indexPath in
                
                //MARK: 削除する処理
                //realm から削除
                let realm = try! Realm()
                let sheets = realm.objects(Sheet.self)
                
                try! realm.write {
                    realm.delete(sheets[indexPath.row]) //削除
                }
                
                //もしシートがなかったらデフォルトのを作成
                if realm.objects(Sheet.self).count == 0 {
                    
                    //デフォルトシートを作成
                    Process.createDefaultSheet()
                    
                    //更新
                    self.sheetList = []
                    
                    for sheet in sheets {
                        self.sheetList.append(sheet)
                    }
                    
                    //更新
                    tableView.reloadData()
                    
                    //アラート
                    self.showAlertAddedDefaultSheet()
                    
                } else {
                    
                    //更新
                    self.sheetList = []
                    
                    for sheet in sheets {
                        self.sheetList.append(sheet)
                    }
                    
                    //tableからせるを削除
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                }
                
            }
            
            // customize the action appearance
            deleteAction.image = UIImage(systemName: "trash")
            
            return [deleteAction]
            
        default:
            return []
            
        }
    }
    
    
}

extension EditColorTableViewController: UIPopoverPresentationControllerDelegate {
    
    // iPhoneで表示させる場合に必要
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
}

extension EditColorTableViewController: EditColorPopupTableViewDelegate {
    
    /// デフォルトのフィルターの作成画面へ遷移する
    func createBlankFilter() {
        
        addDefaultColor()
        
    }
    
    /// テンプレを追加する
    func addExsistingFilter(filter: FilterModel) {
        // realmへ追加してリフレッシュ
        
        let realm = try! Realm()
        
        let newFilter = Sheet()
        newFilter.colorHex = filter.targetColor.hex()
        newFilter.insteadColorHex = filter.insteadColor.hex()
        newFilter.tolerance = filter.tolerance
        newFilter.uuid = UUID().uuidString
        
        // 追加
        try! realm.write {
            realm.add(newFilter)
        }
        
        // 配列の更新
        refreshDataFromRealm()  //データを更新
        
        // rowを追加
        self.tableView.insertRows(at: [IndexPath(row: sheetList.count - 1,
                                                 section: 0)],
                                  with: .automatic)
    }
    
}

/// フィルター
struct FilterModel {
    /// フィルター名
    let name: String
    let targetColor: UIColor // 入れ替える対象の色(オレンジ等)
    let insteadColor: UIColor // 入れ替え後の色(白など)
    let tolerance: Float // 厳しさ
}


