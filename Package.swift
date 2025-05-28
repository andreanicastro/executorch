// swift-tools-version:5.9
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription

let version = "0.7.0.20250528"
let url = "https://ossci-ios.s3.amazonaws.com/executorch/"
let debug = "_debug"
let deliverables = [
  "backend_coreml": [
    "sha256": "cb710c71384e755eb6f19f6c7763c3e815f55448150b10fedf043d2bda135fe4",
    "sha256" + debug: "f246debb85006e2766e6a192aa79a738bdc9f53093485953742fde742f8b7076",
    "frameworks": [
      "Accelerate",
      "CoreML",
    ],
    "libraries": [
      "sqlite3",
    ],
  ],
  "backend_mps": [
    "sha256": "1271684ed582f5bfbb03199063bc91c8917009021b5bc28ed2fd582722f61997",
    "sha256" + debug: "bfb223b9153de0008dea259a41f51ebd16d4d5cc38161c64c594ccf65ad50a50",
    "frameworks": [
      "Metal",
      "MetalPerformanceShaders",
      "MetalPerformanceShadersGraph",
    ],
  ],
  "backend_xnnpack": [
    "sha256": "b4627ea32fd4c04c6a2457b565854e98d3ac2a66a1be2dd037830266614e636c",
    "sha256" + debug: "e7c35e55fd71b6186e694f6aa93a080e775e8100d22bbfccd8a857d2355d28fc",
  ],
  "executorch": [
    "sha256": "9446e933bc7c549bc037e786ad98c7869148caf69e84863fa0f5b7d5ed2c1476",
    "sha256" + debug: "b806baa2a1c3666aa57df19e723ace5901256b06886969b62d5da90429bb1410",
  ],
  "kernels_custom": [
    "sha256": "5df3e05e9655e9699fdb1e3f54b96c760c0f9aa7dbf8fe1c3b835363f78f9c6b",
    "sha256" + debug: "08cfa77eb5b0976f1ca6be3488df3f38c3cb6f4b56fef4b965d577126360b204",
  ],
  "kernels_optimized": [
    "sha256": "de22eef901307d3c4123adf0443807cf8324e9b4f370b38e01cf01c1e53caf17",
    "sha256" + debug: "ebb3fe27418b518f30731c2408daab7f2443a9b6ae7b18edc2eae7a8ddb361b5",
  ],
  "kernels_portable": [
    "sha256": "76b9852dec8b7429a73928985a87284245caa491919c9d634fb94a2d16ab3359",
    "sha256" + debug: "9dd18f290654fd6925f9be9875b95ef4ca266fa7679e08e7e058160f179911fb",
  ],
  "kernels_quantized": [
    "sha256": "8af082d6aba24007b0b3084dc0b75e9c1f4533108c066f3275315b900a902155",
    "sha256" + debug: "970464ecdbf07edd7a2f3a30e64335212144bec4f414191354b268205f45a4f1",
  ],
].reduce(into: [String: [String: Any]]()) {
  $0[$1.key] = $1.value
  $0[$1.key + debug] = $1.value
}
.reduce(into: [String: [String: Any]]()) {
  var newValue = $1.value
  if $1.key.hasSuffix(debug) {
    $1.value.forEach { key, value in
      if key.hasSuffix(debug) {
        newValue[String(key.dropLast(debug.count))] = value
      }
    }
  }
  $0[$1.key] = newValue.filter { key, _ in !key.hasSuffix(debug) }
}

let package = Package(
  name: "executorch",
  platforms: [
    .iOS(.v17),
    .macOS(.v10_15),
  ],
  products: deliverables.keys.map { key in
    .library(name: key, targets: ["\(key)_dependencies"])
  }.sorted { $0.name < $1.name },
  targets: deliverables.flatMap { key, value -> [Target] in
    [
      .binaryTarget(
        name: key,
        url: "\(url)\(key)-\(version).zip",
        checksum: value["sha256"] as? String ?? ""
      ),
      .target(
        name: "\(key)_dependencies",
        dependencies: [.target(name: key)],
        path: ".Package.swift/\(key)",
        linkerSettings: [
          .linkedLibrary("c++")
        ] +
          (value["frameworks"] as? [String] ?? []).map { .linkedFramework($0) } +
          (value["libraries"] as? [String] ?? []).map { .linkedLibrary($0) }
      ),
    ]
  }
)
