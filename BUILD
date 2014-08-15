# Description:
# Visualization toolkit for Dart. Provides D3 (http://d3js.org) like Selection
# API, utilities to achieve data driven DOM and provides an easy-to-use
# Charting library based on the Selection API.

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # Apache License, Version 2.0

exports_files(["LICENSE"])

dart_library(
    name = "charted",
    srcs = glob([
        "lib/*.dart",
        "lib/**/*.dart",
    ]),
    deps = [
        "//third_party/dart/browser",
        "//third_party/dart/csslib",
        "//third_party/dart/intl",
        "//third_party/dart/logging",
        "//third_party/dart/observe",
    ],
)