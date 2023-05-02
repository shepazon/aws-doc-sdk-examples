/// An example that shows how to use the AWS SDK for Swift to demonstrate
/// creating and using crawlers and jobs using AWS Glue.
///
/// 0. Upload the Python job script to Amazon S3 so it can be used when
///    calling `startJobRun()` later.
/// 1. Create a crawler, pass it the IAM role and the URL of the public Amazon
///    S3 bucket that contains the source data:
///    s3://crawler-public-us-east-1/flight/2016/csv.
/// 2. Start the crawler. This takes time, so after starting it, use a loop
///    that calls `getCrawler()` until the state is "READY".
/// 3. Get the database created by the crawler, and the tables in the
///    database. Display them to the user.
/// 4. Create a job. Pass it the IAM role and the URL to a Python ETL script
///    previously uploaded to the user's S3 bucket.
/// 5. Start a job run, passing the following custom arguments. These are
///    expected by the ETL script, so must exactly match.
///    * `--input_database: <name of the database created by the crawler>`
///    * `--input_table: <name of the table created by the crawler>`
///    * `--output_bucket_url: <URL to the scaffold bucket created for the
///      user>`
/// 6. Loop and get the job run until it returns one of the following states:
///    "SUCCEEDED", "STOPPED", "FAILED", or "TIMEOUT".
/// 7. Output data is stored in a group of files in the user's S3 bucket.
///    Either direct the user to their location or download a file and display
///    the results inline.
/// 8. List the jobs for the user's account.
/// 9. Get job run details for a job run.
/// 10. Delete the demo job.
/// 11. Delete the database and tables created by the example.
/// 12. Delete the crawler created by the example.
///
/// _Unless stated otherwise, function names above are in the class
/// `GlueClient`._
///
/// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
/// SPDX-License-Identifier: Apache-2.0

// snippet-start:[glue.swift.basics]
import Foundation
import ArgumentParser
import AWSGlue
import ClientRuntime

struct ExampleCommand: ParsableCommand {
    @Option(help: "The AWS IAM role to use for AWS Glue calls.")
    var role: String

    @Option(help: "The Amazon S3 bucket to use for this example.")
    var bucket: String

    @Option(help: "The Amazon S3 URL of the data to crawl.")
    var s3url: String = "s3://crawler-public-us-east-1/flight/2016/csv"

    @Option(help: "The Python script to run as a job with AWS Glue.")
    var script: String = "./flight_etl_job_script.py"

    @Option(help: "The AWS Region to run AWS API calls in.")
    var awsRegion = "us-east-2"

    @Flag(help: "If this flag is set, output files will have the '.json' extension.")
    var rename = false

    @Option(help: "A prefix string to use when naming tables.")
    var tablePrefix = "swift-glue-basics-table"

    @Option(
        help: ArgumentHelp("The level of logging for the Swift SDK to perform."),
        completion: .list([
            "critical",
            "debug",
            "error",
            "info",
            "notice",
            "trace",
            "warning"
        ])
    )
    var logLevel: String = "error"

    /// Configuration details for the command.
    static var configuration = CommandConfiguration(
        commandName: "basics",
        abstract: "A basic scenario demonstrating the usage of AWS Glue.",
        discussion: """
        An example showing how to use AWS Glue to create, run, and monitor
        crawlers and jobs.
        """
    )

    /// Generate and return a unique file name that begins with the specified
    /// string.
    ///
    /// - Parameters:
    ///   - prefix: Text to use at the beginning of the returned name.
    ///
    /// - Returns: A string containing a unique filename that begins with the
    ///   specified `prefix`.
    func tempName(prefix: String) -> String {
        let id = UUID().uuidString
        
        let name = String(id.prefix(12))
        return "\(prefix)-\(name)"
    }

    /// Called by ``main()`` to asynchronously run the AWS example.
    func runAsync() async throws {
        print("Welcome to the AWS SDK for Swift basic scenario for AWS Glue!")
        SDKLoggingSystem.initialize(logLevel: .error)
        let glueSession = try await GlueSession(region: awsRegion)
        let glue = GlueManager(session: glueSession)

        // Create random names for things that need them.

        let crawlerName = tempName(prefix: "swift-glue-basics-crawler")
        let databaseName = tempName(prefix: "swift-glue-basics-db")

        // A name for the Glue job.

        let jobName = tempName(prefix: "scenario-job")

        // A name to give the Python script upon upload to the Amazon S3
        // bucket, and the full URL of the script on S3.
        let scriptName = "jobscript.py"
        let scriptURL = "s3://\(bucket)/\(scriptName)"

        // Schedule string in `cron` format, as described here:
        // https://docs.aws.amazon.com/glue/latest/dg/monitor-data-warehouse-schedule.html
        let cron = "cron(15 12 * * ? *)"

        //=====================================================================
        // 0. Upload the Python script to the target bucket so it's available
        //    for use by the Amazon Glue service.
        //=====================================================================

        let s3Session = try await S3Session(region: self.awsRegion)
        let s3 = S3Manager(session: s3Session)
        
        // Upload the script to the bucket.

        do {
            print("*****")
            print("Uploading the Python script: \(script) as key \(scriptName)")
            print("Destination bucket: \(bucket)")
            print("*****")

            try await s3.uploadFile(path: script, toBucket: bucket,
                    key: scriptName)
        } catch {
            print("ERROR: Unable to upload the Python AWS Glue job script. Error details:")
            dump(error)
            return
        }

        //=====================================================================
        // 1. Create the database and crawler. This also creates the database
        //    named `databaseName`.
        //=====================================================================

        print("Creating crawler \"\(crawlerName)\"...")
        try await glue.createCrawler(
            crawlerName: crawlerName,
            iamRole: role,
            s3Path: s3url,
            cronSchedule: cron,
            databaseName: databaseName
        )

        //=====================================================================
        // 2. Start the crawler, then call `getCaller()` in a loop to wait for
        //    it to be ready.
        //=====================================================================

        print("Starting the crawler and waiting until it's ready...")
        try await glue.startCrawler(name: crawlerName)
        try await glue.waitUntilCrawlerReady(name: crawlerName)

        //=====================================================================
        // 3. Get the database and table created by the crawler.
        //=====================================================================

        print("Getting the crawler's database...")
        let database = try await glue.getDatabase(name: databaseName)

        // Get a list of the tables in the database. In this example, there
        // should only be one.

        let tableList = try await glue.getTablesInDatabase(name: databaseName)

        // If the table count is wrong, display an error, then stop and delete
        // the crawler before exiting the program.

        if tableList.count != 1 {
            print("*** Unexpected number of tables in the database! Should be 1, but is \(tableList.count)!")
            try await glue.stopCrawler(name: crawlerName)
            try await glue.deleteCrawler(name: crawlerName)
            try await glue.deleteDatabase(name: crawlerName, withTables: true)
            return
        }

        // Get and display the name of the first table in the database. For
        // the purposes of this example, there should only be one.

        guard let tableName = tableList[0].name else {
            throw GlueManagerError.InvalidDatabase
        }

        print("   - First table name is: \(tableName)")

        //=====================================================================
        // 4. Create a job.
        //=====================================================================

        print("\nCreating a job...")
        try await glue.createJob(name: jobName, role: role,
                scriptLocation: scriptURL)

        //=====================================================================
        // 5. Start a job run.
        //=====================================================================

        print("Starting the job...")

        // Construct the Amazon S3 URL for the job run's output. This is in
        // the bucket specified on the command line, with a folder name that's
        // unique for this job run.

        let timeStamp = Date().timeIntervalSince1970
        let jobPath = "\(jobName)-\(Int(timeStamp))"
        let outputURL = "s3://\(bucket)/\(jobPath)"

        // Start the job by calling the Glue manager.

        let jobRunID = try await glue.startJobRun(name: jobName,
                databaseName: databaseName, tableName: tableName,
                outputURL: outputURL)
        
        //=====================================================================
        // 6. Wait for the job to return one of the following states:
        //    "SUCCEEDED", "STOPPED", "FAILED", or "TIMEOUT".
        //=====================================================================

        print("Waiting for job run to end...")

        var jobRunFinished = false
        var jobRunState: GlueClientTypes.JobRunState

        repeat {
            let jobRun = try await glue.getJobRun(name: jobName, id: jobRunID)
            jobRunState = jobRun.jobRunState ?? .failed

            if jobRunState == .succeeded || jobRunState == .stopped
                    || jobRunState == .failed || jobRunState == .timeout {
                jobRunFinished = true
            } else {
                Thread.sleep(forTimeInterval: 0.25)
            }
        } while jobRunFinished != true

        // If the job run completed successfully and the `rename` command line
        // flag was used, rename the files to include the ".json" extension
        // for convenience.

        if rename == true {
            try await s3.addExtensionToFiles(inBucket: bucket, directory: jobPath,
                        extension: ".json")
        }

        //=====================================================================
        // 7. Output where to find the data if the job run was successful.
        //=====================================================================

        if jobRunState == .succeeded {
            print("\nJob run succeeded. JSON files are in the Amazon S3 directory:")
            print("     \(outputURL)")
        } else {
            print("\nJob run ended unsuccessfully with state: \(jobRunState)")
        }

        //=====================================================================
        // 8. List the jobs for the user's account.
        //=====================================================================

        print("\nThe account has the following jobs:")
        let jobs = try await glue.listJobs()

        if jobs.count == 0 {
            print("  <no jobs found>")
        } else {
            for job in jobs {
                print("   \(job)")
            }
        }

        //=====================================================================
        // 9. Get the job run details for a job run.
        //=====================================================================

        print("Information about the job run:")
        let jobRun = try await glue.getJobRun(name: jobName, id: jobRunID)

        let startDate = jobRun.startedOn ?? Date(timeIntervalSince1970: 0)
        let endDate = jobRun.completedOn ?? Date(timeIntervalSince1970: 0)
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long

        print("    Started at: \(dateFormatter.string(from: startDate))")
        print("  Completed at: \(dateFormatter.string(from: endDate))")

        //=====================================================================
        // 10. Delete the job.
        //=====================================================================

        print("\nDeleting the job...")
        try await glue.deleteJob(name: jobName)

        //=====================================================================
        // 11. Delete the database and tables created by this example.
        //=====================================================================

        print("Deleting the database...")
        try await glue.deleteDatabase(name: databaseName, withTables: true)

        //=====================================================================
        // 12. Delete the crawler.
        //=====================================================================

        print("Deleting the crawler...")
        try await glue.deleteCrawler(name: crawlerName)
    }
}

@main
struct Main {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        do {
            let command = try ExampleCommand.parse(args)
            try await command.runAsync()
        } catch {
            ExampleCommand.exit(withError: error)
        }
    }
}
// snippet-end:[glue.swift.basics]
