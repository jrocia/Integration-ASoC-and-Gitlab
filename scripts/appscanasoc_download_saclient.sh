#!/bin/bash

curl https://cloud.appscan.com/api/SCX/StaticAnalyzer/SAClientUtil?os=linux > $HOME/SAClientUtil.zip
unzip $HOME/SAClientUtil.zip -d $HOME
rm -f $HOME/SAClientUtil.zip
mv $HOME/SAClientUtil.* $HOME/SAClientUtil
echo 'export PATH="$HOME/SAClientUtil/bin:${PATH}"' >> ~/.bashrc
source ~/.bashrc
