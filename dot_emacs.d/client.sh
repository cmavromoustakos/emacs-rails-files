#!/bin/bash 
# Written by: Harvey Chapman <hchap...@3gfp.com> 
# With help from: Peter Dyballa <peter_dyb....@web.de> 
# Version: 2008-03-24 
# 
# Release Notes: 
# 
#  2008-03-24 
#  - Initial version supporting multiple files and auto-discovery of 
#    common Emacs.app locations 
# 
# TODO: 
#  - test for a valid EMACS_APP variable 
#  - add code to fallback through all of the other executable options 
#    currently commented out below. 
#  - add "--help"/"-h" options? 
#  - all of the emacsclient code below may be unnecessary if you 
#    don't care about creating a new frame since using 
#    "open Emacs.app filenames..." will open all of the files in the 
#    currently running Carbon Emacs session anyway. Perhaps the 
#    fallback for emacsclient failures should be the direct 
#    executable, $EMACS_APP/Contents/MacOS/Emacs. We'll set it this 
#    way by default for now since that's what the Description below 
#    says we do. 
#  - should errors in the fallbacks be hidden, i.e. "> /dev/null..."? 
#  - figure out how to switch application focus to Emacs.app when 
#    using emacsclient 
# Usage: 
# 
#   client.sh [filename [filename ...]] 
# Example: 
# 
#   cd /etc 
#   ~/.emacs.d/client.sh paths /etc/resolv.conf paths.d/X11 
# Description: 
# 
#   Use this script to load a list of files into an already existing 
#   session of Carbon Emacs or start a new session, if one is not 
#   already running. By default, this script tries to use emacsclient 
#   to connect to an already running Cabron Emacs running gnuserv. If 
#   that fails, the script will try to start a new Carbon Emacs 
#   session. If using gnuserv, the script will open a new frame 
#   (window) with the list of files passed in on the command line. If 
#   run with no list of files, this script will attempt to start a 
#   new Carbon Emacs session. 
# Setup: 
# 
#  - Set the variable EMACS_APP below to the location of you Carbon 
#    Emacs application bundle. If you have it in one of the two 
#    default locations, /Applications or /User/username/Applications, 
#    you can skip this step. 
#  - Make sure you have (server-start) in your .emacs file for 
#    emacsclient to work. If you don't want to use gnuserv and 
#    emacsclient, the script will still work. It will just start a 
#    new copy of Emacs.app. 
#  - If you don't want a new frame (window) created each time this 
#    runs, change EMACS_CMD below to "file-file". 
#  - Make the script executable: "chmod u+x /path/to/client.sh" 
#  Recommended: 
# 
#  - Put this script in ~/.emacs.d for use by one user. 
#    This also ensures that the script stays with your other emacs 
#    customization files. 
#  - Create an alias in ~/.bash_profile: 
#    "alias e='~/.emacs.d/client.sh'" 
#    Now it can be run like this "e [files]" 
# 
#  * and/or * 
# 
#  - Put the script somewhere in the PATH so multiple users can use 
#    it. 
# Location of Emacs.app directory. Set this if Emacs.app is in a 
# non-standard location. 
EMACS_APP="" 
# Open a new frame and put all opened files there. 
EMACS_CMD="find-file-other-frame" 
##################### 
# End Configuration # 
##################### 
# Try to detect the location of Emacs.app if not set already 
# If it exists in two locations, the one in the user's Applications 
# directory will be preferred. 
if [ -z "$EMACS_APP" ] ; then 
    # System Applications Directory 
    if [ -d "/Applications/Emacs.app" ] ; then 
        EMACS_APP="/Applications/Emacs.app" 
    fi 
    # User's Applications Directory 
    if [ -d "${HOME}/Applications/Emacs.app" ] ; then 
        EMACS_APP="${HOME}/Applications/Emacs.app" 
    fi 
fi 
#echo $EMACS_APP 
# Location of executables 
EMACS_CLIENT="$EMACS_APP/Contents/MacOS/bin/emacsclient" 
EMACS_APP_EXE="$EMACS_APP/Contents/MacOS/Emacs" 
# Temporary storage for the modified filenames 
declare -a EMACS_ARRAY 
declare -a CLI_ARRAY 
# Go through the list of filenames and convert them, if necessary, 
# into absolute filenames. 
for i in $* ; do 
    if [ `echo $i | grep '^/'` ] ; then 
        FILE="$i" 
        #echo "Path is absolute: $FILE" 
    else 
        FILE="$PWD/$i" 
        #echo "Path is relative: $FILE" 
    fi 
    #echo '('$EMACS_CMD' "'"$FILE"'")' 
    # Build the arrays for emacsclient, EMACS, and Emacs, CLI 
    EMACS_ARRAY=( "${EMACS_ARRAY[@]}" "($EMACS_CMD \"$FILE\")" ) 
    CLI_ARRAY=( "${CLI_ARRAY[@]}" "$FILE" ) 
    # Switch to find-file after opening the new frame 
    EMACS_CMD="find-file" 
done 
# Debugging. 
# 
#   Changing IFS, using [*], and adding double quotes around the 
#   variables will make it easier to check the output. The double 
#   quotes will cause all array values to be concatenated into a 
#   single word with the first value of IFS used to separate them. 
#   The IFS value, double quotes, and [*] will result in something 
#   like this: "value|value|..." 
debug=0 
if [ $debug -eq 1 ] ; then 
    oldIFS="$IFS" 
    IFS="|" 
    echo 
    echo "${EMACS_ARRAY[*]}" 
    echo 
    echo "${CLI_ARRAY[*]}" 
    echo 
    IFS="$oldIFS" 
    exit 
fi 
# Try to run the client (if the list of files is non-zero) 
if [ ${#EMACS_ARRAY[@]} -ne 0 ] ; then 
    # The double quotes and [@] are required to properly quote the 
    # output and separate the array values into multiple "words" like 
    # this:  client "value" "value" ... 
    #echo $EMACS_CLIENT -n --eval "${EMACS_ARRAY[@]}" 
    #$EMACS_CLIENT -n --eval "${EMACS_ARRAY[@]}" 
    $EMACS_CLIENT -n --eval "${EMACS_ARRAY[@]}" > /dev/null 2>&1 
    status=$? 
else 
    status=1 
fi 
# Did it work? 
if [ $status -ne 0 ] ; then 
    # The client has failed, presumably because the server and 
    # therefore Emacs, itself is not running. Also, there may be no 
    # files. 
    # Start Emacs using Mac OS X "open" 
    #echo open -a $EMACS_APP "${CLI_ARRAY[@]}" 
    #open -a $EMACS_APP "${CLI_ARRAY[@]}" 
    # Start Emacs using the actual executable 
    $EMACS_APP_EXE "${CLI_ARRAY[@]}" & 
    # Try the command line emacs 
    #emacs "${CLI_ARRAY[@]}" 
    # Edit using nano which can only edit one file at a time so we 
    # only pass the first file 
    #nano "${CLI_ARRAY[0]}" 
fi 