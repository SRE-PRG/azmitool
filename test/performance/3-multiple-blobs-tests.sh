#!/bin/bash

echo 'azmi - build executable'
# dotnet build src/azmi-commandline/azmi-commandline.csproj
dotnet publish ./src/azmi-commandline/azmi-commandline.csproj --configuration Release --self-contained true /p:PublishSingleFile=true --runtime linux-x64

exePath=$(cd ./src/azmi-commandline/bin/Release/net5.0/linux-x64/publish || exit; pwd)
export PATH="$exePath:$PATH"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$HOME/cache_dotnet_bundle_extract"

printf  "\n=================\n"
echo "azmi getblobs - performance testing, repeat count: 1"
echo "VM size: $(curl -sS -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2018-10-01&format=text")"
echo "azmi: $(azmi --version)"
CONTAINER="https://azmitest5.blob.core.windows.net/azmi-pt"



printf  "\n=================\n"
echo "azmi listblobs -c $CONTAINER"
time azmi listblobs -c $CONTAINER | wc -l
sleep 1 # required to prevent overlapping output in ADO pipeline logs



printf  "\n=================\n"
echo "rclone ls pt:azmi-pt"
time rclone ls pt:azmi-pt | wc -l



rm -rf download1
mkdir download1
printf  "\n=================\n"
echo "azmi getblobs -c $CONTAINER -d download1"
time azmi getblobs -c $CONTAINER -d download1 > /dev/null
echo "disk usage: $(du download1)"



rm -rf download2
mkdir download2
printf  "\n=================\n"
echo "rclone copy pt:azmi-pt ./download2"
time rclone copy pt:azmi-pt ./download2
echo "disk usage: $(du download2)"



CONTAINER="https://azmitest5.blob.core.windows.net/azmi-rw"
rm -rf upload
mkdir upload
printf  "\n=================\n"
echo "1) Generate 10 x 10MB files"
for i in `seq 1 10`; do
  head -c 10M < /dev/urandom > upload/file${i}
done

echo "2) Measure normal upload"
echo "azmi setblobs --container $CONTAINER --directory ./upload --force"
time azmi setblobs --container $CONTAINER --directory ./upload --force

echo "3) Measure re-upload with --skip-if-same"
echo "azmi setblobs --container $CONTAINER --directory ./upload --force --skip-if-same"
time azmi setblobs --container $CONTAINER --directory ./upload --force --skip-if-same

echo "4) Re-generate the same random files with updated content"
for i in `seq 1 10`; do
  head -c 10M </dev/urandom > upload/file${i}
done

echo "5) Measure upload with --skip-if-same"
echo "azmi setblobs --container $CONTAINER --directory ./upload --force --skip-if-same"
time azmi setblobs --container $CONTAINER --directory ./upload --force --skip-if-same

echo "* teardown"
azmi getblobs --container $CONTAINER --directory ./upload --delete-after-copy
rm -rf upload