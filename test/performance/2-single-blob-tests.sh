#!/bin/bash

echo 'azmi - build executable'
dotnet build src/azmi-commandline/azmi-commandline.csproj

exePath=$(cd ./src/azmi-commandline/bin/Debug/netcoreapp3.0; pwd)
PATH="$PATH:$exePath"


echo "azmi getblob - performance testing, repeat count: $(REPEAT)"



BLOB="https://azmitest5.blob.core.windows.net/azmi-ro/file1"


printf  "\n=================\n"
echo "azmi getblob --blob $BLOB --file download.txt"

time for i in {1..$(REPEAT)}; do azmi getblob --blob $BLOB --file download1.txt > /dev/null; done


printf  "\n=================\n"
echo "$(PREVIOUS_VERSION) getblob --blob $BLOB --file download.txt"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$HOME/cache_dotnet_bundle_extract"
wget --quiet https://azmideb.blob.core.windows.net/azmi-deb/archive/$(PREVIOUS_VERSION)
chmod +x ./$(PREVIOUS_VERSION)
./$(PREVIOUS_VERSION) --version

time for i in {1..$(REPEAT)}; do ./$(PREVIOUS_VERSION) getblob --blob $BLOB --file download1.txt --verbose > /dev/null; done



printf  "\n=================\n"
echo "curl $BLOB"

token=`azmi gettoken --endpoint storage`
request_date=$(TZ=GMT LC_ALL=en_US.utf8 date "+%a, %d %h %Y %H:%M:%S %Z")

time for i in {1..$(REPEAT)}; do
  url='http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F'
  access_token=$(curl -sS $url -H Metadata:true | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')

  curl -sS $BLOB \
     -H "Authorization: Bearer  $token" \
     -H "x-ms-version: 2017-11-09" \
     -H "x-ms-date: $request_date" \
     -H "x-ms-blob-type: BlockBlob" > /dev/null

done



BLOB="https://azmitest5.blob.core.windows.net/azmi-ro/file2"
printf  "\n=================\n"
echo "azmi getblob --blob $BLOB --file download.txt"

time for i in {1..$(REPEAT)}; do azmi getblob --blob $BLOB --file download1.txt > /dev/null; done


token=`azmi gettoken --endpoint storage`
request_date=$(TZ=GMT LC_ALL=en_US.utf8 date "+%a, %d %h %Y %H:%M:%S %Z")



printf  "\n=================\n"
echo "$(PREVIOUS_VERSION) getblob --blob $BLOB --file download.txt"
./$(PREVIOUS_VERSION) --version

time for i in {1..$(REPEAT)}; do ./$(PREVIOUS_VERSION) getblob --blob $BLOB --file download1.txt --verbose > /dev/null; done




printf  "\n=================\n"
echo "curl $BLOB"

time for i in {1..$(REPEAT)}; do
  url='http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F'
  access_token=$(curl -sS $url -H Metadata:true | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')

  curl -sS $BLOB \
     -H "Authorization: Bearer  $token" \
     -H "x-ms-version: 2017-11-09" \
     -H "x-ms-date: $request_date" \
     -H "x-ms-blob-type: BlockBlob" > /dev/null

done

