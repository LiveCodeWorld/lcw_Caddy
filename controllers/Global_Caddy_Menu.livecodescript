script "Global_Caddy_Menu"
--> MetaData
-
license: GPLv3
name: Global_Caddy_Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray


--> Menu | Init
-
on menu_Init tObject   
   -- do something when the menu first loads
end menu_Init


--> Menu | Props
-
getprop test_Param [mTarget]
   return "b"
end test_Param

getprop test_Params [mTarget]
   return "a,b,c"
end test_Params


--> Global | Caddy | Menu
-
on menu_StartCaddy
   caddy_DoShell "caddy start"
   --
   put the result -- into caddyHelp
end menu_StartCaddy

on _
end _

on menu_InstallCaddy
   caddy_Install
   put the result into caddyPath
   --
   caddy_DoShell "caddy help"
   --
   put the result into caddyHelp
   display_Text caddyHelp, "Caddy Help"
end menu_InstallCaddy

on _
end _

on submenu_Help
   return "Caddy | Help"
end submenu_Help


--> Caddy | Help
-
on menu_Getting Started
   launch url "https://caddyserver.com/docs/getting-started"
end menu_Getting

on menu_Github
   launch url "https://github.com/caddyserver/caddy/releases"
end menu_Github

on menu_CaddyHelp
   caddy_DoShell "caddy help"
   put the result into cliHelp
   display_Text cliHelp, "Caddy Help"
end menu_CaddyHelp
