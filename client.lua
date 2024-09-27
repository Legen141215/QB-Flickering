QBCore = exports['qb-core']:GetCoreObject()

local flickerRadius = 50.0 
local flickerTime = 10000 
local flickerInterval = 500
local flickerActive = false
local flickerPattern = "default"
local emergencyMode = false

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
    729253480,
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
            print("Light found: " .. object)
        end

        success, object = FindNextObject(handle)
    until not success

    EndFindObject(handle)
    return lights
end

function GetLightState(light)
    return IsEntityLightOn(light)
end

function SetLightState(light, state)
    SetEntityLights(light, state)
end

function SetLightIntensity(light, intensity)
    SetEntityLightMultiplier(light, intensity)
end

function SetLightColor(light, r, g, b)
    SetEntityLightColor(light, r, g, b)
end

function FlickerLights(lights)
    local startTime = GetGameTimer()
    local originalStates = {}

    for _, light in ipairs(lights) do
        originalStates[light] = GetLightState(light)
    end
    
    flickerActive = true
    while (GetGameTimer() - startTime) < flickerTime and flickerActive do
        for _, light in ipairs(lights) do
            if flickerPattern == "default" then
                SetLightState(light, false)
            elseif flickerPattern == "pulse" then
                SetLightIntensity(light, 0.5)
            elseif flickerPattern == "strobe" then
                SetLightState(light, false)
                Wait(100)
                SetLightState(light, true)
            end
        end
        Wait(flickerInterval)

        for _, light in ipairs(lights) do
            if flickerPattern == "default" then
                SetLightState(light, true)
            elseif flickerPattern == "pulse" then
                SetLightIntensity(light, 1.0)
            elseif flickerPattern == "strobe" then
                SetLightState(light, true)
            end
        end
        Wait(flickerInterval)
    end

    for light, state in pairs(originalStates) do
        SetLightState(light, state)
    end

    flickerActive = false
    QBCore.Functions.Notify("Flickering finished.", "success")
end

RegisterCommand('flicker', function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local nearbyLights = GetNearbyLights(playerCoords, flickerRadius)
    
    if #nearbyLights > 0 then
        print("Nearby lights found: " .. #nearbyLights)
        QBCore.Functions.Notify("Flickering started.", "success")
        FlickerLights(nearbyLights)
    else
        QBCore.Functions.Notify("No nearby street lights or signals.", "error")
    end
end, false)

RegisterCommand('stopflicker', function(source, args, rawCommand)
    if flickerActive then
        flickerActive = false
        QBCore.Functions.Notify("Flickering stopped.", "success")
    else
        QBCore.Functions.Notify("No active flickering.", "error")
    end
end, false)

RegisterCommand('setflickerconfig', function(source, args, rawCommand)
    if #args >= 3 then
        flickerRadius = tonumber(args[1])
        flickerTime = tonumber(args[2])
        flickerInterval = tonumber(args[3])
        QBCore.Functions.Notify("Flickering settings updated.", "success")
    else
        QBCore.Functions.Notify("Usage: /setflickerconfig <radius> <time> <interval>", "error")
    end
end, false)

RegisterCommand('saveflickerconfig', function(source, args, rawCommand)
    local config = {
        radius = flickerRadius,
        time = flickerTime,
        interval = flickerInterval
    }
    SaveResourceFile(GetCurrentResourceName(), "flickerconfig.json", json.encode(config), -1)
    QBCore.Functions.Notify("Flickering settings saved.", "success")
end, false)

RegisterCommand('loadflickerconfig', function(source, args, rawCommand)
    local config = LoadResourceFile(GetCurrentResourceName(), "flickerconfig.json")
    if config then
        config = json.decode(config)
        flickerRadius = config.radius
        flickerTime = config.time
        flickerInterval = config.interval
        QBCore.Functions.Notify("Flickering settings loaded.", "success")
    else
        QBCore.Functions.Notify("No flickering settings found.", "error")
    end
end, false)

RegisterCommand('testflicker', function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local testRadius = 10.0

    local nearbyLights = GetNearbyLights(playerCoords, testRadius)
    
    if #nearbyLights > 0 then
        print("Nearby lights found: " .. #nearbyLights)
        QBCore.Functions.Notify("Flickering test started.", "success")
        FlickerLights(nearbyLights)
    else
        QBCore.Functions.Notify("No nearby street lights or signals for testing.", "error")
    end
end, false)

RegisterCommand('setflickerpattern', function(source, args, rawCommand)
    if #args >= 1 then
        flickerPattern = args[1]
        QBCore.Functions.Notify("Flickering pattern updated to " .. flickerPattern, "success")
    else
        QBCore.Functions.Notify("Usage: /setflickerpattern <pattern>", "error")
    end
end, false)

RegisterCommand('emergencymode', function(source, args, rawCommand)
    emergencyMode = not emergencyMode
    if emergencyMode then
        QBCore.Functions.Notify("Emergency mode activated.", "success")
    else
        QBCore.Functions.Notify("Emergency mode deactivated.", "success")
    end
end, false)

function LogAudit(action, source)
    local playerName = GetPlayerName(source)
    local logMessage = string.format("[%s] %s executed the command: %s", os.date("%Y-%m-%d %H:%M:%S"), playerName, action)
    SaveResourceFile(GetCurrentResourceName(), "audit.log", logMessage .. "\n", -1)
end

AddEventHandler('powerFailure', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyLights = GetNearbyLights(playerCoords, flickerRadius)
    
    if #nearbyLights > 0 then
        QBCore.Functions.Notify("Power failure! Flickering started.", "error")
        FlickerLights(nearbyLights)
    end
end)