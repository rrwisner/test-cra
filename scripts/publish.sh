set -e

export REACT_APP_RELEASE_VERSION="test-cra-${VERSION_ID}"

echo ""
echo "*** BUILD ENVIRONMENT VARIABLES for commit=$COMMIT ***"
echo ""
sh $(dirname $0)/env.sh

if [[ $GIT_BRANCH == $MAINLINE_BRANCH ]]; then
  echo ""
  echo "*** BUILD WEBPACK BUNDLE for ref=$REF ***"
  echo ""
  sh $(dirname $0)/push_to_s3.sh "$AWS_BUCKET_NAME/$REF"
fi

echo ""
echo "*** BUILD WEBPACK BUNDLE for commit=$COMMIT ***"
echo ""
sh $(dirname $0)/push_to_s3.sh "$AWS_BUCKET_NAME/$COMMIT"

echo ""
echo "*** DONE ***"
echo ""
