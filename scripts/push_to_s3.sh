#!/usr/bin/env bash

echo ""
echo "*** PUSH BUNDLE TO S3 ***"
echo "Copying files to s3://$1"
echo ""

aws s3 sync --delete ./build/ s3://$1
