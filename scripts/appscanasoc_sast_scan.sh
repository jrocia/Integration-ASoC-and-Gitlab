#asocApiKeyId='xxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxx'
#serviceUrl='cloud.appscan.com'
#scanName=$CI_PROJECT_NAME-$CI_JOB_ID

appId=$(cat appId.txt)
echo "Sast" > scanTech.txt

# Downloading and preparing SAClientUtil
if ! [ -x "$(command -v appscan.sh)" ]; then
  echo 'appscan.sh is not installed.' >&2
  curl -k "https://$serviceUrl/api/v4/Tools/SAClientUtil?os=linux" > $HOME/SAClientUtil.zip
  unzip $HOME/SAClientUtil.zip -d $HOME > /dev/null
  rm -f $HOME/SAClientUtil.zip
  mv $HOME/SAClientUtil.* $HOME/SAClientUtil
  export PATH="$HOME/SAClientUtil/bin:${PATH}"
fi

# Generate IRX files based on source root folder downloaded by Gitlab
appscan.sh version
appscan.sh prepare

# Authenticate in ASOC
asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')
if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi

irxFile=$(ls -t *.irx | head -n1)
# Upload IRX file
if [ -f "$irxFile" ]; then
    irxFileId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/FileUpload" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:multipart/form-data' -F "uploadedFile=@$irxFile" | grep -oP '(?<="FileId":\ ")[^"]*');
    echo "$irxFile exist. It will be uploaded to ASoC. IRX file id is $irxFileId.";
else
    echo "IRX file not identified.";
fi

# Start scan
scanId=$(curl -s -k -X 'POST' "https://$serviceUrl/api/v4/Scans/Sast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d '{"AppId":"'"$appId"'","ApplicationFileId":"'"$irxFileId"'","ClientType":"user-site","EnableMailNotification":false,"Execute":true,"Locale":"en","Personal":false,"ScanName":"'"SAST $scanName $irxFile"'","EnablementMessage":"","FullyAutomatic":true}'| jq -r '. | {Id} | join(" ")');
#curl -k -X 'POST' "https://$serviceUrl/api/v4/Scans/Sast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d '{"AppId":"'"$appId"'","ApplicationFileId":"'"$irxFileId"'","ClientType":"user-site","EnableMailNotification":false,"Execute":true,"Locale":"en","Personal":false,"ScanName":"'"SAST $scanName $irxFile"'","EnablementMessage":"","FullyAutomatic":true}'
#echo "The ascotoken is $asocToken, appid is $appId, irx id is $irxFileId"
echo "Scan started, scanId $scanId";

echo "The scan name is $scanName and scanId is $scanId"
echo $scanId > scanId.txt

# Check status scan and keep it in loop until Ready status.
scanStatus=$(curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Scans/Sast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" | jq -r '.LatestExecution | {Status} | join(" ")');
echo $scanStatus
while true ; do 
    scanStatus=$(curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Scans/Sast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" | jq -r '.LatestExecution | {Status} | join(" ")');
    if [ "$scanStatus" == "Running" ] || [ "$scanStatus" == "InQueue" ]; then
        echo $scanStatus
    elif [ "$scanStatus" == "Failed" ]; then
        echo $scanStatus
        echo "Scan Failed. Check ASOC logs"
        exit 1
    else
        echo $scanStatus
        break
    fi
    sleep 60
done
