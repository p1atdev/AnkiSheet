//
//  RedSheetTests.swift
//  RedSheetTests
//
//  Created by 周廷叡 on 2021/02/24.
//

import XCTest
import RealmSwift
import Firebase

@testable import RedSheet

class RedSheetTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        
//        Process.logToAnalytics(title: "test")
        
        let realm = try! Realm()
        let folder = Folder()
        folder.title = "フォルダテスト"
        folder.color = "blue"
        folder.createdDate = Date().toFormat("yyyy/MM/dd")
        try! realm.write {
            realm.add(folder)
        }
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
