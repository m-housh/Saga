#! /bin/bash

# Pretty print DocC JSON output so that it can be consistently diffed between commits
export DOCC_JSON_PRETTYPRINT="YES"

# See https://apple.github.io/swift-docc-plugin/documentation/swiftdoccplugin/publishing-to-github-pages
swift package \
  --allow-writing-to-directory ./docs \
  generate-documentation \
  --target Saga \
  --output-path ./docs \
  --transform-for-static-hosting \
  --hosting-base-path Saga
