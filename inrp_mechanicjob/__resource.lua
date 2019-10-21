-----------------------------------------------------------------------
------------------------ INSONIA RP - PORTUGAL ------------------------
-----------------------------------------------------------------------
-------------------------    VERSION - B1G     ------------------------
-----------------------------------------------------------------------

resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

this_is_a_map 'yes'

version '1.1.0'

ui_page "html/menu.html"

file 'nacelle.ytyp'
file 'v_int_40.ytyp'

data_file 'DLC_ITYP_REQUEST' 'nacelle.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/v_int_40.ytyp'

client_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/pt.lua',
	'locales/br.lua',
	'gui.lua',
	'config.lua',
	'client/main.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/pt.lua',
	'locales/br.lua',
	'config.lua',
	'server/main.lua'
}

files {
	"html/menu.html",
	"html/raphael.min.js",
    "html/wheelnav.min.js",
	"html/logout.png",
	"html/faturas.png",
    "html/anim.png",
	"html/limp.png",
	"html/del.png",
    "html/rebocar.png",
	"html/logout.png",
	"html/spawn.png",
	"html/cone.png",
	"html/macaco.png",
	"html/exhaust.png",
    "html/ferramentas.png"
}

