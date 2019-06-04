process.env.NODE_ENV = process.env.NODE_ENV || "production";
const typescript = require("./loaders/typescriptTranspileOnly");
const environment = require("./environment");

environment.loaders.prepend("typescript", typescript);
module.exports = environment.toWebpackConfig();
