export interface HttpServerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
