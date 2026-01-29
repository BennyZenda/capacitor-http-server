package com.zenda.capacitor.httpserver;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.IOException;

@CapacitorPlugin(name = "HttpServer")
public class HttpServerPlugin extends Plugin {

    private HttpServer implementation = new HttpServer();

    @Override
    public void load() {
        implementation.init(getContext());
    }

    @PluginMethod
    public void startServer(PluginCall call) {
        try {
            String url = implementation.start();
            JSObject ret = new JSObject();
            ret.put("url", url);
            call.resolve(ret);
        } catch (IOException e) {
            call.reject("Could not start server", e);
        }
    }

    @PluginMethod
    public void stopServer(PluginCall call) {
        implementation.stop();
        call.resolve();
    }

    @PluginMethod
    public void getServerUrl(PluginCall call) {
        String url = implementation.getUrl();
        JSObject ret = new JSObject();
        ret.put("url", url);
        call.resolve(ret);
    }
}
