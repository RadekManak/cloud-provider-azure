#!/bin/bash
# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Verifies git commits starting from predefined prefix.

# default to checking most recent commit only if not run by CI pipeline
check_base="${PULL_BASE_SHA:-HEAD^}"
check_sha="${PULL_PULL_SHA:-HEAD}"

read -d '' help_message << EOF
commit messages should look like one of:
UPSTREAM: <carry>: message  (commits that should be carried indefinitely)
UPSTREAM: <drop>: message   (commits that should be dropped on the next upstream rebase)
UPSTREAM: 1234: message     (commits that should be carried until an upstream rebase includes upstream PR 1234)
EOF

prefix='UPSTREAM: ([0-9]+|<(carry|drop)>): '

echo "examining commits between $check_base and $check_sha"
echo

while read -r message; do
  if ! [[ "$message" =~ ^$prefix ]]; then
    echo "Git history in this PR doesn't conform to set commit message standards. Offending commit message is:"
    echo "$message"
    echo
    echo "$help_message"
    exit 1
  fi
  echo "$message"
done < <(git log "$check_base".."$check_sha" --pretty=%s --no-merges)

if [[ "$CI" == "true" ]]; then
    echo "Comparing ${PULL_BASE_REF}=$(git rev-parse --verify ${PULL_BASE_REF}^1) and ${PULL_BASE_SHA}"
    echo git log for debugging
    git log --all --decorate --oneline --graph
    if [[ "$(git rev-parse --verify ${PULL_BASE_REF}^1)" != "$PULL_BASE_SHA" ]]; then
        echo "Only pull requests that are based on the latest commit on the base branch are allowed to merge. To fix this, rebase your pull request."
        echo
        echo "Additional commits on ${PULL_BASE_REF} that are not included in this PR:"
        git log ${PULL_BASE_REF} ^${PULL_PULL_SHA}
        exit 1
    fi
    echo "This PR includes all commits from base branch."
fi

echo
echo "All looks good"
