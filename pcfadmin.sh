#!/bin/bash
###############################################################################
## Author : govindkailas@gmail.com
## To run:
##  - Make sure you are logged in via the cf cli
##  - Install jq
##  eg: ./pcfadmin.sh -o portaladmin -s dev -a all -act stop
###############################################################################




function get_orgs()
{
    name=$1
    if echo "$name"|grep -i 'all'; then
        org_url="/v3/organizations?per_page=5000" #getting only 5, this needs to be changed to 5000
    else
        org_url="/v3/organizations?names=$1"    
    fi
    org_names=$(cf curl ${org_url} | jq -r '.resources[]|.name + "," + .guid')
    if [[ "${org_names}X" == "X" ]]; then
        echo -e "${RED}👉 Invalid Org name $name, Exiting .."
        exit 1
    fi
    #echo -e "Valid org name and guid - $org_names \n"       
}

function get_spaces_app_action()
{
    name=$1 #this is same as $SPACE
    #get the valid space url  
    function get_space_url() 
    {
        if echo "$SPACE"|grep -iq '^all$'; then
            space_url="/v2/organizations/${1}/spaces | jq -r '.resources[] |.entity.name +\",\"+ .metadata.guid'"
        else
            space_url="/v2/organizations/${1}/spaces?q=name:${SPACE} | jq -r '.resources[]|.entity.name +\",\"+ .metadata.guid'"  
        fi
    }

    #get the valid app url 
    function get_app_url()
    {
        if echo "$APP"|grep -iq '^all$'; then
            # the max. we can fetch is 100 for any given space, if we have >100 apps, needs a loop
            app_url="/v2/spaces/${1}/apps?results-per-page=100 | jq -r '.resources[] |.entity.name +\",\"+ .metadata.guid'"  
        else
            app_url="/v2/spaces/${1}/apps?q=name:${APP} | jq -r '.resources[]|.entity.name +\",\"+ .metadata.guid' "    
        fi
    }
    

    #set a counter for orgs, spaces and apps
    org_count=0
    total_space_count=0
    total_app_count=0

    for name in $org_names; do
        ((org_count++))
        org_name=$(echo $name | cut -d',' -f1) # output is org name
        org_guid=$(echo $name | cut -d',' -f2) # output is guid
        echo "##### $org_count. Org '"$org_name"' with guid '"$org_guid"' ######"
        get_space_url $org_guid
        echo "space url is $space_url"
        space_names=$( eval cf curl $space_url)
        if [[ "${space_names}X" == "X" ]]; then
                echo -e "${RED}👉 Invalid Space name $SPACE under Org $org_name, Exiting .." | tee -a ${log_file}.log
                exit 1
        fi
        ((total_space_count++))
        for name in $space_names; do
            ((space_count++))
            space_name=$(echo $name | cut -d',' -f1) # output is space name
            space_guid=$(echo $name | cut -d',' -f2) # output is space guid
            echo -e "\t ****** $space_count. Space '"$space_name"' with guid '"$space_guid"' ******"
            get_app_url $space_guid
            echo "app url is $app_url"
            app_names=$( eval cf curl $app_url)
            if [[ "${app_names}X" == "X" ]]; then
                 echo -e "${RED}👉 Could'nt find any $APP/App under Space $space_name and Org $org_name, Exiting ..${CLEAR}" | tee -a ${log_file}.log
                 continue
            fi
            for name in $app_names; do    
                ((app_count++))
                app_name=$(echo $name | cut -d',' -f1) # output is app name
                app_guid=$(echo $name | cut -d',' -f2) # output is app guid
                echo -e "\t\t @@@@@@ $app_count. Going to '"$ACTION"' app '"$app_name"' with guid '"$app_guid"' @@@@@@"
                echo -e "$org_name,$space_name,$app_name,$ACTION" >>${log_file}.log
                cf curl -X POST /v3/apps/${app_guid}/actions/${ACTION}|jq -r '.state'
            done
            total_app_count+=$app_count
            app_count=0
        done
        space_count=0
    done 
}


############ Main starts here #############

CLEAR='\033[0m'
RED='\033[0;31m'

# cf login validation
if echo "$(cf api)"|grep -i 'Not logged in'; then
    echo -e "${RED}👉 You are not logged in , please login and try \nExiting .."
    exit
fi

echo "You are connected to"
echo "#####################"
echo $(cf api)

#print usage, this will be called if any arguments are missing
function usage() {
  if [ -n "$1" ]; then
    echo -e "${RED}👉 $1${CLEAR}\n";
  fi
  echo "Usage: $0 [-o org] [-s space] [-a app] [-act action]"
  echo "  -o, --org   Organization"
  echo "  -s, --space Space"
  echo "  -a, --app   Application"
  echo "  -act, --action   Start/Stop/Restart/Delete"
  echo ""
  echo "Example: $0 --org portaladmin --space dev --app all -act stop"
  exit 1
}

# parse params
while [[ "$#" > 0 ]]; do case $1 in
  -o|--org) ORG="$2"; shift;shift;;
  -s|--space) SPACE="$2";shift;shift;;
  -a|--app) APP=$2;shift;shift;;
  -act|--action) ACTION=$2;shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

# verify params
if [ -z "$ORG" ]; then usage "Org is not set"; fi;
if [ -z "$SPACE" ]; then usage "Space is not set."; fi;
if [ -z "$APP" ]; then usage "App is not set."; fi;
if [ -z "$ACTION" ]; then usage "Action is not set."; fi;

if echo "$ACTION"|grep -viqE '^start$|^stop$|^restart$|^delete$'; then
    echo -e "${RED}👉 Invalid action $ACTION ${CLEAR}\nExiting..";
    exit 1
fi

#Print them all and get user permission to proceed 
echo "Org .....: $ORG"
echo "Space ...: $SPACE"
echo "App .....: $APP"
echo "Action ..: $ACTION"
echo "#####################"

read -p "Warning!! Are you sure to continue? [y|n] " -n 1 -r
echo    
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
fi
echo "Proceeding further.."

time_stamp=$(date +%Y%m%d%H%M%S)
log_file="${ORG}_${SPACE}_${APP}_${ACTION}_${time_stamp}"
get_orgs $ORG
#echo "$valid_orgs"
echo -e "org_name,space_name,app_name,action" >${log_file}.log
get_spaces_app_action $SPACE
