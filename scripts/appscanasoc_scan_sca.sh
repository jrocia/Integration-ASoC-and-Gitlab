# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
