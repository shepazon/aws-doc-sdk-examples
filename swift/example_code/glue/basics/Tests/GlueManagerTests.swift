/*
   Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: Apache-2.0
*/

import XCTest
import Foundation
import ClientRuntime
import AWSGlue
import SwiftUtilities

fileprivate struct Crawler: Equatable {
    var name: String? = nil
    var role: String? = nil
    var s3path: String? = nil
    var cron: String? = nil
    var databaseName: String? = nil
    var tablePrefix: String? = nil
}

struct MockSessionSettings {
    var s3path: String? = nil
    var role: String? = nil
}

public struct MockSession: GlueSessionPrototype {
    fileprivate var crawler: Crawler? = nil
    var settings: MockSessionSettings

    init(settings: MockSessionSettings? = nil) {
        if settings != nil {
            self.settings = settings!
        }
    }

    func verifyCrawler() {
        let text = ""

        if self.crawler.name !=
    }

    mutating func createCrawler(input: CreateCrawlerInput) async throws -> CreateCrawlerOutputResponse {
        self.crawler = Crawler(
            name: input.name,
            role: input.role,
            s3path: settings.s3path,
            cron: input.schedule,
            databaseName: input.databaseName,
            tablePrefix: input.tablePrefix
        )

        let output = CreateCrawlerOutputResponse()
        return output
    }
}

/// Tests for the main program.

final class GlueManagerTests: XCTestCase {

    /// Class-wide setup function for the test suite. This function is called
    /// *once*, before calling any of the other test functions below.
    override class func setUp() {
        super.setUp()
        SDKLoggingSystem.initialize(logLevel: .error)
    }

    func testInit() async throws {
        let session = MockSession()
        let glue = try await GlueManager(session: session)

        XCTAssertTrue(session == glue.session, "GlueManager session mismatch.")
    }

    func testCreateCrawler() async throws {
        let session = MockSession()
        let glue = try await GlueManager(session: session)

        let s3Target = GlueClientTypes.S3Target(path: session.settings.s3path)
        let targetList = GlueClientTypes.CrawlerTargets(s3Targets: [s3Target])

        let input = CreateCrawlerInput(
            databaseName: "test-database",
            name: "test-crawler",
            role: session.settings.role,
            schedule: "cron(15 12 * * ? *)",
            tablePrefix: "prefix-",
            targets: targetList
        )
        try await glue.createCrawler(input: input)
    }
}