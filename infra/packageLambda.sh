#!/bin/bash

function packageLambda {
  mkdir -p zips &&\
  cd ../mailer/ && \
  # Run the npm commands to transpile the TypeScript to JavaScript
  npm i && \
  npm run build && \
  npm prune --production &&\
  # Create a dist folder and copy only the js files to dist.
  # AWS Lambda does not have a use for a package.json or typescript files on runtime.
  mkdir -p dist &&\
  cp -r ./src/*.ts dist/ &&\
  cp -r ./node_modules dist/ &&\
  cd dist &&\
  find . -name "*.zip" -type f -delete && \
  # Zip everything in the dist folder and
  zip -r ../../infra/zips/lambda.zip . && \
  cd .. && rm -rf dist &&\
  cd ../infra
}

packageLambda