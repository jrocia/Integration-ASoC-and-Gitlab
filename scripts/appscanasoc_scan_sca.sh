appId=$(cat appId.txt)
export PATH="$HOME/SAClientUtil/bin:${PATH}"

#apt install docker.io
curl https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar xvz -C /tmp/ && mv /tmp/docker/docker /usr/bin/docker
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
