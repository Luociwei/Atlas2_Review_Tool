#!/bin/bash
#!/usr/bin/expect
THIS_FILE=`basename "$0"`
launchctl unload /Library/LaunchAgents/com.apple.hwte.AtlasCore2.plist
killall AtlasCore
killall AtlasCoreDetectionProcess
killall AtlasTestGroupController
rm  "/Users/gdlocal/.loopConfig.json"
rm  "/Users/gdlocal/.outputConfig.json"
launchctl load /Library/LaunchAgents/com.apple.hwte.AtlasCore2.plist
sleep 1
/usr/local/bin/AtlasLauncher start ~/Library/Atlas2/Config/station.plist

open /AppleInternal/Applications/AtlasRecordsUI.app  &
sleep 0.5
open /AppleInternal/Applications/AtlasUI.app
osascript -e 'tell application "Terminal" to close (every window whose name contains "'"$THIS_FILE"'")' &
exit