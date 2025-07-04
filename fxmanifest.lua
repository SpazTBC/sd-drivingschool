fx_version 'cerulean'
game 'gta5'

author 'Shawns Developments'
description 'SD Driving School - Complete driving school system with multiple license types'
version '2.0.0'

shared_scripts {
    'config.lua',
    'shared/framework.lua',
    'shared/esx.lua',
    'shared/qb.lua',
    'shared/qbx.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'locales/*.json'
}

dependencies {
    'qb-core', -- or esx or qbx_core
    'qb-target' -- optional
}