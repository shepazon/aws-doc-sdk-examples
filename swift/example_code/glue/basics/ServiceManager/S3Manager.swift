/// This file provides several items that are used to manage and test a subset
/// of Amazon Simple Storage Service (S3) calls:
///
/// The `S3SessionPrototype` prototype describes the subset of Amazon S3 calls
/// supported by this example. It is implemented here by the `S3Session`
/// struct, which passes the `input` structure through to the corresponding S3
/// function and returns the output structure intact.
///
/// The `S3Manager` class offers functions that use a specified structure that
/// implements `S3SessionPrototype` to make calls to S3 functions. By
/// providing an `S3Session` structure when initializing the `S3Manager`,
/// these functions call S3 to access the service normally.
///
/// To test these functions, create a second implementation of
/// `S3SessionPrototype` that provides mock functions that return test data
/// instead of actually calling S3.
///
/// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
/// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSS3
import ClientRuntime

// snippet-start:[glue.swift.basics.errors]
/// Errors thrown by the `S3Manager` class.
public enum S3ManagerError: Error {
    /// An error occurred while getting a list of files on Amazon S3.
    case FileListError
}
// snippet-end:[glue.swift.basics.errors]

// snippet-start:[glue.swift.basics.s3-prototype]
/// A prototype representing the signatures of the AWS SDK for Swift functions
/// that can be implemented either to pass through to the actual SDK functions
/// of the same names or to mock functions used for testing.
public protocol S3SessionPrototype {
    func putObject(input: PutObjectInput) async throws -> PutObjectOutputResponse
    func createBucket(input: CreateBucketInput) async throws -> CreateBucketOutputResponse
    func deleteBucket(input: DeleteBucketInput) async throws -> DeleteBucketOutputResponse
    func copyObject(input: CopyObjectInput) async throws -> CopyObjectOutputResponse
    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse
    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse
}
// snippet-end: [glue.swift.basics.s3-prototype]

// snippet-start:[glue.swift.basics.s3session]
/// An implementation of `S3SessionPrototype` that passes calls straight
/// through to Amazon S3.
public struct S3Session: S3SessionPrototype {
    let awsRegion: String
    let client: S3Client

    public init(region: String = "us-east-2") async throws {
        self.awsRegion = region
        client = try await S3Client(region: awsRegion)
    }

    public func putObject(input: PutObjectInput) async throws -> PutObjectOutputResponse {
        return try await client.putObject(input: input)
    }

    public func createBucket(input: CreateBucketInput) async throws
            -> CreateBucketOutputResponse {
        return try await client.createBucket(input: input)
    }

    public func deleteBucket(input: DeleteBucketInput) async throws
            -> DeleteBucketOutputResponse {
        return try await client.deleteBucket(input: input)
    }

    public func copyObject(input: CopyObjectInput) async throws
            -> CopyObjectOutputResponse {
        return try await client.copyObject(input: input)
    }

    public func deleteObject(input: DeleteObjectInput) async throws
            -> DeleteObjectOutputResponse {
        return try await client.deleteObject(input: input)
    }

    public func listObjectsV2(input: ListObjectsV2Input) async throws
            -> ListObjectsV2OutputResponse {
        return try await client.listObjectsV2(input: input)
    }
}
// snippet-end:[glue.swift.basics.s3session]

// snippet-start:[glue.swift.basics.s3manager]
/// A class that uses a session record that implements the
/// `S3SessionPrototype` prototype to store and retrieve data using Amazon S3.
public class S3Manager {
    /// An `S3SessionPrototype` based session object that dispatches AWS SDK
    /// for Swift calls to either the SDK or a mock implementation depending
    /// on whether testing is in progress or not.
    private let session: S3SessionPrototype

    // snippet-start:[glue.swift.basics.s3manager.init]
    /// Initialize a new `S3Manager` object to use the specified session
    /// object to issue calls to AWS Glue functions.
    ///
    /// - Parameters:
    ///   - session: The session object, based on the `S3SessionPrototype`
    ///     protocol, to use for calls to AWS Glue API functions.
    public init(session: S3SessionPrototype) {
        self.session = session
    }
    // snippet-end:[glue.swift.basics.s3manager.init]

    // snippet-start:[glue.swift.basics.s3manager.createbucket]
    /// Create a new Amazon S3 bucket.
    ///
    /// - Parameters:
    ///  -  name: The name to give the new bucket.
    public func createBucket(name: String) async throws {
        let input = CreateBucketInput(
            bucket: name
        )
        _ = try await self.session.createBucket(input: input)
    }
    // snippet-end:[glue.swift.basics.s3manager.createbucket]

    // snippet-start:[glue.swift.basics.s3manager.deletebucket]
    /// Delete an Amazon S3 bucket.
    ///
    /// - Parameters:
    ///   - name: The name of the bucket to delete.
    public func deleteBucket(name: String) async throws {
        let input = DeleteBucketInput(
            bucket: name
        )
        _ = try await self.session.deleteBucket(input: input)
    }
    // snippet-end:[glue.swift.basics.s3manager.deletebucket]

    // snippet-start:[glue.swift.basics.s3manager.uploadfile]
    /// Upload a file from the local system to an Amazon S3 bucket, giving the
    /// copy of the file the given key (name).
    ///
    /// - Parameters:
    ///   - path: The path of the local file to upload.
    ///   - bucket: The Amazon S3 bucket to upload the file into.
    ///   - key: The key (name) to give the copy of the file in the bucket.
    ///
    public func uploadFile(path: String, toBucket bucket: String, key: String) async throws {
        let fileURL = URL(fileURLWithPath: path)
        let fileData = try Data(contentsOf: fileURL)
        let dataStream = ByteStream.from(data: fileData)

        let input = PutObjectInput(
            body: dataStream,
            bucket: bucket,
            key: key
        )
        _ = try await self.session.putObject(input: input)
    }
    // session-end:[glue.swift.basics.s3manager.uploadfile]

    // snippet-start:[glue.swift.basics.s3manager.movefile]
    /// Move a file from its current Amazon s3 path to a new location.
    ///
    /// - Parameters:
    ///   - sourceBucket: The name of the bucket containing the original file.
    ///   - sourcePath: The path within the source bucket of the original file.
    ///   - destBucket: The bucket into which to move the file.
    ///   - destPath: The path within the bucket at which to put the moved file.
    ///
    /// > Note: If the `sourceBucket` and the `destBucket` are the same, the
    /// > result is functionally the same as renaming the file.
    public func moveFile(sourceBucket: String, sourcePath: String,
                destBucket: String, destPath: String) async throws {
        // First, copy the file.
        let copyInput = CopyObjectInput(
            bucket: destBucket,
            copySource: "\(sourceBucket)/\(sourcePath)",
            key: destPath
        )

        _ = try await self.session.copyObject(input: copyInput)

        // Then delete the original.

        let deleteInput = DeleteObjectInput(
            bucket: sourceBucket,
            key: sourcePath
        )
        _ = try await self.session.deleteObject(input: deleteInput)
    }
    // snippet-end:[glue.swift.basics.s3manager.movefile]

    // snippet-start: [glue.swift.basics.s3manager.addextensiontofiles]
    /// Add an extension to every file in the specified bucket and directory.
    ///
    /// - Parameters:
    ///   - bucket: The bucket containing the files to rename.
    ///   - directory: The directory containing the files to append an
    ///     extension to.
    ///   - ext: The extension to append to the file names, including the
    ///     leading period ("."). For example, `".json"`
    public func addExtensionToFiles(inBucket bucket: String,
                directory: String = "", extension ext: String) async throws {
        var continuationToken: String? = nil
        var fileNames: [String] = []

        // Collect the names of the files in the bucket, leaving out any that
        // don't begin with the directory name followed by a "/" character.

        repeat {
            let input = ListObjectsV2Input(
                bucket: bucket,
                continuationToken: continuationToken
            )
            let output = try await self.session.listObjectsV2(input: input)
            
            guard let objList = output.contents else {
                throw S3ManagerError.FileListError
            }

            // Gather the names of the listed files, storing any that start
            // with the directory path followed by a slash character.

            for obj in objList {
                if let objName = obj.key {
                    if objName.starts(with: "\(directory)/") {
                        fileNames.append(objName)
                    }
                }
            }

            continuationToken = output.continuationToken
        } while continuationToken != nil

        // Iterate over the identified file names, renaming the files to end
        // with the specified extension.

        for name in fileNames {
            try await self.moveFile(sourceBucket: bucket, sourcePath: name,
                        destBucket: bucket, destPath: "\(name + ext)")
        }
    }
    // snippet-end:[glue.swift.basics.s3manager.addextensiontofiles]
}
// snippet-end:[glue.swift.basics.s3manager]