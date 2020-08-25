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
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/prefer-optional-chain': 'warn',
    '@typescript-eslint/array-type': ['warn', { default: 'array' }],
    '@typescript-eslint/consistent-type-assertions': [
      'warn',
      { assertionStyle: 'as' },
    ],
    'no-promise-executor-return': 'warn',
    'no-useless-backreference': 'warn',
    'no-template-curly-in-string': 'warn',
    'no-self-compare': 'warn',
    'no-throw-literal': 'warn',
    'no-useless-return': 'warn',
  },
};
