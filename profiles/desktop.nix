{ ... }:

{
  homebrew.casks = [
    "monitorcontrol"
  ];

  system.defaults.CustomUserPreferences."com.apple.controlcenter" = {
    "NSStatusItem Visible WiFi" = false;
  };
}
