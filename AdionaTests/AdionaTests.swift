//
//  AdionaTests.swift
//  AdionaTests
//
//  Created by Ken Franklin on 6/22/22.
//

import XCTest
@testable import Adiona_WatchKit_Extension

class AdionaTests: XCTestCase {
    static let testBucketName = "test_bucket"
        
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testBucketName() throws {
        S3Session.dataBucket.bucketName = AdionaTests.testBucketName
        let bucketPath = "\(S3Session.dataBucket.rootBucket)/\(AdionaTests.testBucketName)/"
        XCTAssertEqual(bucketPath, S3Session.dataBucket.bucketName)
    }
}
