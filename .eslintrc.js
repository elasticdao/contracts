module.exports = {
  env: {
    browser: true,
    es6: true,
    mocha: true,
  },
  extends: ['airbnb-base', 'plugin:mocha/recommended'],
  globals: {
    Atomics: 'readonly',
    SharedArrayBuffer: 'readonly',
  },
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module',
  },
  plugins: ['mocha'],
  rules: {
    'mocha/no-mocha-arrows': 0,
    'no-console': 0,
    'no-underscore-dangle': 0,
  },
};
