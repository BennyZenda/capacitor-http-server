import { WebPlugin } from '@capacitor/core';
import type { HttpServerPlugin } from './definitions';
export declare class HttpServerWeb extends WebPlugin implements HttpServerPlugin {
    startServer(): Promise<{
        url: string;
    }>;
    stopServer(): Promise<void>;
    getServerUrl(): Promise<{
        url: string;
    }>;
    isActive(): Promise<{
        active: boolean;
        port?: number;
        hostname?: string;
        protocol?: string;
        url?: string;
    }>;
}
