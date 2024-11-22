#!/bin/bash
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><Configuration enableSecrets=\"true\" sourceCodeOnly=\"true\" staticAnalysisOnly=\"true\"><Targets><Target path=\"$PWD\"></Target></Targets></Configuration>" > appscan-config.xml
diffFilesList=$(git diff --name-only HEAD HEAD~1)
readarray -t diffFiles <<< "$diffFilesList"
for i in ${diffFiles[@]}; do sed -i "s|\(</Target>\)|<Include>$i</Include>\1|" appscan-config.xml; done
