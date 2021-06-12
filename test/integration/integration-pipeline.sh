#!/bin/bash

#
# this script is used to in azmi integration pipeline to execute tests using BTF.sh
#   BTF.sh stands for Bash testing Framework
#   it is also using merge.sh to create single testing file
#

dotnet publish ./src/azmi-commandline/azmi-commandline.csproj --configuration Release --self-contained true /p:PublishSingleFile=true --runtime linux-x64

exePath=$(cd ./src/azmi-commandline/bin/Release/net5.0/linux-x64/publish || exit; pwd)
export PATH="$exePath:$PATH"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$HOME/cache_dotnet_bundle_extract"

printf  "\n=================\n"
echo "Integration testing azmi v.$(azmi --version)"

cd ./test/integration/ || exit
chmod +x  merge.sh
testFile=$(./merge.sh)

wget --quiet https://azmi.blob.core.windows.net/dev/btf.sh
chmod +x btf.sh

printf  "\n=================\n"
./btf.sh "$testFile" "$@" # $(STORAGE_ACCOUNT_NAME) $(IDENTITY_CLIENT_ID) $(KEY_VAULTS_BASE_NAME) $(OLD_SECRET_ID) $(OLD_CERTIFICATE_ID)
