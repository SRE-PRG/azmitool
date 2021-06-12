#!/bin/bash

REPEAT=$1

echo 'azmi - build executable'
# dotnet build src/azmi-commandline/azmi-commandline.csproj
dotnet publish ./src/azmi-commandline/azmi-commandline.csproj --configuration Release --self-contained true /p:PublishSingleFile=true --runtime linux-x64

exePath=$(cd ./src/azmi-commandline/bin/Release/net5.0/linux-x64/publish || exit; pwd)
export PATH="$exePath:$PATH"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$HOME/cache_dotnet_bundle_extract"


printf  "\n=================\n"
echo "azmi getblob - performance testing, repeat count: $REPEAT"
echo "VM size: $(curl -sS -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2018-10-01&format=text")"


printf  "\n=================\n"
echo "azmi --help"
time seq "$REPEAT" | azmi --help > /dev/null


printf  "\n=================\n"
echo "azmi gettoken"
time seq "$REPEAT" | azmi gettoken > /dev/null
