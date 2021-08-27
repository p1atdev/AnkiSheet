//
//  NewColorViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/16.
//

import UIKit
import RealmSwift
import Instructions

class NewColorViewController: UIViewController {
    
    /// 色のビュー
    @IBOutlet weak var colorView: UIView!
    
    /// 厳しさのフィールド
    @IBOutlet weak var toleranceField: UITextField!
    
    /// 厳しさのフィールドの親ビュー
    @IBOutlet weak var toleranceFieldParentView: UIView!
    
    /// 厳しさのスライダー
    @IBOutlet weak var toleranceSlider: UISlider!
    
    /// 追加ボタン
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    /// 色の説明ラベル
    @IBOutlet weak var colorDescription: UILabel!
    
    /// 入れ替える色のビュー
    @IBOutlet weak var insteadColorView: UIView!
    
    /// 矢印の画像
    @IBOutlet weak var arrowImageView: UIImageView!
    
    /// 追加するからーのラベル
    @IBOutlet weak var addColorLabel: UILabel!
    
    /// 判定の緩さラベル
    @IBOutlet weak var colorToleranceLabel: UILabel!
    
    /// 自作の方のナビバー
    @IBOutlet weak var originalNavibar: UINavigationBar!
    
    ///自作ナビバーの方の保存、更新ボタン
    @IBOutlet weak var originalNaviBarSaveButton: UIBarButtonItem!
    
    /// 通常のナビバーの保存、更新ボタン
    @IBOutlet weak var normalNaviBarSaveButton: UIBarButtonItem!
    
    
    /// 厳しさ
    var tolerance: Float = 0.75
    
    /// ターゲットの色
    var targetColor: UIColor = .orange
    
    /// 入れ替える色
    var insteadColor: UIColor = UIColor(hex: "FFFFFF")
    
    /// 作成するシート
    var willCreateSheet: Sheet? = Sheet()
    
    /// 更新するシート
    var willUpdateSheet: Sheet?
    
    /// デリゲート
    ///サイドメニュー
    var sideDelegate: SideTableViewControllerDelegate? = nil
    
    /// シート編集
    var editDelegate: EditColorTableViewControllerDelegate? = nil
    
    /// 追加か更新か
    var isAdding: Bool = true
    
    /// showで遷移してきたか
    var isFromShow: Bool = false
    
    /**
     今どっちの色を選んでるのか
     - Parameters:
     - leftColorSelecting: 左ならtrue、右ならfalse
     */
    var leftColorSelecting: Bool = true
    
    /// グラデーション用のビュー
    let gradientLayer = CAGradientLayer()
    
    /// コーチビューコントローラー
    let coachMarksController = CoachMarksController()
    
    /// フラグ
    var flag = Flag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isAdding {
            
            colorView.backgroundColor = targetColor
            updateGradient()   //グラデーションをセット
            
            //初期の色をセットする
            insteadColorView.backgroundColor = UIColor(hex: "FFFFFF")
            
            //もしshowから来てたら隠す
            originalNavibar.isHidden = isFromShow
            
            
        } else {
            
            //UIを変更
            //謎の方のナビバーを隠す
            originalNavibar.isHidden = isFromShow
            
            addButton.title = "保存"
            colorDescription.text = "更新するカラー"
            
            toleranceSlider.value = isAdding ? willCreateSheet!.tolerance : willUpdateSheet!.tolerance
            toleranceField.text = String(Int(round(willUpdateSheet!.tolerance * 100)))
            tolerance = toleranceSlider.value
            
            //色を更新
            colorView.backgroundColor = targetColor
            insteadColorView.backgroundColor = insteadColor
            
        }
        
        //影をつける
        //角丸
        let radius = insteadColorView.bounds.width / 2
        Process.setCornerWithShadow(view: colorView,
                                    cornerRadius: radius,
                                    shadowColor: UIColor.label.cgColor,
                                    shadowRadius: 4,
                                    shadowOpacity: 0.4,
                                    shadowOffset: .init(width: 4, height: 4),
                                    parentView: nil)
        Process.setCornerWithShadow(view: insteadColorView,
                                    cornerRadius: radius,
                                    shadowColor: UIColor.label.cgColor,
                                    shadowRadius: 4,
                                    shadowOpacity: 0.4,
                                    shadowOffset: .init(width: 4, height: 4),
                                    parentView: nil)
        
        toleranceFieldParentView.layer.cornerRadius = 8
        
        
        //データソースを紐付けます
        self.coachMarksController.dataSource = self
        
        //フラグを取得
        let realm = try! Realm()
        flag = realm.objects(Flag.self).first!
        
        //レイヤーを追加
        gradientLayer.frame = colorView.bounds
        
        //角丸
        gradientLayer.cornerRadius = gradientLayer.bounds.width / 2
        
        updateGradient()   //グラデーションをセット
        
        colorView.layer.insertSublayer(gradientLayer, at: 0)
        
        // デリゲート
        toleranceField.delegate = self
        
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        updateGradient()   //グラデーションを更新
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //チュートリアルを表示
        if flag.isFirstOpenNewColor {
            self.coachMarksController.start(in: .currentWindow(of: self))
        }
        
    }
    
    //スライダーがいじられた
    @IBAction func toleranceChanged(_ sender: UISlider) {
        
        sender.value = round(sender.value * 100) / 100
        
        tolerance = sender.value
        
        toleranceField.text = String(Int(round(tolerance * 100)))
        
        if isAdding {
            willCreateSheet?.tolerance = tolerance
        } else {
            willUpdateSheet?.tolerance = tolerance
        }
        
    }
    
    //キャンセルボタンが押された
    @IBAction func cancelButtonTapped(_ sender: Any) {
        
        //dimiss
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    //追加・更新ボタンが押された
    @IBAction func addButtonTapped(_ sender: Any) {
        
        let realm = try! Realm()
        
        if isFromShow {
            
            //realmに追加
            let sheet = willCreateSheet!
            
            sheet.uuid = UUID().uuidString
            
            sheet.colorHex = targetColor.hex()
            sheet.insteadColorHex = insteadColor.hex()
            sheet.tolerance = tolerance
            
            try! realm.write {
                realm.add(sheet)
            }
            
            //デリゲートからテーブルを更新
            sideDelegate?.reloadTable()
            
        } else {
            
            if isAdding {
                
                //realmに追加
                let sheet = willCreateSheet!
                
                sheet.uuid = UUID().uuidString
                
                sheet.colorHex = targetColor.hex()
                sheet.insteadColorHex = insteadColor.hex()
                sheet.tolerance = tolerance
                
                try! realm.write {
                    realm.add(sheet)
                }
                
                //デリゲートからテーブルを更新
                sideDelegate?.reloadTable()
                
                
            } else {
                
                guard let sheet = realm.objects(Sheet.self).filter("uuid = %@", willUpdateSheet!.uuid).first else { return }
                
                //更新
                try! realm.write {
                    sheet.colorHex = targetColor.hex()
                    sheet.insteadColorHex = insteadColor.hex()
                    sheet.tolerance = tolerance
                }
                
                //tableのリロード
                sideDelegate?.reloadTable()
                sideDelegate?.refreshFilter()
                
                // キャッシュを更新
                Process.deleteFileteredCache(target: willUpdateSheet!)
                
            }
            
        }
        
        //　更新の通知
        NotificationCenter.default.post(name: .sheetUpdated, object: nil)
        
        //戻る
        self.dismiss(animated: true, completion: nil)
        
    }
    
    //更新ボタンが押された
    @IBAction func saveButtonTapped(_ sender: Any) {
        
        if !isAdding {
            
            //realmを更新
            let realm = try! Realm()
            let sheet = realm.objects(Sheet.self).filter("uuid == %@", willUpdateSheet!.uuid).first!
            
            try! realm.write {
                //値を更新
                sheet.colorHex = targetColor.hex()
                sheet.insteadColorHex = insteadColor.hex()
                sheet.tolerance = tolerance
            }
            
            // キャッシュを更新
            Process.deleteFileteredCache(target: willUpdateSheet!)
            
            //デリゲートを実行
            editDelegate?.updateColor()
            
        } else {
            
            //MARK: showで遷移してきて追加モードの時
            
            //realmを更新
            let realm = try! Realm()
            
            let sheet = Sheet()
            sheet.colorHex = colorView.backgroundColor!.hex()
            sheet.insteadColorHex = insteadColorView.backgroundColor!.hex()
            sheet.tolerance = toleranceSlider.value
            sheet.uuid = UUID().uuidString
            
            try! realm.write {
                //値を更新
                realm.add(sheet)
            }
            
            //デリゲートを実行
            editDelegate?.updateTable()
            
        }
        
        //戻る
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
    
    //左側の色が押された
    @IBAction func leftColorTapped(_ sender: Any) {
        
        //TODO: previewVCからきた場合、ここの色を選択する処理をpreviewVCTableMenuに委託する
        if isFromShow {
            presentToSelectColor()  //色を選択していく
        } else {
            // これを閉じて、ピッカーを表示する
            self.dismiss(animated: true, completion: {
                //通知を送信
                NotificationCenter.default.post(name: .willColorPickerBeCalled,
                                                object: nil,
                                                userInfo: ["data": EditingSheetData(sheet: self.isAdding ?
                                                                                    self.willCreateSheet! :
                                                                                    self.willUpdateSheet!,
                                                                                 type: .target,
                                                                                 status: self.isAdding ?
                                                                                    .adding :
                                                                                    .editing)])
                
            })
        }
        
    }
    
    //右側の色が押された
    @IBAction func rightColorTapped(_ sender: Any) {
        
        //TODO: previewVCからきた場合、ここの色を選択する処理をpreviewVCTableMenuに委託する
        if isFromShow {
            presentToSelectColor(isRight: true)  //色を選択していく
        } else {
            // これを閉じて、ピッカーを表示する
            self.dismiss(animated: true, completion: {
                //通知を送信
                NotificationCenter.default.post(name: .willColorPickerBeCalled, object: nil,
                                                userInfo: ["data": EditingSheetData(sheet: self.isAdding ?
                                                                                    self.willCreateSheet! :
                                                                                    self.willUpdateSheet!,
                                                                                 type: .instead,
                                                                                 status: self.isAdding ?
                                                                                    .adding :
                                                                                    .editing)])
                
            })
        }
    }
    
    // 画面がタップされた
    @IBAction func screenTapped(_ sender: Any) {
        
        //キーボードを閉じる
        toleranceField.endEditing(false)
        
    }
    
    
    /// データをセット
    func setData(color: UIColor) {
        targetColor = color
        
        //もし更新モードなら
        if !isAdding {
            addButton.title = "保存"
            colorDescription.text = "更新するカラー"
        } else {
            willUpdateSheet = Sheet()
        }
    }
    
    /// データをセット
    func setData(sheet: Sheet) {
        
        willUpdateSheet = Sheet()
        willUpdateSheet?.uuid = sheet.uuid
        willUpdateSheet?.colorHex = sheet.colorHex
        willUpdateSheet?.insteadColorHex = sheet.insteadColorHex
        willUpdateSheet?.tolerance = sheet.tolerance
        
        //色をセット
        targetColor = UIColor(hex: sheet.colorHex)
        insteadColor = UIColor(hex: sheet.insteadColorHex)
        
        //グラデーションをセット
        updateGradient()
    }
    
    /// 色を選択して戻ってきた
    func setDataAgain(sheetData: EditingSheetData) {
        
        switch sheetData.sheetStatus {
        case .adding:
            willCreateSheet = sheetData.targetSheet
        case .editing:
            willUpdateSheet = sheetData.targetSheet
        }
        
        print("｜シートカラー")
        print("｜- 代入前")
        print("｜- target:", targetColor.hex())
        print("｜- instead:", insteadColor.hex())

        //色をセット
        targetColor = UIColor(hex: sheetData.targetSheet.colorHex)
        insteadColor = UIColor(hex: sheetData.targetSheet.insteadColorHex)
        
        print("｜- 代入後")
        print("｜- target:", targetColor.hex())
        print("｜- instead:", insteadColor.hex())
        
        //グラデーションをセット
        updateGradient()
        
    }
    
    /**
     どっちの色が押されたのかを指定してカラーピッカーに遷移
     - Parameters:
     - isRight: 指定しなければfalseで左を表す。trueを指定すると右になる
     */
    func presentToSelectColor(isRight: Bool = false) {
        
        leftColorSelecting = !isRight
        
        //遷移
        let colorPicker = UIColorPickerViewController()
        
        colorPicker.delegate = self
        
        colorPicker.supportsAlpha = false
        
        //色をセットする
        colorPicker.selectedColor = !isRight ? targetColor : insteadColor
        
        self.present(colorPicker, animated: true, completion: nil)
    }
    
    /// グラデーションを更新
    func updateGradient() {
        
        // グラデーションカラーの設定
        gradientLayer.colors = generateGradientColor()
        
        //グラデーションのタイプ
        gradientLayer.type = .conic
        
        // グラデーションの開始地点の設定
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
    }
    
    /// グラデーション用の色を生成
    private func generateGradientColor() -> [CGColor] {
        
        //返却用array
        var returnArray: Array<UIColor> = []
        
        //厳しさ
        let sa = CGFloat(tolerance)
        
        //色を取得
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0;
        targetColor.getRed(&r, green: &g, blue: &b, alpha: &a);
        
        //順に色をぶち込む
        returnArray.append(.init(red: r-sa,
                                 green: g,
                                 blue: b,
                                 alpha: 1))
        returnArray.append(.init(red: r-sa,
                                 green: g-sa,
                                 blue: b,
                                 alpha: 1))
        returnArray.append(.init(red: r-sa,
                                 green: g-sa,
                                 blue: b-sa,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g-sa,
                                 blue: b,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g-sa,
                                 blue: b-sa,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g,
                                 blue: b-sa,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g,
                                 blue: b,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g,
                                 blue: b+sa,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g+sa,
                                 blue: b+sa,
                                 alpha: 1))
        returnArray.append(.init(red: r+sa,
                                 green: g+sa,
                                 blue: b+sa,
                                 alpha: 1))
        returnArray.append(.init(red: r,
                                 green: g+sa,
                                 blue: b,
                                 alpha: 1))
        returnArray.append(.init(red: r+sa,
                                 green: g+sa,
                                 blue: b,
                                 alpha: 1))
        returnArray.append(.init(red: r+sa,
                                 green: g,
                                 blue: b,
                                 alpha: 1))
        
        
        return returnArray.map({ $0.cgColor })
    }
    
}

// MARK: カラーピッカー
extension NewColorViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        //        print("Selected color: \(viewController.selectedColor)")
        
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        //        print("Color picker has been closed")
        
        
        if leftColorSelecting { //左なら
            
            targetColor = viewController.selectedColor
            colorView.backgroundColor = targetColor
            updateGradient()   //グラデーションをセット
            
        } else {    //右なら
            
            insteadColor = viewController.selectedColor
            insteadColorView.backgroundColor = insteadColor
            updateGradient()   //グラデーションをセット
        }
        
    }
    
}

// MARK: チュートリアル
extension NewColorViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    /// 吹き出しの数を決める
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 5
    }
    
    /**
     スポットライトが当たるビューを返します
     - Parameters:
     - index: 何ステップ目か
     */
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        
        //保存、更新ボタン
        let saveButton: UIView = {
            if isFromShow {
                return normalNaviBarSaveButton.value(forKey: "view") as! UIView
            } else {
                return originalNaviBarSaveButton.value(forKey: "view") as! UIView
            }
        }()
        
        let highlightViews: Array<UIView> = [colorView,
                                             insteadColorView,
                                             toleranceSlider,
                                             toleranceFieldParentView,
                                             saveButton,
        ]
        
        //チュートリアルで使うビューの中からindexで何ステップ目かを指定
        return coachMarksController.helper.makeCoachMark(for: highlightViews[index])
    }
    
    /**
     吹き出しの詳細を決めます
     - Parameters:
     - coachMarksController: チュートリアル用のVC
     - index: 何ステップ目か
     - coachMark: 吹き出し
     - Returns: 吹き出し
     */
    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        coachMarkViewsAt index: Int,
        madeFrom coachMark: CoachMark
    ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
        
        //吹き出しのビューを作成します
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(
            withArrow: true,    //三角の矢印をつけるか
            arrowOrientation: coachMark.arrowOrientation    //矢印の向き(吹き出しの位置)
        )
        
        //index(ステップ)によって表示内容を分岐させます
        switch index {
        case 0:    //colorView
            coachViews.bodyView.hintLabel.text = "これを押すと消したい色(オレンジなど)を選択できます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 1:    //insteadColorView
            coachViews.bodyView.hintLabel.text = "これを押すと置き換えたい色(白など)を選択できます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 2:    //toleranceSlider
            coachViews.bodyView.hintLabel.text = "このスライダーで色の判定の緩さを変更できます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 3:     // toleranceFieldView
            coachViews.bodyView.hintLabel.text = "直接数値を指定することもできます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 4:     //保存ボタン
            coachViews.bodyView.hintLabel.text = "設定ができたら保存しましょう"
            coachViews.bodyView.nextLabel.text = "OK!"
            
            //フラグを更新
            setFlag()
            
        default:
            break
            
        }
        
        //その他の設定が終わったら吹き出しを返します
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    ///フラグを更新
    private func setFlag() {
        //realm
        let realm = try! Realm()
        try! realm.write {
            flag.isFirstOpenNewColor = false
        }
    }
}

extension NewColorViewController: UITextFieldDelegate {
    
    // リターンキーが押された
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //toleranceを更新
        tolerance = Float(textField.text ?? "50")! / 100
        
        UIView.animate(withDuration: 0.1, animations: {
            
            //スライダを更新
            self.toleranceSlider.value = self.tolerance
            
            //グラデーションを更新
            self.updateGradient()
        })
        
        // キーボードを閉じる
        textField.endEditing(false)
        
        return true
    }
}
