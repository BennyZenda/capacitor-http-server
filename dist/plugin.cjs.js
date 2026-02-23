'use strict';

var core = require('@capacitor/core');

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
//# sourceMappingURL=plugin.cjs.js.map
