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

#appOverallCompliance=$(echo $appData | jq '.Items[0].OverallCompliance')
#echo "$appOverallCompliance"

appCompliances=$(echo $appData | jq -r '.Items[0].ComplianceStatuses[] | "Enabled: \(.Enabled) | Name: \(.Name) | Compliant: \(.Compliant)"')
echo "$appCompliances"

compliance_count=$(echo "$appData" | jq '.Items[0].ComplianceStatuses | length')

for ((i=0; i<$compliance_count; i++)); do
    name=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].Name")
    enabled=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].Enabled")
    compliant=$(echo "$appData" | jq -r ".Items[0].ComplianceStatuses[$i].Compliant")
    if [[ "$enabled" == "true" && "$compliant" == "false" ]]; then
        echo "The application is not in compliance with Enterprise policies."
        exit 1
    fi
done
echo "The application is compliance with Enterprise policies."
curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Account/Logout" -H 'accept: */*' -H "Authorization: Bearer $asocToken"
