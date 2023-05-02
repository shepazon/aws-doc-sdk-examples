/// A protocol that describes the AWS Glue API as used in Swift, and a struct
/// that implements the protocol by calling the corresponding SDK functions.
/// This implementation allows mocking of the AWS Glue API by simply providing
/// another implementation of the protocol.
///
/// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
/// SPDX-License-Identifier: Apache-2.0

// snippet-start:[ddb.swift.glue-all]
import Foundation
import AWSGlue
import ClientRuntime

// snippet-start:[glue.swift.basics.gluemanager.errors]
/// Errors that can be thrown by the `GlueManager` class.
public enum GlueManagerError: Error {
    /// The desired crawler could not be found, or was missing after an
    /// apparently successful call to `createCrawler()`.
    case CrawlerNotFound
    /// The desired database was missing or was not successfully created.
    case DatabaseNotFound
    /// The desired job could not be found or was not successfully created.
    case JobNotFound
    /// The desired job run could not be found or was not successfully created.
    case JobRunNotFound
    /// The desired table could not be found.
    case TableNotFound
    /// The database is invalid or is improperly formed.
    case InvalidDatabase
}
// snippet-end:[glue.swift.basics.gluemanager.errors]

// snippet-start:[glue.swift.basics.gluemanager.session-prototype]
/// A protocol describing the implementation of functions that allow either
/// calling through to AWS Glue or mocking those functions for testing.
protocol GlueSessionPrototype {
    func createCrawler(input: CreateCrawlerInput) async throws -> CreateCrawlerOutputResponse
    func deleteCrawler(input: DeleteCrawlerInput) async throws -> DeleteCrawlerOutputResponse
    func startCrawler(input: StartCrawlerInput) async throws -> StartCrawlerOutputResponse
    func stopCrawler(input: StopCrawlerInput) async throws -> StopCrawlerOutputResponse
    func getCrawler(input: GetCrawlerInput) async throws -> GetCrawlerOutputResponse
    func createDatabase(input: CreateDatabaseInput) async throws -> CreateDatabaseOutputResponse
    func getDatabase(input: GetDatabaseInput) async throws -> GetDatabaseOutputResponse
    func createJob(input: CreateJobInput) async throws -> CreateJobOutputResponse
    func getJob(input: GetJobInput) async throws -> GetJobOutputResponse
    func listJobs(input: ListJobsInput) async throws -> ListJobsOutputResponse
    func startJobRun(input: StartJobRunInput) async throws -> StartJobRunOutputResponse
    func getJobRun(input: GetJobRunInput) async throws -> GetJobRunOutputResponse
    func getJobRuns(input: GetJobRunsInput) async throws -> GetJobRunsOutputResponse
    func deleteJob(input: DeleteJobInput) async throws -> DeleteJobOutputResponse
    func deleteDatabase(input: DeleteDatabaseInput) async throws -> DeleteDatabaseOutputResponse
    func getTables(input: GetTablesInput) async throws -> GetTablesOutputResponse
    func batchDeleteTable(input: BatchDeleteTableInput) async throws -> BatchDeleteTableOutputResponse
}
// snippet-end:[glue.swift.basics.gluemanager.session-prototype]

// snippet-start:[glue.swift.basics.gluesession]
public struct GlueSession: GlueSessionPrototype {
    let awsRegion: String
    let client: GlueClient

    // snippet-start:[glue.swift.basics.gluesession.init]
    /// Create a new Glue session that is actually connected to AWS Glue.
    /// 
    /// - Parameters:
    ///   - region: The AWS Region in which to use Amazon Glue.
    init(region: String = "us-east-2") async throws {
        self.awsRegion = region
        client = try await GlueClient(region: self.awsRegion)
    }
    // snippet-end:[glue.swift.basics.gluesession.init]

    // snippet-start:[glue.swift.basics.gluesession.createcrawler]
    public func createCrawler(input: CreateCrawlerInput) async throws
            -> CreateCrawlerOutputResponse {
        return try await client.createCrawler(input: input)        
    }
    // snippet-end:[glue.swift.basics.gluesession.createcrawler]

    public func deleteCrawler(input: DeleteCrawlerInput) async throws
            -> DeleteCrawlerOutputResponse {
        return try await client.deleteCrawler(input: input)    
    }

    public func startCrawler(input: StartCrawlerInput) async throws
            -> StartCrawlerOutputResponse {
        return try await client.startCrawler(input: input)
    }

    public func stopCrawler(input: StopCrawlerInput) async throws
            -> StopCrawlerOutputResponse {
        return try await client.stopCrawler(input: input)
    }

    public func getCrawler(input: GetCrawlerInput) async throws
            -> GetCrawlerOutputResponse {
        return try await client.getCrawler(input: input)
    }

    public func getDatabase(input: GetDatabaseInput) async throws
            -> GetDatabaseOutputResponse {
        return try await client.getDatabase(input: input)
    }

    public func createJob(input: CreateJobInput) async throws
            -> CreateJobOutputResponse {
        return try await client.createJob(input: input)
    }

    public func getJob(input: GetJobInput) async throws
            -> GetJobOutputResponse {
        return try await client.getJob(input: input)
    }

    public func listJobs(input: ListJobsInput) async throws
            -> ListJobsOutputResponse {
        return try await client.listJobs(input: input)
    }

    public func startJobRun(input: StartJobRunInput) async throws
            -> StartJobRunOutputResponse {
        return try await client.startJobRun(input: input)
    }

    public func getJobRun(input: GetJobRunInput) async throws
            -> GetJobRunOutputResponse {
        return try await client.getJobRun(input: input)
    }

    public func getJobRuns(input: GetJobRunsInput) async throws
            -> GetJobRunsOutputResponse {
        return try await client.getJobRuns(input: input)
    }

    public func getTables(input: GetTablesInput) async throws
            -> GetTablesOutputResponse {
        return try await client.getTables(input: input)
    }

    public func deleteJob(input: DeleteJobInput) async throws
            -> DeleteJobOutputResponse {
        return try await client.deleteJob(input: input)
    }

    public func deleteDatabase(input: DeleteDatabaseInput) async throws
            -> DeleteDatabaseOutputResponse {
        return try await client.deleteDatabase(input: input)
    }

    public func batchDeleteTable(input: BatchDeleteTableInput) async throws
            -> BatchDeleteTableOutputResponse {
        return try await client.batchDeleteTable(input: input)
    }

    public func createDatabase(input: CreateDatabaseInput) async throws
            -> CreateDatabaseOutputResponse {
        return try await client.createDatabase(input: input)
    }
}
// snippet-end:[glue.swift.basics.gluesession]

// snippet-start:[glue.swift.basics.gluemanager]
/// The `GlueManager` class provides functions that use AWS Glue functions.
/// Instead of using the AWS Glue API directly, `GlueManager` uses a session
/// object based on `GlueSessionPrototype`. All Glue function calls are
/// proxied through that object.
///
/// To use the AWS SDK for Swift to interface with AWS Glue, use an instance
/// of `GlueSession` as the session object. Its functions simply call through
/// to the actual AWS Glue API to perform their functions.
///
/// For testing, you can instead implement your own `GlueSessionPrototype`
/// based object to use as the session object. Implement its functions to
/// return mock data and/or do whatever testing or validation of data you wish
/// to do.
public class GlueManager {
    private let session: GlueSessionPrototype

    // snippet-start:[glue.swift.basics.gluemanager.init]
    /// Initialize a new GlueManager instance.
    /// 
    /// - Parameters:
    ///   - session: The `GlueSessionPrototype` to use when making AWS Glue
    ///     calls.
    init(session: GlueSessionPrototype) {
        self.session = session
    }
    // snippet-end:[glue.swift.basics.gluemanager.init]

    // snippet-start:[glue.swift.basics.gluemanager.createdatabase]
    /// Create a database with the given name located at the specified URI.
    ///
    /// - Parameters:
    ///   - databaseName: The name to give the new database.
    ///   - location: The URI at which to create the new database.
    public func createDatabase(name databaseName: String, location: String) async throws {
        let databaseInput = GlueClientTypes.DatabaseInput(
            description: "Created by the AWS SDK for Swift Glue basic scenario example.",
            locationUri: location,
            name: databaseName
        )

        let input = CreateDatabaseInput(
            databaseInput: databaseInput
        )

        _ = try await self.session.createDatabase(input: input)
    }
    // snippet-end:[glue.swift.basics.gluemanager.createdatabase]

    // snippet-start:[glue.swift.basics.gluemanager.createcrawler]
    /// Create a new AWS Glue crawler to crawl the specified data on a
    /// schedule.
    ///
    /// - Parameters:
    ///   - iamRole: The AWS Identity and Access Management (IAM) role to use
    ///     for access permissions.
    ///   - s3Path: The path of the source data (in `bucketname/filepath`
    ///     format).
    ///   - cronSchedule: A string in [`cron`
    ///     format](https://docs.aws.amazon.com/glue/latest/dg/monitor-data-warehouse-schedule.html),
    ///     specifying the schedule on which the crawler should run.
    ///   - databaseName: The name of the database into which located data
    ///     should be stored.
    ///   - tablePrefix: A prefix to use when generating the names of the
    ///     tables that AWS Glue will add to the database.
    ///   - crawlerName: A name to give the new crawler.
    ///
    /// > Note: An example of the `cron` parameter:
    ///         ```let cron = "cron(15 12 * * ? *)"```
    public func createCrawler(crawlerName: String,
                              iamRole: String? = nil,
                              s3Path: String? = nil,
                              cronSchedule: String? = nil,
                              databaseName: String? = nil,
                              tablePrefix: String? = nil) async throws {
        // Create a Glue S3 target from the S3 path string and create a
        // crawler target list from it.

        let s3Target = GlueClientTypes.S3Target(path: s3Path)
        let targetList = GlueClientTypes.CrawlerTargets(s3Targets: [s3Target])

        let input = CreateCrawlerInput(
            databaseName: databaseName,
            description: "Created by the AWS SDK for Swift Glue basic scenario example.",
            name: crawlerName,
            role: iamRole,
            schedule: cronSchedule,
            tablePrefix: tablePrefix,
            targets: targetList
        )

        _ = try await self.session.createCrawler(input: input)
    }
    // snippet-end:[glue.swift.basics.gluemanager.createcrawler]

    // snippet-start:[glue.swift.basics.gluemanager.deletecrawler]
    /// Delete the specified crawler.
    ///
    /// - Parameters:
    ///   - name: A string containing the name of the crawler to
    ///   delete.
    public func deleteCrawler(name: String) async throws {
        let input = DeleteCrawlerInput(name: name)
        _ = try await self.session.deleteCrawler(input: input)
    }
    // snippet-end:[glue.swift.basics.gluemanager.deletecrawler]

    // snippet-start:[glue.swift.basics.gluemanager.startcrawler]
    /// Start the specified crawler, scheduling it to run as specified by the
    /// `cron` parameter specified when calling ``createCrawler()``.
    ///
    /// - Parameters:
    ///   - name: The name of the crawler to start running.
    public func startCrawler(name: String) async throws {
        let input = StartCrawlerInput(name: name)
        _ = try await self.session.startCrawler(input: input)
    }
    // [snippet-end:glue.swift.basics.gluemanager.startcrawler]

    // snippet-start:[glue.swift.basics.gluemanager.stopcrawler]
    /// Stop the specified crawler.
    ///
    /// - Parameters:
    ///   - name: The name of the crawler to stop.
    public func stopCrawler(name: String) async throws {
        let input = StopCrawlerInput(name: name)
        _ = try await self.session.stopCrawler(input: input)
    }
    // snippet-end:[glue.swift.basics.gluemanager.stopcrawler]

    // [snippet-start:glue.swift.basics.gluemanager.getcrawler]
    /// Return a `GlueClientTypes.Crawler` object describing the crawler in
    /// detail.
    ///
    /// - Parameters:
    ///   - name: The name of the crawler to return.
    ///
    /// - Returns: A `ClueClientTypes.Crawler` object describing the specified
    ///   crawler.
    public func getCrawler(name: String) async throws -> GlueClientTypes.Crawler {
        let input = GetCrawlerInput(name: name)
        let output = try await self.session.getCrawler(input: input)
        
        guard let crawler = output.crawler else {
            throw GlueManagerError.CrawlerNotFound
        }
        return crawler
    }
    // snippet-end:[glue.swift.basics.gluemanager.getcrawler]

    // snippet-start:[glue.swift.basics.gluemanager.iscrawlerready]
    /// Checks to see if the crawler is in the `ready` state.
    /// 
    /// - Parameters:
    ///   - name: The name of the crawler to check the ready state of.
    ///
    /// - Returns: `true` if the crawler is ready. If the crawler isn't ready,
    ///  the return value is `false`.
    public func isCrawlerReady(name: String) async throws -> Bool {
        let crawler = try await self.getCrawler(name: name)

        return crawler.state == .ready
    }
    // session-end:[glue.swift.basics.gluemanager.iscrawlerready]

    // session-start:[glue.swift.basics.gluemanager.waituntilcrawlerready]
    /// Watch the state of the crawler and return only when the state is
    /// `ready`
    ///
    /// - Parameters:
    ///   - name: The name of the crawler to wait on.
    public func waitUntilCrawlerReady(name: String) async throws {
        while (try await self.isCrawlerReady(name: name) == false) {
            Thread.sleep(forTimeInterval: 4)
        }
    }
    // session-end:[glue.swift.basics.gluemanager.waituntilcrawlerready]

    // session-start:[glue.swift.basics.gluemanager.getdatabase]
    /// Get and return the specified AWS Glue database.
    ///
    /// - Parameter name: The name of the AWS Glue database to get.
    ///
    /// - Returns: A `GlueClientTypes.Database` object representing the
    ///   database of the specified `name`.
    public func getDatabase(name: String) async throws -> GlueClientTypes.Database {
        let input = GetDatabaseInput(
            name: name
        )
        let output = try await self.session.getDatabase(input: input)

        guard let database = output.database else {
            throw GlueManagerError.DatabaseNotFound
        }
        return database
    }
    // session-end:[glue.swift.basics.gluemanager.getdatabase]

    // session-start:[glue.swift.basics.gluemanager.createjob]
    /// Create a new AWS Glue job.
    /// 
    /// - Parameters:
    ///   - jobName: A name to give the new job.
    ///   - role: The AWS IAM role to use for permissions.
    ///   - scriptLocation: The location on Amazon S3 of the job script.
    public func createJob(name jobName: String, role: String,
                    scriptLocation: String) async throws {
        let command = GlueClientTypes.JobCommand(
            name: "glueetl",
            pythonVersion: "3",
            scriptLocation: scriptLocation
        )

        let input = CreateJobInput(
            command: command,
            description: "Created by the AWS SDK for Swift Glue basic scenario example.",
            glueVersion: "3.0",
            name: jobName,
            numberOfWorkers: 10,
            role: role,
            workerType: .g1x
        )

        _ = try await self.session.createJob(input: input)
    }
    // session-end:[glue.swift.basics.gluemanager.createjob]

    // snippet-start:[glue.swift.basics.gluemanager.getjob]
    /// Return the job matching a given name.
    ///
    /// - Parameters:
    ///   - jobName: The name of the job to return.
    ///
    /// - Returns: A `GlueClientTypes.Job` object containing details about the
    ///   job.
    public func getJob(name jobName: String) async throws -> GlueClientTypes.Job {
        let input = GetJobInput(
            jobName: jobName
        )
        let output = try await self.session.getJob(input: input)
        guard let job = output.job else {
            throw GlueManagerError.JobNotFound
        }

        return job
    }
    // snippet-end:[glue.swift.basics.gluemanager.getjobs]

    // snippet-start:[glue.swift.basics.gluemanager.listjobs]
    /// Return the names of all the AWS Glue jobs on the account.
    ///
    /// - Parameters:
    ///   - maxJobs: The maximum number of jobs to return.
    ///
    /// - Returns: A string array listing the names of all available AWS Glue
    ///   jobs.
    public func listJobs(maxJobs: Int = 1000) async throws -> [String] {
        var jobList: [String] = []
        var nextToken: String? = nil

        // Build a list job names.

        repeat {
            let input = ListJobsInput(
                maxResults: maxJobs,
                nextToken: nextToken
            )
            let output = try await self.session.listJobs(input: input)

            guard let jobs = output.jobNames else {
                return jobList
            }

            jobList = jobList + jobs
            nextToken = output.nextToken
        } while nextToken != nil

        return jobList
    }
    // snippet-end:[glue.swift.basics.gluemanager.listjobs]

    // snippet-start:[glue.swift.basics.gluemanager.startjobrun]
    /// Start an AWS Glue job run.
    ///
    /// - Parameters:
    ///   - jobName: The name of the job to run.
    ///   - databaseName: The name of the database containing the source data.
    ///   - tableName: The name of the table containing the source data.
    ///   - outputBucketURL: The Amazon S3 URL of the bucket and directory
    ///     into which to write the output files.
    ///
    /// - Returns: The job run name's ID as a `String`.
    ///
    public func startJobRun(name jobName: String, databaseName: String,
            tableName: String, outputURL: String) async throws -> String {
        let input = StartJobRunInput(
            arguments: [
                "--input_database": databaseName,
                "--input_table": tableName,
                "--output_bucket_url": outputURL
            ],
            jobName: jobName,
            numberOfWorkers: 10,
            workerType: .g1x
        )

        let output = try await self.session.startJobRun(input: input)

        guard let id = output.jobRunId else {
            throw GlueManagerError.JobNotFound
        }

        return id
    }
    // snippet-end:[glue.swift.basics.gluemanager.startjobrun]

    // snippet-start:[glue.swift.basics.gluemanager.getjobrun]
    /// Return the AWS Glue job whose name and ID are specified.
    ///
    /// - Parameters:
    ///   - jobName: The name of the job to return.
    ///   - id: The job's ID string.
    ///
    /// - Returns: A `GlueClientTypes.JobRun` object containing details about
    ///   the job run.
    public func getJobRun(name jobName: String, id: String) async throws -> GlueClientTypes.JobRun {
        let input = GetJobRunInput(
            jobName: jobName,
            runId: id
        )

        let output = try await self.session.getJobRun(input: input)

        guard let jobRun = output.jobRun else {
            throw GlueManagerError.JobRunNotFound
        }

        return jobRun
    }
    // snippet-end:[glue.swift.basics.gluemanager.getjobrun]

    // snippet-start:[glue.swift.basics.gluemanager.deletejob]
    /// Delete the specified AWS Glue job.
    ///
    /// - Parameters:
    ///   - jobName: The name of the AWS Glue job to delete.
    public func deleteJob(name jobName: String) async throws {
        let input = DeleteJobInput(
            jobName: jobName
        )

        _ = try await self.session.deleteJob(input: input)
    }
    // snippet-end:[glue.swift.basics.gluemanager.deletejob]

    // snippet-start:[glue.swift.basics.gluemanager.gettablesindatabase]
    /// Return a list of the tables in an AWS Glue database.
    ///
    /// - Parameters:
    ///   - databaseName: The name of the database whose tables are to
    ///   be listed.
    ///
    /// - Returns: An array of `GlueClientTypes.Table` objects describing all
    ///   the ables in the specified database.
    public func getTablesInDatabase(name databaseName:String) async throws -> [GlueClientTypes.Table] {
        var tableList: [GlueClientTypes.Table] = []
        var nextToken: String? = nil

        // Build a list of the names of the tables in the database.

        repeat {
            let getTablesInput = GetTablesInput(
                databaseName: databaseName,
                nextToken: nextToken
            )
            let getTablesOutput = try await self.session.getTables(input: getTablesInput)

            guard let tables = getTablesOutput.tableList else {
                return tableList
            }

            tableList = tableList + tables
            nextToken = getTablesOutput.nextToken
        } while nextToken != nil

        return tableList
    }
    // snippet-end:[glue.swift.basics.gluemanager.gettablesindatabase]

    // snippet-start:[glue.swift.basics.gluemanager.getjobruns]
    /// Get a list of the job runs for a specific job.
    ///
    /// - Parameters:
    ///   - jobName: The name of the job whose runs are to be returned.
    ///   - maxRuns: The maximum number of job runs to get.
    ///
    /// - Returns: An array of `GlueClientTypes.JobRun` objects, each
    ///   describing one run of the specified job.
    public func getJobRuns(jobName: String, maxRuns: Int = 1000) async throws
            -> [GlueClientTypes.JobRun] {
        var jobRunList: [GlueClientTypes.JobRun] = []
        var nextToken: String? = nil

        // Build a list of all the job runs on the user's account for the
        // current Region.

        repeat {
            let getJobRunsInput = GetJobRunsInput(
                jobName: jobName,
                maxResults: maxRuns,
                nextToken: nextToken
            )
            let getJobRunsOutput = try await self.session.getJobRuns(input: getJobRunsInput)

            guard let runs = getJobRunsOutput.jobRuns else {
                return jobRunList
            }

            jobRunList = jobRunList + runs
            nextToken = getJobRunsOutput.nextToken
        } while nextToken != nil

        return jobRunList
    }
    // snippet-end:[glue.swift.basics.gluemanager.getjobruns]

    // snippet-start:[glue.swift.basics.gluemanager.deletedatabase]
    /// Delete the specified database.
    ///
    /// - Parameters:
    ///   - databaseName: The name of the database to delete.
    ///   - deleteTables: Whether or not to delete a database (and its tables)
    ///     if the database isn't empty. Default is `false`.
    public func deleteDatabase(name databaseName: String,
            withTables deleteTables: Bool = false) async throws {
        if deleteTables == true {
            var tableNames: [String] = []

            // Get a list of names of all the tables in the database.

            let tableList = try await self.getTablesInDatabase(name: databaseName)
            for table in tableList {
                let name = table.name
                if name != nil {
                    tableNames.append(name!)
                }
            }

            // Delete all the tables in the database.

            let batchDeleteTableInput = BatchDeleteTableInput(
                databaseName: databaseName,
                tablesToDelete: tableNames
            )

            _ = try await self.session.batchDeleteTable(input: batchDeleteTableInput)
        }
        
        // Delete the database itself.

        let input = DeleteDatabaseInput(
            name: databaseName
        )

        _ = try await self.session.deleteDatabase(input: input)
    }
    // snippet-end:[glue.swift.basics.gluemanager.deletedatabase]
}
// snippet-end:[glue.swift.basics.gluemanager]
// snippet-end:[glue.swift.glue-all]
