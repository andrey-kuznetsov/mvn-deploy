#!/bin/bash

. ./setenv.sh # should set RMT_REPO_ID, RMT_REPO_URL, AWS_KEY_ID, AWS_KEY

LOCAL_REPO=$HOME/.m2/repository

while IFS=: read g a p v; do
    gav=$g:$a:$v
    echo "Processing $gav..."
    if [ $p = "jar" ]; then 
        echo "Resolving $gav"
        mvn dependency:get -Dartifact=$gav

        # mvn deploy:deploy-file fails if file is inside local repo, copying to /tmp.
        fpath=$LOCAL_REPO/${g//.//}/$a/$v
        f=$a-$v
        cp -f $fpath/$f.jar $fpath/$f.pom /tmp
        echo "Deploying $f.jar"
        mvn deploy:deploy-file -DpomFile=/tmp/$f.pom -Dfile=/tmp/$f.jar -DrepositoryId=$RMT_REPO_ID -Durl=$RMT_REPO_URL -Daws.accessKeyId=$AWS_KEY_ID -Daws.secretKey=$AWS_KEY
        rm -f /tmp/$f.jar /tmp/$f.pom
    else
        echo "WARNING: do not know what to do with $p packaging."
    fi
done < <(mvn dependency:collect | grep -o '\s\{4\}\([^:]*:\)\{4\}' | sed 's/^ *//g')

