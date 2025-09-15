#asocApiKeyId='xxxxxxxxxxxxx'
#asocApiKeySecret='xxxxxxxxxxxxx'
#serviceUrl='cloud.appscan.com'
#scanName=$CI_PROJECT_NAME-$CI_JOB_ID

appId=$(cat appId.txt)
echo "Sca" > scanTech.txt

# Downloading and preparing SAClientUtil
if ! [ -x "$(command -v appscan.sh)" ]; then
  echo 'appscan.sh is not installed.' >&2
  curl -k -s "https://$serviceUrl/api/v4/Tools/SAClientUtil?os=linux" > $HOME/SAClientUtil.zip
  unzip $HOME/SAClientUtil.zip -d $HOME > /dev/null
  rm -f $HOME/SAClientUtil.zip
  mv $HOME/SAClientUtil.* $HOME/SAClientUtil
  export PATH="$HOME/SAClientUtil/bin:${PATH}"
fi

if [ "${considerPkgManager,,}" = "no" ]; then
    echo "Package manager being disregarded (-nc parameter)."
    appscan.sh prepare_sca -nc
else
    echo "Package manager being considered (default behavior)."
    appscan.sh prepare_sca
fi

# Authenticate in ASOC
appscan.sh api_login -u $asocApiKeyId -P $asocApiKeySecret -persist

# Upload IRX file to ASOC to be analyzed and receive scanId
scanName=$CI_PROJECT_NAME-$CI_JOB_ID
appscan.sh queue_analysis -a $appId -n $scanName > output.txt
scanId=$(sed -n '3p' output.txt)
echo "$scanId" > scanId.txt
echo "The scan name is $scanName and scanId is $scanId"

# Check Scan Status
resultScan=$(appscan.sh status -i $scanId)
  while true ; do
    resultScan=$(appscan.sh status -i $scanId)
    echo $resultScan
    if [ "$resultScan" != "Running" ]
      then break
    fi
    sleep 60
  done

# Get report from ASOC
appscan.sh get_report -i $scanId -s scan -t security
appscan.sh get_report -i $scanId -s scan -t license
