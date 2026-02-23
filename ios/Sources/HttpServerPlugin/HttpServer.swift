import Foundation
import GCDWebServer
import UniformTypeIdentifiers
import Capacitor

/// The HttpServer class manages the lifecycle and configuration of the local GCDWebServer.
@objc public class HttpServer: NSObject {
    // Instance of the GCDWebServer
    private var webServer: GCDWebServer?
    // Cached URL of the running server
    private var serverUrl: String?
    // Base directory from which files will be served
    private var baseDir: URL?
    
    // User intent state for lifecycle management
    public var wasRunning = false
    
    private let defaultStaticPort = 55667
    private let portKey = "CapacitorHttpServerPort"

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
            self.wasRunning = true
            return url
        }

        // Ensure the base directory is set before starting
        guard let baseDir = self.baseDir else {
            return nil
        }

        // Initialize a new instance of GCDWebServer
        webServer = GCDWebServer()
        
        // Use a weak reference to self in the handler block to avoid retain cycles
        weak var weakSelf = self
        
        // Add a handler to serve files with security checks and native MIME type resolution
        webServer?.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { request in
            guard let self = weakSelf, let baseDir = self.baseDir else {
                return GCDWebServerErrorResponse(statusCode: 500)
            }
            
            let path = request.path
            // Map the request path to the absolute file path
            let fileURL = baseDir.appendingPathComponent(path.hasPrefix("/") ? String(path.dropFirst()) : path)
            
            // Security: Prevent Path Traversal attacks
            // Ensure the resolved file path is still within the base directory
            let canonicalFile = fileURL.resolvingSymlinksInPath().path
            let canonicalBase = baseDir.resolvingSymlinksInPath().path
            
            if !canonicalFile.hasPrefix(canonicalBase) {
                CAPLog.print("Blocked path traversal attempt: \(path)")
                return GCDWebServerErrorResponse(statusCode: 403)
            }
            
            // Serve the file if it exists and is not a directory
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                // Determine MIME type using iOS native UniformTypeIdentifiers
                let mimeType = self.getMimeType(for: fileURL)
                return GCDWebServerFileResponse(file: fileURL.path, contentType: mimeType)
            }
            
            // Return 404 if file not found
            return GCDWebServerErrorResponse(statusCode: 404)
        })

        var started = tryStart(on: defaultStaticPort)
        
        if !started {
            let storedPort = UserDefaults.standard.integer(forKey: portKey)
            if storedPort > 0 && storedPort != defaultStaticPort {
                started = tryStart(on: storedPort)
            }
        }
        
        if !started {
            started = tryStart(on: 0) // dynamic port fallback
            if started, let actualPort = webServer?.port {
                UserDefaults.standard.set(Int(actualPort), forKey: portKey)
            }
        }

        if started, let url = webServer?.serverURL {
            self.serverUrl = url.absoluteString
            self.wasRunning = true
            return self.serverUrl
        }

        webServer = nil
        return nil
    }
    
    private func tryStart(on port: Int) -> Bool {
        let options: [String: Any] = [
            GCDWebServerOption_Port: port,
            GCDWebServerOption_BindToLocalhost: true
        ]
        do {
            try webServer?.start(options: options)
            return true
        } catch {
            return false
        }
    }

    /// Stops the running HTTP server and clears associated state.
    @objc public func stop() {
        self.wasRunning = false
        // Stop the server if it's running
        webServer?.stop()
        // Reset server instance and URL cache
        webServer = nil
        serverUrl = nil
    }

    /// Pauses the running HTTP server for backgrounding without modifying user intent.
    @objc public func pause() {
        webServer?.stop()
        webServer = nil
        serverUrl = nil
    }

    /// Returns the current server URL if the server is running.
    @objc public func getUrl() -> String? {
        return serverUrl
    }
    
    /// Returns the active status and connection properties.
    @objc public func getActiveStatus() -> [String: Any] {
        let active = webServer?.isRunning == true
        var status: [String: Any] = ["active": active]
        if active {
            status["port"] = webServer?.port
            status["hostname"] = "localhost"
            status["protocol"] = "http:"
            status["url"] = self.serverUrl
        }
        return status
    }
    
    /// Resolves MIME type for a given URL using native system APIs.
    private func getMimeType(for url: URL) -> String {
        if #available(iOS 14.0, *) {
            if let type = UTType(filenameExtension: url.pathExtension),
               let mimeType = type.preferredMIMEType {
                return mimeType
            }
        } else {
            // Fallback for older iOS versions
            if let ident = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)?.takeRetainedValue(),
               let type = UTTypeCopyPreferredTagWithClass(ident, kUTTagClassMIMEType)?.takeRetainedValue() as String? {
                return type
            }
        }
        return "application/octet-stream"
    }
}
