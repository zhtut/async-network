import XCTest
@testable import AsyncNetwork

final class AsyncNetworkTests: XCTestCase {
    func testExample() async throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        let res = try await Networking.shared.send(request: .init(path: "https://www.baidu.com"))
        if res.succeed {
            print("请求成功")
            print(res.bodyString ?? "")
        }
    }
}
