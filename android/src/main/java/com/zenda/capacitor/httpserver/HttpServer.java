package com.zenda.capacitor.httpserver;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;

import android.content.Context;
import com.getcapacitor.Logger;
import fi.iki.elonen.NanoHTTPD;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.util.Map;

public class HttpServer {

    private AndroidHttpServer server;
    private String serverUrl;
    private int port;
    private File baseDir;

    public void init(Context context) {
        String basePath = "";
        try {
            ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = ai.metaData;
            if (bundle != null && bundle.containsKey("HTTP_SERVER_BASE_DIR")) {
                basePath = bundle.getString("HTTP_SERVER_BASE_DIR");
            }
        } catch (PackageManager.NameNotFoundException e) {
            Logger.error("HttpServer", "Failed to load meta-data, NameNotFound: " + e.getMessage(), e);
        } catch (NullPointerException e) {
            Logger.error("HttpServer", "Failed to load meta-data, NullPointer: " + e.getMessage(), e);
        }

        if (basePath != null && !basePath.isEmpty()) {
            this.baseDir = new File(context.getFilesDir(), basePath);
        } else {
            this.baseDir = context.getFilesDir();
        }

        if (!baseDir.exists()) {
            baseDir.mkdirs();
        }
    }

    public String start() throws IOException {
        if (server != null && server.isAlive()) {
            return serverUrl;
        }

        this.port = findFreePort();
        this.server = new AndroidHttpServer(port, baseDir);
        this.server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false);
        this.serverUrl = "http://localhost:" + port + "/";

        Logger.info("HttpServer", "Server started at " + serverUrl + " serving from " + baseDir.getAbsolutePath());
        return serverUrl;
    }

    public void stop() {
        if (server != null) {
            server.stop();
            server = null;
            serverUrl = null;
            Logger.info("HttpServer", "Server stopped");
        }
    }

    public String getUrl() {
        return serverUrl;
    }

    private int findFreePort() {
        try (ServerSocket socket = new ServerSocket(0)) {
            return socket.getLocalPort();
        } catch (IOException e) {
            return 8080; // Fallback
        }
    }

    private static class AndroidHttpServer extends NanoHTTPD {

        private final File baseDir;

        public AndroidHttpServer(int port, File baseDir) {
            super(port);
            this.baseDir = baseDir;
        }

        @Override
        public Response serve(IHTTPSession session) {
            String uri = session.getUri();
            File file = new File(baseDir, uri.substring(1));

            if (file.exists() && file.isFile()) {
                try {
                    String mimeType = getMimeType(uri);
                    InputStream inputStream = new FileInputStream(file);
                    return newChunkedResponse(Response.Status.OK, mimeType, inputStream);
                } catch (IOException e) {
                    return newFixedLengthResponse(
                        Response.Status.INTERNAL_ERROR,
                        NanoHTTPD.MIME_PLAINTEXT,
                        "Error reading file: " + e.getMessage()
                    );
                }
            }

            return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "File not found: " + uri);
        }

        private String getMimeType(String uri) {
            if (uri.endsWith(".html") || uri.endsWith(".htm")) return "text/html";
            if (uri.endsWith(".css")) return "text/css";
            if (uri.endsWith(".js")) return "application/javascript";
            if (uri.endsWith(".png")) return "image/png";
            if (uri.endsWith(".jpg") || uri.endsWith(".jpeg")) return "image/jpeg";
            if (uri.endsWith(".json")) return "application/json";
            return NanoHTTPD.MIME_PLAINTEXT;
        }
    }
}
