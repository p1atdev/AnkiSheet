//
//  PreviewViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import RealmSwift
import SnapKit
import PKHUD
import Instructions
import SwiftMessages

protocol PreviewViewControllerDelegate: AnyObject {
    func makeImageFiltered(sheet: Sheet)
    func reloadSideTable()
    func refreshFilter()
    func removeFilter(sheet: Sheet)
}

class PreviewViewController: UIViewController {
    
    deinit {
        print("PreviewVC did deinit")
    }
    
    /// 画像のビュー
    @IBOutlet weak var originalImageView: UIImageView!
    
    /// フィルターかかってるビュー
    @IBOutlet weak var filteredImageView: UIImageView!
    
    /// シート
    @IBOutlet weak var sheetView: UIView!
    
    /// フィルター(色だけ)
    @IBOutlet weak var filterView: UIView!
    
    /// 横のコントローラー
    @IBOutlet weak var sideConrtrollerView: UIView!
    
    /// 画面のdoubletaprecognizer
    @IBOutlet var screenDoubleTapRecognizer: UITapGestureRecognizer!
    
    /// シートの動きを固定するボタン
    @IBOutlet weak var lockButtonView: UIView!
    
    /// ロックボタンの画像のビュー
    @IBOutlet weak var lockButtonImageView: UIImageView!
    
    /// ロックボタンの長押しハンドラ
    @IBOutlet var lockButtonPressRecognizer: UILongPressGestureRecognizer!
    
    /// 次のドキュメントに行くボタン
    @IBOutlet weak var nextDocButton: UIBarButtonItem!
    
    /// 前のドキュメントに行くボタン
    @IBOutlet weak var prevDocButton: UIBarButtonItem!
    
    /// 何枚目かを表すフィールド
    @IBOutlet weak var numberOfIndexField: UITextField!
    
    /// 何枚目かを表すフィールドの親ビュー
    @IBOutlet weak var numberOfIndexFieldParentView: UIView!
    
    /// ナビバー自体
    @IBOutlet weak var naviBar: UINavigationBar!
    
    /// ナビバーアイテム
    @IBOutlet weak var naviBarItem: UINavigationItem!
    
    
    /// 実際の画像
    var originalImage: UIImage?
    
    /// フィルターかかってる画像
    var filteredImage: UIImage?
    
    /// 変形用の変数
    var originalViewTransform: CGAffineTransform = CGAffineTransform(scaleX: 1, y: 1)
    var sheetViewTransform: CGAffineTransform = CGAffineTransform(scaleX: 1, y: 1)
    var filteredViewTransform: CGAffineTransform = CGAffineTransform(scaleX: 1, y: 1)
    
    //いろんなデータ
    
    /// ドキュメントのリスト
    private var documentsData: Array<Document> = []
    
    /// ドラッグ可能なビュー一覧
    private var dragableView: Array<UIView> = []
    
    /// いまドラッグ中のビュー(基本的には一つしか入らない)
    private var draggingView: Array<UIView> = []
    
    /// 有効になってるフィルター一覧
    var enabledFilters: Array<Sheet> = []
    
    /// サイドメニューが表示されているかどうか
    var isSideMenuShowing: Bool = true
    
    /// フィルタードのサイズの変数
    var filteredBeforeSize: CGSize!
    /// フィルタードのサイズの変数
    var filteredAfterSize: CGSize!
    
    /// realmの今の番号
    var documentRealmIndexNum: Int = -1
    
    /**
     シートのロック状態
     - Parameters:
     - Bool: true: ロックされている、false: ロックされていない
     */
    var isSheetLocked: Bool = false
    
    //イメージビューのデフォルトのサイズの倍率
    var scale: CGFloat = 1
    
    /// 入れ替える白
    let targetWhite = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    /// 色の厳しさ
    let tmpTolerance: CGFloat = 0.6
    
    /// 今のシート
    var selectedSheet: Sheet?
    
    ///チュートリアル
    let coachMarksController = CoachMarksController()
    
    /// フラグ
    var flag = Flag()
    
    /// 設定
    var config = Config()
    
    /// ドキュメント
    var document = Document()
    
    /// 現在表示しているPDFのページ
    var currentPDFPageNum: Int = 1
    
    /// PDFの全ページ
    var allPDFPage: Array<PDFData> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // realmのセットアップ
        setUpRealm()
        
        //倍率を更新
        scale = min(self.view.frame.width / originalImage!.size.width * 0.8,
                    self.view.frame.height / originalImage!.size.height * 0.8)
        
        //動かせるビューの一覧を更新
        dragableView = [originalImageView, sheetView]
        
        //recognizerを設定
        screenDoubleTapRecognizer.numberOfTapsRequired = 2
        
        //画像をセットする
        originalImageView.image = originalImage
        
        //イメージビューのサイズの調整
        originalImageView.frame = CGRect(x: 0,
                                         y: 0,
                                         width: originalImage!.size.width * scale,
                                         height: originalImage!.size.height * scale)
        
        // ナビバーのセットアップ
        setUpNaviBar()
        
        // シートのセットアップ
        setUpSheet()
        
        //サイドメニューのセットアップ
        setUpSideMenu()
        
        //TODO: サイドメニューにできたら影をつけたいな
        
        //ロックボタンをセットアップ
        setupLockButton()
        
        //チュートリアルの設定
        self.coachMarksController.dataSource = self
        
        // pdfの設定をセットアップ
        setUpPDFSetting()
        
    }
    
    //画面がロードされたら
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //nilじゃなかったら実行しない
        if filteredImage == nil {
            
            filteredImage = originalImage
            
            makeImageFiltered(sheet: selectedSheet!)
            
            updateImagePositions(pinch: false)  //位置を調整
            
            filteredBeforeSize = filteredImageView.frame.size
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 通知を送信し、コレクションをリロード
        NotificationCenter.default.post(name: .reloadListCollection, object: nil)
        
    }
    
    //タップされたら
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first! //このタッチイベントの場合確実に1つ以上タッチ点があるので`!`つけてOKです
        let location = touch.location(in: self.view) //in: には対象となるビューを入れます
        
        //ドラッグ中のビューを決定する
        
        // シートがロックされていたら
        if isSheetLocked {
            
            // オリジナルイメージビューに指があったら入って、なかったら空
            draggingView = whichViewIsUnderTouched(targetView: [originalImageView],
                                                   in: location)
            
            //複数枚指の下にあるか
        } else if whichViewIsUnderTouched(targetView: dragableView, in: location).count > 1 {
            
            //複数あるならシートの方のみをとる
            let draggingUpperView: UIView = sheetView
            
            draggingView = [draggingUpperView]
            
        } else {
            //一つだけならそのまま
            draggingView = whichViewIsUnderTouched(targetView: dragableView, in: location)
            
        }
        
        // テキストフィールドの編集を終了する
        numberOfIndexField.endEditing(false)
    }
    
    //タップが終わったら
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingView = []   //ドラッグ中のビューをクリアする
    }
    
    
    /*
     ドラッグを感知した際に呼ばれるメソッド.
     (ドラッグ中何度も呼ばれる)
     */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        switch touches.count {
        case 1:
            
            for dragging in draggingView {
                
                let touch = touches.first!
                
                // 移動した先の座標を取得.
                let location = touch.location(in: self.view)
                
                // 移動する前の座標を取得.
                let prevLocation = touch.previousLocation(in: self.view)
                
                // CGRect生成.
                var myFrame: CGRect = dragging.frame
                
                // ドラッグで移動したx, y距離をとる.
                let deltaX: CGFloat = location.x - prevLocation.x
                let deltaY: CGFloat = location.y - prevLocation.y
                
                // 移動した分の距離をmyFrameの座標にプラスする.
                myFrame.origin.x += deltaX
                myFrame.origin.y += deltaY
                
                // frameにmyFrameを追加.
                dragging.frame = myFrame
                
            }
            
            //座標を更新
            updateImagePositions(pinch: false)
            
        default:
            break
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "side":
            let des = segue.destination as! SideTableViewController
            
            //デリゲートの設定
            des.delegate = self
            
        default:
            break
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //自身が捨てられるときに、ナビゲーションバーのアルファを1に
        UIView.animate(withDuration: 0.5, animations: {
            self.navigationController?.navigationBar.alpha = 1.0
        })
        
        // フラグを更新
        let realm = try! Realm()
        try! realm.write {
            flag.numberOfReturnFromPreview += 1 //何回戻ったかの回数を記録する
        }
        
    }
    
    //MARK:　画面がダブルタップされた
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        
        //サイドを表示非表示
        UIView.animate(withDuration: 0.2, animations: {
            
            if self.isSideMenuShowing {
                //表示されてるので隠す
                //alphaを0に
                self.sideConrtrollerView.alpha = 0.0
                self.naviBar.alpha = 0.0
                self.numberOfIndexFieldParentView.alpha = 0.0
                
            } else {
                //隠れてるので表示
                //alphaを1に
                self.sideConrtrollerView.alpha = 1.0
                self.naviBar.alpha = 1.0
                self.numberOfIndexFieldParentView.alpha = 1.0
                
            }
            
            self.isSideMenuShowing = !self.isSideMenuShowing
        })
        
    }
    
    //MARK:  ピンチ、ピンチアウト
    @IBAction func originalImagePinch(_ sender: UIPinchGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            //ピンチ開始時のアフィン変換をクラス変数に保持する。
            originalViewTransform = originalImageView.transform
            filteredViewTransform = filteredImageView.transform
        }
        
        //拡大縮小
        originalImageView.transform = originalViewTransform.scaledBy(x: sender.scale, y: sender.scale)
        filteredImageView.transform = originalViewTransform.scaledBy(x: sender.scale, y: sender.scale)
        
        //サイズを更新
        filteredBeforeSize.width = filteredAfterSize.width * sender.scale
        filteredBeforeSize.height = filteredAfterSize.height * sender.scale
        
        //座標を更新
        updateImagePositions(pinch: true)
        
        //終わったら
        if sender.state == UIGestureRecognizer.State.ended {
            //afterを更新
            filteredAfterSize = filteredImageView.frame.size
        }
    }
    
    @IBAction func sheetViewPinch(_ sender: UIPinchGestureRecognizer) {
        
        //もしシートがロックされてたらオリジナル画像の方の処理を実行する
        if isSheetLocked {
            
            //画面をタッチしている指の数
            switch sender.numberOfTouches {
            case 2:
                if sender.state == UIGestureRecognizer.State.began {
                    //ピンチ開始時のアフィン変換をクラス変数に保持する。
                    originalViewTransform = originalImageView.transform
                    filteredViewTransform = filteredImageView.transform
                }
                
                /*
                 指がちゃんとオリジナル画像の上にある場合
                */
                if whichViewIsUnderTouched(targetView: [originalImageView],
                                           in: sender.location(ofTouch: 0, in: self.view)
                ).contains(originalImageView) &&
                whichViewIsUnderTouched(targetView: [originalImageView],
                                        in: sender.location(ofTouch: 1, in: self.view)
                ).contains(originalImageView){
                    
                    // オリジナル画像の上に指があったら拡大縮小
                    originalImagePinch(sender)
                    
                }
                
            default:
                //トランスフォームを初期化
                originalViewTransform = originalImageView.transform
                filteredViewTransform = filteredImageView.transform
            }
            
            //終わったら
            if sender.state == UIGestureRecognizer.State.ended {
                //afterを更新
                filteredAfterSize = filteredImageView.frame.size
            }
            
            return  //撤退!
        }
        
        if sender.state == UIGestureRecognizer.State.began {
            
            //ピンチ開始時のアフィン変換をクラス変数に保持する。
            sheetViewTransform = sheetView.transform
            filteredViewTransform = filteredImageView.transform
            
        }
        
        /// 逆の拡大スケール倍率
        let reverseScale: CGFloat =  (1 / sender.scale) //* (1 / sender.scale)
        
        //拡大縮小
        sheetView.transform = sheetViewTransform.scaledBy(x: sender.scale, y: sender.scale)
        filteredImageView.transform = filteredViewTransform.scaledBy(x: reverseScale, y: reverseScale)
        
        //サイズを更新
        filteredBeforeSize.width = filteredAfterSize.width * reverseScale
        filteredBeforeSize.height = filteredAfterSize.height * reverseScale
        
        //座標を更新
        updateImagePositions(pinch: true)
        
        //指が離れたら
        if(sender.state == UIGestureRecognizer.State.ended){
            
            //afterを更新
            filteredAfterSize = filteredImageView.frame.size
            
        }
    }
    
    // viewをピンチした時の判定
    @IBAction func selfViewPinch(_ sender: UIPinchGestureRecognizer) {
        if !isSheetLocked { return }    //固定されていなければ返る
        
        switch sender.numberOfTouches {    //二本指のタッチを判定
        case 2:
            //仮にタッチ始めなら
            if sender.state == UIGestureRecognizer.State.began {
                //ピンチ開始時のアフィン変換をクラス変数に保持する。
                originalViewTransform = originalImageView.transform
                filteredViewTransform = filteredImageView.transform
            }
            
            /// タッチされている座標
            var touches: Array<CGPoint> = []
            
            // タッチを取得
            for index in 0..<sender.numberOfTouches {
                /// self.viewにおけるタッチ座標
                let touch = sender.location(ofTouch: index, in: self.view)
                
                touches.append(touch)   //タッチを追加
            }
            
            // オリジナルイメージビューとフィルタードの上に指がある時のみ反応
            if whichViewIsUnderTouched(targetView: [originalImageView],
                                        in: touches[0]).contains(originalImageView) &&
                 whichViewIsUnderTouched(targetView: [originalImageView],
                                         in: touches[1]).contains(originalImageView) {
                
                //変形
                originalImagePinch(sender)
                
            }
            
        default:
            //トランスフォームを初期化
            originalViewTransform = originalImageView.transform
            filteredViewTransform = filteredImageView.transform
        }
        
        if sender.state == UIGestureRecognizer.State.ended {
            //afterを更新
            filteredAfterSize = filteredImageView.frame.size
        }
    }
    
    
    
    //MARK: 次のドキュメントに行く
    @IBAction func goToNextDoc(_ sender: Any) {
        
        //遷移
        goToOtherDoc(way: .next)
    }
    
    
    //MARK: 前のドキュメントに行く
    @IBAction func goToPrevDoc(_ sender: Any) {
        
        //遷移
        goToOtherDoc(way: .previous)
    }
    
    //MARK: ロックボタンが押された
    @IBAction func lockButtonTouched(_ sender:  UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .began:
            //透明度を下げる
            lockButtonView.alpha = 0.9
            
        case .ended:
            //透明度を戻す
            lockButtonView.alpha = 1.0
            
            //ロックの状態を更新する
            changeLockSheetState()
            
        default:
            break
        }
    }
    
    // indexのfieldが更新された
    @IBAction func numberOfIndexChanged(_ sender: UITextField) {
        
        // indexが有効か判定
        if let index = Int(sender.text!) {
            
            //ページ内の範囲かどうか
            if 1 <= index && index <= allPDFPage.count {
                
                //キーボードを閉じる
                numberOfIndexField.endEditing(false)
                
                //更新
                turnPDFPage(to: index)
                
            } else {
                
                //正しくないので元に戻す
                sender.text = String(currentPDFPageNum)
                
                //アラート
                showAlertWhyNumberOfPageIsWrong()
            }
            
        } else {
            
            //正しくないので元に戻す
            sender.text = String(currentPDFPageNum)
            
            //アラート
            showAlertWhyNumberOfPageIsWrong()
        }
        
    }
    
    // ホームに戻るボタンが押された
    @IBAction func homeButtonTapped(_ sender: Any) {
        
        // 最後に開いていたドキュメントのidを無に還す
        let realm = try! Realm()
        
        try! realm.write {
            realm.objects(Config.self).first!.lastWatchedDocumentId = ""
        }
        
        // 帰宅
//        hero.dismissViewController()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: functions
    
    /**
     データをセット
     - Parameters:
     - imageData: 画像のデータ
     - realmIndex: realm上でのインデックス
     */
    func setData(imageData: Data, realmIndex: Int, documentsData: Array<Document>) {
        
        //画像のデータ
        self.originalImage = UIImage(data: imageData)
        
        //realm上のインデックスから、前後のドキュメントのインデックスを決定する
        //もしなかったら、一周させる?
        let realm = try! Realm()
        
        //現在のrealmの座標を保存
        documentRealmIndexNum = realmIndex
        
        // ドキュメントの配列を順番も含めて読み込む
        self.documentsData = documentsData
        
        //ドキュメントをセット
        document = documentsData[documentRealmIndexNum]
        
        // 開いた回数を記録(1追加)
        try! realm.write {
            document.countOfOpened += 1
        }
        
    }
    
    /// オリジナルとフィルタードの座標を更新
    func updateImagePositions(pinch: Bool) {
        
        //コンバートした座標を適応する
        filteredImageView.frame.origin = originalImageView.convert(self.view.frame, to: sheetView).origin
        
        if !pinch {
            
            if filteredBeforeSize == nil {
                //サイズを調整
                filteredImageView.frame.size.width = originalImageView.frame.width
                filteredImageView.frame.size.height = originalImageView.frame.height
                
                //サイズを保存
                filteredAfterSize = filteredImageView.frame.size
                
            } else {
                
                //サイズを調整
                filteredImageView.frame.size.width = filteredBeforeSize!.width
                filteredImageView.frame.size.height = filteredBeforeSize!.height
                
            }
            
        } else {
            
            //サイズを調整
            filteredImageView.frame.size.width = filteredBeforeSize!.width
            filteredImageView.frame.size.height = filteredBeforeSize!.height
            
        }
    }
    
    /// 次に行くのか、前に行くのか
    private enum ArrowWay {
        case next,
             previous
    }
    
    ///MARK:  他のドキュメントに飛ぶ
    private func goToOtherDoc(way: ArrowWay) {
        
        switch document.type {
        case "image":
            // 画像だった際はそのままチェンジ
            
            switch way {
            case .previous:
                turnOtherImage(to: getPrevDocNum())
                
            case .next:
                turnOtherImage(to: getNextDocNum())
            }
            
            
        case "pdf":
            
            switch way {
            case .previous:
                if isEdgeOfPDF(start: true) {
                    
                    // ページをリセット
                    currentPDFPageNum = 1
                    
                    // 前のドキュメントへ行く
                    turnOtherImage(to: getPrevDocNum())
                    
                } else { //通常なら
                    turnPDFPage(to: currentPDFPageNum - 1)
                }
                
            case .next:
                if isEdgeOfPDF(end: true) {
                    // ページをリセット
                    currentPDFPageNum = 1
                    
                    // 次のドキュメントに行く
                    turnOtherImage(to: getNextDocNum())
                    
                    //アラートを表示
                    showAlertWhyReachToEdgeOfPDF()
                } else {    //通常なら
                    turnPDFPage(to: currentPDFPageNum + 1)
                    
                }
            }
            
        default:
            break
        }
        
        // 最後に開いていたドキュメントのidを更新
        let realm = try! Realm()
        
        try! realm.write {
            realm.objects(Config.self).first!.lastWatchedDocumentId = document.uid
        }
        
    }
    
    /**
     前後の画像に飛ぶ
        - Parameters:
            - index: 飛ぶRealmのDocumentのインデックス
    */
    private func turnOtherImage(to index: Int) {
        
        let realm = try! Realm()
        
        //ドキュメントを更新
        document = documentsData[index]
        
        //ドキュメントの画像
        originalImage = UIImage(data: document.imageData)
        originalImageView.image = originalImage
        
        // 見た目のために、フィルター後のビューもオリジナルを表示しておく
        filteredImageView.image = originalImage
        
        //フィルターかける
        refreshFilter()
        
        //タイトルを更新
        naviBarItem.title = document.title
        
        // 右上のページ番号の表示も際セットアップ
        setUpPDFSetting()
        
        switch document.type {
        case "pdf":
            //リストを初期化
            allPDFPage = []
            
            // PDFだった場合、ページを全て取得
            for pdfData in realm.objects(PDFData.self).filter({ $0.uuid == self.document.uid }) {
                allPDFPage.append(pdfData)
            }
            
            //タイトルを更新
            naviBarItem.title! += " [\(currentPDFPageNum)/\(allPDFPage.count)]"
            
        default:
            break
        }
        
        // 開いたという数値を増やす
        try! realm.write {
            document.countOfOpened += 1
        }
        
    }
    
    /**
     前後のPDFに飛ぶ
        - Parameters:
            - page: 飛ぶページ
    */
    private func turnPDFPage(to page: Int) {
        
        //PDFのデータを取得
        let pdfData = allPDFPage.filter({ $0.pageNum == page }).first!
        
        //画像を取得
        let nextPageImage = UIImage(data: pdfData.data)
        
        //画像を更新
        originalImage = nextPageImage
        originalImageView.image = originalImage
        
        // 見た目のために、フィルター後のビューもオリジナルを表示しておく
        filteredImageView.image = originalImage
        
        // 現在のPDFページを更新
        currentPDFPageNum = page

        //フィルターかける
        refreshFilter()

        // ページindexを更新
        numberOfIndexField.text = String(page)
        
        // タイトルを更新
        naviBarItem.title = document.title + " [\(currentPDFPageNum)/\(allPDFPage.count)]"
        
    }
    
    /// 前のドキュメントのインデックスを割り出す
    private func getPrevDocNum() -> Int {
        
//        let realm = try! Realm()
        
        if documentRealmIndexNum == 0 { //一番最初なら
            // 一番後ろにする
            documentRealmIndexNum = documentsData.count - 1
            //アラートを表示
            showAlertWhyJumpedToEnd()
        } else {
            // 何もなければそのまま前のドキュメントに
            documentRealmIndexNum -= 1
        }
        
        return documentRealmIndexNum
    }
    
    /// 次のドキュメントのインデックスを割り出す
    private func getNextDocNum() -> Int {
        
//        let realm = try! Realm()
        
        let numOfDoc = documentsData.count
        
        if documentRealmIndexNum == numOfDoc - 1 { //一番後ろ
            //一番前にする
            documentRealmIndexNum = 0
            //アラートを表示
            showAlertWhyJumpedToFirst()
        } else {
            //何もなければそのまま次へ
            documentRealmIndexNum += 1
        }
        
        return documentRealmIndexNum
        
    }
    
    
    /// このPDFが最初か最後のページかどうか
    private func isEdgeOfPDF(start: Bool = false, end: Bool = false) -> Bool {
        
        if start {  //最初について判定
            
            return currentPDFPageNum == 1
            
        } else if end { //最後について判定
            
            return currentPDFPageNum == allPDFPage.count
            
        } else {
            //絶対起きない
            return false
        }
        
    }
    
    /**
     指の下にどのビューがあるかどうか
     */
    private func whichViewIsUnderTouched(targetView: Array<UIView>, in position: CGPoint) -> Array<UIView> {
        //返す用のarray
        var returnArray: Array<UIView> = []
        //回す
        for view in targetView {
            //ビュー内にタップされた座標があるかどうか
            if view.frame.minX <= position.x &&
                view.frame.maxX >= position.x &&
                view.frame.minY <= position.y &&
                view.frame.maxY >= position.y {
                
                returnArray.append(view)
            }
        }
        
        return returnArray
    }
    
    /// ロックボタンのセットアップ
    private func setupLockButton() {
        //背景色
        lockButtonView.backgroundColor = .darkGray
        
        //角丸
        lockButtonView.layer.cornerRadius = lockButtonView.frame.width / 2
        
        //ボーダー
        lockButtonView.layer.borderWidth = 4.0
        lockButtonView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        
        //画像をセット
        lockButtonImageView.image = Icon.lock_open_fill
        
        //長押しに要する時間を変更
        lockButtonPressRecognizer.minimumPressDuration = 0
        
    }
    
    /// ロックボタンの画像を変更する
    private func changeLockButtonUI() {
        if isSheetLocked { //もしロックされてたら
            //解除する
            lockButtonImageView.image = Icon.lock_open_fill
            //背景色を灰色に
            lockButtonView.backgroundColor = .darkGray
            
        } else {    //ロックされてなかったら
            //鍵をかける
            lockButtonImageView.image = Icon.lock_fill
            //背景色を青色に
            lockButtonView.backgroundColor = .systemBlue
        }
    }
    
    /// シートロックロックの状態を変更する
    func changeLockSheetState() {
        //画像を更新
        changeLockButtonUI()
        
        //フラグを更新
        isSheetLocked = !isSheetLocked
    }
    
    //MARK: アラート
    /// PDFのページの最後から別のドキュメントに移りました
    func showAlertWhyReachToEdgeOfPDF() {
        
        let view = MessageView.viewFromNib(layout: .statusLine)

        // テンプレなのでテーマも用意されています
        // .error, .info, .success, .warning
        view.configureTheme(.info)

        // 影をつけることができます
        view.configureDropShadow()

        // タイトル、メッセージ本文、アイコンとなる絵文字をセットします
        view.configureContent(title: "情報",
                      body: "次のドキュメントに移動しました",
                      iconText: "ℹ️")
        
        // ボタンがいらない
         view.button?.isHidden = true

        // アラートを表示します
        SwiftMessages.show(view: view)
        
    }
    
    /// 最後のドキュメントに飛んだ
    func showAlertWhyJumpedToEnd() {
        
        let view = MessageView.viewFromNib(layout: .statusLine)

        // テンプレなのでテーマも用意されています
        // .error, .info, .success, .warning
        view.configureTheme(.info)

        // 影をつけることができます
        view.configureDropShadow()

        // タイトル、メッセージ本文、アイコンとなる絵文字をセットします
        view.configureContent(title: "情報",
                      body: "最後のドキュメントに移動しました",
                      iconText: "ℹ️")
        
        // ボタンがいらない
         view.button?.isHidden = true

        // アラートを表示します
        SwiftMessages.show(view: view)
        
    }
    
    /// 最初のドキュメントに飛んだ
    func showAlertWhyJumpedToFirst() {
        
        let view = MessageView.viewFromNib(layout: .statusLine)

        // テンプレなのでテーマも用意されています
        // .error, .info, .success, .warning
        view.configureTheme(.info)

        // 影をつけることができます
        view.configureDropShadow()

        // タイトル、メッセージ本文、アイコンとなる絵文字をセットします
        view.configureContent(title: "情報",
                      body: "最初のドキュメントに移動しました",
                      iconText: "ℹ️")
        
        // ボタンがいらない
         view.button?.isHidden = true

        // アラートを表示します
        SwiftMessages.show(view: view)
        
    }
    
    /// ページの値が間違ってるよのアラート
    func showAlertWhyNumberOfPageIsWrong() {
        
        let view = MessageView.viewFromNib(layout: .statusLine)

        // テンプレなのでテーマも用意されています
        // .error, .info, .success, .warning
        view.configureTheme(.warning)

        // 影をつけることができます
        view.configureDropShadow()

        // タイトル、メッセージ本文、アイコンとなる絵文字をセットします
        view.configureContent(title: "エラー",
                      body: "ページの数字が正しくありません",
                      iconText: "🤔")
        
        // ボタンがいらない
         view.button?.isHidden = true

        // アラートを表示します
        SwiftMessages.show(view: view)
        
    }
    
    //MARK: セットアップ
    
    /// ブラーのセットアップ
    private func setUpBlur() {
        // ブラーエフェクトを作成
        let blurEffect = UIBlurEffect(style: .regular)
        
        // ブラーエフェクトからエフェクトビューを作成
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        // エフェクトビューを初期viewに追加
        self.sideConrtrollerView.addSubview(visualEffectView)
        
        //奥におく
        self.sideConrtrollerView.sendSubviewToBack(visualEffectView)
        
        //制約
        visualEffectView.snp.makeConstraints { make in
            make.top.equalTo(sideConrtrollerView)
            make.bottom.equalTo(sideConrtrollerView)
            make.left.equalTo(sideConrtrollerView)
            make.right.equalTo(sideConrtrollerView)
        }
    }
    
    /// realmのセットアップ
    private func setUpRealm() {
        
        //realmから一番最初のシートを取得(なかったらデフォルトのを)
        let realm = try! Realm()
        let sheets = realm.objects(Sheet.self)
        selectedSheet = sheets[0]
        config = realm.objects(Config.self).first!  //設定
        
        flag = realm.objects(Flag.self).first!  //フラグ
        
        // 最後に開いていたドキュメントのidを更新
        try! realm.write {
            realm.objects(Config.self).first!.lastWatchedDocumentId = document.uid
        }
        
        switch document.type {
        case "pdf":
            //リストを初期化
            allPDFPage = []
            
            // PDFだった場合、ページを全て取得
            for pdfData in realm.objects(PDFData.self).filter({ $0.uuid == self.document.uid }) {
                allPDFPage.append(pdfData)
            }
            
            //タイトルを更新
            naviBarItem.title! += "[1/\(allPDFPage.count)]"
            
        default:
            break
        }
        
    }
    
    /// シートのセットアップ
    private func setUpSheet() {
        
        //シートのサイズの調整
        sheetView.frame.size.width = originalImageView.frame.width * 1.2
        sheetView.frame.size.height = originalImageView.frame.height * 1.2
        
        //オリジナル画像とシートの座標と中央に持ってくる
        originalImageView.center = self.view.center
        sheetView.center = self.view.center
        
        //シートをマスクするように
        sheetView.layer.masksToBounds = true
        
        //制約を追加
        filterView.snp.makeConstraints { make in
            make.top.equalTo(sheetView)
            make.bottom.equalTo(sheetView)
            make.right.equalTo(sheetView)
            make.left.equalTo(sheetView)
        }
        
        //シートの色を変更
        filterView.backgroundColor = UIColor(hex: config.sheetAppearanceHex, alpha: CGFloat(config.sheetAppearanceAlpha))
        
        //角丸を設定
        sheetView.layer.cornerRadius = config.sheetRounded ? 16 : 0
        
    }
    
    /// サイドメニューのセットアップ
    private func setUpSideMenu() {
        
        //ブラー
        setUpBlur()
        
        //サイドメニューの角丸&クリップ
        sideConrtrollerView.layer.cornerRadius = 16
        sideConrtrollerView.layer.masksToBounds = true
        
    }
    
    /// pdfの設定をセットアップ
    private func setUpPDFSetting() {
        
        //タイプによって右上のインデックスを表示
        switch document.type {
        case "pdf":
            numberOfIndexFieldParentView.isHidden = false
        default:
            numberOfIndexFieldParentView.isHidden = true
        }
        
        //現在表示しているページをリセット
        currentPDFPageNum = 1
        
        // 現在表示しているページを適応
        numberOfIndexField.text = String(currentPDFPageNum)
        
        //角丸、影
        Process.setCornerWithShadow(view: numberOfIndexFieldParentView,
                                    cornerRadius: 8,
                                    shadowColor: UIColor.black.cgColor,
                                    shadowRadius: 4,
                                    shadowOpacity: 0.2,
                                    shadowOffset: .init(width: 0, height: 0),
                                    parentView: nil)
        
    }
    
    /// ナビバーをセットアップ
    private func setUpNaviBar() {
        
        naviBar.layer.cornerRadius = 8  //角丸
        naviBar.clipsToBounds = true
        
        //タイトルをセット
        naviBarItem.title = document.title
        
    }
}

//MARK: デリゲート
extension PreviewViewController: PreviewViewControllerDelegate {
    /// 画像にフィルターをかける
    func makeImageFiltered(sheet: Sheet) {
        
        //スレッドセーフなシートたち
        var sheetObjs: Array<ThreadSafeReference<Sheet>> = []
        
        //すでに存在してるか
        let alreadyExist: Bool = {
            //有効になっているarrayになければ追加、あったら削除
            for filter in enabledFilters {
                
                if filter.uuid == sheet.uuid {
                    enabledFilters.removeAll(where: {$0 == filter})
                    //終了
                    return true
                }
            }
            return false
        }()
        
        //もし存在してなかったら追加する
        if !alreadyExist {
            enabledFilters.append(sheet)
        }
        
        if judgeUseFilterCache() {  //もしキャッシュがあるなら
            return
        }
        
        HUD.show(.progress) //くるくる表示
        
        //スレッドセーフにしてからぶち込む
        for filter in enabledFilters {
            //スレッドセーフにしてから追加
            sheetObjs.append(ThreadSafeReference(to: filter))
        }
        
        
        //一度リセットしてから
        self.filteredImage = self.originalImage
        
        //非同期で生成
        DispatchQueue.global().async {
            
            for filterObj in sheetObjs {
                //realm
                let realmAsync = try! Realm()
                
                //解決する
                guard let filter = realmAsync.resolve(filterObj) else { return }
                
                
                //フィルターかかった画像を生成
                self.filteredImage = Process.replaceColor(color:
                                                            UIColor(hex: filter.colorHex),
                                                          withColor:
                                                            UIColor(hex: filter.insteadColorHex),
                                                          image:
                                                            self.filteredImage!,
                                                          tolerance:
                                                            CGFloat(filter.tolerance))
            }
            
            DispatchQueue.main.async {
                
                // フィルターがかかった画像を保存しておく
                
                let filteredImageObj = FilteredImage() //有効なフィルターを指定して作成
                filteredImageObj.uuid = self.document.uid
                filteredImageObj.data = self.filteredImage?.jpegData(compressionQuality: 1.0)
                filteredImageObj.pageNum = self.currentPDFPageNum
                
                
                //保存
                let realm = try! Realm()
                try! realm.write {
                    realm.add(filteredImageObj)
                    for enabled in self.enabledFilters {
                        filteredImageObj.sheets.append(enabled)
                    }
                }
                
                //画像をセット
                self.filteredImageView.image = self.filteredImage
                
                //終わったら隠す
                HUD.hide()
                
                //チュートリアル実行
                self.startTutorial()
            }
        }
        
        //座標を更新
        updateImagePositions(pinch: false)
        
    }
    
    func makeImageFiltered(color: UIColor, withColor: UIColor, tolerance: CGFloat) {
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                HUD.show(.progress)
            }
            
            //フィルターかかった画像を生成
            self.filteredImage = Process.replaceColor(color: color,
                                                      withColor: withColor,
                                                      image: self.filteredImage!,
                                                      tolerance: CGFloat(tolerance))
            
            DispatchQueue.main.async {
                //画像をセット
                self.filteredImageView.image = self.filteredImage
                
                //座標を更新
                self.updateImagePositions(pinch: false)
                
                HUD.hide(animated: true)
                
                //チュートリアル実行
                self.startTutorial()
                
            }
        }
    }
    
    /// サイドのテーブルを更新する
    func reloadSideTable() {
        let sideTableVC = self.children[0] as! SideTableViewController
        
        //更新
        sideTableVC.reloadTable()
        
    }
    
    /// チュートリアルを実行するか判定して実行する
    private func startTutorial() {
        if flag.isFirstOpenPreview {
            self.coachMarksController.start(in: .currentWindow(of: self))
        }
    }
    
    /// フィルターを更新
    func refreshFilter() {
        
        //一度リセットしてから
        self.filteredImage = self.originalImage
        
        if judgeUseFilterCache() {  //もしキャッシュがあるなら
            return
        }
        
        HUD.show(.progress)
        
        //スレッドセーフなシートたち
        var sheetObjs: Array<ThreadSafeReference<Sheet>> = []
        
        //スレッドセーフにしてからぶち込む
        for filter in enabledFilters {
            //スレッドセーフにしてから追加
            sheetObjs.append(ThreadSafeReference(to: filter))
        }
        
        //非同期で生成
        DispatchQueue.global().async {
            
            for filterObj in sheetObjs {
                
                
                //realm
                let realm = try! Realm()
                //解決する
                guard let filter = realm.resolve(filterObj) else { return }
                
                //フィルターかかった画像を生成
                self.filteredImage = Process.replaceColor(color:
                                                            UIColor(hex: filter.colorHex),
                                                          withColor:
                                                            UIColor(hex: filter.insteadColorHex),
                                                          image:
                                                            self.filteredImage!,
                                                          tolerance:
                                                            CGFloat(filter.tolerance))
            }
            
            DispatchQueue.main.async {
                
                // フィルターがかかった画像を保存しておく
                
                let filteredImageObj = FilteredImage() //有効なフィルターを指定して作成
                filteredImageObj.uuid = self.document.uid
                filteredImageObj.data = self.filteredImage?.jpegData(compressionQuality: 1.0)
                filteredImageObj.pageNum = self.currentPDFPageNum
                
                
                //保存
                let realm = try! Realm()
                try! realm.write {
                    realm.add(filteredImageObj)
                    for enabled in self.enabledFilters {
                        filteredImageObj.sheets.append(enabled)
                    }
                }
                
                //画像をセット
                self.filteredImageView.image = self.filteredImage
                
                //終わったら隠す
                HUD.hide()
            }
        }
        
        //座標を更新
        updateImagePositions(pinch: false)
    }
    
    /// フィルターを削除
    func removeFilter(sheet: Sheet) {
        //有効リストから取り除く
        enabledFilters.removeAll(where: {$0.uuid == sheet.uuid})
        
        //realmからも排除
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(Sheet.self).filter("uuid == %@", sheet.uuid)) //.filter({$0.uuid == sheet.uuid}))
        }
        
        //更新
        refreshFilter()
    }
    
    /// フィルターキャッシュを利用するか判断、実行
    func judgeUseFilterCache() -> Bool {
        
        // もしフィルターがないなら
        if enabledFilters == [] {
            
            filteredImage = originalImage
            
            filteredImageView.image = filteredImage
            
            //座標を更新
            updateImagePositions(pinch: false)
            
            return true//返る
        }
        
        // ここで、このドキュメントとフィルターの組み合わせのキャッシュがあったらそれを採用、なかったら作成して保存
        let realm = try! Realm()
        
        print("uid:", document.uid)
        print("upageNum:", currentPDFPageNum)
        
        // 現在表示している画像の、フィルターがかかったもののリスト
        let currentFilteredImages =  realm.objects(FilteredImage.self).filter("uuid == %@ && pageNum == %@",
                                                                              document.uid,
                                                                              currentPDFPageNum)
        searchFilterObj: for filteredObj in currentFilteredImages {  //ひとつづつ見ていく
            
            var targetSheetList: Array<Sheet> = []
            for sheet in filteredObj.sheets {
                targetSheetList.append(sheet)
            }
            
            //1回目のチェック
            for targetSheet in targetSheetList {
                
                if enabledFilters.filter({$0.uuid == targetSheet.uuid}).count == 0 {
                    //このオブジェは違うのでスキップ
                    continue searchFilterObj
                }
                
            }
            
            //2回目のチェック
            for enabled in enabledFilters {
                
                if targetSheetList.filter({$0.uuid == enabled.uuid}).count == 0 {
                    //このオブジェは違うのでスキップ
                    continue searchFilterObj
                }
                
            }
            
            //ここまできているということは、現在のオブジェが目的のオブジェなので、
            
            //画像を取得
            filteredImage = UIImage(data: filteredObj.data)
            
            //画像をセット
            self.filteredImageView.image = filteredImage
            
            //チュートリアル実行
            self.startTutorial()
            
            //座標を更新
            updateImagePositions(pinch: false)
            
            return true //返る
        }
        
        return false //キャッシュがなかった
        
    }
    
}

//MARK: コンテキストメニュー
extension PreviewViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 5
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        //ダブルタップでメニューを消せるよのビュー
        let doubleTapView = UIView()
        
        doubleTapView.frame = .init(x: 0, y: 0, width: 0, height: 0)
        
        self.view.addSubview(doubleTapView)
        
        doubleTapView.center = view.center
        
        //後ろに
        view.sendSubviewToBack(doubleTapView)
        
        ///注釈がつくビュー
        let markView: Array<UIView> = [sideConrtrollerView,
                        lockButtonView,
                        nextDocButton.value(forKey: "view") as! UIView,
                        prevDocButton.value(forKey: "view") as! UIView,
                        doubleTapView
        ]
        
        return coachMarksController.helper.makeCoachMark(for: markView[index])
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
            
            coachViews.bodyView.hintLabel.text = Localize.tutorial.preview.list
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 1:
            coachViews.bodyView.hintLabel.text = Localize.tutorial.preview.lock
            coachViews.bodyView.nextLabel.text = "OK!"
            
            
            
        case 2:
            coachViews.bodyView.hintLabel.text = Localize.tutorial.preview.nextDoc
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 3:
            coachViews.bodyView.hintLabel.text = Localize.tutorial.preview.prevDoc
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 4:
            coachViews.bodyView.hintLabel.text = Localize.tutorial.preview.doubleTap
            coachViews.bodyView.nextLabel.text = "OK!"
            
            //最後なのでフラグをセット
            setFlag()
            
        default:
            break
            
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    ///　フラグを立てる
    private func setFlag() {
        //realm
        let realm = try! Realm()
        
        try! realm.write {
            flag.isFirstOpenPreview = false
        }
    }
}
