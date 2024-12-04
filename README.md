# Integration: AppScan on Cloud (ASoC) and Gitlab
Yaml file and Dockerfile giving ideas in how to integrate ASoC and Gitlab

Scan Job
![image](https://user-images.githubusercontent.com/69405400/144601178-9bc8c675-a2dd-44c4-a312-908800be1472.png)

Artifact downloadable
![image](https://user-images.githubusercontent.com/69405400/144601700-40bfa642-a776-4e4f-ba05-e96f4324ef19.png)

Security Gate response failing or succeeding build
![image](https://user-images.githubusercontent.com/69405400/144601954-ae41e5ea-a9fa-464b-b931-36cd0887723b.png)
![image](https://user-images.githubusercontent.com/69405400/144602140-3e4320f3-a86c-44a1-93ed-5ad7f5fa3348.png)


<b><h1>SAST:</b></h1><br>
Based in 3 components:<br>
1 - a Dockerfile to generate a image container where download ASOC command line client and some tools to be used by Gitlab image Pipeline<br>
2 - YAML project file with a scan job to be used in a YAML project file<br>
3 - some variable that could be on YAML project file or be add directly on Gitlab Project (Settings > CI/CD and expand the Variables)<br>

Dockerfile to generate a docker image with SAClient:</br> 
docker build -t saclient .
````dockerfile
FROM ubuntu:latest
ENV PATH="$HOME/SAClientUtil/bin:${PATH}"
RUN apt update
RUN apt install -y curl unzip maven openjdk-11-jre gradle && apt clean
RUN curl https://cloud.appscan.com/api/SCX/StaticAnalyzer/SAClientUtil?os=linux > $HOME/SAClientUtil.zip
RUN unzip $HOME/SAClientUtil.zip -d $HOME
RUN rm -f $HOME/SAClientUtil.zip
RUN mv $HOME/SAClientUtil.* $HOME/SAClientUtil
````

Gitlab YAML file to run SAST analyzes:
````yaml
image: saclient

# The options to sevSecGw are highIssues, mediumIssues, lowIssues and totalIssues
# maxIssuesAllowed is the amount of issues in selected sevSecGw
# appId is application id located in ASoC 
variables:
  asocApiKeyId: xxxxxxxxxxxxxxxxxx
  asocApiKeySecret: xxxxxxxxxxxxxxxxxx
  appId: xxxxxxxxxxxxxxxxxx
  sevSecGw: totalIssues
  maxIssuesAllowed: 200

stages:
- clean
- build
- scan-sast

clean-job:
  stage: clean
  script:
  - gradle clean

build-job:
  stage: build
  script:
  - gradle build

scan-job:
  stage: scan-sast
  script:
  - gradle build
  # Generate IRX files based on source root folder downloaded by Gitlab
  - appscan.sh prepare
  # Authenticate in ASOC
  - appscan.sh api_login -u $asocApiKeyId -P $asocApiKeySecret -persist
  # Upload IRX file to ASOC to be analyzed and receive scanId
  - scanName=$CI_PROJECT_NAME-$CI_JOB_ID
  - appscan.sh queue_analysis -a $appId -n $scanName > output.txt
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
````

<b><h1>DAST:</b></h1><br>
Based in 2 components:<br>
1 - YAML project file with a scan job to be used in a YAML project file.<br>
2 - some variable that could be on YAML project file or be add directly on Gitlab Project (Settings > CI/CD and expand the Variables)<br>

Gitlab YAML file to run DAST analyzes:
````yaml
# The options to sevSecGw are highIssues, mediumIssues, lowIssues and totalIssues.
# maxIssuesAllowed is the amount of issues in selected sevSecGw.
# appId is application id located in ASoC.
# appscanPresenceId is AppScan Presence ID that will be used to reach out URL.
# If there is login.dast.config and manualexplorer.dast.config in repository it will be uploaded and used in Scan otherwise will be ignored.
variables:
  asocApiKeyId: 'xxxxxxxxxxxxxxxx'
  asocApiKeySecret: 'xxxxxxxxxxxxxxxx'
  asocAppName: $CI_PROJECT_NAME
  serviceUrl: 'cloud.appscan.com'
  assetGroupId: 'xxxxxxxxxxxxxxxx'
  scanName: $CI_PROJECT_NAME-$CI_JOB_ID
  urlTarget: 'https://demo.testfire.net?mode=demo'
  loginDastConfig: 'login.dast.config'
  manualExplorerDastConfig: 'manualexplorer.dast.config'
  appscanPresenceId: ''
  sevSecGw: 'criticalIssues'
  maxIssuesAllowed: 100

include:
  - remote: 'https://raw.githubusercontent.com/jrocia/Integration-ASoC-and-Gitlab/main/yaml/appscanasoc_scan_dast.yaml'

stages:
- scan-dast

scan-job:
  stage: scan-dast
````
