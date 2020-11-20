#!/bin/bash
#Bartosz Stępak

isConfigurationFileExist=false
configFileDir=""
websiteUrl=""
confidDir="/config"
keyWord=""
websites=()
<<<<<<< HEAD
instinstal
=======

>>>>>>> 735bbf98ac50d6111168c64f118c3dd70b6c087f
mkdir -p config

function Help()
{
        echo "This script can filter website by given key-word using website's HTML file."
        echo "You can create a configuration file where the first line will be your key wore and the next lines will be the full website's URL (https://.....). There is a connected example file named config.txt"
        echo "To run scrip using config file use command:"
        echo "$ ./web_filter.sh -c config.txt"
        echo "To run scrip and put data during working execute:"
        echo "$ ./web_filter.sh"
        echo "After finished filtration, you will be able to perform it another time and put a different data"

        echo "Syntax": scrpitTemplate [-h]
        echo "h print this help"
}

function isPackageNotInstalled() {
    dpkg --status $1 &> /dev/null

    if [ $? -eq 0 ]; then
        echo "$1: Already installed"
    else
        echo "___________________________Confirm action___________________________"
        echo "You dont have installed "$1
        read -r -p "It is nessesry to install this library. If do you agree type [Y/n] " response
        if [[ "$response" =~ ^([yY])$ ]]
        then
            sudo apt-get install -y $1
        else
            echo "Can not install " $1 ". Ending scrip"
            exit 1;
        fi 
    fi
}
    
isPackageNotInstalled "libxml2-utils"
isPackageNotInstalled "dos2unix" 
isPackageNotInstalled "ruby-nokogiri"

function check_if_paramater_has_Valid_argumetn {
	if [[ $1 == "-h" ]];
	then
		Help
		exit
	fi

    if [[ $1 == "-c" ]];
    then
        echo "Error: $1 should be a paramteter. correct way to run script -> web_filter.sh $1 [dir_to_your_cofing_file]"
        exit
	fi
}

function get_hyperlinks_data_from_website {
    curl -s  "$1" | nokogiri -e 'puts $_.search('\''a'\'')'  >> config/hyperlinkTags
    echo "added new tags from "$1
}

function get_configuration_data_from_config_file {
    echo "Readed from file"
    echo "websites"
    
    touch config/hyperlinkTags

    sed 1d "$configFileDir" | while IFS="" read -r line || [ -n "$line" ]
    do
        echo $line
        get_hyperlinks_data_from_website $line
    done 
    
    dos2unix $configFileDir
    keyWord=$(head -n 1 $configFileDir)
    echo "key-word -> "$keyWord
}


while getopts ":hc:" option; do
    case $option in
        h) 
            Help
            exit;;
        \?)
            Help
            exit;;
        c)   
            check_if_paramater_has_Valid_argumetn $OPTARG
            configFileDir=$OPTARG
            isConfigurationFileExist=true
            get_configuration_data_from_config_file
            ;;
        :)
            echo "error: $OPTARG argument value required."
            exit;;

    esac
done


function create_configuration_data {  
    keyWord=""
    websiteUrl=""
    echo "What is the key-word you want to filter by" 
    read keyWord
    echo "Your key-word -> " $keyWord
    echo "Wchis website do you want to filter? Enter full URL if you want to filter in more than one website at once, create configuration file -> more inforamtion in help [-h]"
    read websiteUrl
    echo "Your website -> " $websiteUrl
    > config/hyperlinkTags
    get_hyperlinks_data_from_website $websiteUrl
    isConfigurationFileExist=true

    echo "Created temporary configuration enviroment sucessfully"
    read -n 1 -s -r -p "Press [ANY KEY] to continue"
}

function chechk_if_file_is_not_empty {
 if [ -s "$1" ]
then 
   echo "Sucessfully filtred data from websites!"
else
   echo "No data found for keyword - "$keyWord
   exit 1;
fi   
}

function get_filered_links {
    echo "Start filtring ..."
    tr '[:upper:]' '[:lower:]' <config/hyperlinkTags >config/hyperlinkTagsToLowerCase
    grep -w $keyWord  config/hyperlinkTagsToLowerCase >config/FiltredHyperlinkTags
    xmllint  --html --xpath "//a/@href"  "config/FiltredHyperlinkTags" 2>/dev/null  >config/hrefElements
    #cat config/hrefElements | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" >config/finalLinks
    awk -F 'href="|"  |">|</' '{for(i=2;i<=NF;i=i+4) print $i,$(i+2)}' config/hrefElements >config/links
    sed 's/..$//' < config/links > config/finalLinks
    chechk_if_file_is_not_empty "config/finalLinks"
}

function get_url_to_open {
    counter=1

    cat "config/finalLinks" | while IFS="" read -r line || [ -n "$line" ]
    do
        if [[ $counter = $1 ]];then
            echo równy
            open $line
        fi
        ((counter=counter+1))
    done 
}

function display_result {
    counter=1

    echo "Printing results"
    echo "************************************************************"

    cat "config/finalLinks" | while IFS="" read -r line || [ -n "$line" ]
    do
        echo $counter". "$line
        ((counter=counter+1))
    done 

    echo "************************************************************"
    create_new_configuration_data_on_Confirm
}

function create_new_configuration_data_on_Confirm {
    read -r -p "Do you want to serch again and change your configiration data? [Y/n] " response
        
    if [[ "$response" =~ ^([yY])$ ]]
    then
        create_configuration_data
        get_filered_links
        display_result
        rm -r "config"
    else
        rm -r "config"
        exit 1;
    fi 
}


if [[ $isConfigurationFileExist = false ]];
then 
    create_configuration_data
fi

get_filered_links
display_result
rm -r "config" 

exit 1;
