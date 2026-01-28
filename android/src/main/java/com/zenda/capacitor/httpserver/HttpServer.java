package com.zenda.capacitor.httpserver;

import com.getcapacitor.Logger;

public class HttpServer {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}
