#!/bin/bash
#
# Modifies the application.yml file in the local config-repo to reflect the new release. The
# change is commited and pushed to the dev branch of the github repository.
# If run from Jenkins script, expect:
#     NEXT_RELEASE_NAME
#     NEXT_VERSION_TAG
#     CONFIG_REPO
#     GIT_PUBLIC_SERVER_URL
#     GIT_PRIVATE_SERVER_URL

#-------------------------------------------------------------------------------------

usage() {
   echo
   echo "This script modifies the release name and version number in the dev-branch of the"
   echo "spring-config's application.yml, to reflect the next release that dev is intended"
   echo " for. User will be prompted if release info is not provided via options."
   echo "See script for comments on parameter settings via environment variables."
   echo
   echo "Usage:  $0 [options]"
   echo
   echo "Options:"
   echo
   echo "  --config-repo <dir>     Directory path to config-repo"
   echo "  -h, --help              Prints usage. "
   echo "  --release-name <name>   Next release name, e.g., \"Hollywood\"."
   echo "  --tag <version>         Next version tag, e.g. \"2.4.0\"."
   echo
   exit 1;
}

#-------------------------------------------------------------------------------------

# Uncomment following line to debug script line by line:
#set -x; trap read debug

scriptName=$0
pushd `dirname ${BASH_SOURCE[0]}` >/dev/null
. ./common.sh
popd >/dev/null

# Parse command line
while [ $# -gt 0 ]; do
   case $1 in
      --config-repo) CONFIG_REPO=$2 ; shift ;;
      -h|--help) usage ;;
      --release-name) NEXT_RELEASE_NAME=${2} ; shift ;;
      -t|--tag) NEXT_VERSION_TAG=${2} ; shift ;;
      --) break ;;
      -*|--*) echo "$0: ERROR - unrecognized option $1" 1>&2; usage ;;
   esac
   shift
done
if [ ! -d "$CONFIG_REPO" ] ; then
  echo; echo "ERROR: The config-repo directory provided does not exist. Aborting."; echo
  exit 1
fi

RELEASE_NAME=$NEXT_RELEASE_NAME
VERSION_TAG=$NEXT_VERSION_TAG
TAG_DESCRIPTION="N/A"
checkReleaseInfo

# Verify we are on the dev branch of the config repo:
pushd $CONFIG_REPO
appFileName="application.yml"
if [ ! -f "$appFileName" ] ; then
   appFileName="spring-config/application.yml"
   if [ ! -f "$appFileName" ] ; then
      echo; echo "ERROR: The config-repo directory does not contain $appFileName. Aborting."; echo
      exit 1
   fi
fi
echo "appFileName = $appFileName"
runCommand git checkout dev

# Perform the line substitution in the file (no actual YAML parsing):
echo; echo "Updated:"
tempFilename="app-temp.yml"
rm -f $tempFilename
modified=false
while IFS='' read -r line || [[ -n "$line" ]]; do
   words=($line)
   if [ "${words[0]}" == "releaseName:" ] && [ "${words[1]}" != "${RELEASE_NAME}" ]; then
      line="releaseName: ${RELEASE_NAME}"
      echo "$line"
      modified=true
   elif [ "${words[0]}" == "releaseNumber:" ] && [ "${words[1]}" != "${VERSION_TAG}" ]; then
      line="releaseNumber: ${VERSION_TAG}"
      echo "$line"
      modified=true
   fi
   echo "${line}" >> $tempFilename
done < "$appFileName"

if $modified; then
   runCommand mv $tempFilename $appFileName
   runCommand git add $appFileName
   runCommand git commit -m \"$scriptName: Modified release info to ${RELEASE_NAME}-${VERSION_TAG}\"
   runCommand git push --set-upstream origin dev
else
   echo; echo "No changes detected."
   runCommand rm $tempFilename
fi

popd
echo; echo "Done.";echo
exit 0
