# Get summary scan and give it to Security Gateway decision
scanId=$(cat scanId.txt)
appscan.sh info -i $scanId > scanStatus.txt
highIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NHighIssues":)[^,]*')
mediumIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NMediumIssues":)[^,]*')
lowIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NLowIssues":)[^,]*')
totalIssues=$(cat scanStatus.txt | grep LatestExecution | grep -oP '(?<="NIssuesFound":)[^,]*')
echo "There is $highIssues high issues, $mediumIssues medium issues and $lowIssues low issues."
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
echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
 echo "Security Gate passed"
