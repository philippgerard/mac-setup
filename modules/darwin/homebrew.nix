{ ... }:

{
  homebrew = {
    enable = true;

    # Configuration changes must not implicitly update or remove software.
    # Cleanup is a separate, reviewed maintenance operation.
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      {
        name = "getsentry/xcodebuildmcp";
        trusted = true;
      }
      {
        name = "shebe-oss/tap";
        trusted = true;
      }
    ];

    brews = [
      "mas"
      "getsentry/xcodebuildmcp/xcodebuildmcp"
      "shebe-oss/tap/shebe"
    ];
  };
}
