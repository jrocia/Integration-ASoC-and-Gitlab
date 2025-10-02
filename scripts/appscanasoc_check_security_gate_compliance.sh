#asocApiKeyId='xxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxx'
#serviceUrl='xxxxxxxxxxxxx'
#asocAppName='xxxxxxxxxxxxx'

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')
if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi
appData=$(curl -s -k -X GET --header 'Authorization: Bearer '"$asocToken"'' --header 'Accept:application/json' "https://$serviceUrl/api/v4/Apps?%24filter=Name%20eq%20%27$asocAppName%27")
echo "--------------Compliance Policies---------------" 
appCompliances=$(echo $appData | jq -r '.Items[0].ComplianceStatuses[] | "Enabled: \(.Enabled) | Compliant: \(.Compliant) | Name: \(.Name)"')
echo "$appCompliances"
compliance_count=$(echo "$appData" | jq '.Items[0].ComplianceStatuses | length')
for ((i=0; i<$compliance_count; i++)); do
    name=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].Name")
    enabled=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].Enabled")
    compliant=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].Compliant")
    complianceId=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].PolicyId")
    appId=$(echo "$appData" | jq -r ".Items[0].Id")

    if [[ "$enabled" == "true" && "$compliant" == "false" ]]; then
        issuesNoCompliance=$(curl -s -k -X GET --header 'Authorization: Bearer '"$asocToken"'' --header 'Accept:application/json' "https://$serviceUrl/api/v4/Issues/Application/$appId?selectPolicyIds=$complianceId&applyPolicies=Select&select=Severity,IssueType,Location,Id")
        issue_count=$(echo "$issuesNoCompliance" | jq '.Items | length')
        echo "----------------New Issues Found-----------------" 
        echo "This scan found $issue_count new issues." 
            for ((i=0; i<$issue_count; i++)); do
                issueSeverity=$(echo "$issuesNoCompliance" | jq -r ".Items[$i].Severity")
                issueType=$(echo "$issuesNoCompliance" | jq -r ".Items[$i].IssueType")
            	issueLocation=$(echo "$issuesNoCompliance" | jq -r ".Items[$i].Location")
                issueId=$(echo "$issuesNoCompliance" | jq -r ".Items[$i].Id")
                echo "------------------New Issue---------------------"                
                echo "Issue Id : $issueId"
                echo "Issue Sev: $issueSeverity"
                echo "Issue Typ: $issueType"
                echo "Issue Loc: $issueLocation"
            done
        echo "------------------------------------------------" 
    	echo -e "\033[31mThe application is not in compliance with Enterprise policies.\033[0m"
        exit 1
    fi
done
echo "The application is compliance with Enterprise policies."
curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Account/Logout" -H 'accept: */*' -H "Authorization: Bearer $asocToken"
