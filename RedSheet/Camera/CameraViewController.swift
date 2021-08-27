//
//  CameraViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/26.
//

import UIKit
import AVFoundation
import SnapKit
//import WeScan

// URL: https://qiita.com/t_okkan/items/f2ba9b7009b49fc2e30a

class CameraViewController: UIViewController {
    
    /// シャッターボタン
    @IBOutlet weak var shutterButton: HamburgerMenuRootButton!
    
    /// デバイスからの入力と出力を管理するオブジェクト
    var captureSession = AVCaptureSession()
    
    // カメラデバイスそのものを管理するオブジェクトの作成
    /// メインカメラの管理オブジェクト
    var mainCamera: AVCaptureDevice?
    /// インカメの管理オブジェクト
    var innerCamera: AVCaptureDevice?
    /// 現在使用しているカメラデバイスの管理オブジェクト
    var currentDevice: AVCaptureDevice?
    /// キャプチャーの出力データを受け付けるオブジェクト
    var photoOutput: AVCapturePhotoOutput?
    /// プレビュー表示用のレイヤ
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// 画面の向き
    enum Orientaion: Int {
        /// ホームボタンの位置が
        case right = -1,
             down = 0,
             left = 1,
             up = 2
    }
    
    ///回転前の画面の向き
//    var initialOrientation: Orientaion = .down
    
    /// 保存する画像のパス
    var targetPath: String = "/"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //セットアップ
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        
        //ボタンの設定
        shutterButton.isPlusButton = false
        
        //ボタンの中身を作成していく
        let roundedSquare = CAShapeLayer()
        
        roundedSquare.fillColor = UIColor.white.cgColor
        roundedSquare.lineWidth = 0
        
        roundedSquare.path = UIBezierPath(roundedRect: .init(x: 16,
                                                             y: 16,
                                                             width: 32,
                                                             height: 32),
                                          cornerRadius: 8).cgPath
        //セット
        shutterButton.customLayer = roundedSquare
        
        //カメラの向きを修正
        setUpOrientaion()
        
    }
    
    //画面回転時の動作
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { _ in
                
                //カメラの向きを修正
                self.fixCameraOrientation()
                
            }
        )
    }
    
    /// touch down
    @IBAction func shutterButtonTouchDown(_ sender: Any) {
        
        shutterButton.alpha = 0.8
        
    }
    
    /// touch up
    @IBAction func shutterButtonTouchUpOutside(_ sender: Any) {
        
        shutterButton.alpha = 1.0
        
    }
    
    /// シャッターが切られた
    @IBAction func shutterButtonTouchUpInside(_ sender: Any) {
        
        shutterButton.alpha = 1.0
        
        let settings = AVCapturePhotoSettings()
        
        //デバイスを取得し、
        let device = AVCaptureDevice.default(
            AVCaptureDevice.DeviceType.builtInWideAngleCamera,
            for: AVMediaType.video, // ビデオ入力
            position: AVCaptureDevice.Position.back
        )
        //フラッシュが付いていないならフラッシュを無効化
        if !device!.hasFlash{
            settings.flashMode = .off
        } else {
            //そうでなければフラッシュは自動
            settings.flashMode = .auto
        }
        
        // 撮影された画像をdelegateメソッドで処理
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
        
    }
    
    /// 確認ページに遷移
    func showToCheckVC(imageData: Data) {
        
        let checkSB = UIStoryboard(name: "Check", bundle: nil)
        let checkVC = checkSB.instantiateViewController(identifier: "check") as! CheckViewController
        
        //データをセット
        checkVC.setData(imageData: imageData)
        // パスをセット
        checkVC.targetPath = targetPath
        
        //遷移
        self.show(checkVC, sender: nil)
    }
    
    /// 確認ページに遷移
    func showToCheckVC(image: UIImage) {
        
        let checkSB = UIStoryboard(name: "Check", bundle: nil)
        let checkVC = checkSB.instantiateViewController(identifier: "check") as! CheckViewController
        
        //データをセット
        checkVC.setData(image: image)
        // パスをセット
        checkVC.targetPath = targetPath
        
        //遷移
        self.show(checkVC, sender: nil)
    }
    
    /// UIInterfaceOrientation -> AVCaptureVideoOrientationにConvertする
//    private func convertUIOrientation2VideoOrientation(f: () -> UIInterfaceOrientation) -> AVCaptureVideoOrientation? {
//        let v = f()
//        switch v {
//        case UIInterfaceOrientation.unknown:
//                return nil
//            default:
//                return ([
//                    UIInterfaceOrientation.portrait:
//                        AVCaptureVideoOrientation.portrait,
//                    UIInterfaceOrientation.portraitUpsideDown:
//                        AVCaptureVideoOrientation.portraitUpsideDown,
//                    UIInterfaceOrientation.landscapeLeft:
//                        AVCaptureVideoOrientation.landscapeLeft,
//                    UIInterfaceOrientation.landscapeRight:
//                        AVCaptureVideoOrientation.landscapeRight
//                ])[v]
//        }
//    }
    
    /// カメラの向きを修正
    private func fixCameraOrientation() {
        
        // 最初から回転した角度を取得
        let rotation: CGFloat = CGFloat(getDeviceOrientation().rawValue) * 90
        
        self.cameraPreviewLayer?.transform = CATransform3DMakeRotation(
            rotation / 180 * CGFloat.pi,
            0,
            0,
            1
        )
        
        // フレームを調整
        cameraPreviewLayer?.frame = view.frame
    }
    
    /// 画面の向きについてセットアップする
    private func setUpOrientaion() {
        
        //回転前の画面の向きを保存
//        initialOrientation = getDeviceOrientation()
        
        
        // 通常の状態との違いの角度を取得
        let rotation: CGFloat = {
            switch getDeviceOrientation() {
            case .down:
                return 0
                
            case .right:
                return -90
                
            case .up:
                return 180
                
            case .left:
                return 90
                
            }
            
        }()
        
        self.cameraPreviewLayer?.transform = CATransform3DMakeRotation(
            rotation / 180 * CGFloat.pi,
            0,
            0,
            1
        )
        
        // フレームを調整
        cameraPreviewLayer?.frame = view.frame

    }
    
/// 画面の向きからオリエンテーションを取得する
private func getDeviceOrientation() -> Orientaion {
    
    guard let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation else {
        return .right
    }
    
    switch interfaceOrientation {
    case .landscapeLeft:
        return .left
    case .landscapeRight:
        return .right
    case .portrait:
        return .down
    case .portraitUpsideDown:
        return .up
        
    default:
        return .right
    }
    
}
    
}

//MARK: AVCapturePhotoCaptureDelegateデリゲートメソッド
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    // 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            
            //画像の向きを判定
            let imageOrientation: UIImage.Orientation = {
                switch getDeviceOrientation(){

                case .down:
                    
                    return .right
                    
                case .right:
                    
                    return .up
                    
                case .left:
                    
                    return .down
                    
                case .up:
                    
                    return .left
                }
            }()

            //向きを考慮して画像に変換
            let image = UIImage(cgImage: UIImage(data: imageData)!.cgImage!,
                                scale: 1.0,
                                orientation: imageOrientation
            )
            
            //データを持って遷移する
            showToCheckVC(image: image)
            
        }
    }
}

//MARK: カメラ設定メソッド
extension CameraViewController {
    /// カメラの画質の設定
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    /// デバイスの設定
    func setupDevice() {
        /// カメラデバイスのプロパティ設定
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        /// プロパティの条件を満たしたカメラデバイスの取得
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                mainCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                innerCamera = device
            }
        }
        // 起動時のカメラを設定
        currentDevice = mainCamera
    }
    
    /// 入出力データの設定
    func setupInputOutput() {
        do {
            /// 指定したデバイスを使用するために入力を初期化
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            // 指定した入力をセッションに追加
            captureSession.addInput(captureDeviceInput)
            // 出力データを受け取るオブジェクトの作成
            photoOutput = AVCapturePhotoOutput()
            // 出力ファイルのフォーマットを指定
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
    }
    
    /// カメラのプレビューを表示するレイヤの設定
    func setupPreviewLayer() {
        // 指定したAVCaptureSessionでプレビューレイヤを初期化
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // プレビューレイヤの表示の向きを設定
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        self.cameraPreviewLayer?.frame = view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
        
    }
}
