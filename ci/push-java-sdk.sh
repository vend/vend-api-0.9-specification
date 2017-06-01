#!/bin/bash

set -e

DIR=$(dirname "$0")
packageVersion=$( cat ./swagger-codegen-config/java.json | jq -r ".artifactVersion" )

echo "Going to update Java SDK..."

eval "$(ssh-agent -s)"
chmod 600 $DIR/id_rsa
ssh-add $DIR/id_rsa

git clone git@github.com:vend/vend-api-0.9-java-sdk.git
cd vend-api-0.9-java-sdk

RELEASE_BRANCH=release/$packageVersion
if [ `git branch -r | grep "${RELEASE_BRANCH}"` ];
then
    git checkout $RELEASE_BRANCH
else
    git checkout -b $RELEASE_BRANCH
    git push -u origin $RELEASE_BRANCH
fi

if [ "${TRAVIS_BRANCH}" = "master" ];
then
    BRANCH_NAME=$RELEASE_BRANCH
else
    BRANCH_NAME=travis-ci/$TRAVIS_BRANCH
    if [ `git branch -r | grep "${BRANCH_NAME}"` ];
    then
        git checkout $BRANCH_NAME
    else
        git checkout -b $BRANCH_NAME
    fi
fi

echo "Copying files..."
rm -rf docs src/main
cp -r ../swagger-codegen-out/java/docs .
cp -r ../swagger-codegen-out/java/src/main ./src/
rm ./src/main/AndroidManifest.xml
cp ../swagger-codegen-out/java/build.gradle .
cp ../swagger-codegen-out/java/build.sbt .
cp ../swagger-codegen-out/java/gradle.properties .
cp ../swagger-codegen-out/java/pom.xml .
cp ../swagger-codegen-out/java/settings.gradle .
cp ../swagger-codegen-out/java/README.md .

git add --all .
git commit -m "From vend-api-0.9-specification: ${TRAVIS_COMMIT_MESSAGE}"
git push -u origin $BRANCH_NAME
