#!/usr/bin/env bash
# Author : nimula+github@gmail.com

# Any commands you need
source /src/envsetup.sh && lunch && /src/build.sh && /src/mkfirmware.sh && date
