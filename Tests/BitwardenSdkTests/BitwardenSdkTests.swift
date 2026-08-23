import XCTest
@testable import BitwardenSdk

final class BitwardenSdkTests: XCTestCase {
    func testRustFFIRuntime() {
        let client = Client(
            tokenProvider: TestTokenProvider(),
            settings: nil
        )

        XCTAssertEqual(client.echo(msg: "Hello, macOS!"), "Hello, macOS!")
    }
}

private final class TestTokenProvider: ClientManagedTokens, @unchecked Sendable {
    func getAccessToken() async -> String? {
        nil
    }
}
