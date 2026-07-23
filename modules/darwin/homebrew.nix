{ ... }:

{
  homebrew = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    # Configuration changes must not implicitly update or remove software.
    # Cleanup is a separate, reviewed maintenance operation.
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      {
        name = "shebe-oss/tap";
        trusted = true;
      }
    ];

    brews = [
      "mas"
      "mole"
      "shebe-oss/tap/shebe"
    ];
  };
}
