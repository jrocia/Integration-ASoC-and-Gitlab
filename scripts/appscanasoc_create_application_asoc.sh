#asocApiKeyId=xxxxxxxxxxxxxxx
#asocApiKeySecret=xxxxxxxxxxxxxxxx
#asocAppName=xxxxxxxxxxxx

asocToken=$(curl -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"${asocApiKeyId}"'","KeySecret":"'"${asocApiKeySecret}"'"}' 'https://cloud.appscan.com/api/V2/Account/ApiKeyLogin' | grep -oP '(?<="Token":")[^"]*')


appId=$(curl -s -X GET --header 'Authorization: Bearer '"${asocToken}"'' --header 'Accept:application/json' 'https://cloud.appscan.com/api/v4/Apps?%24top=5000&%24filter=Name%20eq%20%27'"${asocAppName}"'%27&%24select=name%2Cid&%24count=false' | grep -oP '(?<="Id": ")[^"]*')

echo "$appId"

if [ -z "$appId" ]; then
	appId=$(curl -s -X POST --header "Authorization: Bearer ${asocToken}" --header 'Accept:application/json' --header 'Content-Type: application/json' -d '{"Name":"'"${asocAppName}"'","AssetGroupId":"dfc34b60-f178-4739-83d3-335066ff30ad","UseOnlyAppPresences":false}' 'https://cloud.appscan.com/api/v4/Apps' | grep -oP '(?<="Id": ")[^"]*' | head -n 1);
	echo "App was created $appId";
fi

echo $appId >> appId.txt
