#!/bin/bash

. ./setenv.sh # should set RMT_REPO_ID, RMT_REPO_URL, AWS_KEY_ID, AWS_KEY

LOCAL_REPO=$HOME/.m2/repository

while IFS=: read g a p v; do
    artifact=$g:$a:$v:$p
    echo "Processing $artifact..."
    mvn dependency:get -Dartifact=$artifact

    # mvn deploy:deploy-file fails if file is inside local repo, copying to /tmp.
    fpath=$LOCAL_REPO/${g//.//}/$a/$v
    f=$a-$v
    echo "Deploying $f.$p"
    if [ $p = "jar" ]; then 
        cp -f $fpath/$f.jar $fpath/$f.pom /tmp
        mvn deploy:deploy-file -DpomFile=/tmp/$f.pom -Dfile=/tmp/$f.jar -DrepositoryId=$RMT_REPO_ID -Durl=$RMT_REPO_URL -Daws.accessKeyId=$AWS_KEY_ID -Daws.secretKey=$AWS_KEY
        rm -f /tmp/$f.jar /tmp/$f.pom
    elif [ $p == "pom" ]; then
        cp -f $fpath/$f.pom /tmp
        mvn deploy:deploy-file -Dfile=/tmp/$f.pom -DgroupId=$g -DartifactId=$a -Dversion=$v -DrepositoryId=$RMT_REPO_ID -Durl=$RMT_REPO_URL -Daws.accessKeyId=$AWS_KEY_ID -Daws.secretKey=$AWS_KEY
        rm -f /tmp/$f.pom
    else
        echo "WARNING: do not know what to do with $p packaging, skipping"
    fi
done < <(mvn dependency:collect -DincludeParents | grep -o '\s\{4\}[^:]\+\(:[^:]\+\)\{3\}' | sed 's/^ *//g')

