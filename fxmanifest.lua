fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'DevKern'
description 'DK Spedition by fish'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/bridge.lua',
    'shared/levels.lua',
    'shared/cargo.lua'
}

client_scripts {
    'client/main.lua',
    'client/blips.lua',
    'client/targets.lua',
    'client/menus.lua',
    'client/documents.lua',
    'client/vehicle.lua',
    'client/loading.lua',
    'client/delivery.lua',
    'client/adr.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/main.lua',
    'server/profiles.lua',
    'server/offers.lua',
    'server/settlement.lua',
    'server/runs.lua',
    'server/vehicles.lua',
    'server/keys.lua',
    'server/cargo.lua',
    'server/documents.lua',
    'server/loading.lua',
    'server/delivery.lua',
    'server/police.lua',
    'server/adr.lua',
    'server/rewards.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-inventory',
    'qb-vehiclekeys',
    'oxmysql'
}