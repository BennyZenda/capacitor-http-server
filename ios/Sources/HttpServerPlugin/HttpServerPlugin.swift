import Foundation
import Capacitor

/**
 * HttpServerPlugin provides a Capacitor interface to manage a local HTTP server.
 * It bridges JavaScript calls to the underlying Swift implementation.
 */
@objc(HttpServerPlugin)
public class HttpServerPlugin: CAPPlugin, CAPBridgedPlugin {
    // Unique identifier for the plugin
    public let identifier = "HttpServerPlugin"
    // Name of the plugin as exposed to JavaScript
    public let jsName = "HttpServer"
    // List of methods exposed to the web layer
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getServerUrl", returnType: CAPPluginReturnPromise)
    ]
    // Internal instance that handles the actual server logic
    private let implementation = HttpServer()

    /// Called when the plugin is loaded into memory.
    override public func load() {
        // Perform initial setup for the server implementation
        implementation.initialize()
    }

    /// Capacitor method to start the server.
    /// Runs on a background thread by default, so it's dispatched to the main thread.
    @objc func startServer(_ call: CAPPluginCall) {
        // Ensure server start happens on the main thread for GCDWebServer compatibility
        DispatchQueue.main.async {
            if let url = self.implementation.start() {
                // Return the server URL to the web layer on success
                call.resolve([
                    "url": url
                ])
            } else {
                // Reject the promise if the server fails to start
                call.reject("Could not start server")
            }
        }
    }

    /// Capacitor method to stop the server.
    /// Dispatched to the main thread to safely interact with GCDWebServer.
    @objc func stopServer(_ call: CAPPluginCall) {
        // Ensure server stop happens on the main thread
        DispatchQueue.main.async {
            self.implementation.stop()
            // Resolve the promise once the server is stopped
            call.resolve()
        }
    }

    /// Capacitor method to retrieve the current server URL.
    @objc func getServerUrl(_ call: CAPPluginCall) {
        // Fetch the URL from the implementation (defaults to empty string if nil)
        let url = implementation.getUrl() ?? ""
        // Return the URL to the web layer
        call.resolve([
            "url": url
        ])
    }
}
