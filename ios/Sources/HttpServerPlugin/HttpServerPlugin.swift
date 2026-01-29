import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(HttpServerPlugin)
public class HttpServerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "HttpServerPlugin"
    public let jsName = "HttpServer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getServerUrl", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = HttpServer()

    override public func load() {
        implementation.initialize()
    }

    @objc func startServer(_ call: CAPPluginCall) {
        if let url = implementation.start() {
            call.resolve([
                "url": url
            ])
        } else {
            call.reject("Could not start server")
        }
    }

    @objc func stopServer(_ call: CAPPluginCall) {
        implementation.stop()
        call.resolve()
    }

    @objc func getServerUrl(_ call: CAPPluginCall) {
        let url = implementation.getUrl() ?? ""
        call.resolve([
            "url": url
        ])
    }
}
