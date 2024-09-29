QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('qb-flicker:syncLights')
AddEventHandler('qb-flicker:syncLights', function(lights)
    TriggerClientEvent('qb-flicker:clientFlickerLights', -1, lights)
end)