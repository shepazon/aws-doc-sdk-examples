/*
   Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: Apache-2.0
*/

import XCTest
import Foundation
import ClientRuntime
import AWSGlue
import SwiftUtilities
import ServiceManager

struct MockSessionSettings {
    var s3path: String? = nil
    var role: String? = nil
    var crawlerName: String? = nil
}

public struct Crawler {
    var createInput: CreateCrawlerInput? = nil

    init(input: CreateCrawlerInput?) {
        self.createInput = input
    }
}

public struct MockSession: GlueSessionPrototype {
    var settings: MockSessionSettings
    public var crawler: Crawler?

    init(settings: MockSessionSettings? = nil) {
        if settings != nil {
            self.settings = settings!
        } else {
            self.settings = MockSessionSettings()
        }

        self.crawler = nil
    }

    mutating public func createCrawler(input: CreateCrawlerInput) async throws -> CreateCrawlerOutputResponse {
        self.crawler = Crawler(input: input)

        let output = CreateCrawlerOutputResponse()
        return output
    }

    mutating public func deleteCrawler(input: DeleteCrawlerInput) async throws -> DeleteCrawlerOutputResponse {
        self.crawler?.createInput = nil
        return DeleteCrawlerOutputResponse()
    }

    public func startCrawler(input: StartCrawlerInput) async throws -> StartCrawlerOutputResponse {
        return StartCrawlerOutputResponse()
    }

    public func stopCrawler(input: StopCrawlerInput) async throws -> StopCrawlerOutputResponse {
        return StopCrawlerOutputResponse()
    }

    public func getCrawler(input: GetCrawlerInput) async throws -> GetCrawlerOutputResponse {
        return GetCrawlerOutputResponse()
    }

    public func createDatabase(input: CreateDatabaseInput) async throws -> CreateDatabaseOutputResponse {
        return CreateDatabaseOutputResponse()
    }

    public func getDatabase(input: GetDatabaseInput) async throws -> GetDatabaseOutputResponse {
        return GetDatabaseOutputResponse()
    }

    public func createJob(input: CreateJobInput) async throws -> CreateJobOutputResponse {
        return CreateJobOutputResponse()
    }

    public func getJob(input: GetJobInput) async throws -> GetJobOutputResponse {
        return GetJobOutputResponse()
    }

    public func listJobs(input: ListJobsInput) async throws -> ListJobsOutputResponse {
        return ListJobsOutputResponse()
    }

    public func startJobRun(input: StartJobRunInput) async throws -> StartJobRunOutputResponse {
        return StartJobRunOutputResponse()
    }

    public func getJobRun(input: GetJobRunInput) async throws -> GetJobRunOutputResponse {
        return GetJobRunOutputResponse()
    }

    public func getJobRuns(input: GetJobRunsInput) async throws -> GetJobRunsOutputResponse {
        return GetJobRunsOutputResponse()
    }

    public func deleteJob(input: DeleteJobInput) async throws -> DeleteJobOutputResponse {
        return DeleteJobOutputResponse()
    }

    public func deleteDatabase(input: DeleteDatabaseInput) async throws -> DeleteDatabaseOutputResponse {
        return DeleteDatabaseOutputResponse()
    }

    public func getTables(input: GetTablesInput) async throws -> GetTablesOutputResponse {
        return GetTablesOutputResponse()
    }

    public func batchDeleteTable(input: BatchDeleteTableInput) async throws -> BatchDeleteTableOutputResponse {
        return BatchDeleteTableOutputResponse()
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

    func testCreateCrawler() async throws {
        let session = MockSession()
        let glue = GlueManager(session: session)

        try await glue.createCrawler(
            crawlerName: "test-crawler",
            iamRole: session.settings.role,
            s3Path: session.settings.s3path,
            cronSchedule: "cron(15 12 * * ? *)",
            databaseName: "test-database",
            tablePrefix: "prefix-"
        )

        // Confirm that the `crawler` has all the right stuff in it.

        XCTAssertNotNil(session.crawler, "Crawler not created successfully")
        XCTAssertNotNil(session.crawler?.createInput, "Crawler's cached `CreateCrawlerInput` is nil")
        XCTAssertEqual("test-crawler", session.crawler?.createInput?.name, "Crawler name mismatch")
        XCTAssertEqual(session.settings.role, session.crawler?.createInput?.role, "Crawler role mismatch")
        XCTAssertEqual("cron(15 12 * * ? *)", session.crawler?.createInput?.schedule, "Crawler cron schedule mismatch")
        XCTAssertEqual("test-database", session.crawler?.createInput?.databaseName, "Crawler database name mismatch")
        XCTAssertEqual("prefix-", session.crawler?.createInput?.tablePrefix, "Crawler table prefix mismatch")

        // Check the S3 target by creating a new targets object and comparing
        // it to the one in the `createInput`.

        let s3Target = GlueClientTypes.S3Target(path: session.settings.s3path)
        let targetList = GlueClientTypes.CrawlerTargets(s3Targets: [s3Target])
        XCTAssertEqual(targetList, session.crawler?.createInput?.targets, "Target list mismatch")

        try await glue.deleteCrawler(name: "test-crawler")
    }
/***** ===> MOVE THESE TO THE TEST INSTEAD OF DOING THEM HERE.
       ===> UPDATE THIS TO REACT LIKE THE REAL FUNCTION!
        XCTAssertNotNil(self.crawler?.createInput, "Crawler was not created before deleting")
        XCTAssertEqual(input.name, self.crawler?.createInput?.name, "Specified crawler name doesn't match the one created")
 */        

    func testDeleteCrawler() async throws {
        let session = MockSession()
        let glue = GlueManager(session: session)

        //try await glue.deleteCrawler(name: "test-crawler")
    }
}