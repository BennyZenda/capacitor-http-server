import Foundation

@objc public class HttpServer: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
