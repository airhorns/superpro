module.exports = {
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: __dirname + "/tsconfig.json"
  },
  plugins: ["@typescript-eslint", "react-hooks", "lodash"],
  extends: [
    "plugin:@typescript-eslint/recommended",
    "prettier",
    "prettier/@typescript-eslint",
    "plugin:react/recommended",
    "plugin:lodash/recommended"
  ],
  rules: {
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/explicit-member-accessibility": "off",
    "@typescript-eslint/camelcase": "warn",
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-unused-vars": [
      "warn",
      {
        argsIgnorePattern: "^_"
      }
    ],
    "react/display-name": "off",
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn",
    "lodash/import-scope": ["error", "member"],
    "lodash/prefer-lodash-method": "off",
    "lodash/prefer-noop": "off",
    "lodash/prefer-is-nil": "off",
    "lodash/prefer-constant": "off",
    "lodash/prefer-get": "off",
    "lodash/prefer-set": "off",
    "lodash/prefer-lodash-typecheck": "off",
    "lodash/matches-prop-shorthand": "warn"
  },
  settings: {
    react: {
      version: "detect"
    }
  }
};
