#apt update
#apt upgrade -y
#apt install apt-utils
#curl -fsSL https://get.docker.com | sh

appId=$(cat appId.txt)
export PATH="$HOME/SAClientUtil/bin:${PATH}"

appscan.sh prepare_sca -image $image

# Authenticate in ASOC
appscan.sh api_login -u $asocApiKeyId -P $asocApiKeySecret -persist

# Upload IRX file to ASOC to be analyzed and receive scanId
scanName=$CI_PROJECT_NAME-$CI_JOB_ID
appscan.sh queue_analysis -a $appId -n $scanName > output.txt
scanId=$(sed -n '2p' output.txt)
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
appscan.sh get_report -i $scanId -s scan -t licenses
