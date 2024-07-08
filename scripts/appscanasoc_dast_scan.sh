#asocApiKeyId='xxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxx'
#serviceUrl='cloud.appscan.com'
#urlTarget='xxxxxxxxxxx'
#loginDastConfig='login.dast.config'
#manualExplorerDastConfig='manualexplorer.dast.config'
#appscanPresenceId='xxxxxxxxxxx'
#scanName=$CI_PROJECT_NAME-$CI_JOB_ID

appId=$(cat appId.txt)
echo "Dast" > scanTech.txt

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')

if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi

# Check if there is login file in root repository folder and upload to ASoC
if [ -f "$loginDastConfig" ]; then
    loginDastConfigId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/FileUpload" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:multipart/form-data' -F "uploadedFile=@$loginDastConfig" | grep -oP '(?<="FileId":\ ")[^"]*');
    echo "$loginDastConfig exist. So it will be uploaded to ASoC and will be used to Authenticate in the URL target during tests. Login file id is $loginDastConfigId.";
else
    echo "Login file not identified.";
fi

  # Check if there is manual explorer file in root repository folder and upload to ASoC  
if [ -f "$manualExplorerDastConfig" ]; then
    manualExplorerDastConfigId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/FileUpload" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:multipart/form-data' -F "uploadedFile=@$manualExplorerDastConfig" | grep -oP '(?<="FileId":\ ")[^"]*');
    echo "$manualExplorerDastConfig file exist. So it will be uploaded to ASoC and will be used to navigate in the URL target during tests. Manual Explorer file id is $manualExplorerDastConfigId.";
else
    echo "Manual Explorer file not identified.";
fi

# Start scan. If there is manual explorer file, start the scan  in test only mode otherwise full scan
if [[ -n $appscanPresenceId ]]; then
    echo "Scanning a private url."
    if [ -f $manualExplorerDastConfig ] && [ -f $loginDastConfig ]; then
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":true,"ExploreItems":[{"FileId":"'"$manualExplorerDastConfigId"'","MultiStep":false}],"LoginSequenceFileId":"'"$loginDastConfigId"'","PresenceId":"'"$appscanPresenceId"'","ScanName":"'"DAST $scanName $urlTarget"'","EnableMailNotification":false,"Locale":"en","AppId":"'"$appId"'","ClientType":"user-site","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}' | jq -r '. | {Id} | join(" ")');
        echo "Scan started with Manual Explorer and Login Sequence using Test Only mode, scanId $scanId";
    elif [ -f $manualExplorerDastConfig ]; then
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":true,"ExploreItems":[{"FileId":"'"$manualExplorerDastConfigId"'","MultiStep":false}],"PresenceId":"'"$appscanPresenceId"'","ScanName":"'"DAST $scanName $urlTarget"'","EnableMailNotification":false,"Locale":"en","AppId":"'"$appId"'","Personal":false,"ClientType":"user-site","EnablementMessage":"","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}' | jq -r '. | {Id} | join(" ")');
        echo "Scan started with Manual Explorer and Test Only mode, scanId $scanId";
    elif [ -f $loginDastConfig ]; then
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":false,"ExploreItems":[],"LoginSequenceFileId":"'"$loginDastConfigId"'","PresenceId":"'"$appscanPresenceId"'","ScanName":"'"DAST $scanName $urlTarget"'","Locale":"en","AppId":"'"$appId"'","ClientType":"user-site","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}'| jq -r '. | {Id} | join(" ")');
        echo "Scan started with a Login sequence, scanId $scanId";
    else
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":false,"ExploreItems":[],"PresenceId":"'"$appscanPresenceId"'","ScanName":"'"DAST $scanName $urlTarget"'","Locale":"en","AppId":"'"$appId"'","ClientType":"user-site","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}'| jq -r '. | {Id} | join(" ")');
        echo "Scan started, scanId $scanId";
    fi
else
    echo "Scanning a public url."
    if [ -f $manualExplorerDastConfig ] && [ -f $loginDastConfig ]; then
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":true,"ExploreItems":[{"FileId":"'"$manualExplorerDastConfigId"'","MultiStep":false}],"LoginSequenceFileId":"'"$loginDastConfigId"'","ScanName":"'"DAST $scanName $urlTarget"'","EnableMailNotification":false,"Locale":"en","AppId":"'"$appId"'","ClientType":"user-site","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}' | jq -r '. | {Id} | join(" ")');
        echo "Scan started with Manual Explorer and Login Sequence using Test Only mode, scanId $scanId";
    elif [ -f $manualExplorerDastConfig ]; then
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":true,"ExploreItems":[{"FileId":"'"$manualExplorerDastConfigId"'","MultiStep":false}],"ScanName":"'"DAST $scanName $urlTarget"'","EnableMailNotification":false,"Locale":"en","AppId":"'"$appId"'","Personal":false,"ClientType":"user-site","EnablementMessage":"","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}' | jq -r '. | {Id} | join(" ")');
        echo "Scan started with Manual Explorer and Test Only mode, scanId $scanId";
    elif [ -f $loginDastConfig ]; then
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":false,"ExploreItems":[],"LoginSequenceFileId":"'"$loginDastConfigId"'","ScanName":"'"DAST $scanName $urlTarget"'","Locale":"en","AppId":"'"$appId"'","ClientType":"user-site","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}'| jq -r '. | {Id} | join(" ")');
        echo "Scan started with a Login sequence, scanId $scanId";
    else
        scanId=$(curl -k -s -X 'POST' "https://$serviceUrl/api/v4/Scans/Dast" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" -H 'Content-Type:application/json' -d  '{"ScanConfiguration":{"Target":{"StartingUrl":"'"$urlTarget"'","ShouldScanBelowThisDirectory":false,"UseCaseSensitivePaths":false,"AdditionalDomains":[]},"Tests":{"TestPolicy":"Default.policy","TestOptimizationLevel":"Fast","TestLoginPages":false,"TestLoginPagesWithoutSessionIds":false,"TestLogoutPages":false},"Communication":{"ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":10,"MaxRequestsTimeFrame":1000},"ApplicationElements":{"EnableAutomaticFormFill":true}},"TestOnly":false,"ExploreItems":[],"ScanName":"'"DAST $scanName $urlTarget"'","Locale":"en","AppId":"'"$appId"'","ClientType":"user-site","FullyAutomatic":false,"Execute":true,"Recurrence":{"Rule":null,"StartDate":null,"EndDate":null}}'| jq -r '. | {Id} | join(" ")');
        echo "Scan started, scanId $scanId";
    fi
fi

echo $scanId > scanId.txt

  # Check status scan and keep it in loop until Ready status.
scanStatus=$(curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Scans/Dast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" | jq -r '.LatestExecution | {Status} | join(" ")');
echo $scanStatus

while true ; do 
    scanStatus=$(curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Scans/Dast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" | jq -r '.LatestExecution | {Status} | join(" ")');
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
