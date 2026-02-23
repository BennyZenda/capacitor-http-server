import { WebPlugin } from '@capacitor/core';

import type { HttpServerPlugin } from './definitions';

export class HttpServerWeb extends WebPlugin implements HttpServerPlugin {
  async startServer(): Promise<{ url: string }> {
    throw this.unimplemented('Not implemented on web.');
  }

  async stopServer(): Promise<void> {
    throw this.unimplemented('Not implemented on web.');
  }

  async getServerUrl(): Promise<{ url: string }> {
    throw this.unimplemented('Not implemented on web.');
  }

  async isActive(): Promise<{ active: boolean, port?: number, hostname?: string, protocol?: string, url?: string }> {
    throw this.unimplemented('Not implemented on web.');
  }
}
