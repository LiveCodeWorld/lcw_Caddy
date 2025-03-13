script "Global | Caddy | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Caddy | Menu
type: controller
version: 0.1

/*
Here you can describe this menu.
Full help text should be provided on the linked wiki.
*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   -- put display_MenuTarget (tObject) into dView
   put the display_View of tObject into dView
   return dView
end menu_Target

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Caddy | Menu
-
on menu_StartCaddy
   caddy_ToggleProxy
end menu_StartCaddy

getprop checked_StartCaddy
   return caddy_IsRunning()
end checked_StartCaddy

on menu_UsingBrew
   put caddy_GetUsingBrew() into usingBrew
   caddy_SetUsingBrew (usingBrew is false)
end menu_UsingBrew

getprop disabled_UsingBrew
   -- put 
end disabled_UsingBrew

getprop checked_UsingBrew
   return caddy_GetUsingBrew()
end checked_UsingBrew

private on _
end _

on menu_EditCaddyFile
   put caddyFile_Path() into caddyFile
   -- put caddyFile_Construct() into caddyFile
   if there is a file caddyFile then
      code_EditFile caddyFile
   else
      breakpoint
   end if
end menu_EditCaddyFile

on menu_CaddyBinFolder
   put caddy_GetBinFolder() into caddyBinFolder
   finder_Reveal caddyBinFolder
end menu_CaddyBinFolder

on menu_ExportCaddyFile
   lcw_Answer "Create Caddy file from folders..."
   breakpoint
   
   caddy_Stop
   put the result into pIDs
   --
   put caddyFile_ConstructText() into cText
   caddyFile_Set cText
   lcw_Notify "Exported new CaddyFile based on local wiki folders."
   --
   caddy_Start
end menu_ExportCaddyFile

on menu_SaveCaddyFile
   breakpoint
   --
   put ":2015" into cText
   put CR after cText
   put CR & "respond 'Hello, world!" after cText
   replace "'" with quote in cText
   --
   caddyFile_Set cText
end menu_SaveCaddyFile

private on __
end __

on menu_RevealCaddyBinary
   put caddyFile_Path() into caddyFile
   --
   finder_Reveal caddyFile
end menu_RevealCaddyBinary

on menu_RevealCaddyFile
   -- put caddyFile_Folder() into caddFileFolder
   put caddyFile_Path() into caddyFile
   --
   finder_Reveal caddyFile
end menu_RevealCaddyFile

private on ___
end ___

on menu_GetConfigData
   display_CaddyAdmin
   display_CaddyTools
end menu_GetConfigData

on menu_CaddyAdapt
   caddy_Adapt
   put the result
end menu_CaddyAdapt

private on ____
end ____

on menu_ListCaddyWikiDomains dView
   -- put the caddy_ConfigData of dView into caddyConfigData
   put caddy_FetchConfig() into caddyConfigData
   set the caddy_ConfigData of dView to caddyConfigData
   --
   put caddyRouteArray_Get (caddyConfigData) into routeArray
   put caddyRouteArray_ListWikiHosts (routeArray) into wikiDomians
   --
   set the displayed_Index ["Wiki Routes"] of dView to wikiDomians
end menu_ListCaddyWikiDomains

on menu_DisplayCaddyAdmin
   display_CaddyTools
   --
   put caddy_ConfigUrl() into someUrl
   display_Browser someUrl
end menu_DisplayCaddyAdmin

on menu_CaddyApiHelp
   display_Browser "https://caddyserver.com/docs/api"
end menu_CaddyApiHelp

private on _____
end _____

on menu_CaddyInstalled
   put shell ("brew info caddy")
end menu_CaddyInstalled

on menu_DisplayXterm
   display_Xterm "brew info caddy"
end menu_DisplayXterm

on menu_Refresh
   display_CaddyTools
end menu_Refresh

on submenu_Dev
   return menu_DevTitle ("Global | Caddy | Menu")
end submenu_Dev
