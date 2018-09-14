#!/bin/bash

set -e

trap "trap_ctrlc" 2

ROOT_DIR=$(pwd)
SKIP_BROWSER="0"
function local_read_args() {
  while (( "$#" )); do
  opt="$1"
  case $opt in
    -h|-\?|--\?--help)
      PRINT_USAGE=1
      QUICKSTART_ARGS="$SCRIPT $1"
      break
    ;;
    -b|--branch)
      BRANCH="$2"
      QUICKSTART_ARGS+=" $1 $2"
      shift
    ;;
    -o|--override)
      RECREATE_TAR="1"
      QUICKSTART_ARGS=" $SCRIPT"
    ;;
    --skip-setup)
      SKIP_SETUP=true
    ;;
    *)
      QUICKSTART_ARGS+=" $1"
      #echo $1
    ;;
  esac
  shift
  done

  if [[ -z $BRANCH ]]; then
    echo "Usage: $0 -b/--branch <branch> [--skip-setup]"
    exit 1
  fi
}

BRANCH="master"
PRINT_USAGE=0
SKIP_SETUP=false
#ASSET_MODEL="-amrmd predix-ui-seed/server/sample-data/predix-asset/asset-model-metadata.json predix-ui-seed/server/sample-data/predix-asset/asset-model.json"
SCRIPT="-script edge-starter-deploy.sh -script-readargs edge-starter-deploy-readargs.sh -deploy-edge-app"
QUICKSTART_ARGS=" $SCRIPT"
VERSION_JSON="version.json"
PREDIX_SCRIPTS="predix-scripts"
REPO_NAME="wind-workbench"
VERSION_JSON="version.json"
APP_DIR="edge-hello-world"
APP_NAME="Edge Starter Hello World"
TOOLS="Docker, Git"
TOOLS_SWITCHES="--docker --git"

local_read_args $@
IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/$BRANCH/izon.sh"
VERSION_JSON_URL=https://raw.githubusercontent.com/PredixDev/$REPO_NAME/$BRANCH/version.json


function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

function init() {
  currentDir=$(pwd)
  if [[ $currentDir == *"scripts" ]]; then
    echo 'Please launch the script from the root dir of the project'
    exit 1
  fi
  if [[ ! $currentDir == *"$REPO_NAME" ]]; then
    mkdir -p $APP_DIR
    cd $APP_DIR
  fi

  check_internet

  #get the script that reads version.json
  eval "$(curl -s -L $IZON_SH)"

  getVersionFile
  getLocalSetupFuncs
}

if [[ $PRINT_USAGE == 1 ]]; then
  init
  __print_out_standard_usage
else
  if $SKIP_SETUP; then
    init
  else
    init
    __standard_mac_initialization
  fi
fi

getPredixScripts
#clone the repo itself if running from oneclick script
pwd
ls -lrt
#if [[ ! -d "$PREDIX_SCRIPTS/$REPO_NAME" ]]; then
#  echo "repo not present"
getCurrentRepo
#fi
echo "pwd after copy -> $(pwd)"
ls -lrt
echo "quickstart_args=$QUICKSTART_ARGS"
source $PREDIX_SCRIPTS/bash/quickstart.sh $QUICKSTART_ARGS -repo-name $REPO_NAME -app-name $APP_DIR

sleep 20
# Automagically open the application in browser, based on OS
if [[ $SKIP_BROWSER == 0 ]]; then
  app_url="http://$IP_ADDRESS:9098"

  case "$(uname -s)" in
     Darwin)
       # OSX
       open $app_url
       ;;
     Linux)
       # OSX
       xdg-open $app_url
       ;;
     CYGWIN*|MINGW32*|MINGW64*|MSYS*)
       # Windows
       start "" $app_url
       ;;
  esac
fi

echo "Deployed Predix Edge Hello World Application to Predix Edge OS."
