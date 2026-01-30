# Agents Guide - Local HTTP Server Capacitor Plugin

This document serves as instructions for AI agents and developers working on the `capacitor-http-server` plugin.

## Project Goal

Create a Capacitor plugin that starts a local HTTP server on Android and iOS to serve files from app-specific storage.

## Requirements

- **Platforms**: Android, iOS.
- **Port**: Dynamic or configurable (default to a random available port).
- **Base Directory**: Configurable via app metadata (default: app's files directory).
- **Core Methods**:
  - `startServer()`: Starts the server and returns the URL.
  - `stopServer()`: Stops the server.
  - `getServerUrl()`: Retrieves the current server URL.

## Configuration

### Base Directory

You can specify the subfolder from which the server should serve files by adding the following to your app's configuration:

#### Android (`AndroidManifest.xml`)

Add a `<meta-data>` tag inside the `<application>` element:

```xml
<application>
    <meta-data
        android:name="HTTP_SERVER_BASE_DIR"
        android:value="micro-live-update-assets/apps" />
</application>
```

#### iOS (`Info.plist`)

Add the `HTTP_SERVER_BASE_DIR` key:

```xml
<key>HTTP_SERVER_BASE_DIR</key>
<string>micro-live-update-assets/apps</string>
```

If these values are not present, the server defaults to serving from the root of the app's standard files/documents directory.

## Architecture

- **TypeScript Layer**: `src/definitions.ts` defines the plugin interface.
- **Android Layer**: Uses `com.zenda.capacitor.httpserver.HttpServer` to handle the actual server logic.
- **iOS Layer**: Uses `GCDWebServer` to handle the server logic.

## Key Files

- [definitions.ts](./src/definitions.ts): API interface.
- [HttpServerPlugin.java](./android/src/main/java/com/zenda/capacitor/httpserver/HttpServerPlugin.java): Android bridge.
- [HttpServer.java](./android/src/main/java/com/zenda/capacitor/httpserver/HttpServer.java): Android implementation.
- [HttpServerPlugin.swift](./ios/Sources/HttpServerPlugin/HttpServerPlugin.swift): iOS bridge.
- [HttpServer.swift](./ios/Sources/HttpServerPlugin/HttpServer.swift): iOS implementation.

## HTTP / Cleartext Support

Since the server runs on `http://localhost`, you must configure your application to allow cleartext (non-HTTPS) traffic.

### Android

The plugin includes a targeted Network Security Configuration that automatically permits cleartext traffic for `localhost` and `127.0.0.1`. This means you usually **do not** need to manually add `android:usesCleartextTraffic="true"` to your application tag.

### iOS

In your app's `Info.plist`, you still need to add the following to allow local networking:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Future Requirements (Roadmap)

The following features have been identified for future implementation:

### 1. Custom Scheme Support (`zhc://`)

Instead of standard `http://`, the plugin should support a custom scheme `zhc://`. This likely requires moving from a socket-based HTTP server to a **WebView Scheme Handler** (e.g., `WebViewAssetLoader` on Android and `WKURLSchemeHandler` on iOS).

### 2. Multi-Host Support

Support multiple virtual hostnames within the custom scheme:

- `zhc://app1`
- `zhc://app2`
- `zhc://app3`

Each host should map to a specific subfolder within the app's storage.

### 3. Static/Fixed Port

Allow `startServer()` to accept a `port` parameter. If not provided, it should default to a fixed port (e.g., `58080`) to ensure URL consistency across restarts.

## Development Workflow
