import Foundation
import GCDWebServer

/// The HttpServer class manages the lifecycle and configuration of the local GCDWebServer.
@objc public class HttpServer: NSObject {
    // Instance of the GCDWebServer
    private var webServer: GCDWebServer?
    // Cached URL of the running server
    private var serverUrl: String?
    // Base directory from which files will be served
    private var baseDir: URL?

    /// Initializes the server configuration, determining the base directory for serving files.
    @objc public func initialize() {
        let fileManager = FileManager.default
        // Get the app's documents directory as the default root
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var basePath = ""
        // Check Info.plist for a custom base directory configuration
        if let path = Bundle.main.object(forInfoDictionaryKey: "HTTP_SERVER_BASE_DIR") as? String {
            basePath = path
        }
        
        // If a base path is configured, append it to the documents URL
        if !basePath.isEmpty {
            self.baseDir = documentsURL.appendingPathComponent(basePath)
        } else {
            // Otherwise, use the documents directory directly
            self.baseDir = documentsURL
        }
    }

    /// Starts the HTTP server and returns the server URL.
    @objc public func start() -> String? {
        // Return existing URL if server is already running
        if let url = serverUrl, webServer?.isRunning == true {
            return url
        }

        // Ensure the base directory is set before starting
        guard let baseDir = self.baseDir else {
            return nil
        }

        // Initialize a new instance of GCDWebServer
        webServer = GCDWebServer()
        
        // Add a handler to serve static files from the base directory
        webServer?.addGETHandler(forBasePath: "/", directoryPath: baseDir.path, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)

        // Configure server options: use dynamic port (0) and bind to localhost
        let options: [String: Any] = [
            GCDWebServerOption_Port: 0,
            GCDWebServerOption_BindToLocalhost: true
        ]

        do {
            // Attempt to start the server with the specified options
            try webServer?.start(options: options)
            // If successfully started, capture and return the server URL
            if let url = webServer?.serverURL {
                self.serverUrl = url.absoluteString
                return self.serverUrl
            }
        } catch {
            // Log any errors encountered during server startup
            print("Could not start server: \(error)")
        }

        return nil
    }

    /// Stops the running HTTP server and clears associated state.
    @objc public func stop() {
        // Stop the server if it's running
        webServer?.stop()
        // Reset server instance and URL cache
        webServer = nil
        serverUrl = nil
    }

    /// Returns the current server URL if the server is running.
    @objc public func getUrl() -> String? {
        return serverUrl
    }
}
