#!/usr/bin/env bash

# This script is used to set up a buildkite-agent EC2 instance so that
# it can run all steps in the C.I pipeline.
#
# You can customize your stack’s instances by using the `BootstrapScriptUrl`
# stack parameter to run a bash script on instance boot.
# Currently `BootstrapScriptUrl` is set to:  s3://buildkite-agent-scripts/bootstrap_agent.sh
#
# Upload Cmd: aws --profile aws-2019-admin s3 cp --sse aws:kms .buildkite/bootstrap_agent.sh "s3://buildkite-agent-scripts/boostrap_agent.sh"

echo "Starting Buildkite agent bootstrap..."


BAZEL_VERSION="0.25.2"
sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip
curl -sSL -O \
  "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
chmod +x "bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
sudo "./bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"


echo "Finished Buildkite agent bootstrap..."