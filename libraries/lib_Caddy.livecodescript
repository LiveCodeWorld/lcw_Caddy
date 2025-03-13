script "lib_Caddy"
--> MetaData
-
license: GPLv3
name: lib_Caddy
type: library
version: 0.6

/*
This library is for installing and manipulating a Caddy Server.
The aim is to have a locally running Caddy environment which runs Livecode command line cgi/s and Javascript

Check these locations for the Caddyfile:

/etc/caddy/Caddyfile
/usr/local/etc/caddy/Caddyfile
*/

--> Variables
-
local LocalArray
constant PlatformRestDomain = "rest.livecode.wiki"
constant PlatformRestPort = 9090
constant CaddyPrefKey = "Caddy"


--> Old
-
command caddy_StopProcess
   breakpoint -- old
   
   # Gets stuck sometimes - put in background?
   put caddy_ListProcessIds() into pIDs
   switch the number of items of pIDs
      case 0
         return empty
      case 1
         caddy_DoShell "caddy stop" -- hangs sometimes
         put the result into sResult
         if sResult is not empty then
            breakpoint
         end if
         break
      default
         caddy_CloseServerProcesses pIDs
   end switch
   return pIDs
end caddy_StopProcess


--> Working on
-
function brew_ListServices
   put shell ("brew services list") into sResult
   return sResult
end brew_ListServices

function caddyFile_Path pWhich
   put caddyFile_Construct (pWhich) into caddyFile
   if there is a file caddyFile then
      return caddyFile
   else
      return empty
   end if
end caddyFile_Path

function caddyFile_Construct pUsingBrew
   if pUsingBrew is empty then
      put caddy_GetUsingBrew() into pUsingBrew
   end if
   
   if pUsingBrew is true then
      put caddyFile_BrewDefault() into caddyFile
   else
      put caddyFile_ProjectDefault() into caddyFile
   end if
   return caddyFile
end caddyFile_Construct

function caddyFile_BrewDefault
   put "/opt/homebrew/etc/Caddyfile" into caddyFile -- my M2 macOS
   if there is a file caddyFile then
      return caddyFile
   else
      return empty
   end if
end caddyFile_BrewDefault


--> Platform
-
function platform_WikiDomain pSubDomain
   if pSubDomain is empty then
      return PlatformWikiDomain
   else
      text_AddTrailing pSubDomain, "."
      return pSubDomain & PlatformWikiDomain
   end if
end platform_WikiDomain

function platform_RestUrl restBit
   put "http://" & PlatformRestDomain into restURL
   if restBit is not empty then
      put slash & restBit after restURL
   end if
   return restURL
end platform_RestUrl

function platform_RestDomain
   return PlatformRestDomain
end platform_RestDomain


--> Display
-
command display_CaddyTools
   -- put caddy_ConstructArray() into cArray
   put caddy_FetchConfig() into caddyConfigData
   put caddyRouteArray_Get(caddyConfigData) into routeArray
   put caddyRouteArray_ListWikiHosts (routeArray) into wikiDomains
   
   display_Tool wikiDomains, "Admin", "Caddy", "lib_Caddy"
   put the result into dView
   --
   set the caddy_ConfigData of dView to caddyConfigData
   return dView
end display_CaddyTools

command display_CaddyAdmin
   display_Browser "http://localhost:2019/config/"
end display_CaddyAdmin


--> Caddy | Start and Stop
-
command caddy_ToggleProxy
   if caddy_IsRunning() then
      caddy_Stop
   else
      caddy_Start
   end if
   return the result
end caddy_ToggleProxy

command caddy_Start pLog
   if caddy_IsRunning() is true then return "Error, Caddy is already runing!"
   
   if caddy_GetUsingBrew() then
      caddy_BrewStart
   else
      caddy_ProjectStart
   end if
   return the result
end caddy_Start

command caddy_Stop
   if caddy_GetUsingBrew() then
      caddy_BrewStop
   else
      caddy_CloseServerProcesses
   end if
   return the result
end caddy_Stop

command caddy_BrewStart
   if caddy_IsRunning() is true then return "Error, Caddy is already runing!"
   if caddy_BrewInstalled() is false then return "Error, Caddy not installed by brew"
   
   put shell ("brew services start caddy") into sResult
   return sResult
end caddy_BrewStart

command caddy_BrewStop
   put shell ("brew services stop caddy") into sResult
   
   /*
   Stopping `caddy`... (might take a while)
   ==> Successfully stopped `caddy` (label: homebrew.mxcl.caddy)
   */
   return sResult
end caddy_BrewStop

command caddy_ProjectStart
   # Start Caddy
   put caddy_ConstructHupShell (pLog) into someShell
   caddy_DoShell someShell, false
   put the result into sResult
   put word 2 of sResult into pID
   --
   return pID
end caddy_ProjectStart

function caddy_ConstructHupShell pLog
   put "caddy start" into someShell
   --
   shell_WrapNohup someShell, pLog
   shell_AddSource someShell
   --
   return someShell
end caddy_ConstructHupShell

command caddy_Run pUsingBrew
   caddy_DoShell "caddy run", pUsingBrew
   return the result
end caddy_Run

command caddy_DoShell sShell, pUsingBrew
   put caddy_GetBinFolder (pUsingBrew) into binFolder
   set the defaultfolder to binFolder
   --
   if char 1 to 2 of sShell is not "./" then
      put "./" before sShell
   end if
   put shell (sShell) into shellResult
   --
   set the defaultFolder to oFolder
   return shellResult
end caddy_DoShell


--> Caddy | Install
-
command caddy_BrewInstall
   put shell ("brew install caddy") into sResult
   --
   put caddy_BrewBinFileFromInfo() into brewBinFile
   caddy_SetBrewBinPath brewBinFile
   --
   return sResult
end caddy_BrewInstall

command caddy_BrewUnInstall
   if caddy_IsRunning() is true then
      caddy_Stop
   end if
   
   put shell ("brew uninstall caddy") into sResult
   --
   caddy_SetBrewBinPath "not installed"
   return sResult
end caddy_BrewUnInstall

function caddy_BrewInstalled pForce
   if pForce is true then
      get caddy_BrewInfo()
      return "Installed" is among the lines of it
   else
      put caddy_BrewBinFile() is not empty into isInstalled
      return isInstalled
   end if
end caddy_BrewInstalled

function caddy_BrewBinFile
   put caddy_GetBrewBinPath() into brewBinFile
   --
   switch brewBinFile
      case empty
         put caddy_BrewBinFileFromInfo() into brewBinFile
         if brewBinFile is empty then
            caddy_SetBrewBinPath "not installed"
         else
            caddy_SetBrewBinPath brewBinFile
         end if
         return brewBinFile
      case "not installed"
         return empty
      default
         return brewBinFile
   end switch
end caddy_BrewBinFile

function caddy_GetBrewBinPath
   put caddy_GetPref ("brewBinFile") into brewBinFile
   return brewBinFile
end caddy_GetBrewBinPath

command caddy_SetBrewBinPath brewBinFile
   caddy_SetPref "brewBinFile", brewBinFile
   return the result
end caddy_SetBrewBinPath

function caddy_BrewBinFileFromInfo
   get caddy_BrewInfo()
   put lineOffset ("Installed", it) into lineNum
   if lineNum = 0 then return empty
   
   -- /opt/homebrew/Cellar/caddy/2.8.4 (39 files, 39.0MB) *
   put line (lineNum + 1) of it into fileLine
   return word 1 of fileLine
end caddy_BrewBinFileFromInfo

function caddy_BrewInfo
   /*
   caddy: stable 2.7.4
   https://caddyserver.com/
   ...
   /usr/local/Cellar/caddy/2.7.4 (10 files, 23MB) *
   Poured from bottle on 2024-03-09 at 10:00:00
   From: https://github.com/Homebrew/homebrew-core/blob/master/Formula/caddy.rb
   */
   put shell ("brew info caddy") into brewInfo
   return brewInfo
end caddy_BrewInfo

function caddy_GetUsingBrew
   put caddy_GetPref ("usingBrew") into usingBrew
   if usingBrew is empty then
      return false
   else
      return usingBrew
   end if
end caddy_GetUsingBrew

command caddy_SetUsingBrew sBoolean
   caddy_SetPref "usingBrew", (sBoolean is true)
   return the result
end caddy_SetUsingBrew

function caddy_GetPref prefName
   put pref_FetchValue (prefName, CaddyPrefKey) into prefValue
   return prefValue
end caddy_GetPref

command caddy_SetPref prefName, someValue
   pref_SaveValue prefName, someValue, CaddyPrefKey
   return the result
end caddy_SetPref

function caddy_GetBinFolder pUsingBrew
   if pUsingBrew is empty then
      put caddy_GetUsingBrew() into pUsingBrew
   end if
   
   if pUsingBrew is true then
      put caddy_BrewBinFolder() into binFolder
   else
      put caddy_ProjectFolder() into caddyProjectFolder
      put asset_GetFolder (caddyProjectFolder, "bin") into binFolder
   end if
   return binFolder
end caddy_GetBinFolder


--> CaddyFile
-
function caddyFile_ConstructText pTopDomains, pToLocalHostPort
   if pTopDomains is empty then
      put wikiFolder_ListTopLevel() into pTopDomains
   end if
   --
   put "{" into caddyFileText
   put CR&Tab & "auto_https off" after caddyFileText
   put CR & "}" after caddyFileText
   put CR after caddyFileText
   --
   put platform_RestDomain() into restDomain
   put CR & "# Handle" && restDomain after caddyFileText   
   put _CaddyFileToProxy (PlatformRestPort) into toProxy
   put platform_RestDomain() into restDomain
   put CR & _CaddyFileProxyLine (restDomain, toProxy) after caddyFileText
   --
   put CR after caddyFileText
   put CR & "# Catch-all for wikis and their subdomains" after caddyFileText
   --
   put _CaddyFileToProxy (pToLocalHostPort) into toProxy
   repeat for each line wikiDomain in pTopDomains
      put CR & _CaddyFileProxyLine (wikiDomain, toProxy) after caddyFileText
      -- put CR after caddyFileText
   end repeat
   --
   return caddyFileText
end caddyFile_ConstructText

function caddyFile_Get pWhich
   -- should be in the same place as the caddy binary?
   put caddyFile_Construct  (pWhich) into caddyFile
   put text_Get  (caddyFile) into caddyText
   return caddyText
end caddyFile_Get

command caddyFile_Set caddyText, pWhich
   put caddyFile_Construct  (pWhich) into caddyFile
   text_Set caddyFile, caddyText
   return caddyFile
end caddyFile_Set


--> CaddyFile | Files
-
function caddyFile_Folder pWhich
   put caddyFile_Construct (pWhich) into caddFileFolder
   set the itemdelimiter to slash
   put empty into item -1 of caddFileFolder
   return caddFileFolder
end caddyFile_Folder

function caddyFile_ProjectDefault
   put caddy_GetBinFolder() & "CaddyFile" into caddyFile
   if there is a file caddyFile then
      return caddyFile
   else
      return empty
   end if
end caddyFile_ProjectDefault


--> Caddy
-
function caddy_ListBinFiles
   get shell ("which caddy")
   return it
end caddy_ListBinFiles

function caddy_GetBinFile
   put caddy_GetBinFolder()
end caddy_GetBinFile

function caddy_BrewBinFolder
   -- put "/opt/homebrew/Cellar/caddy/" into caddyBinFolder
   put caddy_BrewBinFile() into caddyBinFolder
   set the itemdelimiter to slash
   put empty into item -1 of caddyBinFolder
   return caddyBinFolder
end caddy_BrewBinFolder

function caddy_ProjectFolder
   put the project_Folder of stack "lcw_Caddy" into projectFolder
   return projectFolder
end caddy_ProjectFolder

function caddy_Version
   caddy_DoShell "caddy version"
   return the result
end caddy_Version


--> Caddy | Process
-
command caddy_CloseServerProcesses pIDs
   if pIDs is not a number then
      put caddy_ListProcessIds() into pIDs
      if pIDs is empty then
         return empty
      end if
   end if
   --
   repeat for each item pID in pIDs
      -- close process pName
      kill process pID -- bug: does not kill?
   end repeat
   --
   return pIDs
end caddy_CloseServerProcesses

command caddy_ForceQuit
   breakpoint
   put caddy_ListProcessIds() into pIDs
   repeat for each item pID in pIDs
      kill -9 process pIDs -- does not work on OSX
   end repeat
   put caddy_ListProcessIds() into stillOpenIDs
   return stillOpenIDs
end caddy_ForceQuit

command caddy_Adapt
   caddy_DoShell "caddy adapt"
   put the result into sResult
   return sResult
end caddy_Adapt

function caddy_IsRunning
   put caddy_ListProcessIds() into pIDs
   return pIDs is not empty
end caddy_IsRunning

function caddy_ListProcessIds
   put ps_Grep ("caddy") into pids
   return pids
end caddy_ListProcessIds


--> Caddy | RouteArray
-
function caddyRouteArray_FindHostArray wikiDomain, routeIndexArray
   put caddyRouteArray_FindItemArray(wikiDomain, routeIndexArray) into routeItemArray
   put routeItemArray ["match"][1]["host"] into hostArray
   return hostArray
end caddyRouteArray_FindHostArray

function caddyRouteArray_FindItemArray wikiDomain, routeIndexArray
   put item 2 of the extents of routeIndexArray into maxItem
   repeat with routeNum = 1 to maxItem
      put routeIndexArray [routeNum] into routeItemArray
      --
      put routeItemArray ["match"][1]["host"] into hostArray
      repeat for each element sLine in hostArray
         if char 1 to 2 of sLine = "*." then next repeat
         --
         if sLine = wikiDomain then
            return routeItemArray
         end if
      end repeat
   end repeat
   return empty
end caddyRouteArray_FindItemArray

function caddyRouteArray_ListWikiHosts routeArray
   put item 2 of the extents of routeArray into maxItem
   repeat with routeNum = 1 to maxItem
      put routeArray [routeNum]["match"][1]["host"] into hostArray
      --
      repeat for each element sLine in hostArray
         if char 1 to 2 of sLine = "*." then next repeat
         --
         put sLine & CR after sDomains
      end repeat
   end repeat
   delete char -1 of sDomains
   url_SortDomainIndex sDomains
   return sDomains
end caddyRouteArray_ListWikiHosts

function caddyRouteArray_Get caddyConfigData, pSrvName
   -- routeArray is an indexArray
   if pSrvName is empty then put "srv0" into pSrvName
   --
   put caddyConfigData ["apps"]["http"]["servers"][pSrvName]["routes"] into indexArray
   return indexArray
end caddyRouteArray_Get


--> Caddy | Rest
-
command caddy_Post
   -- curl localhost:2019/load -H "Content-Type: application/json" -d @caddy.json
   put caddy_ConstructJson() into sJSON
   --
   put "localhost:2019/load" into restUrl
   put caddy_RestUrl ("load") into restUrl
   --
   put jsonrpc_POST (sJSON, restUrl) into sResult
   --
   put url "localhost:2015" into sTest
   display_CaddyAdmin
   return sTest
end caddy_Post


--> CaddyRouteArray
-
function caddyRouteArray_Construct wikiDomain, toDomainPort
   put "subroute" into routeArray ["handle"][1]["handler"]
   --
   put "reverse_proxy" into routeArray ["handle"][1]["routes"][1]["handle"][1]["handler"]
   
   put toDomainPort into routeArray ["handle"][1]["routes"][1]["handle"][1]["upstreams"][1]["dial"]
   --
   put true into routeArray ["terminal"]
   --
   put ("*." & wikiDomain) into routeArray ["match"][1]["host"][1]
   put wikiDomain into routeArray ["match"][1]["host"][2]
   --
   return routeArray
end caddyRouteArray_Construct


--> Caddy | API | Config
-
function caddy_FetchConfig
   put caddy_FetchConfigJson() into cJSON
   put json_ToArray (cJSON) into configArray
   return configArray
end caddy_FetchConfig

function caddy_FetchConfigJson
   put caddy_RestUrl ("config") into restUrl
   put url restUrl into cJSON
   return cJSON
end caddy_FetchConfigJson

function caddy_ConstructCurl sBody
   put "curl" && "localhost:2019/config/apps/http/servers/srv0/routes/0/handle/0/body" into sShell
   -- put "curl" && "localhost:2019/config/apps/http/servers/example/routes/0/handle/body" into sShell
   
   put space & "-H 'Content-Type: application/json'" after sShell
   put space & "-d '" & kwote (sBody) & "'" after sShell
   --
   return sShell
end caddy_ConstructCurl

function caddy_ConfigUrl
   -- "http://localhost:2019/config/"
   return caddy_RestUrl ("config")
end caddy_ConfigUrl

function caddy_RestUrl pPath
   put "http://" into pBit
   put pBit & "localhost:2019" into restUrl
   if pPath is not empty then
      put slash & pPath & slash after restUrl
   end if
   return restUrl
end caddy_RestUrl

function caddy_ConstructJson
   put caddy_ConstructArray() into cArray
   -- put JsonExport (cArray) into cJSON -- problem with numbers
   put json_FromArray (cArray, false, true) into cJSON
   return cJSON
end caddy_ConstructJson

function caddy_ConstructArray
   get {"apps": {"http": {"servers": {"example": {"listen": [":2015"],"routes": [{"handle": {"handler": "static_response","body": "Hello, world!"}}]}}}}}
   -- display_Data it, "Test Array"
   return it
end caddy_ConstructArray


--> Caddy | Install
-
command caddy_InstallBinaryToProject
   put the project_Folder of stack "lcw_Caddy" into projectFolder
   --
   get url "https://github.com/caddyserver/caddy/releases/download/v2.0.0-rc.1/caddy_2.0.0-rc.1_macOS_x86_64.tar.gz"
   put decompress(it) into tarData
   --
   put asset_GetFile (projectFolder, "caddy.tar", "bin") into somePath
   put tarData into url ("binfile:" & somePath)
   --
   put "tar xvzf caddy.tar" into someShellCommand
   caddy_DoShell someShellCommand
   --
   _DeleteInstalledFile projectFolder, "caddy.tar", "bin"
   _DeleteInstalledFile projectFolder, "LICENSE", "bin"
   _DeleteInstalledFile projectFolder, "README.md", "bin"
   --
   put asset_GetFile (projectFolder, "caddy", "bin") into caddyPath
   return caddyPath
end caddy_InstallBinaryToProject


--> Private
-
private command _DeleteInstalledFile projectFolder, shortFile, pShortAssetFolder
   breakpoint
   put asset_GetFile (projectFolder, shortFile, pShortAssetFolder) into assetFile
   delete file assetFile
   return the result
end _DeleteInstalledFile

private function _CaddyFileToProxy pToLocalHostPort
   if pToLocalHostPort is empty then put wikiServer_GetNodePort() into pToLocalHostPort
   put "http://localhost:" & pToLocalHostPort into toProxy
   return toProxy
end _CaddyFileToProxy

private function _CaddyFileProxyLine wikiDomain, toProxy
   put "http://*.[[wikiDomain]], http://[[wikiDomain]]" into proxyLines
   put space & "{" after proxyLines
   put CR&Tab & "reverse_proxy [[toProxy]]" after proxyLines
   put CR & "}" after proxyLines
   return merge (proxyLines)
end _CaddyFileProxyLine
