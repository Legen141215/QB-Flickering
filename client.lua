-- Caminho: resources/[qb]/qb-flicker/client.lua

QBCore = exports['qb-core']:GetCoreObject()

local flickerRadius = 50.0
local flickerTime = 10000
local flickerInterval = 500

local lightObjects = {
    -145818549,
    -1098506160,
    682169123,
    -994492850,
    1327054116,
    -163910917,
    1043035044,
    865627822,
    -2083448347,
    -1036807324,
    -521477124,
    -655644382,
    1241740398,
    -1323100960,
    -655644382,
    -313922460,
    729253480
}

function IsLightObject(object)
    local objectModel = GetEntityModel(object)
    for _, hash in ipairs(lightObjects) do
        if objectModel == hash then
            return true
        end
    end
    return false
end

function GetNearbyLights(playerCoords, radius)
    local lights = {}
    local handle, object = FindFirstObject()
    local success
    repeat
        local objectCoords = GetEntityCoords(object)
        local distance = #(playerCoords - objectCoords)
        if distance <= radius and IsLightObject(object) then
            table.insert(lights, object)
            print("Luz encontrada: " .. object)
        end
        success, object = FindNextObject(handle)
    until not success
    EndFindObject(handle)
    return lights
end

function FlickerLights(lights)
    local startTime = GetGameTimer()
    while (GetGameTimer() - startTime) < flickerTime do
        for _, light in ipairs(lights) do
            SetEntityLights(light, false)
        end
        Wait(flickerInterval)
        for _, light in ipairs(lights) do
            SetEntityLights(light, true)
        end
        Wait(flickerInterval)
    end
    for _, light in ipairs(lights) do
        SetEntityLights(light, true)
    end
end

RegisterCommand('flicker', function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyLights = GetNearbyLights(playerCoords, flickerRadius)
    if #nearbyLights > 0 then
        print("Luzes próximas encontradas: " .. #nearbyLights)
        FlickerLights(nearbyLights)
    else
        QBCore.Functions.Notify("There are no lights nearby.", "error")
    end
end, false)
