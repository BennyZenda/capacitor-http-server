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
        CAPPluginMethod(name: "getServerUrl", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isActive", returnType: CAPPluginReturnPromise)
    ]
    // Internal instance that handles the actual server logic
    private let implementation = HttpServer()

    /// Called when the plugin is loaded into memory.
    override public func load() {
        // Perform initial setup for the server implementation
        implementation.initialize()
        
        /* // Register for app lifecycle notifications to manage server state
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil) */
    }
    
    /// Cleanup notifications on deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /* /// Handles app entering background
    @objc private func handleDidEnterBackground() {
        // Stop server when backgrounded to save resources and avoid OS termination
        DispatchQueue.main.async {
            self.implementation.pause()
        }
    }
    
    /// Handles app entering foreground
    @objc private func handleWillEnterForeground() {
        // Restart server when returning to foreground only if it was intended to be running
        DispatchQueue.main.async {
            if self.implementation.wasRunning {
                _ = self.implementation.start()
            }
        }
    } */

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

    /// Capacitor method to retrieve active server status.
    @objc func isActive(_ call: CAPPluginCall) {
        let status = implementation.getActiveStatus()
        // Note: Using JSPluginKit's native type casting
        call.resolve(status)
    }
}
