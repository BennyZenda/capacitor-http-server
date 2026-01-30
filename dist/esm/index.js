import { registerPlugin } from '@capacitor/core';
const HttpServer = registerPlugin('HttpServer', {
    web: () => import('./web').then((m) => new m.HttpServerWeb()),
});
export * from './definitions';
export { HttpServer };
//# sourceMappingURL=index.js.map