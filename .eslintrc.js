module.exports = {
  parser: '@typescript-eslint/parser', // Specifies the ESLint parser

  parserOptions: {
    ecmaVersion: 2020, // Allows for the parsing of modern ECMAScript features

    sourceType: 'module', // Allows for the use of imports
  },

  extends: [
    'plugin:@typescript-eslint/recommended', // Uses the recommended rules from the @typescript-eslint/eslint-plugin
  ],

  rules: {
    '@typescript-eslint/no-inferrable-types': 'off',
    '@typescript-eslint/no-empty-function': 'off',
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    // Place to specify ESLint rules. Can be used to overwrite rules specified from the extended configs
    // e.g. "@typescript-eslint/explicit-function-return-type": "off",
  },
};
