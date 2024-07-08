#asocApiKeyId='xxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxx'
#serviceUrl='xxxxxxxxxxxxx'
#sevSecGw='xxxxxxxxxxxxx'
#maxIssuesAllowed=xxxxxxxxxxxxx

scanId=$(cat scanId.txt)

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')

if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi

scanTech=$(cat scanTech.txt)
if [[ $scanTech == 'Sast' ]]; then
    curl -k -s -X GET "https://cloud.appscan.com/api/v4/Scans/Sast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" > scanResult.txt
elif [[ $scanTech == 'Dast' ]]; then
    curl -k -s -X GET "https://cloud.appscan.com/api/v4/Scans/Dast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" > scanResult.txt
else
    echo "Scan technology not identified."
    exit 1
fi

criticalIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NCriticalIssues} | join(" ")')
highIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NHighIssues} | join(" ")')
mediumIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NMediumIssues} | join(" ")')
lowIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NLowIssues} | join(" ")')
totalIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NIssuesFound} | join(" ")')
echo "There is $criticalIssues critical issues, $highIssues high issues, $mediumIssues medium issues and $lowIssues low issues"

if [[ "$criticalIssues" -gt "$maxIssuesAllowed" ]] && [[ "$sevSecGw" == "criticalIssues" ]]; then
    echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
    echo "Security Gate build failed"
    exit 1
elif [[ "$highIssues" -gt "$maxIssuesAllowed" ]] && [[ "$sevSecGw" == "highIssues" ]]; then
    echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
    echo "Security Gate build failed"
    exit 1
elif [[ "$mediumIssues" -gt "$maxIssuesAllowed" ]] && [[ "$sevSecGw" == "mediumIssues" ]]; then
    echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
    echo "Security Gate build failed"
    exit 1
elif [[ "$lowIssues" -gt "$maxIssuesAllowed" ]] && [[ "$sevSecGw" == "lowIssues" ]]; then
    echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
    echo "Security Gate build failed"
    exit 1
elif [[ "$totalIssues" -gt "$maxIssuesAllowed" ]] && [[ "$sevSecGw" == "totalIssues" ]]; then
    echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
    echo "Security Gate build failed"
    exit 1
fi
echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
echo "Security Gate passed"
