module.exports = {
  client: {
    service: {
      name: "flurish",
      localSchemaFile: "./tmp/app-schema.graphql"
    },
    includes: ["./app/javascript/app/**/*.{ts,tsx}"]
  }
};
