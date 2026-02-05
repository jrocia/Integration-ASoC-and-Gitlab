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
    curl -k -s -X GET "https://$serviceUrl/api/v4/Scans/Sast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" > scanResult.txt
elif [[ $scanTech == 'Dast' ]]; then
    curl -k -s -X GET "https://$serviceUrl/api/v4/Scans/Dast/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" > scanResult.txt
elif [[ $scanTech == 'Sca' ]]; then
    curl -k -s -X GET "https://$serviceUrl/api/v4/Scans/Sca/$scanId" -H 'accept:application/json' -H "Authorization:Bearer $asocToken" > scanResult.txt
else
    echo "Scan technology not identified."
    exit 1
fi

criticalIssues=0
highIssues=0
mediumIssues=0
lowIssues=0
totalIssues=0

criticalIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NCriticalIssues} | join(" ")')
highIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NHighIssues} | join(" ")')
mediumIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NMediumIssues} | join(" ")')
lowIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NLowIssues} | join(" ")')
totalIssues=$(cat scanResult.txt | jq -r '.LatestExecution | {NIssuesFound} | join(" ")')
echo "There is $criticalIssues critical issues, $highIssues high issues, $mediumIssues medium issues and $lowIssues low issues"

if [["$scanName" == *feature*]]; then
    echo "Branch type: feature"
    if [[$criticalIssues gt 0]]; then
        echo "ERROR: FEATURE branch must not contain CRITICAL vulnerabilities."
        exit 1
    fi     

elif [[ "$scanName" == *qa* ]]; then
    echo "Branch type: qa"
    if [[ $criticalIssues -gt 0 || $highIssues -gt 0 ]]; then
        echo "ERROR: QA branch must not contain CRITICAL or HIGH vulnerabilities."
        exit 1
    fi

elif [[ "$scanName" == *release* ]]; then
    echo "Branch type: release"
    if [[ $criticalIssues -gt 0 || $highIssues -gt 0 || $mediumIssues -gt 0 ]]; then
        echo "ERROR: RELEASE branch must not contain CRITICAL, HIGH or MEDIUM vulnerabilities."
        exit 1
    fi
else
    echo "Branch type: unknown (no security gate applied)"
fi

echo "Security Gate passed"

curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Account/Logout" -H 'accept: */*' -H "Authorization: Bearer $asocToken"
