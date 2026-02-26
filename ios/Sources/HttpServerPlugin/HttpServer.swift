import Foundation
import GCDWebServer
import UniformTypeIdentifiers
import Capacitor
import MobileCoreServices

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

        // Stop any existing inactive server before we reassign
        webServer?.stop()
        webServer = nil
        
        // 1. Try static port
        var startedServer = startServerInstance(on: defaultStaticPort, baseDir: baseDir)
        
        // 2. Try stored port if static port fails
        if startedServer == nil {
            let storedPort = UserDefaults.standard.integer(forKey: portKey)
            if storedPort > 0 && storedPort != defaultStaticPort {
                startedServer = startServerInstance(on: storedPort, baseDir: baseDir)
            }
        }
        
        // 3. Try dynamic free port if all above failed
        if startedServer == nil {
            startedServer = startServerInstance(on: 0, baseDir: baseDir) // dynamic port fallback
            if let server = startedServer {
                UserDefaults.standard.set(Int(server.port), forKey: portKey)
            }
        }

        if let server = startedServer, let url = server.serverURL {
            self.webServer = server
            self.serverUrl = url.absoluteString
            self.wasRunning = true
            return self.serverUrl
        }

        return nil
    }
    
    private func startServerInstance(on port: Int, baseDir: URL) -> GCDWebServer? {
        let server = GCDWebServer()
        
        // Use a weak reference to self in the handler block to avoid retain cycles
        weak var weakSelf = self
        
        // Add a handler to serve files with security checks and native MIME type resolution
        server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { request in
            guard let self = weakSelf else {
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
            
            // Serve the file if it exists and is not a directory, or serve index.html if it is a directory
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    let indexFileURL = fileURL.appendingPathComponent("index.html")
                    var indexIsDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: indexFileURL.path, isDirectory: &indexIsDirectory), !indexIsDirectory.boolValue {
                        let mimeType = self.getMimeType(for: indexFileURL)
                        let response = GCDWebServerFileResponse(file: indexFileURL.path)
                        response?.contentType = mimeType
                        return response
                    }
                } else {
                    // Determine MIME type using iOS native UniformTypeIdentifiers
                    let mimeType = self.getMimeType(for: fileURL)
                    let response = GCDWebServerFileResponse(file: fileURL.path)
                    response?.contentType = mimeType
                    return response
                }
            }
            
            // SPA Fallback: walk up the directory tree to find an index.html
            var fallbackDir = fileURL.deletingLastPathComponent()
            
            while fallbackDir.path.hasPrefix(baseDir.path) {
                let indexFileURL = fallbackDir.appendingPathComponent("index.html")
                var indexIsDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: indexFileURL.path, isDirectory: &indexIsDirectory), !indexIsDirectory.boolValue {
                    let mimeType = self.getMimeType(for: indexFileURL)
                    let response = GCDWebServerFileResponse(file: indexFileURL.path)
                    response?.contentType = mimeType
                    return response
                }
                
                if fallbackDir.path == baseDir.path {
                    break
                }
                fallbackDir = fallbackDir.deletingLastPathComponent()
            }
            
            // Return 404 if file not found
            return GCDWebServerErrorResponse(statusCode: 404)
        })
        
        let options: [String: Any] = [
            GCDWebServerOption_Port: port,
            GCDWebServerOption_BindToLocalhost: true,
            GCDWebServerOption_AutomaticallySuspendInBackground: false
        ]
        
        do {
            try server.start(options: options)
            return server
        } catch {
            // CRITICAL: Stop the server to clean up internal _options if start failed
            // This prevents a crash when the GCDWebServer instance is deallocated
            server.stop()
            return nil
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
            if let ident = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil as CFString?)?.takeRetainedValue(),
               let type = UTTypeCopyPreferredTagWithClass(ident, kUTTagClassMIMEType)?.takeRetainedValue() as String? {
                return type
            }
        }
        return "application/octet-stream"
    }
}
