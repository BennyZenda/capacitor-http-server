# capacitor-http-server

Creates local http server

```bash
npm install capacitor-http-server
npx cap sync
```

## Configuration

The plugin serves files from a specific base directory in your app's storage. By default, it uses the root of the app's standard files/documents directory, but you can configure a subfolder.

### Android (`AndroidManifest.xml`)

Add the following inside the `<application>` element of your **main app's** `AndroidManifest.xml`:

```xml
<meta-data
    android:name="HTTP_SERVER_BASE_DIR"
    android:value="micro-live-update-assets/apps" />
```

### iOS (`Info.plist`)

Add the following to your **main app's** `Info.plist`:

```xml
<key>HTTP_SERVER_BASE_DIR</key>
<string>micro-live-update-assets/apps</string>
```

## Usage

```typescript
import { HttpServer } from 'capacitor-http-server';

// Start the server
const { url } = await HttpServer.startServer();
console.log(`Server started at ${url}`);

// Get the current URL
const { url: currentUrl } = await HttpServer.getServerUrl();

// Stop the server
await HttpServer.stopServer();
```

## API

<docgen-index>

* [`startServer()`](#startserver)
* [`stopServer()`](#stopserver)
* [`getServerUrl()`](#getserverurl)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startServer()

```typescript
startServer() => Promise<{ url: string; }>
```

Starts the local HTTP server.

**Returns:** <code>Promise&lt;{ url: string; }&gt;</code>

--------------------


### stopServer()

```typescript
stopServer() => Promise<void>
```

Stops the local HTTP server.

--------------------


### getServerUrl()

```typescript
getServerUrl() => Promise<{ url: string; }>
```

Gets the current URL of the local HTTP server.

**Returns:** <code>Promise&lt;{ url: string; }&gt;</code>

--------------------

</docgen-api>
