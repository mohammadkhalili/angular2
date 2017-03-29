#!/bin/bash

# Fast fail the script on failures.
set -ev

# NOTE: Only needed for vm tests, but no easy way to sniff the `dart_task`
#       config from a shell script.
dart test/source_gen/template_compiler/generate.dart

if [ -n "$PUB_PORT" ]; then
  # Kill any existing pub instance.
  pid=$(lsof -i:$PUB_PORT -t); kill -TERM $pid || kill -KILL $pid

  # Fail fast.
  set -e

  # Run pub serve on directories that have codegen tests.
  # Some errors will occur on other tests that don't use codegen yet; ignore.
  exec 3< <(pub serve test --port $PUB_PORT)
fi
