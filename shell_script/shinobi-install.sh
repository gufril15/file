#! /bin/sh
# Check OS
OSTYPE="$(uname -s)"
defaultDirectory="/home"
if [ "$OSTYPE" = "Darwin" ]; then
    defaultDirectory="/Applications"
fi
installLocation="$defaultDirectory"

cd $installLocation
echo "Opening Install Location : \"$installLocation\""
if [ ! -d "Shinobi" ]; then
    # Check if Mac OS and if Git is needed
    if [ "$OSTYPE" = "Darwin" ]; then
        if [ ! -x "$(command -v brew)" ]; then
            ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
            brew doctor
        fi
        if [ ! -x "$(command -v git)" ]; then
            brew install git
        fi
    else
        # Check if user is root
        # if [ "$(id -u)" != 0 ]; then
        #     echo "*--------------------**---------------------*"
        #     echo "*Shinobi requires being run as root."
        #     echo "*Do you want to continue without being root?"
        #     echo "(Y)es or (n)o? Default : Yes"
        #     read nonRootUser
        #     if [  "$nonRootUser" = "N" ] || [  "$nonRootUser" = "n" ]; then
        #         echo "Stopping..."
        #         exit 1
        #     fi
        # fi
        # Check if Git is needed
        if [ ! -x "$(command -v git)" ]; then
            # Check if Ubuntu
            if [ -x "$(command -v apt)" ]; then
                apt update
                apt install git -y
            fi
            # Check if CentOS
            if [ -x "$(command -v yum)" ]; then
                yum makecache
                yum install git -y
            fi
        fi
        # Check if wget is needed
        if [ ! -x "$(command -v wget)" ]; then
            # Check if Ubuntu
            if [ -x "$(command -v apt)" ]; then
                apt install wget -y
            fi
            # Check if CentOS
            if [ -x "$(command -v yum)" ]; then
                yum install wget -y
            fi
        fi
    fi
    theRepo=''
    productName="Shinobi Professional (Pro)"
    echo "Install the Development branch?"
    echo "(y)es or (N)o? Default : No"
    read theBranchChoice
    if [ "$theBranchChoice" = "Y" ] || [ "$theBranchChoice" = "y" ]; then
        echo "Getting the Development Branch"
        theBranch='dev'
    else
        echo "Getting the Master Branch"
        theBranch='master'
    fi
    # Download from Git repository
    gitURL="https://gitlab.com/Shinobi-Systems/Shinobi$theRepo"
    git clone $gitURL.git -b $theBranch Shinobi
    # Enter Shinobi folder "/home/Shinobi"
    cd Shinobi
    gitVersionNumber=$(git rev-parse HEAD)
    theDateRightNow=$(date)
    # write the version.json file for the main app to use
    touch version.json
    chmod 777 version.json
    echo '{"Product" : "'"$productName"'" , "Branch" : "'"$theBranch"'" , "Version" : "'"$gitVersionNumber"'" , "Date" : "'"$theDateRightNow"'" , "Repository" : "'"$gitURL"'"}' > version.json
    echo "-------------------------------------"
    echo "---------- Shinobi Systems ----------"
    echo "Repository : $gitURL"
    echo "Product : $productName"
    echo "Branch : $theBranch"
    echo "Version : $gitVersionNumber"
    echo "Date : $theDateRightNow"
    echo "-------------------------------------"
    echo "-------------------------------------"
else
    echo "!-----------------------------------!"
    echo "Shinobi already downloaded."
    cd Shinobi
fi
# start the installer in the main app (or start shinobi if already installed)
echo "*-----------------------------------*"
chmod +x INSTALL/start.sh
INSTALL/start.sh
