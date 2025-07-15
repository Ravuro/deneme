local QBCore = exports["qb-core"]:GetCoreObject()

local players = {}

QBCore.Functions.CreateCallback("tgiann-mdtv2:ilk-data", function(source, cb)
    cb(players)
end)

Citizen.CreateThread(function()
    players = {police = {}, user = {}}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player then
            if Player.PlayerData.job.type == "leo" or Player.PlayerData.job.name == "bcso" or Player.PlayerData.job.name == "sheriff" then
                table.insert(players.police, Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname)
            else
                table.insert(players.user, Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname)
            end
        end
    end
end)

QBCore.Commands.Add("mdt", "EMS/Polis Tabletini Aç", {}, false, function(source, args) -- name, help, arguments, argsrequired,  end sonuna persmission
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and (Player.PlayerData.job.name == "police" or Player.PlayerData.job.name == "ambulance" or Player.PlayerData.job.name == "bcso" or Player.PlayerData.job.name == "sheriff") then
        TriggerClientEvent('tgiann-mdtv2:open', source)
        TriggerClientEvent("tgiann-emstab:open", source)
    else
        TriggerClientEvent('QBCore:Notify', source, "Bu komutu kullanma yetkiniz yok.", "error")
    end
end)

QBCore.Functions.CreateUseableItem("pmdt", function(source, item)
    TriggerClientEvent("tgiann-mdtv2:open", source)
end)

QBCore.Functions.CreateUseableItem("emdt", function(source, item)
    TriggerClientEvent("tgiann-emstab:open", source)
end)

QBCore.Commands.Add("tabletzoom", 'Tabletin Boyutunu Ayarlar.', {{ name="Tablet Boyutu", help="50 İle 100 Arası Bir Değer"}}, false, function(source, args) -- name, help, arguments, argsrequired,  end sonuna persmission
    TriggerClientEvent('tgiann-mdtv2:zoom', source, args[1])
    TriggerClientEvent("tgiann-emstab:zoom", source, args[1])
end)


QBCore.Functions.CreateCallback("tgiann-mdtv2:sorgula", function(source, cb, data)
    if data.tip == "isim" then
        exports.oxmysql:execute("SELECT * FROM players WHERE charinfo LIKE @firstname LIMIT 30", {
            ['@firstname'] = '%'..data.data..'%'
        }, function (result)
            if result then
                cb(result)
            end
        end) 
    elseif data.tip == "arac" then
        exports.oxmysql:execute("SELECT * FROM player_vehicles WHERE citizenid = @citizenid", {
            ['@citizenid'] = data.data
        }, function (result)
            if result then
                cb(result)
            end
        end) 
    elseif data.tip == "numara" then
        exports.oxmysql:execute("SELECT * FROM players WHERE charinfo LIKE @phone LIMIT 30", {
            ['@phone'] = '%'..data.data..'%'
        }, function (result)            
            if result then
                cb(result)
            end
        end) 
    elseif data.tip == "plaka" then
        exports.oxmysql:execute("SELECT * FROM player_vehicles LEFT JOIN players ON player_vehicles.citizenid = players.citizenid WHERE player_vehicles.plate LIKE @plate LIMIT 30", {
            ['@plate'] = '%'..data.data..'%'
        }, function (result)
            if result then
                cb(result)
            end
        end) 
    end
end)

-- QBCore.Functions.CreateCallback('tgiann-mdtv2:ev', function(source, cb, citizenid)
--     exports.oxmysql:execute("SELECT * FROM tgiann_ev WHERE (id = @id OR anahtar1 = @id OR anahtar2 = @id OR anahtar3 = @id OR anahtar4 = @id OR anahtar5 = @id)", {
--         ['@id'] = citizenid
--     }, function(result)
--         if result[1] then
--             cb(result[1].id)
--         else
--             cb("Ev Bilgisi Yok!")
--         end
--     end)
-- end)

RegisterServerEvent('tgiann-mdtv2:ceza-kaydet')
AddEventHandler('tgiann-mdtv2:ceza-kaydet', function(data)
    local src = source
    local zanliisim, zanlicid = {data.zanli[1]}, data.zanli[2]
    exports.oxmysql:execute("INSERT INTO tgiann_mdt_olaylar SET aciklama = @aciklama, polis = @polis, zanli = @zanli, esyalar = @esyalar", {
        ["@aciklama"] = data.aciklama,
        ["@polis"] = json.encode(data.polis),
        ["@zanli"] = json.encode(zanliisim),
        ["@esyalar"] = json.encode(data.esyalar),
     }, function(result)
        exports.oxmysql:execute("INSERT INTO tgiann_mdt_cezalar SET citizenid = @citizenid, aciklama = @aciklama, ceza = @ceza, polis = @polis, cezalar = @cezalar, zanli = @zanli, olayid = @id", {
            ["@citizenid"] = zanlicid,
            ["@aciklama"] = data.aciklama,
            ["@ceza"] = json.encode(data.ceza),
            ["@polis"] = json.encode(data.polis),
            ["@zanli"] = json.encode(zanliisim),
            ["@cezalar"] = data.cezaisim,
            ["@id"] = result.insertId
        })
    end)
end)

QBCore.Functions.CreateCallback("tgiann-mdtv2:olaylardata", function(source, cb, data)
    exports.oxmysql:execute("SELECT * FROM tgiann_mdt_olaylar ORDER BY id DESC LIMIT 100", {
    }, function (result)
        cb(result)
    end) 
end)

QBCore.Functions.CreateCallback("tgiann-mdtv2:sabikadata", function(source, cb, data)
    exports.oxmysql:execute("SELECT * FROM tgiann_mdt_cezalar WHERE citizenid = @citizenid ORDER BY id DESC ", {
        ["@citizenid"] = data
    }, function (result)
        cb(result)
    end) 
end)

RegisterServerEvent('tgiann-mdtv2:sabikasil')
AddEventHandler('tgiann-mdtv2:sabikasil', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute("SELECT * FROM tgiann_mdt_cezalar WHERE id = @id", {
        ["@id"] = data
    }, function (result)
        if result[1] then
            TriggerEvent('ria-logs:server:CreateLog', "sicilsilme", "", "sicilsilme", GetPlayerName(src) .. " discord:" .. QBCore.Functions.GetIdentifier(src, 'discord') .. " adli kisi ".. json.encode(result[1].zanli) .. " adli kisinin sabikasini sildi!")
            exports.oxmysql:execute("DELETE FROM tgiann_mdt_cezalar WHERE id = @id", {
                ['@id'] = data
            })
        end
    end)
end)

RegisterServerEvent('tgiann-mdtv2:setavatar')
AddEventHandler('tgiann-mdtv2:setavatar', function(url, id)
    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(id)
    if xPlayer then
        xPlayer.Functions.SetCharInfo("photo", url)
        xPlayer.Functions.Save()
    end
end)

RegisterServerEvent('tgiann-mdtv2:olaysil')
AddEventHandler('tgiann-mdtv2:olaysil', function(id)
    exports.oxmysql:execute("DELETE FROM tgiann_mdt_olaylar WHERE id = @id", {
        ['@id'] = id
    })
    exports.oxmysql:execute("DELETE FROM tgiann_mdt_cezalar WHERE olayid = @olayid", {
        ['@olayid'] = id
    })
end)

RegisterServerEvent('tgiann-mdtv2:aranma')
AddEventHandler('tgiann-mdtv2:aranma', function(data, durum)
    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(data.id)
    if durum then
        local saat = os.time() + data.saat * 86400
        exports.oxmysql:execute("UPDATE players SET aranma=@aranma WHERE citizenid = @citizenid", {
            ['@citizenid'] = data.id,
            ['@aranma'] = json.encode({durum = true, sebep=data.neden, suansaat=os.time(), saat=saat})
        })
        exports.oxmysql:execute("INSERT INTO tgiann_mdt_arananlar SET citizenid = @citizenid, sebep = @sebep, baslangic = @baslangic, bitis = @bitis, isim = @isim", {
            ["@citizenid"] = data.id,
            ["@sebep"] = data.neden,
            ["@baslangic"] = os.time(),
            ["@bitis"] = saat,
            ["@isim"] = data.isim
        })
    else
        exports.oxmysql:execute("UPDATE players SET aranma=@aranma WHERE citizenid = @citizenid", {
            ['@citizenid'] = data.id,
            ['@aranma'] = json.encode({durum = false, sebep="", suansaat="", saat=""})
        })
        exports.oxmysql:execute("DELETE FROM tgiann_mdt_arananlar WHERE citizenid = @citizenid", {
            ['@citizenid'] = data.id
        })
    end
end)

QBCore.Functions.CreateCallback("tgiann-mdtv2:arananlar", function(source, cb, data)
    exports.oxmysql:execute("SELECT * FROM tgiann_mdt_arananlar", {
    }, function (result)
        cb(result)
    end) 
end)

QBCore.Functions.CreateCallback("tgiann-mdtv2:olayara", function(source, cb, data)
    exports.oxmysql:execute("SELECT * FROM tgiann_mdt_olaylar WHERE id = @id", {
        ["@id"] = tonumber(data)
    }, function (result)
        cb(result)
    end) 
end)
