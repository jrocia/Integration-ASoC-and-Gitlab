#asocApiKeyId='xxxxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxxxx'
#asocAppName='xxxxxxxxxxxxxxx'
#serviceUrl='xxxxxxxxxxxxxxx'
#assetGroupId='xxxxxxxxxxxxxxx'

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')

if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi

appId=$(curl -s -X GET --header 'Authorization: Bearer '"$asocToken"'' --header 'Accept:application/json' "https://$serviceUrl/api/v4/Apps?%24top=5000&%24filter=Name%20eq%20%27$asocAppName%27&%24select=name%2Cid&%24count=false" | grep -oP '(?<="Id":\ ")[^"]*')
if [ -z "$appId" ]; then
	appId=$(curl -s -X POST --header "Authorization: Bearer $asocToken" --header 'Accept:application/json' --header 'Content-Type: application/json' -d '{"Name":"'"$asocAppName"'","AssetGroupId":"'"$assetGroupId"'","UseOnlyAppPresences":false}' "https://$serviceUrl/api/v4/Apps" | grep -oP '(?<="Id": ")[^"]*' | head -n 1);
	echo "There is no $asocAppName application. It was created. The appId is $appId";
else 
	echo "Application name $asocAppName exist. The appId is $appId."
fi

echo $appId > appId.txt
