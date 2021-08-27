//
//  CheckViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/27.
//

import UIKit
import CropViewController
import RealmSwift
import Instructions

class CheckViewController: UIViewController {
    
    /// サムネの画像ビュー
    @IBOutlet weak var samuneImageView: UIImageView!
    
    /// テキストフィールドの背景用ビュー
    @IBOutlet weak var textFieldBackgroundView: UIView!
    
    /// ドキュメントの名前のフィールド
    @IBOutlet weak var nameField: UITextField!
    
    /// 白を強調するスイッチ
    @IBOutlet weak var whiteSwitch: UISwitch!
    
    /// 黒を強調するスイッチ
    @IBOutlet weak var blackSwitch: UISwitch!
    
    ///強調スイッチに背景
    @IBOutlet weak var whiteHighlightBackground: UIView!
    @IBOutlet weak var blackHighlightBackground: UIView!
    
    /// トリミングボタン
    @IBOutlet weak var editImageButton: UIButton!
    
    /// 追加ボタン
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    /// サムネの画像
    var samuneImage: UIImage?
    
    /// サムネの画像データ
    var samuneImageData: Data?
    
    // 画像サンプル
    /// 黒を強調
    var blackHighlightedImage: UIImage?
    
    /// 白を強調
    var whiteHighlightedImage: UIImage?
    
    /// 両方強調
    var bothHighlightedImage: UIImage?
    
    /// 画像を配置するパス
    var targetPath: String = "/"
    
    
    /// フラグ
    var flag = Flag()
    
    /// チュートリアル
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 画像を表示
        samuneImageView.image = samuneImage
        
        //角丸
        textFieldBackgroundView.layer.cornerRadius = 16
        
        // ハイライト画像を生成
        generateHighlightedImage()
        
        //チュートリアル
        self.coachMarksController.dataSource = self
        
        //フラグを取得
        let realm = try! Realm()
        flag = realm.objects(Flag.self).first!
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //フラグがオフなら帰る
        if !flag.isFirstOpenCheck { return }
        
        self.coachMarksController.start(in: .window(over: self))
        
    }
    
    /// 画像のクロップのボタンが押された
    @IBAction func cropButtonTouchUpInside(_ sender: Any) {
        
        // もし画像が空だったら(おそらくありえない)
        guard let image = samuneImage else { return }
        
        //CropViewControllerを初期化する。pickerImageを指定する。
        let cropController = CropViewController(croppingStyle: .default, image: image)
        
        cropController.delegate = self
        
        //AspectRatioのサイズをimageViewのサイズに合わせる。
        //        cropController.customAspectRatio = image.size
        
        // 言語を変更
        cropController.doneButtonTitle = "完了"
        cropController.cancelButtonTitle = "キャンセル"
        
        
        self.present(cropController, animated: true, completion: nil)
        
    }
    
    /// 画面がタップされた
    @IBAction func viewTapped(_ sender: Any) {
        
        //キーボードを閉じる
        nameField.endEditing(false)
        
    }
    
    /// 追加ボタンが押された
    @IBAction func addButtonTapped(_ sender: Any) {
        
        //名前がnilだったら突き返す(普通なら発生しない)
        guard let documentName = nameField.text else {
            //TODO: エラーメッセージを表示させる
            
            return
        }
        
        //realmに追加する
        let realm = try! Realm()
        
        let document = Document()
        
        print(targetPath)
        
        //データをセット
        document.imageData = samuneImageView.image?.jpegData(compressionQuality: 0.5)
        document.title = documentName
        document.uid = UUID().uuidString
        document.parentPathID = targetPath
        document.createdDate = Date().toFormat("yyyy/MM/dd")
        
        //書き込み
        try! realm.write {
            realm.add(document)
        }
        
        // ログ
        Process.logToAnalytics(title: "create_document_from_photo", id: "create_document_photo")
        
        //帰る&コレクションの更新
        let layere_number = navigationController!.viewControllers.count
        let listVC = navigationController!.viewControllers[layere_number-2] as! ListViewController
        if let listCollectionVC = listVC.children.first(where: {$0 is ListCollectionViewController}) as? ListCollectionViewController {
            //リストの更新
            listCollectionVC.reloadCollection()
        }
        
        //前の画面に戻る
        self.navigationController?.popToViewController(listVC, animated: true)
        
    }
    
    //スイッチが更新された
    @IBAction func switchValueChanged(_ sender: Any) {
        
        
        if whiteSwitch.isOn && blackSwitch.isOn {
            //両方有効時
            samuneImageView.image = bothHighlightedImage
            
        } else if whiteSwitch.isOn {
            //白のみ
            samuneImageView.image = whiteHighlightedImage
            
        } else if blackSwitch.isOn {
            //黒のみ
            samuneImageView.image = blackHighlightedImage
            
        } else {
            //オリジナル
            samuneImageView.image = samuneImage
        }
        
    }
    
    
    /// データをセットする(Data)
    func setData(imageData: Data) {
        
        self.samuneImage = UIImage(data: imageData)
        self.samuneImageData = imageData
        
    }
    
    /// データをセットする(UIImage)
    func setData(image: UIImage) {
        
        self.samuneImage = image
        self.samuneImageData = image.jpegData(compressionQuality: 0.5)
        
    }
    
    /// 画像の更新
    func updateSamune(image: UIImage) {
        
        //データ
        self.samuneImage = image
        self.samuneImageData = image.jpegData(compressionQuality: 0.5)
        
        //ビュー
        samuneImageView.image = image
        
        //ハイライト画像を生成
        generateHighlightedImage()
    }
    
    /// ハイライト画像を生成する
    func generateHighlightedImage() {
        
        //終わったらenabledをオフに
        self.whiteSwitch.isEnabled = false
        self.blackSwitch.isEnabled = false
        
        DispatchQueue.global().async {
        
            // 黒に近い色を黒に入れ替える処理
            self.blackHighlightedImage = Process.replaceColor(color: UIColor(hex: "000000"),
                                                         withColor: UIColor(hex: "000000"),
                                                         image: self.samuneImage!, tolerance: 0.4)
            
            DispatchQueue.main.async {
                self.blackSwitch.isEnabled = true
            }
            
            // 白を
            self.whiteHighlightedImage = Process.replaceColor(color: UIColor(hex: "FFFFFF"),
                                                         withColor: UIColor(hex: "FFFFFF"),
                                                         image: self.samuneImage!, tolerance: 0.3)
            
            // 黒に白を施す
            self.bothHighlightedImage = Process.replaceColor(color: UIColor(hex: "FFFFFF"),
                                                         withColor: UIColor(hex: "FFFFFF"),
                                                         image: self.blackHighlightedImage!, tolerance: 0.3)
            
            DispatchQueue.main.async {
                //終わったらenabledをオンに
                self.whiteSwitch.isEnabled = true
            }
        }
        
    }
}

// MARK: extension
extension CheckViewController: CropViewControllerDelegate {
    
    //加工した画像が取得できる
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        //画像を更新
        updateSamune(image: image)
        
        //閉じる
        dismiss(animated: true, completion: nil)
    }
    
    // キャンセル時
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension CheckViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 5
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        
        let markView: Array<UIView> = [textFieldBackgroundView,
                        whiteHighlightBackground,
                        blackHighlightBackground,
                        editImageButton,
                        addButton.value(forKey: "view") as! UIView]
        
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
            coachViews.bodyView.hintLabel.text = "ここでドキュメントに名前を設定することができます。設定しなくても構いません。"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 1:
            coachViews.bodyView.hintLabel.text = "このスイッチをオンにすると、画像内の白に近い色が白に変換され、後のフィルターをかける際に見やすくなることがあります。"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 2:
            coachViews.bodyView.hintLabel.text = "このスイッチをオンにすると、画像内の黒に近い色が黒に変換され、後のフィルターをかける際に見やすくなることがあります。"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 3:
            coachViews.bodyView.hintLabel.text = "このボタンで写真を編集することができます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 4:
            coachViews.bodyView.hintLabel.text = "設定できたら追加ボタンを押して追加しましょう！"
            coachViews.bodyView.nextLabel.text = "OK!"
            
            let realm = try! Realm()
            
            try! realm.write {
                //フラグをオンに
                flag.isFirstOpenCheck = false
            }
            
        default:
            break
        
        }

        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
}
