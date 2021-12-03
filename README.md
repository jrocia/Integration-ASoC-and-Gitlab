# Integration AppScan on Cloud (ASoC) and Gitlab
Yaml file and Dockerfile giving ideas in how to integrate ASoC and Gitlab

SAST:
Based in 3 components: 
1 - a Dockerfile to get ASOC command line client inside a container to be used by Gitlab image Pipeline
2 - YAML project file with a scan job to be used in any YAML project file 
3 - Some variable that could be on YAML or be add directly on Gitlab Project (Settings > CI/CD and expand the Variables)

features:
- Downloadable artifact scan report
- Parameterizable Security Gate

Scan Job
![image](https://user-images.githubusercontent.com/69405400/144601178-9bc8c675-a2dd-44c4-a312-908800be1472.png)

Artifact downloadable
![image](https://user-images.githubusercontent.com/69405400/144601700-40bfa642-a776-4e4f-ba05-e96f4324ef19.png)

Security Gate response failing or succeeding build
![image](https://user-images.githubusercontent.com/69405400/144601954-ae41e5ea-a9fa-464b-b931-36cd0887723b.png)
![image](https://user-images.githubusercontent.com/69405400/144602140-3e4320f3-a86c-44a1-93ed-5ad7f5fa3348.png)


````dockerfile
FROM ubuntu:20.04
ENV PATH="/SAClientUtil.8.0.1461/bin:${PATH}"
RUN apt update
RUN apt install -y curl unzip maven openjdk-11-jre gradle && apt clean
RUN curl https://cloud.appscan.com/api/SCX/StaticAnalyzer/SAClientUtil?os=linux > SAClientUtil.zip
RUN unzip SAClientUtil.zip
````

````yaml
image: saclient

# The options to sevSecGw are highIssues, mediumIssues, lowIssues and totalIssues
# maxIssuesAllowed is the amount of issues in selected sevSecGw
# appId is application id located in ASoC 
variables:
  sevSecGw: totalIssues
  maxIssuesAllowed: 200
  appId: xxxxxxxxxxxxxxxxxx
  apiKeyId: xxxxxxxxxxxxxxxxxx
  apiKeySecret: xxxxxxxxxxxxxxxxxx

stages:
- clean
- build
- scan

clean-job:
  stage: clean
  script:
  - gradle clean

build-job:
  stage: build
  script:
  - gradle build

scan-job:
  stage: scan
  script:
  - gradle build
  - appscan.sh prepare
  - appscan.sh api_login -P $apiKeyId -u $apiKeySecret -persist
  - appscan.sh queue_analysis -a $appId >> output.txt
  - cat output.txt
  - scanId=$(sed -n '2p' output.txt)
  - >
    for x in $(seq 1 1000)
      do
        resultScan=$(appscan.sh status -i $scanId)
        echo $resultScan 
        if [ "$resultScan" == "Ready" ]
          then break 
        fi
        sleep 60
      done
  - appscan.sh get_result -i $scanId -t html
  - appscan.sh info -i $scanId > scanStatus.txt
  - highIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NHighIssues":)[^,]*')
  - mediumIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NMediumIssues":)[^,]*')
  - lowIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NLowIssues":)[^,]*')
  - totalIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NIssuesFound":)[^,]*')
  - >
    if [ "$highIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "highIssues" ]
      then
        echo "Security Gate build failed"
        exit 1
    elif [ "$mediumIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "mediumIssues" ]
      then
        echo "Security Gate build failed"
        exit 1
    elif [ "$lowIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "lowIssues" ]
      then
        echo "Security Gate build failed"
        exit 1
    elif [ "$totalIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "totalIssues" ]
      then
        echo "Security Gate build failed"
        exit 1
    fi
  - echo "Security Gate passed"
  
  artifacts:
    paths:
      - "*.html"
````
