#!/usr/bin/env bash

set -euo pipefail

echo "vagrant:asdf" | chpasswd vagrant
echo "### vagrant 사용자 암호 변경 완료"