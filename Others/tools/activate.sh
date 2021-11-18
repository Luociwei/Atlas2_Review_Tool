#!/bin/sh

echo "Activating Atlas 2.0"

set -e

# RestoreTools doesn't yet include the plist in the right location
# Copy to the right location and launch it
function setupLaunchDaemon() {
    local source_path="/usr/local/Atlas/Library/LaunchAgents/$1"
    local dest_path="/Library/LaunchAgents/$1"
    if [[ "$(sum "${source_path}" |cut -f1 -d' ')" != "$(sum "${dest_path}" |cut -f1 -d' ')" ]]; then
        echo "Copying and launching new $1"
        cp "${source_path}" "${dest_path}"
        launchctl load -w "${dest_path}"
    fi
}
setupLaunchDaemon "com.apple.hwte.AtlasCore2.plist"
setupLaunchDaemon "com.apple.hwte.AtlasStatusMenu.plist"

if [[ ! -d /Users/gdlocal ]]; then
    # This machine doesn't have gdlocal, so the remainder of workarounds are
    # for GH machines only, so skip them
    exit 0
fi

# Update sudoers file to grant no password access to log collect and terminate from gdlocal
# Workaround until <rdar://problem/61266537> Atlas2 : core-as-admin
function ensureSudoerString() {
    local expectedString="$1"

    if [[ -f /etc/sudoers ]]; then
        touch /etc/sudoers
    fi
    if [[ $(grep -c "$1" /etc/sudoers) == 0 ]]; then
        echo "$1" >> /etc/sudoers
    fi
}
ensureSudoerString "gdlocal ALL =  NOPASSWD: /usr/bin/log"
ensureSudoerString "gdlocal ALL =  NOPASSWD: /bin/kill"
