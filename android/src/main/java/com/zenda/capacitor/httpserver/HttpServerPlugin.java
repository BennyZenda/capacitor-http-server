package com.zenda.capacitor.httpserver;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.IOException;

/**
 * HttpServerPlugin bridges the Capacitor web layer to the Android HTTP server implementation.
 * It provides methods to start, stop, and query the local server.
 */
@CapacitorPlugin(name = "HttpServer")
public class HttpServerPlugin extends Plugin {

    // Internal instance that handles the server lifecycle and file serving
    private HttpServer implementation = new HttpServer();

    /**
     * Called when the plugin is initialized.
     * Sets up the base directory configuration for the server.
     */
    @Override
    public void load() {
        implementation.init(getContext());
    }

    /**
     * Starts the local HTTP server.
     * @param call Plugin call from the web layer.
     */
    @PluginMethod
    public void startServer(PluginCall call) {
        try {
            // Attempt to start the server and get its URL
            String url = implementation.start();
            JSObject ret = new JSObject();
            ret.put("url", url);
            // Resolve the promise with the server URL
            call.resolve(ret);
        } catch (IOException e) {
            // Reject the promise if server startup fails
            call.reject("Could not start server", e);
        }
    }

    /**
     * Stops the local HTTP server.
     * @param call Plugin call from the web layer.
     */
    @PluginMethod
    public void stopServer(PluginCall call) {
        // Halt the server implementation
        implementation.stop();
        // Resolve the promise indicating the server has stopped
        call.resolve();
    }

    /**
     * Returns the current local URL of the HTTP server.
     * @param call Plugin call from the web layer.
     */
    @PluginMethod
    public void getServerUrl(PluginCall call) {
        // Query the implementation for the current URL
        String url = implementation.getUrl();
        JSObject ret = new JSObject();
        ret.put("url", url);
        // Resolve the promise with the URL (may be null if server is stopped)
        call.resolve(ret);
    }

    /**
     * Returns the active status of the HTTP server.
     * @param call Plugin call from the web layer.
     */
    @PluginMethod
    public void isActive(PluginCall call) {
        call.resolve(implementation.getActiveStatus());
    }

    /* @Override
    protected void handleOnPause() {
        super.handleOnPause();
        // Stop server when backgrounded to save resources
        implementation.pause();
    }

    @Override
    protected void handleOnResume() {
        super.handleOnResume();
        // Restart server when returning to foreground if it was intended to be running
        if (implementation.wasRunning()) {
            try {
                implementation.start();
            } catch (IOException e) {
                com.getcapacitor.Logger.error("HttpServerPlugin", "Failed to resume server", e);
            }
        }
    } */
}
