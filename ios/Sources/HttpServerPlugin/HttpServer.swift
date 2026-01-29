import Foundation
import GCDWebServer

@objc public class HttpServer: NSObject {
    private var webServer: GCDWebServer?
    private var serverUrl: String?

    private var baseDir: URL?

    @objc public func initialize() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var basePath = ""
        if let path = Bundle.main.object(forInfoDictionaryKey: "HTTP_SERVER_BASE_DIR") as? String {
            basePath = path
        }
        
        if !basePath.isEmpty {
            self.baseDir = documentsURL.appendingPathComponent(basePath)
        } else {
            self.baseDir = documentsURL
        }

        if let baseDir = self.baseDir, !fileManager.fileExists(atPath: baseDir.path) {
            try? fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    @objc public func start() -> String? {
        if let url = serverUrl, webServer?.isRunning == true {
            return url
        }

        guard let baseDir = self.baseDir else {
            return nil
        }

        webServer = GCDWebServer()
        
        webServer?.addGETHandler(forAbsolutePath: "/", directoryPath: baseDir.path, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)

        // Use port 0 for dynamic port allocation
        let options: [String: Any] = [
            GCDWebServerOption_Port: 0,
            GCDWebServerOption_BindToLocalhost: true
        ]

        do {
            try webServer?.start(options: options)
            if let url = webServer?.serverURL {
                self.serverUrl = url.absoluteString
                return self.serverUrl
            }
        } catch {
            print("Could not start server: \(error)")
        }

        return nil
    }

    @objc public func stop() {
        webServer?.stop()
        webServer = nil
        serverUrl = nil
    }

    @objc public func getUrl() -> String? {
        return serverUrl
    }
}
