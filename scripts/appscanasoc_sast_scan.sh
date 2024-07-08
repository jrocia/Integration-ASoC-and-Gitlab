#asocApiKeyId='xxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxx'
#serviceUrl='cloud.appscan.com'
#scanName=$CI_PROJECT_NAME-$CI_JOB_ID

appId=$(cat appId.txt)

# Downloading and preparing SAClientUtil
curl https://cloud.appscan.com/api/SCX/StaticAnalyzer/SAClientUtil?os=linux > $HOME/SAClientUtil.zip
unzip $HOME/SAClientUtil.zip -d $HOME > /dev/null
rm -f $HOME/SAClientUtil.zip
mv $HOME/SAClientUtil.* $HOME/SAClientUtil
export PATH="$HOME/SAClientUtil/bin:${PATH}"

# Generate IRX files based on source root folder downloaded by Gitlab
appscan.sh prepare
# Authenticate in ASOC
appscan.sh api_login -u $asocApiKeyId -P $asocApiKeySecret -persist

# Upload IRX file to ASOC to be analyzed and receive scanId
appscan.sh queue_analysis -a $appId -n $scanName > output.txt
scanId=$(sed -n '2p' output.txt)
echo "The scan name is $scanName and scanId is $scanId"
echo $scanId > scanId.txt

# Check Scan Status
resultScan=$(appscan.sh status -i $scanId)
while true ; do 
    resultScan=$(appscan.sh status -i $scanId)
    echo $resultScan
        if [ "$resultScan" != "Running" ]; then 
            break
        fi
    sleep 60
done
