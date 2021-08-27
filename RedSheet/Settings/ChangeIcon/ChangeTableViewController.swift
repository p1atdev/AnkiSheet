//
//  ChangeTableViewController.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/22.
//

import UIKit

class ChangeTableViewController: UITableViewController {
    
    /// アイコンのストラクチャ
    struct AppIcon {
        let name: String
        let thumbnail: String
        let image: String
    }
    
    //アイコンのリスト
    let icons: [AppIcon] = [
        .init(name: NSLocalizedString("icon.name.classicBlue", comment: "classicBlue"),
              thumbnail: "icon-classic-blue",
              image: "classic-blue"),
        .init(name: NSLocalizedString("icon.name.classicRed", comment: "classicRed"),
              thumbnail: "icon-classic-red",
              image: "classic-red"),
        .init(name: NSLocalizedString("icon.name.blueLight", comment: "blueLight"),
              thumbnail: "icon-blue-light",
              image: "blue-light"),
        .init(name: NSLocalizedString("icon.name.blueDark", comment: "blueDark"),
              thumbnail: "icon-blue-dark",
              image: "blue-dark"),
        .init(name: NSLocalizedString("icon.name.redLight", comment: "redLight"),
              thumbnail: "icon-red-light",
              image: "red-light"),
        .init(name: NSLocalizedString("icon.name.redDark", comment: "redDark"),
              thumbnail: "icon-red-dark",
              image: "red-dark"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //タイトルをセット
        self.title = "アプリアイコンを変更"
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return icons.count    //アイコンの数
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default,
                                   reuseIdentifier: "iconCell")
        
        cell.textLabel?.text = icons[indexPath.row].name  //テキストをセット
        
        cell.imageView?.image = UIImage(named: icons[indexPath.row].thumbnail) //画像をセット
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.clipsToBounds = true
        
        cell.imageView?.frame.size = .init(width: 56, height: 24)
        
        print(cell.imageView?.frame.size)
        
        //角丸
        cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.width)! / 4
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row  = indexPath.row    //ロー
        
        //アイコンを変更
        setIcon(icons[row])
    }
    
    /// アイコンを変更する
    private func setIcon(_ icon: AppIcon, completion: ((Bool) -> Void)? = nil) {
        
        if UIApplication.shared.supportsAlternateIcons {
            UIApplication.shared.setAlternateIconName(icon.image) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("changed icon")
                }
            }
        }
    }

}
