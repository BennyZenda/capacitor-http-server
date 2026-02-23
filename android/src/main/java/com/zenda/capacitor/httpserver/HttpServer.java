package com.zenda.capacitor.httpserver;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.content.Context;
import android.webkit.MimeTypeMap;
import com.getcapacitor.Logger;
import fi.iki.elonen.NanoHTTPD;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.util.Map;

/**
 * HttpServer class manages the lifecycle and configuration of the local NanoHTTPD server on Android.
 */
public class HttpServer {

    // Instance of the internal NanoHTTPD server implementation
    private AndroidHttpServer server;
    // Cached URL where the server is accessible
    private String serverUrl;
    // The port number the server is listening on
    private int port;
    // The base directory from which static files are served
    private File baseDir;
    // The application context
    private Context context;
    // Flag to track user intent for the server state
    private boolean wasRunning = false;
    
    private static final int DEFAULT_STATIC_PORT = 55667;
    private static final String PREFS_NAME = "CapacitorHttpServerPrefs";
    private static final String PREF_PORT_KEY = "server_port";

    /**
     * Initializes the server configuration by reading the base directory from AndroidManifest meta-data.
     */
    public void init(Context context) {
        this.context = context;
        String basePath = "";
        try {
            // Retrieve application info to access meta-data from AndroidManifest.xml
            ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = ai.metaData;
            // Check for the "HTTP_SERVER_BASE_DIR" configuration
            if (bundle != null && bundle.containsKey("HTTP_SERVER_BASE_DIR")) {
                basePath = bundle.getString("HTTP_SERVER_BASE_DIR");
            }
        } catch (PackageManager.NameNotFoundException e) {
            Logger.error("HttpServer", "Failed to load meta-data, NameNotFound: " + e.getMessage(), e);
        } catch (NullPointerException e) {
            Logger.error("HttpServer", "Failed to load meta-data, NullPointer: " + e.getMessage(), e);
        }

        // Set the base directory; default to app's internal files directory if not specified
        if (basePath != null && !basePath.isEmpty()) {
            this.baseDir = new File(context.getFilesDir(), basePath);
        } else {
            this.baseDir = context.getFilesDir();
        }
    }

    /**
     * Starts the HTTP server on an available port and returns its URL.
     */
    public String start() throws IOException {
        // If server is already running, return the existing URL
        if (server != null && server.isAlive()) {
            this.wasRunning = true;
            return serverUrl;
        }

        // 1. Try static port
        boolean started = tryStartOnPort(DEFAULT_STATIC_PORT);
        
        // 2. Try stored port if static port fails
        if (!started) {
            android.content.SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            int storedPort = prefs.getInt(PREF_PORT_KEY, -1);
            if (storedPort != -1 && storedPort != DEFAULT_STATIC_PORT) {
                started = tryStartOnPort(storedPort);
            }
        }
        
        // 3. Try dynamic free port if all above failed
        if (!started) {
            int freePort = findFreePort();
            started = tryStartOnPort(freePort);
            if (started) {
                // Store the new dynamically chosen port
                android.content.SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
                prefs.edit().putInt(PREF_PORT_KEY, this.port).apply();
            }
        }

        if (!started) {
            throw new IOException("Failed to start server on any port.");
        }

        // Construct the server's local URL
        this.serverUrl = "http://localhost:" + port + "/";
        this.wasRunning = true;

        Logger.info("HttpServer", "Server started at " + serverUrl + " serving from " + baseDir.getAbsolutePath());
        return serverUrl;
    }
    
    private boolean tryStartOnPort(int targetPort) {
        try {
            this.server = new AndroidHttpServer(targetPort, baseDir);
            this.server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false);
            this.port = this.server.getListeningPort();
            return true;
        } catch (IOException e) {
            Logger.debug("HttpServer", "Failed to start server on port " + targetPort);
            this.server = null;
            return false;
        }
    }

    /**
     * Stops the running HTTP server and clears associated state.
     */
    public void stop() {
        this.wasRunning = false;
        if (server != null) {
            // Shut down the server
            server.stop();
            // Clear instance variables
            server = null;
            serverUrl = null;
            Logger.info("HttpServer", "Server stopped");
        }
    }
    
    /**
     * Used by app lifecycle hooks to pause the server without losing the user's intent.
     */
    public void pause() {
        if (server != null) {
            server.stop();
            server = null;
            Logger.info("HttpServer", "Server paused");
        }
    }
    
    public boolean wasRunning() {
        return this.wasRunning;
    }

    /**
     * Returns the current server URL.
     */
    public String getUrl() {
        return serverUrl;
    }

    /**
     * Returns the active status and connection info as a JSObject.
     */
    public com.getcapacitor.JSObject getActiveStatus() {
        com.getcapacitor.JSObject status = new com.getcapacitor.JSObject();
        boolean active = (server != null && server.isAlive());
        status.put("active", active);
        if (active) {
            status.put("port", this.port);
            status.put("hostname", "localhost");
            status.put("protocol", "http:");
            status.put("url", this.serverUrl);
        }
        return status;
    }

    /**
     * Finds an available port on the device by opening a ServerSocket on port 0.
     */
    private int findFreePort() {
        try (ServerSocket socket = new ServerSocket(0)) {
            return socket.getLocalPort();
        } catch (IOException e) {
            // Fallback port if automatic detection fails
            return 8080;
        }
    }

    /**
     * Internal implementation of NanoHTTPD to serve files from the specified base directory.
     */
    private static class AndroidHttpServer extends NanoHTTPD {

        private final File baseDir;

        public AndroidHttpServer(int port, File baseDir) {
            super(port);
            this.baseDir = baseDir;
        }

        @Override
        public Response serve(IHTTPSession session) {
            // Extract the requested URI
            String uri = session.getUri();
            
            // Map the URI to a file within the base directory
            // Note: uri starts with /
            File file = new File(baseDir, uri.substring(1));

            try {
                // Security: Prevent Path Traversal attacks
                // Ensure the resolved canonical path is still within the base directory
                String canonicalBase = baseDir.getCanonicalPath();
                String canonicalFile = file.getCanonicalPath();
                
                if (!canonicalFile.startsWith(canonicalBase)) {
                    // Logger.error("HttpServer", "Blocked path traversal attempt: " + uri);
                    return newFixedLengthResponse(Response.Status.FORBIDDEN, NanoHTTPD.MIME_PLAINTEXT, "Forbidden: Path traversal attempt");
                }

                // If the file exists and is indeed a file, serve its content
                if (file.exists() && file.isFile()) {
                    // Determine MIME type using Android's native MimeTypeMap
                    String mimeType = getMimeType(uri);
                    InputStream inputStream = new FileInputStream(file);
                    // Return a chunked response for the file content
                    return newChunkedResponse(Response.Status.OK, mimeType, inputStream);
                }
            } catch (IOException e) {
                // Return internal error if file reading or path resolution fails
                Logger.error("HttpServer", "Error serving file: " + uri, e);
                return newFixedLengthResponse(
                    Response.Status.INTERNAL_ERROR,
                    NanoHTTPD.MIME_PLAINTEXT,
                    "Error processing request: " + e.getMessage()
                );
            }

            // Return 404 Not Found if the file doesn't exist or is outside baseDir
            return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "File not found: " + uri);
        }

        /**
         * Resolves MIME type using Android's native MimeTypeMap.
         */
        private String getMimeType(String uri) {
            String extension = MimeTypeMap.getFileExtensionFromUrl(uri);
            if (extension != null) {
                String type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase());
                if (type != null) {
                    return type;
                }
            }
            // Fallback to plaintext
            return NanoHTTPD.MIME_PLAINTEXT;
        }
    }
}
