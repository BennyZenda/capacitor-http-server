import Foundation
import GCDWebServer

@objc public class HttpServer: NSObject {
    private var webServer: GCDWebServer?
    private var serverUrl: String?

    @objc public func start() -> String? {
        if let url = serverUrl, webServer?.isRunning == true {
            return url
        }

        webServer = GCDWebServer()
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseDir = documentsURL.appendingPathComponent("app-b")

        if !fileManager.fileExists(atPath: baseDir.path) {
            try? fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true, attributes: nil)
        }

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
