//
//  SettingsTableViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import RealmSwift
import Alertift
import StoreKit
import SafariServices
import SwiftMessages

class SettingsTableViewController: UITableViewController {
    
    /// シートの表示色のビュー
    @IBOutlet weak var sheetColorView: UIView!
    
    /// 角丸のスイッチ
    @IBOutlet weak var roundedSwitch: UISwitch!
    
    /// シートの表示色の親ビュー
    @IBOutlet weak var sheetColorParentView: UIView!
    
    /// キャッシュのバイトサイズを表すラベル
    @IBOutlet weak var cacheBytesSizeLabel: UILabel!
    
    ///設定
    var config: Config!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        config = realm.objects(Config.self).first!
        
        //角丸
        sheetColorParentView.layer.cornerRadius = 16
        //マスク
        sheetColorParentView.layer.masksToBounds = true
        
        //色
        sheetColorView.backgroundColor = UIColor(hex: config.sheetAppearanceHex,
                                                 alpha: CGFloat(config.sheetAppearanceAlpha))
        
        //タイトルをセット
        self.title = NSLocalizedString("settingVC.title", comment: "")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // キャッシュサイズを更新
        updateFilterCacheSize()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
            
        case 1:
            return 2
            
        case 2:
            return 1
            
        case 3:
            return 5
            
        default:
            return 0
        }
        
    }
    
    //選択されたら
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                //シートの色を変更する
                changeSheetColor()
                
            case 1:
                //シートの管理へ
                self.performSegue(withIdentifier: "toEditColor", sender: nil)
                
            case 2:
                //選択解除
                deselectCell(indexPath: indexPath)
                
            case 3:
                //グラデーション表示
                
                //選択解除
                deselectCell(indexPath: indexPath)
                break
                
            default:
                break
            }
            
        case 1:
            switch indexPath.row {
            case 0:
                
                //評価をする
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
                
                //選択を解除
                deselectCell(indexPath: indexPath)
                
                
            case 1:
                // バグの報告フォームへ飛ぶ
                let webPage = "https://forms.gle/mdk4BwGqysEXRVDf9"
                let safariVC = SFSafariViewController(url: NSURL(string: webPage)! as URL)
                safariVC.modalPresentationStyle = .pageSheet
                present(safariVC, animated: true, completion: nil)
                
                
            default:
                break
            }
            
        case 2:
            switch indexPath.row {
            case 0:
                //クレジットを表示
                let creditSB = UIStoryboard(name: "Credit", bundle: nil)
                let creditVC = creditSB.instantiateViewController(identifier: "credit")
                
                self.present(creditVC,
                             animated: true,
                             completion: nil)
                
            case 1:
                //アプリアイコンを変更するページに飛ぶ
                let changeIconSB = UIStoryboard(name: "ChangeIcon", bundle: nil)
                let changeIconVC = changeIconSB.instantiateViewController(identifier: "changeIcon")
                
                self.show(changeIconVC, sender: nil)
            
                
            case 2:
                // バージョン情報を表示する(更新履歴的な)
                break
                
            case 3:
                //プライバシーポリシーに飛ぶ
                let webPage = "https://redsheet.hateblo.jp/entry/2020/03/18/170008"
                let safariVC = SFSafariViewController(url: NSURL(string: webPage)! as URL)
                safariVC.modalPresentationStyle = .pageSheet
                present(safariVC, animated: true, completion: nil)
                
            default:
                break
                
            }
            
            //選択を解除する
            deselectCell(indexPath: indexPath)
            
        case 3:
            switch indexPath.row {
            case 0:
                Alertift.alert(title: Localize.default.settings.deleteCache, message: Localize.default.settings.deleteCacheTips)
                    .action(.destructive(Localize.default.settings.delete)) {
                        self.deleteFilterImageObjs()
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
            
            case 1:
                Alertift.alert(title: Localize.default.settings.resetSettings, message: Localize.default.settings.cannotBeUndone)
                    .action(.destructive(Localize.default.settings.reset)) {
                        self.resetSettings()
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
                
            case 2:
                Alertift.alert(title: Localize.default.settings.deleteAllSheet, message: Localize.default.settings.cannotBeUndone)
                    .action(.destructive(Localize.default.settings.delete)) {
                        self.deleteAllSheet()
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
                
            case 3:
                Alertift.alert(title: Localize.default.settings.deleteAllDocument, message: Localize.default.settings.cannotBeUndone)
                    .action(.destructive(Localize.default.settings.delete)) {
                        self.deleteAllDocument()
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
                
            case 4:
                Alertift.alert(title: Localize.default.settings.clearAllData, message: Localize.default.settings.cannotBeUndone)
                    .action(.destructive(Localize.default.settings.delete)) {
                        self.clearAllData()
                    }
                    .action(.cancel(Localize.alert.default.cancel))
                    .show()
                
            default:
                break
            }
            
            //選択解除
            deselectCell(indexPath: indexPath)
            
        default:
            break
        }
    }
    
    //角丸スイッチの値が変わった
    @IBAction func roundedSwitchValueChanged(_ sender: UISwitch) {
        
        let realm = try! Realm()
        let config = realm.objects(Config.self).first!
        
        try! realm.write {
            config.sheetRounded = sender.isOn
        }
        
    }
    
    
    /// 設定をリフレッシュ
    func reloadSettings() {
        
        roundedSwitch.isOn = config.sheetRounded    //角丸
        sheetColorView.backgroundColor = UIColor(hex: config.sheetAppearanceHex,
                                                 alpha:  CGFloat(config.sheetAppearanceAlpha))
        
        Alertift.alert(title: "確認", message: "変更を適用するためにアプリを終了します")
            .action(.default("OK👌")) {
                UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                //Comment if you want to minimise app
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
                    exit(0)
                }
            }
            .show()
        
    }
    
    /// ピッカーに遷移して、シートの色を変更する
    func changeSheetColor() {
        
        //カラーピッカー
        let colorPicker = UIColorPickerViewController()
        
        colorPicker.delegate = self
        
        //色をセットする
        colorPicker.selectedColor = sheetColorView.backgroundColor!
        
        self.present(colorPicker, animated: true, completion: nil)
        
    }
    
    /// フィルターキャッシュを削除する
    func deleteFilterImageObjs() {
        
        
        let realm = try! Realm()
        
        let allFilterImageObjs = realm.objects(FilteredImage.self)
        
        try! realm.write {
            realm.delete(allFilterImageObjs)    //削除ー！
        }
        
        //完了アラートを
        Alertift.alert(title: "🎉", message: "フィルターキャッシュを正常に削除できました")
            .action(.cancel("👌OK")) {
                // キャッシュサイズを更新
                self.updateFilterCacheSize()
            }
            .show()
        
    }
    
    /// 設定を初期化
    func resetSettings() {
        let realm = try! Realm()
        
        let newConfig = Config()
        
        try! realm.write {
            realm.delete(config)
            realm.add(newConfig)
        }
        
        config = realm.objects(Config.self).first!
        
        reloadSettings()
    }
    
    /// シートをデフォルト以外前消去
    func deleteAllSheet() {
        let realm = try! Realm()
        
        let oldSheets = realm.objects(Sheet.self)
        
        let newSheet = Sheet()
        
        try! realm.write {
            realm.delete(oldSheets)
            realm.add(newSheet)
        }
        
        reloadSettings()
    }
    
    /// ドキュメントを全消去
    func deleteAllDocument() {
        
        let realm = try! Realm()
        
        let oldDocuments = realm.objects(Document.self)
        
        try! realm.write {
            realm.delete(oldDocuments)
        }
        
        reloadSettings()
        
    }
    
    /// 全データ消去
    func clearAllData() {
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
        }
        
        //        reloadSettings()
        Alertift.alert(title: "確認", message: "変更を適用するためにアプリを終了します")
            .action(.default("OK👌")) {
                UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                //Comment if you want to minimise app
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
                    exit(0)
                }
            }
            .show()
    }
    
    /// 指定したインデックスパスのセルの選択状態を解除する
    func deselectCell(indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)!
        
        cell.setSelected(false, animated: true)
    }
    
    
    /// シートの見た目を変更したことを表すアラート
    private func showAlertChangeSheetAppearance() {
        
        // 表示するビュー
        let view = MessageView.viewFromNib(layout: .tabView)
        
        // .error, .info, .success, .warning
        view.configureTheme(.info)
        
        // 影をつけることができます
        view.configureDropShadow()
        
        //非表示
        view.iconLabel?.isHidden = true
        view.button?.isHidden = true
        
        // タイトル、メッセージ本文、アイコンとなる絵文字をセットします
        view.configureContent(title: "成功",
                              body: "シートの見た目を変更しました",
                              iconText: "✅")
        
        // 角丸を指定します
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 8
        
        //表示の設定を変更
        var config = SwiftMessages.Config()
        
        config.duration = .seconds(seconds: 1)
        
        // アラートを表示します
        SwiftMessages.show(config: config, view: view)
        
    }
    
    /// フィルターキャッシュのサイズを計算して更新する
    func updateFilterCacheSize() {
        
        self.cacheBytesSizeLabel.text = "現在のキャッシュサイズ: 計算中..."
        
        DispatchQueue(label: "background").async {
            
            // フィルターキャッシュのサイズを計算する
            let realm = try! Realm()
            
            var byteSize: Int64 = 0
            
            for filterImgObj in realm.objects(FilteredImage.self) {
                byteSize += Int64(filterImgObj.data.count)
            }
            
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = .useAll
            formatter.countStyle = .file
            formatter.includesUnit = true
            formatter.isAdaptive = true
            
            // サイズを文字列化
            let byteSizeString = formatter.string(fromByteCount: byteSize)
            
            //更新
            DispatchQueue.main.async {
                self.cacheBytesSizeLabel.text = "現在のキャッシュサイズ: \(byteSizeString)"
            }
            
        }
        
    }
    
}

extension SettingsTableViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        print("Selected color: \(viewController.selectedColor)")
        
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("Color picker has been closed")
        
        //色を更新
        let realm = try! Realm()
        let config = realm.objects(Config.self).first!
        
        //更新
        try! realm.write {
            config.sheetAppearanceHex = viewController.selectedColor.hex()
            config.sheetAppearanceAlpha = Float(viewController.selectedColor.cgColor.alpha)
        }
        
        //見た目を更新
        sheetColorView.backgroundColor = viewController.selectedColor
        
        //選択を解除
        deselectCell(indexPath: IndexPath(row: 0, section: 0))
        
        //アラートを出す
        showAlertChangeSheetAppearance()
    }
    
}
