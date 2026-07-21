{ lib, ... }:

{
  system.activationScripts.preActivation.text = lib.mkAfter ''
    rosetta_runtime="/Library/Apple/usr/libexec/oah/libRosettaRuntime"

    if [[ "$(/usr/bin/uname -m)" == "arm64" && ! -e "$rosetta_runtime" ]]; then
      echo "installing Rosetta 2 for Intel-only applications" >&2
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license

      if [[ ! -e "$rosetta_runtime" ]]; then
        echo "Rosetta 2 installation completed, but its runtime was not found" >&2
        exit 1
      fi
    fi
  '';
}
