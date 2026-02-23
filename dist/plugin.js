var capacitorHttpServer = (function (exports, core) {
    'use strict';

    const HttpServer = core.registerPlugin('HttpServer', {
        web: () => Promise.resolve().then(function () { return web; }).then((m) => new m.HttpServerWeb()),
    });

    class HttpServerWeb extends core.WebPlugin {
        async startServer() {
            throw this.unimplemented('Not implemented on web.');
        }
        async stopServer() {
            throw this.unimplemented('Not implemented on web.');
        }
        async getServerUrl() {
            throw this.unimplemented('Not implemented on web.');
        }
        async isActive() {
            throw this.unimplemented('Not implemented on web.');
        }
    }

    var web = /*#__PURE__*/Object.freeze({
        __proto__: null,
        HttpServerWeb: HttpServerWeb
    });

    exports.HttpServer = HttpServer;

    return exports;

})({}, capacitorExports);
//# sourceMappingURL=plugin.js.map
