#!/bin/bash
#!/usr/bin/expect
THIS_FILE=`basename "$0"`
launchctl unload /Library/LaunchAgents/com.apple.hwte.AtlasCore2.plist
killall AtlasCore
killall AtlasCoreDetectionProcess
killall AtlasTestGroupController
killall AtlasUI
killall AtlasRecordsUI
killall AtlasIPCDaemon
rm  "/Users/gdlocal/.loopConfig.json"
rm  "/Users/gdlocal/.outputConfig.json"

# If everything passed, close the terminal window and exit
osascript -e 'tell application "Terminal" to close (every window whose name contains "'"$THIS_FILE"'")' &
exit