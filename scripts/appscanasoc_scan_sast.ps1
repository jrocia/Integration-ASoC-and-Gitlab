# Requirement: Gitlab-runner running in a Windows Server, SAClientUtil deployed and folder bin in Windows System PATH

variables:
  apiKeyId: xxxxxxxxxxxxxxxxxxx
  apiKeySecret: xxxxxxxxxxxxxxxxxxx
  appId: xxxxxxxxxxxxxxxxxxx
  sevSecGw: totalIssues
  maxIssuesAllowed: 200

stages:
- scan-sast

scan-job:
  stage: scan-sast
  script:
  # Generate IRX files based on source root folder downloaded by Gitlab
  - appscan prepare
  # Authenticate in ASOC
  - appscan api_login -u $apiKeyId -P $apiKeySecret -persist
  # Upload IRX file to ASOC to be analyzed and receive scanId
  - scanName=$CI_PROJECT_NAME-$CI_JOB_ID
  - appscan queue_analysis -a $appId -n $scanName > output.txt
  - scanId=$(sed -n '2p' output.txt)
  - echo "The scan name is $scanName and scanId is $scanId"
  # Check Scan Status
  - resultScan=$(appscan.sh status -i $scanId)
  - >
    while true ; do 
      resultScan=$(appscan.sh status -i $scanId)
      echo $resultScan
      if [ "$resultScan" != "Running" ]
        then break
      fi
      sleep 60
    done
  # Get report from ASOC
  - appscan.sh get_result -i $scanId -t html
  # Get summary scan and give it to Security Gateway decision
  - appscan.sh info -i $scanId > scanStatus.txt
  - highIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NHighIssues":)[^,]*')
  - mediumIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NMediumIssues":)[^,]*')
  - lowIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NLowIssues":)[^,]*')
  - totalIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NIssuesFound":)[^,]*')
  - echo "There is $highIssues high issues, $mediumIssues medium issues and $lowIssues low issues."
  - >
    if [ "$highIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "highIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    elif [ "$mediumIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "mediumIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    elif [ "$lowIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "lowIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    elif [ "$totalIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "totalIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    fi
  - echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
  - echo "Security Gate passed"
  
  artifacts:
    when: always
    paths:
      - "*.html"
