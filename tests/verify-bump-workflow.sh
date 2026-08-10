#!/usr/bin/env bash
set -euo pipefail

workflow=${1:-.github/workflows/bump.yml}

line_number() {
  local pattern=$1
  local line
  line=$(grep -nF -- "$pattern" "$workflow" | head -n1 | cut -d: -f1 || true)
  if [[ -z "$line" ]]
  then
    printf 'Missing "%s" in %s\n' "$pattern" "$workflow" >&2
    exit 1
  fi
  printf '%s\n' "$line"
}

timeout_line=$(line_number 'timeout-minutes: 30')
qemu_line=$(line_number 'name: Set up QEMU')
buildx_line=$(line_number 'name: Set up Docker Buildx')
verify_line=$(line_number 'name: Verify multi-platform build')
build_action_line=$(line_number 'uses: docker/build-push-action@')
commit_line=$(line_number 'name: Commit and tag')

if (( timeout_line >= qemu_line || qemu_line >= verify_line || buildx_line >= verify_line || verify_line >= commit_line ))
then
  printf 'The release gate must precede commit and tag within the job timeout\n' >&2
  exit 1
fi

if (( build_action_line < verify_line || build_action_line >= commit_line ))
then
  printf 'The verification step must use build-push-action\n' >&2
  exit 1
fi

verify_block=$(sed -n "${verify_line},$((commit_line - 1))p" "$workflow")
qemu_block=$(sed -n "${qemu_line},$((buildx_line - 1))p" "$workflow")
buildx_block=$(sed -n "${buildx_line},$((verify_line - 1))p" "$workflow")
commit_block=$(sed -n "${commit_line},\$p" "$workflow")

for step_block in "$qemu_block" "$buildx_block" "$verify_block"
do
  if ! grep -Fq -- "if: steps.bump.outputs.changed == 'true'" <<< "$step_block"
  then
    printf 'Every release verification step must run only for a changed version\n' >&2
    exit 1
  fi
done

if ! grep -Fq -- 'uses: docker/setup-qemu-action@' <<< "$qemu_block"
then
  printf 'The QEMU verification step must use setup-qemu-action\n' >&2
  exit 1
fi

if ! grep -Fq -- 'uses: docker/setup-buildx-action@' <<< "$buildx_block"
then
  printf 'The Buildx verification step must use setup-buildx-action\n' >&2
  exit 1
fi

if ! grep -Fq -- 'uses: docker/build-push-action@' <<< "$verify_block"
then
  printf 'The multi-platform verification step must use build-push-action\n' >&2
  exit 1
fi

if ! grep -Fq -- "if: steps.bump.outputs.changed == 'true'" <<< "$commit_block"
then
  printf 'Commit and tag must run only after a changed version is verified\n' >&2
  exit 1
fi

if grep -Eq -- 'if:.*always\(\)' <<< "$commit_block"
then
  printf 'Commit and tag must not bypass a failed verification step\n' >&2
  exit 1
fi

for setting in \
  'context: .' \
  'platforms: linux/amd64,linux/arm64' \
  'pull: true' \
  'push: false'
do
  if ! grep -Fq -- "$setting" <<< "$verify_block"
  then
    printf 'Missing "%s" from the multi-platform verification step\n' "$setting" >&2
    exit 1
  fi
done

if grep -Fq -- 'run: docker build --pull' "$workflow"
then
  printf 'The release gate must not use the single-platform docker build command\n' >&2
  exit 1
fi

printf 'bump workflow validates both release platforms before tagging\n'
