lua54 'yes' -- needed for reaper
fx_version 'bodacious'
game 'gta5'
client_script 'client.lua'
server_scripts {
	'@oxmysql/lib/MySQL.lua',
	"server.lua"
}
ui_page 'ui/index.html'
files {
	'ui/index.html',
	'ui/css/*.css',
	'ui/js/*.js',
	'ui/img/*.png',
}
