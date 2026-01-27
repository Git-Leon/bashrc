killScript=$HOME/bashrc/aliases/kill-process.sh  
# handle explorer specially (kill then restart)
"$killScript" explorer
start explorer.exe &

# consolidated list of processes to kill
processes=(
	"code"
	"cursor"
	"notepad++"
	"discord"
	"mspaint"
	"idea64"
	"java"
	"firefox"
	"chrome"
	"msedge"
	"opera"
	"Audacity"
	"GameBar"
	"obs64"
	"steam"
	"Splitter Studio"

	"LITSSvc"
	"ibmpmsvc"
	"PowerMgr"
	"ApsInsSvc"
	"EasyResume"
	"Lenovo.Modern.ImController"
	"Lenovo.Modern.ImController.PluginHost"
	"Lenovo.Modern.ImController.PluginHost.Device"
	"Lenovo.Modern.ImController.PluginHost.SettingsApp"
	"Zoom"

	# Webex
	"CiscoCollabHost"
	"WebexHost"
	"wmlhost"

	# Citrix
	"AuthManSvr"
	"concentr"
	"wfcrun32"
	"SelfServicePlugin"
	"Receiver"
	"CDViewer"

	# extra common bloat
	"OneDrive"
	"OneDrive.exe"
	"AdobeARM"
	"AdobeARM.exe"
	"AdobeUpdateService"
	"GoogleUpdate"
	"gupdate"
	"gupdatem"
	"Spotify"
	"SpotifyWebHelper"
	"Teams"
	"TeamsUpdater"
	"Slack"
	"Skype"
	"Dropbox"
	"EpicGamesLauncher"
	"Battle.net"
	"RazerSynapse"
	"LogitechGHub"
	"LogiOverlay"
	"IntelDriverUpdateService"
	StartMenuExperienceHost
	SearchHost
	TextInputHost
	
	"ConEmu64"
	"bash"
)


# iterate and kill each process
for proc in "${processes[@]}"; do
	"$killScript" "$proc"
done