#!/bin/sh

dir='muplayer'
if [ $1 ]; then
    dir=$1
fi

git clone https://github.com/Baidu-Music-FE/muplayer.git $dir

cd $dir

npm install

command -v bower >/dev/null 2>&1 || { npm install -g bower; exit 1; }
bower install

grunt
