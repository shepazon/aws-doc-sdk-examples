// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import AuthenticationServices

/// A view that displays information about the user, handles signing the user
/// into AWS using Sign In With Apple, and shows user interface to fetch and
/// display the user's Amazon S3 bucket names.
struct UserView: View {
    /// Indicates whether or not the user has successfully signed into AWS.
    @State private var signedIn = false
    /// The view model used to access AWS and manipulate the user data.
    @State private var viewModel: ViewModel
    
    /// Initialize the view by creating its view model.
    init() {
        viewModel = ViewModel()
    }
    
    /// The main application view's contents.
    var body: some View {
        // If the user hasn't signed into AWS, show the Sign In form.
        // Otherwise, show the bucket list views.
        
        if !signedIn {
            VStack {
                Text("Sign In to AWS using Apple")
                    .font(.title)
                    .padding(.bottom)
                
                Form {
                    VStack {
                        HStack {
                            Text("AWS account number:")
                            TextField(text: $viewModel.accountNumber, prompt: Text("Account number")) { }
                        }
                        HStack {
                            Text("AWS IAM role name:")
                            TextField(text: $viewModel.iamRole, prompt: Text("Role name")) { }
                        }
                    }
                }

                // Show the "Sign In With Apple" button, using the
                // `.continue` mode, which allows the user to create
                // a new ID if they don't already have one. When SIWA
                // is complete, the view model's `handleSignInResult()`
                // function is called to turn the JWT token into AWS
                // credentials.
                
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.email, .fullName ]
                } onCompletion: { result in
                    Task {
                        do {
                            try await viewModel.handleSignInResult(result)
                        } catch let error as AWSAccountError {
                            let errorMessage = error.errorDescription ?? "An unknown error occurred while trying to authenticate."
                            print(errorMessage)
                            signedIn = false
                            return
                        }
                        signedIn = true
                    }
                }
                .frame(height: 60)
            }
            .padding()
            .frame(minWidth: 500, minHeight: 260)

            Spacer()
        } else {
            // The user is signed into their AWS account, so show their
            // basic account information.
            
            VStack() {
                Text("Welcome")
                    .font(.largeTitle)
                Text("\(viewModel.givenName) \(viewModel.familyName)")
                    .font(.title)
                Text("\(viewModel.email)")
                    .font(.subheadline)
            }
            .padding()
                        
            // Show UI to allow the user to fetch and display a list
            // of their Amazon S3 buckets.
            
            VStack {
                VStack {
                    List(viewModel.bucketList) { bucket in
                        Text(bucket.text)
                    }
                }
                .padding()
                
                // Show the user's ID, as assigned by Sign In With Apple.
                
                VStack {
                    Text("User ID:")
                        .font(.caption)
                    Text(viewModel.userID)
                        .font(.caption2)
                }
                .padding(.horizontal)
                
                // Show the action buttons.
                
                HStack {
                    Button("List Buckets") {
                        Task {
                            viewModel.bucketList = []
                            try await viewModel.getBucketList()
                        }
                    }
                    Button("Sign Out") {
                        viewModel.signOut()
                        signedIn = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        
    }
}

#Preview {
    UserView()
}
