# Glue code examples for the SDK for Swift
## Overview
This folder contains code examples demonstrating how to use the AWS SDK for
Swift to use AWS Glue. This README discusses how to run these examples.

AWS Glue is a serverless data integration service that makes it easier to
discover, prepare, move, and integrate data from multiple sources for
analytics, machine learning (ML), and application development.

## ⚠️ Important
* Running this code might result in charges to your AWS account. 
* Running the tests might result in charges to your AWS account.
* We recommend that you grant your code least privilege. At most, grant only the minimum permissions required to perform the task. For more information, see [Grant least privilege](https://docs.aws.amazon.com/Glue/latest/UserGuide/best-practices.html#grant-least-privilege). 
* This code is not tested in every AWS Region. For more information, see [AWS Regional Services](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services).

## Code examples

### Single actions
<!-- Code excerpts that show you how to call individual service functions.
* [Example name](./basics/path/to/file) (`FunctionName`)
 -->

### Scenarios
Code examples that show you how to accomplish a specific task by calling multiple functions within the same service.

* [Glue Basics](./basics/Sources/basics.swift). Demonstrates how to create and
  run crawlers and jobs, and how to monitor those jobs. (`Basics`)

<!-- ### Cross-service examples
Sample applications that work across multiple AWS services.
* [*Title of code example*](*relative link to code example*) --->

## Run the examples
To build any of these examples from a terminal window, navigate into its
directory, then use the following command:

```
$ swift build
```

To build one of these examples in Xcode, navigate to the example's directory
(such as the `basics` directory, to build that example). Then type `xed.`
to open the example directory in Xcode. You can then use standard Xcode build
and run commands.

### Prerequisites
See the [Prerequisites](https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/swift#Prerequisites) section in the README for the AWS SDK for Swift examples repository.

## Tests
⚠️ Running the tests might result in charges to your AWS account.

To run the tests for an example, use the command `swift test` in the example's directory.

## Additional resources
* [Glue Developer Guide](https://docs.aws.amazon.com/glue/)
* [Glue API Reference](https://docs.aws.amazon.com/glue/latest/webapi/)
* [Glue Developer Guide for Swift](https://docs.aws.amazon.com/sdk-for-swift/latest/developer-guide/examples-glue.html)
* [Glue API Reference for Swift](https://awslabs.github.io/aws-sdk-swift/reference/0.x/AWSGlue/Home)
* [Security best practices for Glue](https://docs.aws.amazon.com/glue/latest/dg/security.html)

_Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. SPDX-License-Identifier: Apache-2.0_