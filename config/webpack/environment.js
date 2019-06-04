const { environment } = require("@rails/webpacker");

environment.splitChunks();

if (process.env['ANALYZE_BUNDLE']) {
  const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

  environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());
}

module.exports = environment;
