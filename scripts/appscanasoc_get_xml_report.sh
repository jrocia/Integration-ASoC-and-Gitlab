#asocApiKeyId='xxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxx'
#serviceUrl='cloud.appscan.com'

scanId=$(cat scanId.txt)

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')

if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi

# Request the report

reportId=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' --header "Authorization:Bearer $asocToken" -d '{"Configuration":{"Summary":true,"Details":true,"Discussion":true,"Overview":true,"TableOfContent":true,"Articles":true,"History":true,"Coverage":true,"MinimizeDetails":true,"ReportFileType":"XML","Title":"","Notes":"","Locale":"en"},"OdataFilter":"","ApplyPolicies":"None"}' "https://$serviceUrl/api/v4/Reports/Security/Scan/$scanId" | grep -oP '(?<="Id":\ ")[^"]*')

echo "Report requested. The report id is $reportId."

while true ; do
    reportStatus=$(curl -k -s -X GET --header 'Accept:text/xml' --header "Authorization:Bearer $asocToken" "https://$serviceUrl/api/v4/Reports/$reportId/Download" | grep -oP '(?<="Message":\ ")[^"]*')
    if [ "$reportStatus" == "Report is not available" ]; then
        echo "Report being generated."
        sleep 30
    else
        echo "Report ready."
        break
    fi
done

scanTech=$(cat scanTech.txt)
if [[ $scanTech == 'Sast' ]]; then
    curl -k -s -X GET --header 'Accept:text/xml' --header "Authorization:Bearer $asocToken" "https://$serviceUrl/api/v4/Reports/$reportId/Download" > SAST_report.xml
elif [[ $scanTech == 'Dast' ]]; then
    curl -k -s -X GET --header 'Accept:text/xml' --header "Authorization:Bearer $asocToken" "https://$serviceUrl/api/v4/Reports/$reportId/Download" > DAST_report.xml
elif [[ $scanTech == 'Sca' ]]; then
    curl -k -s -X GET --header 'Accept:text/xml' --header "Authorization:Bearer $asocToken" "https://$serviceUrl/api/v4/Reports/$reportId/Download" > SCA_report.xml
else
    echo "Scan technology not identified. XML Report not generated."
    exit 1
fi

curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Account/Logout" -H 'accept: */*' -H "Authorization: Bearer $asocToken"
