import { WebPlugin } from '@capacitor/core';

import type { HttpServerPlugin } from './definitions';

export class HttpServerWeb extends WebPlugin implements HttpServerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
