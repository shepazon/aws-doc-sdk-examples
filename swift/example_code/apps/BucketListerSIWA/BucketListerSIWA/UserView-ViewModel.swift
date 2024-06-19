// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import AuthenticationServices

// Import needed AWS SDK for Swift and Smithy modules.
import AWSSTS
import AWSS3
import AWSClientRuntime
import ClientRuntime

extension UserView {
    /// A view model to manage a user's Sign In With Apple session and
    /// its properties.
    ///
    /// > Important: This example uses `@AppStorage` to store personal
    ///   identifiable information (PII). Shipping applications should
    ///   store any PII securely, such as by using the Keychain.
    ///
    ///   There are many useful packages available for this purpose that
    ///   you can find using the [Swift Package
    ///   Index](https://swiftpackageindex.com/).
    struct ViewModel {
        /// The unique string assigned by Sign In With Apple for this login
        /// session. This ID is valid across application launches until it
        /// is signed out from Sign In With Apple.
        var userID = ""
        /// The user's email address.
        ///
        /// This is only returned by SIWA if the user has just created
        /// the app's SIWA account link. Otherwise, it's returned as `nil`
        /// by SIWA and must be retrieved from local storage if needed.
        @AppStorage("email") var email = ""
        /// The user's family (last) name.
        ///
        /// This is only returned by SIWA if the user has just created
        /// the app's SIWA account link. Otherwise, it's returned as `nil`
        /// by SIWA and must be retrieved from local storage if needed.
        @AppStorage("family-name") var familyName = ""

        /// The user's given (first) name.
        ///
        /// This is only returned by SIWA if the user has just created
        /// the app's SIWA account link. Otherwise, it's returned as `nil` by SIWA and must
        /// be retrieved from local storage if needed.
        @AppStorage("given-name") var givenName = ""

        /// The AWS account number as provided by the user in the sign in sheet.
        @AppStorage("account-number") var accountNumber = ""
        
        /// The AWS IAM role name as given by the user in the sign in sheet.
        @AppStorage("iam-role") var iamRole = ""
        
        /// An array of the user's bucket names.
        ///
        /// This is filled out once the user is signed into AWS.
        var bucketList: [IDString] = []

        /// The credential identity resolver created by the AWS SDK for
        /// Swift. This provides the temporary credentials generated
        /// using `AssumeRoleWithWebIdentity`.
        var identityResolver: StaticAWSCredentialIdentityResolver? = nil
        
        /// Called by the Sign In With Apple button when a JWT token has
        /// been returned by the Sign In With Apple service. This function
        /// in turn handles fetching AWS credentials using that token.
        ///
        /// - Parameter result: The result object passed to the Sign In
        ///   With Apple button's `onCompletion` handler. If the sign
        ///   in request succeeded, this contains an `ASAuthorization`
        ///   object that contains the Apple ID sign in information.
        mutating func handleSignInResult(_ result: Result<ASAuthorization, Error>) async throws {
            switch result {
            case .success(let auth):
                // Sign In With Apple returned a JWT identity token. Gather
                // the information it contains and prepare to convert the
                // token into AWS credentials.
                
                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                      let webToken = credential.identityToken,
                      let tokenString = String(data: webToken, encoding: .utf8)
                else {
                    throw AWSAccountError.credentialsIncomplete
                }
                
                userID = credential.user
                email = credential.email ?? self.email

                if let name = credential.fullName {
                    self.familyName = name.familyName ?? self.familyName
                    self.givenName = name.givenName ?? self.givenName
                }
                
                // Use the JWT token to request a set of temporary AWS
                // credentials. Upon successful return, the
                // `credentialsProvider` can be used when configuring
                // any AWS service.
                
                try await authenticate(withWebIdentity: tokenString)
            case .failure:
                throw AWSAccountError.credentialsFailed
            }
        }
        
        /// Convert the given JWT identity token string into the temporary
        /// AWS credentials needed to allow this application to operate, as
        /// specified using the Apple Developer portal and the AWS Identity
        /// and Access Management (IAM) service.
        ///
        /// - Parameters:
        ///   - tokenString: The string version of the JWT identity token
        ///     returned by Sign In With Apple.
        ///   - region: An optional string specifying the AWS Region to
        ///     access. If not specified, "us-east-1" is assumed.
        mutating func authenticate(withWebIdentity tokenString: String,
                          region: String = "us-east-1") async throws {
            let roleARN = "arn:aws:iam::\(accountNumber):role/\(iamRole)"
            let client = try STSClient(region: region)

            // Use `AssumeRoleWithWebIdentity` to convert the JWT token into a
            // set of temporary AWS credentials.
            
            do {
                let options = AssumeRoleWithWebIdentityInput(
                    durationSeconds: 3600,
                    roleArn: roleARN,
                    roleSessionName: "AWSWithSIWA",
                    webIdentityToken: tokenString
                )
                let response = try await client.assumeRoleWithWebIdentity(input: options)
                
                guard let credentialInfo = response.credentials else {
                    throw AWSAccountError.assumeRoleFailed
                }
                
                // Check that the the credential information received from
                // Apple is complete. Throw an exception if it isn't.
                
                guard let accessKeyId = credentialInfo.accessKeyId,
                      let secretAccessKey = credentialInfo.secretAccessKey,
                      let sessionToken = credentialInfo.sessionToken,
                      let expiration = credentialInfo.expiration else {
                    throw AWSAccountError.credentialsIncomplete
                }
                
                // Create a credential identity resolver that converts the
                // ID and key information received from Sign In With Apple
                // into AWS credentials.
                //
                // Instead of using an `STSWebIdentityAWSCredentialIdentityResolver`
                // to resolve the identity, create a static credential
                // identity resolver using the values obtained from the
                // web token. This lets us authenticate without writing
                // the JWT token to a file first.
                
                let credentials = AWSCredentialIdentity(accessKey: accessKeyId, secret: secretAccessKey, expiration: expiration, sessionToken: sessionToken)
                identityResolver = try StaticAWSCredentialIdentityResolver(credentials)
            } catch {
                throw AWSAccountError.credentialsFailed
            }
        }
        
        /// "Sign out" of the user's account.
        ///
        /// All this does is erase the user ID to drop our ability to
        /// reference the AWS sign in, and empty the bucket list so a
        /// new sign-in won't already have a populated and possibly
        /// incorrect list.
        mutating func signOut() {
            userID = ""
            bucketList = []
        }
        
        /// Fetches a list of the user's Amazon S3 buckets.
        ///
        /// The bucket names are stored in the view model's `bucketList`
        /// property.
        mutating func getBucketList() async throws {
            // Create an Amazon S3 client configuration that uses the
            // credential identity resolver created from the JWT token
            // returned by Sign In With Apple.
            let config = try await S3Client.S3ClientConfiguration(
                    awsCredentialIdentityResolver: identityResolver,
                    region: "us-east-1"
            )
            let s3 = S3Client(config: config)
            
            let output = try await s3.listBuckets(
                input: ListBucketsInput()
            )
            
            guard let buckets = output.buckets else {
                throw AWSAccountError.bucketListMissing
            }
            
            // Add the names of all the buckets to `bucketList`. Each
            // name is stored as a new `IDString` for use with the SwiftUI
            // `List`.
            for bucket in buckets {
                self.bucketList.append(IDString(bucket.name ?? "<unknown>"))
            }
        }
    }
}
