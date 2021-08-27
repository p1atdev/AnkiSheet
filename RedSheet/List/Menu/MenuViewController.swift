//
//  MenuViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit
import SnapKit
import RealmSwift
import Instructions
import WeScan
import UniformTypeIdentifiers
import PDFKit
import PKHUD
import UTIKit

protocol MenuViewControllerDelegate: AnyObject {
    func addedPDFSuccessfly()
    func getTargetPath() -> String
}

class MenuViewController: UIViewController {
    
    /// PDFのボタン
    @IBOutlet weak var fromPDFButton: HamburgerMenuRootButton!
    
    ///写真のボタン
    @IBOutlet weak var fromPicturesButton: HamburgerMenuRootButton!
    
    ///カメラのボタン
    @IBOutlet weak var fromCameraButton: HamburgerMenuRootButton!
    
    /// ボタンが透けるときに後ろのボタンが見えないようにするための背景ビュー
    @IBOutlet weak var blockClearBackgroundView: UIView!
    
    ///チュートリアル
    let coachMarksController = CoachMarksController()
    
    ///フラグ
    var flag = Flag()
    
    /// デリゲート
    weak var delegate: MenuViewControllerDelegate?
    
    /// パス
    var targetPath: String = "/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //制約を外す
        fromPicturesButton.snp.removeConstraints()
        fromCameraButton.snp.removeConstraints()
        fromPDFButton.snp.removeConstraints()
        
        //ハンバーガーメニューの設定
        fromPicturesButton.isShadowEnabled = false
        fromCameraButton.isShadowEnabled = false
        fromPDFButton.isShadowEnabled = false
        fromPicturesButton.lineWidth =  min(Screen.shortLength / 128, 3)
        fromCameraButton.lineWidth = min(Screen.shortLength / 128, 3)
        fromPDFButton.lineWidth = min(Screen.shortLength / 128, 3)
        
        fromPicturesButton.image = UIImage(systemName: "photo.on.rectangle.angled")!
        fromCameraButton.image = UIImage(systemName: "camera")!
        fromPDFButton.image = UIImage(systemName: "doc.text")
        
        //透けを防ぐビューのセットアップ
        blockClearBackgroundView.snp.makeConstraints { make in
            make.width.equalTo(fromCameraButton.frame.width - 8)
            make.bottom.equalTo(view).offset(-4)
        }
        //角丸に
        blockClearBackgroundView.layer.cornerRadius = (blockClearBackgroundView.frame.width - 8) / 2
        
        //チュートリアル
        self.coachMarksController.dataSource = self
        
        //フラグを取得
        let realm = try! Realm()
        flag = realm.objects(Flag.self).first!
        
        // パスをセットアップ
        setupPath()
        
    }
    
    //ボタンが押されたのでアルファを下げる
    @IBAction func menuButtonTouchDown(_ sender: HamburgerMenuRootButton) {
        
        sender.alpha = 0.8
        
    }
    
    //ボタンから指が離れた
    @IBAction func menuButtonTouchUpOutside(_ sender: HamburgerMenuRootButton) {
        
        sender.alpha = 1.0
        
    }
    
    /// 写真ライブラリから追加するボタンが押された
    @IBAction func fromPicturesButtonTouchUpInside(_ sender: HamburgerMenuRootButton) {
        sender.alpha = 1.0
        
        //遷移
        let pickerController = UIImagePickerController()
        
        //PhotoLibraryから画像を選択
        pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        //デリゲートを設定する
        pickerController.delegate = self
        
        //ピッカーを表示する
        present(pickerController, animated: true, completion: nil)
        
    }
    
    /// 直接カメラで撮るボタンが押された
    @IBAction func fromCameraButtonTouchUpInside(_ sender: HamburgerMenuRootButton) {
        sender.alpha = 1.0
        
        //遷移する
        let cameraSB = UIStoryboard(name: "Camera", bundle: nil)
        let cameraVC = cameraSB.instantiateViewController(identifier: "camera") as! CameraViewController
        
        cameraVC.hidesBottomBarWhenPushed = true
        // パスをセット
        cameraVC.targetPath = targetPath
        
        //遷移
        self.show(cameraVC, sender: nil)
        
        //スキャナーに遷移する
        //        let scannerViewController = ImageScannerController()
        //        scannerViewController.imageScannerDelegate = self
        //
        //        scannerViewController.modalPresentationStyle = .fullScreen
        //
        //
        //        self.present(scannerViewController, animated: true, completion: nil)
        
    }
    
    /// PDFを選択しに行く
    @IBAction func fromPDFButtonTouchUpInside(_ sender: HamburgerMenuRootButton) {
        sender.alpha = 1.0  //透明度を戻す
        
        print("fromPDFButtonがタップされた")
        
        // 2. forOpeningContentTypesでUTTypeで選択して欲しいファイル形式を指定する
        // ここでは選択できるファイルを.m4a, .mp3に限定する
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.pdf
            ],
            asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        self.present(picker, animated: true, completion: nil)
        
    }
    
    
    
    ///ボタンの状態を切り替えるアニメーション
    func changeButtonStatus(isOpened status: Bool) {
        
        //空いてたら閉じる
        if status {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.fromPicturesButton.transform = CGAffineTransform(translationX: 0, y: 0)
                
                self.fromCameraButton.transform = CGAffineTransform(translationX: 0, y: 0)
                
                self.fromPDFButton.transform = CGAffineTransform(translationX: 0, y: 0)
            })
            
        } else {
            //閉じてたら開ける
            UIView.animate(withDuration: 0.2, animations: {
                
                self.fromPicturesButton.transform = CGAffineTransform(translationX: 0, y: -288)
                
                self.fromCameraButton.transform = CGAffineTransform(translationX: 0, y: -192)
                
                self.fromPDFButton.transform = CGAffineTransform(translationX: 0, y: -96)
                
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                //フラグが初めてだったら実行
                if self.flag.isFirstOpenMenu {
                    
                    //チュートリアルを開始
                    self.coachMarksController.start(in: .currentWindow(of: self))
                    
                    //フラグを更新
                    let realm = try! Realm()
                    try! realm.write {
                        self.flag.isFirstOpenMenu = false
                    }
                }
            }
            
        }
        
    }
    
    /// 確認ページに遷移
    func showToCheckVC(image: UIImage) {
        
        let checkSB = UIStoryboard(name: "Check", bundle: nil)
        let checkVC = checkSB.instantiateViewController(identifier: "check") as! CheckViewController
        
        //画像をセット
        checkVC.setData(image: image)
        
        print(targetPath)
        
        // パスをセット
        checkVC.targetPath = targetPath
        
        //遷移
        self.show(checkVC, sender: nil)
    }
    
    /// パスのセットアップ
    private func setupPath() {
        
        if let path = delegate?.getTargetPath() {
            targetPath = path
        } else {
            targetPath = "/"
        }
        
    }
    
}


//MARK: extension
// イメージピッカー
extension MenuViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 画像が選択されたら
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            //写真を持ってチェックに遷移
            let checkSB = UIStoryboard(name: "Check", bundle: nil)
            let checkVC = checkSB.instantiateViewController(identifier: "check") as! CheckViewController
            
            checkVC.setData(image: image)
            checkVC.targetPath = targetPath
            
            // モーダルビュー（つまり、イメージピッカー）を閉じる
            dismiss(animated: true, completion: nil)
            
            //閉じたら遷移
            show(checkVC, sender: targetPath)
            
        } else{
            print("Error")
        }
    }
    
    // 画像選択がキャンセルされた時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // モーダルビューを閉じる
        dismiss(animated: true, completion: nil)
    }
    
}

//MARK: チュートリアル
extension MenuViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 3    //マークの数
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        let markView = [fromPicturesButton, fromCameraButton, fromPDFButton]
        
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
            coachViews.bodyView.hintLabel.text = "このボタンから写真を選んで追加することができます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 1:
            coachViews.bodyView.hintLabel.text = "このボタンで直接カメラを起動して写真を撮ることができます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
        case 2:
            coachViews.bodyView.hintLabel.text = "このボタンからPDFを選んで追加することができます"
            coachViews.bodyView.nextLabel.text = "OK!"
            
            
        default:
            break
            
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}

extension MenuViewController: ImageScannerControllerDelegate {
    
    func imageScannerController(_ scanner: ImageScannerController,
                                didFailWithError error: Error) {
        //エラー発生
        print(error)
    }
    
    func imageScannerController(_ scanner: ImageScannerController,
                                didFinishScanningWithResults results: ImageScannerResults) {
        
        //閉じる
        scanner.dismiss(animated: true)
        
        //確認ページに移動する
        showToCheckVC(image: results.croppedScan.image)
        
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        //キャンセルされた
        scanner.dismiss(animated: true)
    }
    
}

// ファイルピッカー
extension MenuViewController: UIDocumentPickerDelegate {
    
    /// ファイルが選択された
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // ファイル選択後に呼ばれる
        
        for url in urls {
            //ファイルの形式を判定
            switch UTI(filenameExtension: url.pathExtension) {
            case UTI("public.image"), UTI("public.jpeg"), UTI("public.png"):
                print("画像を受け取った")
                
            case UTI("com.adobe.pdf"):  // PDFの場合
                Process.savePDF(path: urls.first!, targetPath: targetPath, completion: {
                    //デリゲートを実行
                    self.delegate?.addedPDFSuccessfly()
                })
                
            case let ext:
                print("他の拡張子のファイルを受け取った:", ext!)
                
            }
        }
        
    }
    
    // 選択がキャンセルされた
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
