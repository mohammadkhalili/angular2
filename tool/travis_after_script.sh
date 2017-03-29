#!/bin/bash

# We don't want to fail fast, but verbose is good
set -v

# Only "interesting" for pub tests - but will be a noop in other cases
# Kill pub since we succeeded.
pid=$(lsof -i:$PUB_PORT -t); kill -TERM $pid || kill -KILL $pid
