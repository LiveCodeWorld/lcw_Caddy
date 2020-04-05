script "lib_Caddy"
--> MetaData
-
license: GPLv3
name: lib_Caddy
type: library
version: 0.1


--> Caddy
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
   asset_DeleteFile projectFolder, "caddy.tar", "bin"
   asset_DeleteFile projectFolder, "LICENSE", "bin"
   asset_DeleteFile projectFolder, "README.md", "bin"
   --
   put asset_GetFile (projectFolder, "caddy", "bin") into caddyPath
   return caddyPath
end caddy_Install

command asset_DeleteFile projectFolder, shortFile, pShortAssetFolder
   put asset_GetFolder (projectFolder, pShortAssetFolder) into assetFolder
   put assetFolder & shortFile into assetFile
   set the defaultfolder to assetFolder
   --
   delete file assetFile
   return the result
end asset_DeleteFile

command caddy_DoShell someShellCommand
   put caddy_GetBinFolder() into binFolder
   set the defaultfolder to binFolder
   --
   if char 1 to 2 of someShellCommand is not "./" then
      put "./" before someShellCommand
   end if
   put shell (someShellCommand) into shellResult
   return shellResult
end caddy_DoShell

function caddy_GetBinFolder
   put the project_Folder of stack "lcw_Caddy" into projectFolder
   put asset_GetFolder (projectFolder, "bin") into binFolder
   return binFolder
end caddy_GetBinFolder
