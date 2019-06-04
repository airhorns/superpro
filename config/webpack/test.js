process.env.NODE_ENV = process.env.NODE_ENV || "development";
const typescript = require("./loaders/typescript");
const environment = require("./environment");
environment.loaders.prepend("typescript", typescript);
module.exports = environment.toWebpackConfig();
