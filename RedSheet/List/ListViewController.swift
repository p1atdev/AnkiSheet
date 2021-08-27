//
//  ListViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import Instructions
import RealmSwift
import PKHUD
import SwiftMessages
import StoreKit
import Alertift
import Firebase
//import ChameleonFramework

protocol ListViewControllerDelegate {
    func reloadCollectionWith(sort: ListSortType)
}

class ListViewController: UIViewController  {
    
    /// メニューを開くボタン
    @IBOutlet weak var menuButton: HamburgerMenuRootButton!
    
    /// メニューのコンテナ
    @IBOutlet weak var menuContainer: UIView!
    
    /// フォルダーを作るボタン
//    @IBOutlet weak var createFolderButton: UIBarButtonItem!
    
    
    // MARK: Variables
    
    /// メニューが開いてるかどうか
    var isMenuOpend: Bool = false
    
    /// チュートリアルのコーチ
    let coachMarksController = CoachMarksController()
    
    ///フラグ
    var flag: Flag?
    
    /// コレクションのデリゲート
    weak var collectionDelegate: ListCollectionViewControllerDelegate?
    
    /// コレクションの並びは逆向き状態か
    var isReveresed = false
    
    /// 今のコレクションの並びから
    var listSortType: ListSortType = .name
    
    /// 今のフォルダー
    var currentFolder: Folder?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //メニューボタンの設定
        //メニューボタンの中心を設定
        menuButton.center = CGPoint(x: menuButton.frame.origin.x + menuButton.frame.width / 2,
                              y: menuButton.frame.origin.y + menuButton.frame.height / 2)
        
        menuButton.isPlusButton = true
        
        //チュートリアル
        self.coachMarksController.dataSource = self
        
        //realmからフラグを取得
        let realm = try! Realm()
        flag = realm.objects(Flag.self).first!
        
        // タイトルをセットする
        title = NSLocalizedString("listVC.title", comment: "")
        
        // NotificationCenterを登録
        // ファイルが追加されたという通知がきた時に実行するものを設定
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fileReceived),
                                               name: .fileReceived, object: nil)
        
        // スプラッシュからの遷移
//        self.view.alpha = 0
        
        // 対応していない機能を隠す
        hideUnsupportedFeatures()
        
        // ソートボタンのセットアップ
        setupSortButton()
        
        // フォルダー追加ボタンのセットアップ
        setupAddFolderButton()
        
        // フォルダーパス関連をセットアップ
        setupFolder()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // スプラッシュから自然につながるように
//        UIView.animate(withDuration: 0.8,
//                       delay: 0,
//                       options: .curveEaseInOut, animations: {
//                        
//                        self.view.alpha = 1.0
//
//                       })
        
        //もし指定の条件ならレビューを促すアラートを出す
        if let flag = flag {
            if flag.numberOfReturnFromPreview % 30 == 3 {
                
                //評価をする
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
                
                //フラグを更新
                let realm = try! Realm()
                try! realm.write {
                    flag.numberOfReturnFromPreview += 1
                }
                
            }
            
            // 閲覧途中のやつを再開
            resumeLastDocument()
            
            //もし初回じゃなかったら帰る
            if !flag.isFirstOpenList { return }
            
            //チュートリアルを開始
            self.coachMarksController.start(in: .currentWindow(of: self))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        self.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "toMenu":
            let menu = segue.destination as! MenuViewController
            menu.delegate = self
            
        case "toCollection":
            let collection = segue.destination as! ListCollectionViewController
            self.collectionDelegate = collection
            
        default:
            break
        }
        
    }
    
    //ボタンが押し込まれた
    @IBAction func menuButtonTouchDown(_ sender: Any) {
        //影っぽくする
        menuButton.alpha = 0.8
    }
    
    //ボタンから指が離れた
    @IBAction func menuButtonTouchUp(_ sender: Any) {
        //影っぽいのを外す
        menuButton.alpha = 1.0
    }
    
    //メニューボタンが押された時のアクション
    @IBAction func menuButtonTouchUpInside(_ sender: Any) {
        
        /// メニュー
        let menuContainerVC = self.children[1] as! MenuViewController
        
        menuContainerVC.changeButtonStatus(isOpened: isMenuOpend)
        
        //閉じてたら
        if !isMenuOpend {
            
            //360 + 45度回転させる
            menuButton.rotate(angle: 360 + 45)
            
        } else {
            //空いてたら
            
            // -360 - 45度回転させる
            menuButton.rotate(angle: 0)
            
        }
        
        //ステータスを更新
        isMenuOpend = !isMenuOpend
        
    }
    
    // フォルダー追加ボタンが押されたら
    
    
    /// ファイルを受け取った時に呼ばれる
    @objc func fileReceived() {
        
        //まだ対応してないよーっていうアラートを出す
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
        view.configureContent(title: "ファイルを受け取りました",
                              body: "PDFドキュメントを追加しました",
                              iconText: "👍")
        
        // 角丸を指定します
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 8
        
        //表示の設定を変更
        var config = SwiftMessages.Config()
        
        config.duration = .seconds(seconds: 3)
        
        // アラートを表示します
        SwiftMessages.show(config: config, view: view)
    }
    
    /// まだ対応していない機能を隠す
    private func hideUnsupportedFeatures() {
//        createBinderButton.tintColor = .clear
//        sortListButton.tintColor = .clear
    }
    
    /// ソートするボタンを更新
    private func updateSortButton() {
        setupSortButton()   //見た目の更新を行う
        
        //デリゲートを実行
        collectionDelegate?.reloadCollectionWith(sort: listSortType,
                                                 isReversed: isReveresed)
    }
    
    /// 並べ替えボタンをセットアップ
    private func setupSortButton() {
        
        // 表示する項目
        let items = UIMenu(options: .displayInline, children: [
            UIAction(title: Localize.listVC.sort.byName,
                     image: UIImage(systemName: listSortType == .name ? "checkmark" : ""),
                     handler: { _ in
                        
                        self.listSortType = .name
                        
                        self.updateSortButton()
                     }),
            UIAction(title: Localize.listVC.sort.byDate,
                     image: UIImage(systemName: listSortType == .date ? "checkmark" : ""),
                     handler: { _ in
                        
                        self.listSortType = .date
                        
                        self.updateSortButton()
                     }),
            UIAction(title: Localize.listVC.sort.byCount,
                     image: UIImage(systemName: listSortType == .opened ? "checkmark" : ""),
                     handler: { _ in
                        
                        self.listSortType = .opened
                        
                        self.updateSortButton()
                     }),
        ])

        // メインアクション(いらないかも)
        let destruct = UIAction(title: Localize.listVC.sort.reverse,
                                image: UIImage(systemName: isReveresed ? "checkmark" : "")) {  [weak self] _ in
            // メインアクションが押された時の
            self!.isReveresed.toggle()
            
            self!.updateSortButton()  //ソートボタンを更新
        }
        
        // メニューの
        let menu = UIMenu(title: "", children: [destruct, items])
        
        // バージョンによってアイコンの名前が違うらしいので
        /// ソートボタンのアイコンの名前
        let sortIconName: String = {
            if #available(iOS 15.0, *) {
                return "line.3.horizontal.decrease.circle"
            } else {
                return "line.horizontal.3.decrease.circle"
            }
        }()
        
        let menuBarItem = UIBarButtonItem(image: UIImage(systemName: sortIconName),
                                          menu: menu)
        
        self.navigationItem.rightBarButtonItems = [menuBarItem]
        navigationItem.rightBarButtonItems![0].menu = menu
    }
    
    /// もし前回閲覧中で終了した場合に実行
    private func resumeLastDocument() {
        
        let realm = try! Realm()
        
        let lastDocumentId = realm.objects(Config.self).first!.lastWatchedDocumentId
        
        if  lastDocumentId != "" {
            // アラートで確認してから飛ばす
            Alertift.alert(title: Localize.alert.list.resume.title,
                           message: Localize.alert.list.resume.message)
                .action(.cancel(Localize.alert.list.resume.cancel)) {
                    // 前回閲覧途中だったuuidを削除
                    try! realm.write {
                        realm.objects(Config.self).first!.lastWatchedDocumentId = ""
                    }
                }
                .action(.default(Localize.alert.list.resume.another)) {
                    //preview
                    let previewSB = UIStoryboard(name: "Preview", bundle: nil)
                    let previewVC = previewSB.instantiateViewController(identifier: "preview") as! PreviewViewController
                    
                    // 対象のドキュメント
                    let targetDocument = realm.objects(Document.self).filter("uid = %@", lastDocumentId).first!
                    
                    // ドキュメンツの配列を生成
                    let documentsDatas: [Document] = {
                        return Array(realm.objects(Document.self).filter("parentPathID = %@", targetDocument.parentPathID))
                    }()
                    
                    let documentsRow = documentsDatas.firstIndex(where: {$0.uid == targetDocument.uid})!
                    
                    //セット
                    previewVC.setData(imageData: targetDocument.imageData,
                                      realmIndex: documentsRow,
                                      documentsData: documentsDatas)
                    
                    //ボトムバーを隠す
                    previewVC.hidesBottomBarWhenPushed = true
                    
                    // ログをとる
                    Process.logToAnalytics(title: "open_document_from_alert", id: "open_document_from_alert")
                    
                    //遷移
                    previewVC.modalPresentationStyle = .fullScreen
                    self.present(previewVC, animated: true, completion: nil)
                }
                .show(on: self)
        }

    }
    
    /// フォルダーを追加するボタンをセットアップ
    private func setupAddFolderButton() {
        
        let addFolderButton = UIBarButtonItem(image: UIImage(systemName: "folder.fill.badge.plus"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(addTestFolder(sender:)))
        
        self.navigationItem.rightBarButtonItems?.append(addFolderButton)
    }
    
    /// 試験的にフォルダーを追加する
    @objc private func addTestFolder(sender: UIBarButtonItem) {
        let realm = try! Realm()
        let folder = Folder()
        folder.title = "無題のフォルダ"
        folder.color = "blue"
        folder.createdDate = Date().toFormat("yyyy/MM/dd")
        try! realm.write {
            realm.add(folder)
        }
        
        collectionDelegate?.reloadCollection()
    }
    
    /// フォルダー内に入るとき用のデータをセット
    func setFolderData(folder: Folder) {
        
        self.currentFolder = folder
        
    }
    
    /// フォルダー内ならデータを色々セットする
    private func setupFolder() {
        
        if let folder = currentFolder {
            self.title = folder.title
            collectionDelegate?.setFolder(folder: folder)
        }
    }
    
}

extension ListViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    //マークの数
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
    
    //マークするやつ
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        
        let markViews = [menuButton]
        
        return coachMarksController.helper.makeCoachMark(for: markViews[index])
    }
    
    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        coachMarkViewsAt index: Int,
        madeFrom coachMark: CoachMark
    ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(
            withArrow: true,
            arrowOrientation: coachMark.arrowOrientation
        )
        
        switch index {
        case 0:
            coachViews.bodyView.hintLabel.text = "まずはこのボタンを押して、ドキュメントを追加するメニューを開きましょう"
            coachViews.bodyView.nextLabel.text = "OK!"
            
            //フラグを更新
            let realm = try! Realm()
            try! realm.write {
                flag!.isFirstOpenList = false
            }
            
            // チュートリアル開始のイベントを発信
            Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: nil)
            
        default:
            break
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}

extension ListViewController: MenuViewControllerDelegate {
    
    // PDFが正常に追加されたら
    func addedPDFSuccessfly() {
        
        //コレクションを更新
        collectionDelegate?.reloadCollection()
        
    }
    
    // ターゲットパスを渡す
    func getTargetPath() -> String {
        if let uid = currentFolder?.uid {
            return uid
        } else {
            return "/"
        }
    }
    
}
