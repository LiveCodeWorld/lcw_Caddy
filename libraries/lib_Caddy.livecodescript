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
constant PlatformRestDomain = "rest.livecode.wiki"
constant PlatformRestPort = 9090


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


--> Caddy | Files
-
function caddyFile_Construct pWhich
   switch pWhich
      case "brew"
         put caddyFile_BrewDefault() into caddyFile
         break
      default
         put caddyFile_ProjectDefault() into caddyFile
   end switch
   return caddyFile
end caddyFile_Construct

function caddyFile_ProjectDefault
   put caddy_GetBinFolder() & "CaddyFile" into caddyFile
   if there is a file caddyFile then
      return caddyFile
   else
      return empty
   end if
end caddyFile_ProjectDefault

function caddyFile_BrewDefault
   put "/usr/local/etc/caddy/Caddyfile" into caddyFile
   if there is a file caddyFile then
      return caddyFile
   else
      return empty
   end if
end caddyFile_BrewDefault

function caddy_GetBinFolder
   -- where the CaddyFile and add binary are
   put caddy_ProjectFolder() into caddyProjectFolder
   put asset_GetFolder (caddyProjectFolder, "bin") into binFolder
   return binFolder
end caddy_GetBinFolder

function caddy_ProjectFolder
   put the project_Folder of stack "lcw_Caddy" into projectFolder
   return projectFolder
end caddy_ProjectFolder


--> Caddy
-
function caddy_Version
   return caddy_DoShell ("caddy version")
end caddy_Version

command caddy_Run
   put caddy_DoShell ("caddy run") into sResult
   return sResult
end caddy_Run

command caddy_DoShell sShell
   put caddy_GetBinFolder() into binFolder
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

function caddy_ConstructShell pLog
   put "caddy start" into someShell
   --
   shell_WrapNohup someShell, pLog
   shell_AddSource someShell
   --
   return someShell
end caddy_ConstructShell


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
      put the result into pIDs
      --
      lcw_Notify ("Stopped Caddy servers." && pIDs)
      return empty
   else
      caddy_Start
      put the result into pID
      --
      lcw_Notify ("Started Caddy server on process" && pID)
      return pID
   end if
end caddy_ToggleProxy

command caddy_Start pLog
   if caddy_IsRunning() is true then
      put "Error, Caaddy is already runing!" into sWarning
      lcw_Notify sWarning
      return sWarning
   end if
   
   # Start in wiki assets folder to use local Caddyfile
   put caddy_ConstructShell (pLog) into someShell
   put caddy_DoShell (someShell) into sResult
   put word 2 of sResult into pID
   --
   lcw_Notify "Started Caddy reverse-proxy using local wiki Caddyfile!"
   return pID
end caddy_Start

command caddy_Stop
   caddy_CloseServerProcesses
   return the result
   
   # Gets stuck sometimes - put in background?
   put caddy_ListProcessIds() into pIDs
   switch the number of items of pIDs
      case 0
         return empty
      case 1
         put caddy_DoShell ("caddy stop") into sResult -- hangs sometimes
         if sResult is not empty then
            breakpoint
         end if
         break
      default
         caddy_CloseServerProcesses pIDs
   end switch
   return pIDs
end caddy_Stop

command caddy_CloseServerProcesses pIDs
   if pIDs is not a number then
      put caddy_ListProcessIds() into pIDs
      if pIDs is empty then
         lcw_Notify "No open Caddy servers..."
         return empty
      end if
   end if
   --
   repeat for each item pID in pIDs
      -- close process pName
      kill process pID -- bug: does not kill?
   end repeat
   
   # Notify
   put "Closed caddy server using sockets" && pIDs & "!" into sComment
   --
   lcw_Notify sComment, "Caddy Server"
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
   put caddy_DoShell ("caddy adapt") into sResult
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
on caddy_Install
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
end caddy_Install


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
