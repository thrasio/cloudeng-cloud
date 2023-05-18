#!/usr/bin/env bash

cd "$(dirname "$0")"

pipenv install
pipenv run python -m sealer.sealer
