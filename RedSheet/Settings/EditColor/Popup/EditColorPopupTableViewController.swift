//
//  EditColorPopupTableViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/07/19.
//

import UIKit

protocol EditColorPopupTableViewDelegate {
    func createBlankFilter()    //自分で入力する系のやつ
    func addExsistingFilter(filter: FilterModel)
}

class EditColorPopupTableViewController: UITableViewController {
    
    // デフォルトのカラーとか
    private let exsistingFilters: [FilterModel] = [
        .init(name: Localize.sheet.orangeToWhite,
              targetColor: Color.sheet.default.orange.color,
              insteadColor: Color.sheet.default.white.color,
              tolerance: 0.75),
        .init(name: Localize.sheet.greenToBlack,
              targetColor: Color.sheet.default.green.color,
              insteadColor: Color.sheet.default.black.color,
              tolerance: 0.5),
        .init(name: Localize.sheet.blueToWhite,
              targetColor: Color.sheet.default.blue.color,
              insteadColor: Color.sheet.default.white.color,
              tolerance: 0.36),
        .init(name: Localize.sheet.blueToBlack,
              targetColor: Color.sheet.default.blue.color,
              insteadColor: Color.sheet.default.black.color,
              tolerance: 0.36),
        .init(name: Localize.sheet.purpleToWhite,
              targetColor: Color.sheet.default.purple.color,
              insteadColor: Color.sheet.default.white.color,
              tolerance: 0.45)
        
        
    ]
    
    // デリゲート
    var delegate: EditColorPopupTableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セルのセットアップ
        setupCell()
        
        // 余計なセルを削除
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
//        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return exsistingFilters.count
            
        case 1:
            return 1
            
        default:
            return 0
        }
    }
    
    // セクションのタイトル
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return "テンプレート"
            
        case 1:
            return "カスタム"
            
        default:
            return nil
        }
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        case 1:
            // カスタムフィルターを作るセル
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            
            cell.textLabel?.text = Localize.settings.editColor.createOriginalFilter
            cell.imageView?.image = UIImage(systemName: "wand.and.stars")
            
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: EditColorPupupTableViewCell.identifier,
                                                     for: indexPath) as! EditColorPupupTableViewCell
            //セット
            cell.setData(filter: exsistingFilters[indexPath.row])
            
            return cell
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            // テンプレの追加
            
            //デリゲートを実行
            delegate?.addExsistingFilter(filter: exsistingFilters[indexPath.row])
            
        case 1:
            // カスタムへ遷移
            //初期値のフィルターを作成する
            delegate?.createBlankFilter()
            
        default:
            break
        }
    }
    
    /// セルのセットアップ
    private func setupCell() {
        // 登録
        tableView.register(EditColorPupupTableViewCell.nib,
                           forCellReuseIdentifier: EditColorPupupTableViewCell.identifier)
        
    }
}
