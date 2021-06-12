#!/bin/bash

REPEAT=$1
PREVIOUS_VERSION=$2

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
BLOB="https://azmitest5.blob.core.windows.net/azmi-ro/file1"
echo "azmi getblob --blob $BLOB --file download.txt"
time seq "$REPEAT" | azmi getblob --blob $BLOB --file download1.txt > /dev/null



printf  "\n=================\n"
echo "$PREVIOUS_VERSION getblob --blob $BLOB --file download.txt"
wget --quiet https://azmi.blob.core.windows.net/archive/"$PREVIOUS_VERSION"
chmod +x ./"$PREVIOUS_VERSION"
./"$PREVIOUS_VERSION" --version

time seq "$REPEAT" | ./"$PREVIOUS_VERSION" getblob --blob $BLOB --file download1.txt > /dev/null



printf  "\n=================\n"
echo "curl $BLOB"


time for ((n=0;n<"$REPEAT";n++))
do
  url='http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F'
  token=$(curl -sS "$url" -H Metadata:true | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
  request_date=$(TZ=GMT LC_ALL=en_US.utf8 date "+%a, %d %h %Y %H:%M:%S %Z")

  curl -sS $BLOB \
     -H "Authorization: Bearer  $token" \
     -H "x-ms-version: 2017-11-09" \
     -H "x-ms-date: $request_date" \
     -H "x-ms-blob-type: BlockBlob" > /dev/null
done


BLOB="https://azmitest5.blob.core.windows.net/azmi-ro/file2"
printf  "\n=================\n"
echo "azmi getblob --blob $BLOB --file download.txt"

time seq "$REPEAT" | azmi getblob --blob $BLOB --file download1.txt > /dev/null



printf  "\n=================\n"
echo "$PREVIOUS_VERSION getblob --blob $BLOB --file download.txt"
./"$PREVIOUS_VERSION" --version

time seq "$REPEAT" | ./"$PREVIOUS_VERSION" getblob --blob $BLOB --file download1.txt --verbose > /dev/null



printf  "\n=================\n"
echo "curl $BLOB"

time for ((n=0;n<"$REPEAT";n++))
do
  url='http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F'
  token=$(curl -sS "$url" -H Metadata:true | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
  request_date=$(TZ=GMT LC_ALL=en_US.utf8 date "+%a, %d %h %Y %H:%M:%S %Z")

  curl -sS $BLOB \
     -H "Authorization: Bearer  $token" \
     -H "x-ms-version: 2017-11-09" \
     -H "x-ms-date: $request_date" \
     -H "x-ms-blob-type: BlockBlob" > /dev/null
done
