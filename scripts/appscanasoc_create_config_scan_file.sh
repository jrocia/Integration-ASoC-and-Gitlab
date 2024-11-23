#!/bin/bash
# scanLatestCommitFiles: 'no'

if [[ -z "$scanLatestCommitFiles" || ( "$scanLatestCommitFiles" != "yes" && "$scanLatestCommitFiles" != "no" ) ]]; then
  echo "The variable scanLatestCommitFiles must be 'yes' or 'no', and it cannot be empty."
  exit 1
fi

if [ "$scanLatestCommitFiles" = 'yes' ]; then
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><Configuration enableSecrets=\"true\" sourceCodeOnly=\"true\" staticAnalysisOnly=\"true\"><Targets><Target path=\"$PWD\"></Target></Targets></Configuration>" > appscan-config.xml
  echo "Only these files will be scanned:"
  echo $(git diff --name-only HEAD HEAD~1)
  diffFilesList=$(git diff --name-only HEAD HEAD~1)
  readarray -t diffFiles <<< "$diffFilesList"
  for i in ${diffFiles[@]}; do sed -i "s|\(</Target>\)|<Include>$i</Include>\1|" appscan-config.xml; done
else
  echo "All files in the repository will be scanned."
fi
