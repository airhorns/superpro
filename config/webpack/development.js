process.env.NODE_ENV = process.env.NODE_ENV || "development";
const ForkTsCheckerNotifierWebpackPlugin = require('fork-ts-checker-notifier-webpack-plugin');
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');
const typescript = require("./loaders/typescriptTranspileOnly");
const environment = require("./environment");

environment.plugins.prepend('ts-warnings', new ForkTsCheckerNotifierWebpackPlugin({ title: 'TypeScript', excludeWarnings: false }),
)

environment.plugins.prepend('fork-ts-checker', new ForkTsCheckerWebpackPlugin({
  useTypescriptIncrementalApi: true
}));

environment.loaders.prepend("typescript", typescript);

module.exports = environment.toWebpackConfig();
