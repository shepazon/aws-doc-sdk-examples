// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents errors that need to be handled or reported to the user.
enum AWSAccountError: Error, LocalizedError {
    /// The `AssumeRoleWithWebIdentity` request failed.
    case assumeRoleFailed
    /// The credentials returned by Sign In With Apple is missing
    /// required information.
    case credentialsIncomplete
    /// The authentication request failed.
    case credentialsFailed
    /// The `ListBuckets` request did not successfully return a list
    /// of Amazon S3 buckets.
    case bucketListMissing
    
    /// A human-readable error message string corresponding to the
    /// error returned.
    var errorDescription: String? {
        switch self {
        case .assumeRoleFailed:
            return "The role could not be assumed using the web token returned by Sign In With Apple."
        case .credentialsIncomplete:
            return "The credentials returned by AssumeRoleWithWebIdentity are incomplete."
        case .credentialsFailed:
            return "An error occurred while attempting to retrieve credentials from AWS."
        case .bucketListMissing:
            return "Amazon S3 did not return a valid bucket list."
        }
    }
}
