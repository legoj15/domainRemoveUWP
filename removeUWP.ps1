if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$args`"" -Verb RunAs; 
    exit 
}

$debug = $false

# Check if --debug is in the arguments
if ($args -contains "--debug") {
    $debug = $true
}

# Check if --azure is in the arguments
if ($args -contains "--azure") {
    $azure = $true
}

if ($debug) {
    Write-Host "Debug mode is ON"
}

whoami

fsutil behavior set disable8dot3 1

Write-Host "Violently removing Dell SupportAssist"

$SAVer = Get-ChildItem -Path HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall, HKLM:\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "SupportAssist"} | Where-Object {$_.DisplayVersion -notlike "3.2*"} | Select-Object -Property DisplayVersion, UninstallString, PSChildName
ForEach ($ver in $SAVer) {
    If ($ver.UninstallString) {
        $uninst = $ver.UninstallString ; cmd /c $uninst /quiet /norestart
    }
}

Remove-Item -Path "C:\ProgramData\Dell\SARemediation" -Recurse -Force

$UWPApps = @(
"26720RandomSaladGamesLLC.SimpleSolitaire"
"2B24874D.DealsOffers"
"4DF9E0F8.Netflix"
"598StudiosInc.qoolforToshiba"
"5A894077.McAfeeSecurity"
"828B5831.HiddenCityMysteryofShadows"
"89006A2E.AutodeskSketchBook"
"9E2F88E3.Twitter"
"A278AB0D.DisneyMagicKingdoms"
"A278AB0D.MarchofEmpires"
"AD2F1837.HPJumpStart"
"AD2F1837.SmartfriendbyHPCare"
"Amazon.com.Amazon"
"AMZNMobileLLC.KindleforWindows8"
"C27EB4BA.DropboxOEM"
"CAF9E577.Plex"
"ClearChannelRadioDigital.iHeartRadio"
"Clipchamp.Clipchamp"
"CyberLinkCorp.hs.PowerMediaPlayer14forHPConsumerPC"
"D52A8D61.FarmVille2CountryEscape"
"DB6EA5DB.MediaSuiteEssentialsforDell"
"DB6EA5DB.Power2GoforDell"
"DB6EA5DB.PowerDirectorforDell"
"DB6EA5DB.PowerMediaPlayerforDell"
"DellInc.DellCustomerConnect"
"DellInc.DellDigitalDelivery"
"DellInc.DellOptimizer"
"DellInc.DellSupportAssistforPCs"
"DellInc.MyDell"
"DellInc.PartnerPromo"
"Disney.37853FC22B2CE"
"DropboxInc.Dropbox"
"E046963F.AIMeetingManager"
"E0469640.SmartAppearance"
"eBayInc.eBay"
"EnnovaResearch.ToshibaPlaces"
"HONHAIPRECISIONINDUSTRYCO.DellWatchdogTimer"
"HuluLLC.HuluPlus"
"king.com.BubbleWitch3Saga"
"king.com.CandyCrushFriends"
"king.com.CandyCrushSaga"
"king.com.CandyCrushSodaSaga"
"king.com.FarmHeroesSaga"
"McAfeeInc.04.McAfeeSecurityAdvisorforToshiba"
"Microsoft.3DBuilder"
"Microsoft.549981C3F5F10"
"Microsoft.BingFinance"
"Microsoft.BingFoodAndDrink"
"Microsoft.BingHealthAndFitness"
"Microsoft.BingNews"
"Microsoft.BingSports"
"Microsoft.BingTravel"
"Microsoft.BingWeather"
"Microsoft.Copilot"
"Microsoft.GamingApp"
"Microsoft.GetHelp"
"Microsoft.Getstarted"
"Microsoft.Messaging"
"Microsoft.Microsoft3DViewer"
"Microsoft.MicrosoftJournal"
"Microsoft.MicrosoftOfficeHub"
"Microsoft.MicrosoftSolitaireCollection"
"Microsoft.MicrosoftSudoku"
"Microsoft.MicrosoftTreasureHunt"
"Microsoft.MinecraftUWP"
"Microsoft.MixedReality.Portal"
"Microsoft.MSPaint"
"Microsoft.Office.OneNote"
"Microsoft.Office.Sway"
"Microsoft.OneConnect"
"Microsoft.OneDriveSync"
"Microsoft.OutlookForWindows"
"Microsoft.People"
"Microsoft.PowerAutomateDesktop"
"Microsoft.Print3D"
"Microsoft.Reader"
"Microsoft.RemoteDesktop"
"Microsoft.SkypeApp"
"Microsoft.SkypeWiFi"
"Microsoft.Todos"
"Microsoft.Todos"
"Microsoft.Wallet"
"Microsoft.Whiteboard"
"Microsoft.Windows.Ai.Copilot.Provider"
"Microsoft.Windows.DevHome"
"microsoft.windowscommunicationsapps"
"Microsoft.WindowsFeedbackHub"
"Microsoft.WindowsReadingList"
"Microsoft.Xbox.TCUI"
"Microsoft.XboxApp"
"Microsoft.XboxGameOverlay"
"Microsoft.XboxGamingOverlay"
"Microsoft.XboxIdentityProvider"
"Microsoft.XboxSpeechToTextOverlay"
"Microsoft.YourPhone"
"Microsoft.ZuneMusic"
"Microsoft.ZuneVideo"
"MicrosoftCorporationII.MicrosoftFamily"
"MicrosoftTeams"
"MicrosoftWindows.CrossDevice"
"MirametrixInc.GlancebyMirametrix"
"MSTeams"
"MSWP.DellTypeCStatus"
"NextIssue.NextIssueMagazines"
"PandoraMediaInc.29680B314EFC2"
"PricelinePartnerNetwork.Priceline.comTheBestDealso"
"RivetNetworks.KillerControlCenter"
"ScreenovateTechnologies.DellMobileConnectPlus"
"sMedioforToshiba.TOSHIBAMediaPlayerbysMedioTrueLin"
"SpotifyAB.SpotifyMusic"
"ToshibaAmericaInformation.ToshibaCentral"
"Weather.TheWeatherChannelforToshiba"
"WildTangentGames.63435CFB65F55"
"WinZipComputing.WinZipUniversal"
"ZapposIPInc.Zappos.com"
#Dell Command Update is useful and has not previously caused issues
)

if ($azure) {
    $UWPApps = $UWPApps | Where-Object { 
        $_ -ne "Microsoft.OneDriveSync" -and 
        $_ -ne "MicrosoftTeams" -and 
        $_ -ne "Microsoft.MicrosoftOfficeHub" -and 
        $_ -ne "MSTeams" 
    }
}

foreach ($UWPApp in $UWPApps) {
    Get-AppxPackage -Name $UWPApp -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -eq $UWPApp | Remove-AppxProvisionedPackage -Online
}

if ($azure) {
    Write-Host "Skipping OneDrive, MicrosoftTeams, and MSTeams uninstallation because --azure was specified, assuming Entra joined computer"
} else {
    start-process "$env:windir\SysWOW64\OneDriveSetup.exe" "/uninstall"
    winget uninstall microsoft.onedrive --scope machine --accept-source-agreements
    winget uninstall microsoft.onedrive --scope user --accept-source-agreements
}

Disable-WindowsOptionalFeature -Online -FeatureName Printing-XPSServices-Features
Get-WindowsCapability -Online | Where-Object {$_.Name -like '*Print.Fax.Scan*'} | Remove-WindowsCapability -Online

Set-ExecutionPolicy default

if ($debug) {
    Read-Host -Prompt "Press Enter to exit"
}