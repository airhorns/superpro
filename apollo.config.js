module.exports = {
  client: {
    service: {
      name: "flurish",
      url: "https://ggt.dev/edit/graphql",
      headers: {
        "x-trusted-dev-client": "yes"
      },
      skipSSLValidation: true
    },
    includes: ['./app/javascript/edit/**/*.{ts,tsx}']
  }
};
