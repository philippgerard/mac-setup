{ lib, ... }:

{
  system.activationScripts.preActivation.text = lib.mkAfter ''
    xcodebuild="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

    if [[ -x "$xcodebuild" ]] && ! "$xcodebuild" -checkFirstLaunchStatus >/dev/null 2>&1; then
      echo "completing Xcode first-launch setup and accepting its license" >&2
      "$xcodebuild" -runFirstLaunch

      if ! "$xcodebuild" -checkFirstLaunchStatus >/dev/null 2>&1; then
        echo "Xcode first-launch setup is still incomplete" >&2
        exit 1
      fi
    fi
  '';
}
