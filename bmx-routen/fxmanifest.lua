fx_version 'cerulean'
game 'gta5'

author 'bmxyz'
description ''
version '1.1.0'

client_scripts {
    'config/config.lua',
    'client/client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config/config.lua',
    'server/server.lua'
}

dependencies {
    'es_extended'
}