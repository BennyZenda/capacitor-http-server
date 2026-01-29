# cap-http-server

Craetes local http server

## Install

```bash
npm install cap-http-server
npx cap sync
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
