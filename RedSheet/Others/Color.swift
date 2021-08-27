//
//  Color.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/03/22.
//

import UIKit

enum Color {
    
    ///シートの色関係
    enum sheet {
        
        /// デフォルトシート
        enum `default` {
            /// デフォルトシートのオレンジ
            enum orange {
                /// デフォルトシートのオレンジの色
                static let color: UIColor = UIColor(hex: "F09819")
                /// デフォルトシートのオレンジの色のhex
                static let hex: String = "F09819"
            }
            
            /// デフォルトシートの緑
            enum green {
                /// デフォルトシートの緑の色
                static let color: UIColor = UIColor(hex: "5E773C")
                /// デフォルトシートの緑の色のhex
                static let hex: String = "5E773C"
            }
            
            /// 青
            enum blue {
                /// デフォルトシートの青
                static let color: UIColor = UIColor(hex: "335880")
                /// デフォルトシートの青の色のhex
                static let hex: String = "5E773C"
            }
            
            /// 紫
            enum purple {
                /// デフォルトシートの紫
                static let color: UIColor = UIColor(hex: "8B7EE4")
                /// デフォルトシートの紫の色のhex
                static let hex: String = "8B7EE4"
            }
            
            /// 白
            enum white {
                /// 真っ白
                static let color: UIColor = UIColor(hex: "FFFFFF")
                /// 白のhex
                static let hex: String = "FFFFFF"
            }
            
            /// 黒
            enum black {
                /// 真っ黒
                static let color: UIColor = UIColor(hex: "000000")
                /// 黒のhex
                static let hex: String = "000000"
            }
        }
        
        /// 編集、newColorでinsteadなのかそうでないのかを表す
        enum editing {
            /// 置き換えられる色(オレンジ等)
            case target
            /// 置き換える色(白等)
            case instead
        }
        
    }
    
    /// 背景色
    enum background {
        
    }
    
}
