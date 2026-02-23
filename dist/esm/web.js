import { WebPlugin } from '@capacitor/core';
export class HttpServerWeb extends WebPlugin {
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
//# sourceMappingURL=web.js.map