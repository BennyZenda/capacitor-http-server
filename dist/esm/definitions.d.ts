export interface HttpServerPlugin {
    /**
     * Starts the local HTTP server.
     * @returns {Promise<{ url: string }>} A promise that resolves with the server URL.
     */
    startServer(): Promise<{
        url: string;
    }>;
    /**
     * Stops the local HTTP server.
     * @returns {Promise<void>}
     */
    stopServer(): Promise<void>;
    /**
     * Gets the current URL of the local HTTP server.
     * @returns {Promise<{ url: string }>} A promise that resolves with the server URL.
     */
    getServerUrl(): Promise<{
        url: string;
    }>;
}
