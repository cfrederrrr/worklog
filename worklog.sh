#!/bin/bash
​
[[ -f $WORKLOG ]] || WORKLOG=$HOME/.worklog
​
usage-and-exit()
{
  cat <<'USAGE' >&2
Usage: worklog MESSAGE [OPTIONS]
  -p    --project NAME          Project name
  -d    --duration MINUTES      Approximate duration in minutes
  -t    --tags TAG[,TAG...]     Tags for the log
  -s    --timestamp             Add a timestamp to the date field
  -h    --help                  Print this help text
USAGE
exit 1
}
​
PARAMS=""
while (( "$#" ))
do
  case "$1" in
  -p|--project)
    if [ -n "$2" ] && [ ${2:0:1} != "-" ]
    then
      PROJECT=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      usage-and-exit
    fi
    ;;
  -t|--tags)
    if [ -n "$2" ] && [ ${2:0:1} != "-" ]
    then
      TAGS=$2
      shift 2
    else
      echo "Error: No tag provided" >&2
      usage-and-exit
    fi
    ;;
  -s|--timestamp)
    TIME=1
    shift
    ;;
  -d|--duration)
    if [ -n "$2" ] && [ ${2:0:1} != "-" ]
    then
      DURATION=$2
      shift 2
    else
      echo "Error: No duration length provided" >&2
      usage-and-exit
    fi
    ;;
  -h|--help)
    usage-and-exit
    ;;
  -*|--*=) # unsupported flags
    usage-and-exit
    ;;
  *) # preserve positional arguments
    PARAMS="$PARAMS $1"
    shift
    ;;
  esac
done
​
# set positional arguments in their proper place
eval set -- "$PARAMS"
MESSAGE="$@"
​
if [[ -z $MESSAGE ]]
then usage-and-exit
fi
​
if (($TIME))
then DATE=$(date '+%a %b %d - %Y/%m/%d %T')
else DATE=$(date '+%a %b %d - %Y/%m/%d')
fi
​
read -d '' SCRIPT <<'SCRIPT'
{
  date: $date,
  duration: $duration,
  project: $project,
  message: $message,
  tags: $tags
}
| if .duration=="" then .duration=null else .duration=($duration|tonumber) end
| if .project==""  then .project=null  else . end
| if .tags==""
  then .tags=[]
  else .tags=(.tags | split(","))
  end
SCRIPT
​
>>$WORKLOG jq "$SCRIPT" \
  --null-input \
  --compact-output \
  --monochrome-output \
  --arg tags "$TAGS" \
  --arg date "$DATE" \
  --arg duration "$DURATION" \
  --arg project "$PROJECT" \
  --arg message "$MESSAGE"
