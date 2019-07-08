module.exports = {
  client: {
    service: {
      name: "superpro",
      localSchemaFile: "./tmp/app-schema.graphql"
    },
    includes: ["./app/javascript/app/**/*.{ts,tsx}"]
  }
};
