#asocApiKeyId='xxxxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxxxx'
#asocAppName='xxxxxxxxxxxxxxx'
#serviceUrl='xxxxxxxxxxxxxxx'
#assetGroupId='xxxxxxxxxxxxxxx'

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://$serviceUrl/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')
if [ -z "$asocToken" ]; then
	echo "The token variable is empty or wrong. Check the API keys.";
    exit 1
fi

assetGroupIdExist=$(curl -k -s -X 'GET' "https://$serviceUrl/api/v4/AssetGroups" -H 'accept: application/json' -H "Authorization: Bearer $asocToken" | grep "$assetGroupId")
if [ -z "$assetGroupIdExist" ]; then
        echo "Asset Group ID does not exist or wrong. Check the Asset Group ID.";
    exit 1
fi

appId=$(curl -s -k -X GET --header 'Authorization: Bearer '"$asocToken"'' --header 'Accept:application/json' "https://$serviceUrl/api/v4/Apps?%24top=5000&%24filter=Name%20eq%20%27$asocAppName%27&%24select=name%2Cid&%24count=false" | grep -oP '(?<="Id":\ ")[^"]*')
if [ -z "$appId" ]; then
	appId=$(curl -s -k -X POST --header "Authorization: Bearer $asocToken" --header 'Accept:application/json' --header 'Content-Type: application/json' -d '{"Name":"'"$asocAppName"'","AssetGroupId":"'"$assetGroupId"'","UseOnlyAppPresences":false}' "https://$serviceUrl/api/v4/Apps" | grep -oP '(?<="Id": ")[^"]*' | head -n 1);
	echo "There is no $asocAppName application. It was created. The appId is $appId";
else 
	echo "Application name $asocAppName exist. The appId is $appId."
fi

if [ -z "$appId" ]; then
        echo "Something went wrong while checking if the application ID exists. Check the ASoC Keys and AssetGroupId variables.";
    exit 1
fi

echo $appId > appId.txt

curl -k -s -X 'GET' "https://$serviceUrl/api/v4/Account/Logout" -H 'accept: */*' -H "Authorization: Bearer $asocToken"
