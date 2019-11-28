-----------------------------------------------------------------------
------------------------ INSONIA RP - PORTUGAL ------------------------
-----------------------------------------------------------------------
-------------------------     AUTHOR - B1G     ------------------------
-----------------------------------------------------------------------

ESX                           = nil
local HasAlreadyEnteredMarker, LastZone = false, nil
local CurrentlyTowedVehicle, Blips = nil, {}
local NPCTargetDeleterZone =  false
local isDead, isBusy = false, false
local PlayerData              = {}
local LastPart                = nil
local LastPartNum             = nil
local LastEntity              = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local CurrentTask             = {}
local isInMarker  = false
local registed = false
local inArea = false
local state = false
local currentZone = nil
local Vehicles =		{}
local lsMenuIsShowed	= false
local isInLSMarker		= false
local myCar				= {}
local holdingPackage          = false
local disabledWeapons         = false
local APPbone	= 0
local APPx 		= 0.0
local APPy 		= 0.0
local APPz 		= 0.0
local APPxR 	= 0.0
local APPyR 	= 0.0
local APPzR 	= 0.0
local dropkey 	= 161 -- Key to drop/get the props
local closestEntity = 0

local Interior = GetInteriorAtCoords(440.84, -983.14, 30.69)

LoadInterior(Interior)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	
	while true do
		PlayerData = ESX.GetPlayerData()
		if PlayerData.job.name == 'mechanic' and not registed then
			RegisterCommands()
			registed = true
		else
			registed = false
		end
		Citizen.Wait(1500)
	end
end)



------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--------------------------------------- ANIMATIONS PROPS ---------------------------------------
---------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------



-- Prop list, you can add as much as you want
attachPropList = {

	["prop_roadcone02a"] = { 
        ["model"] = "prop_roadcone02a", ["bone"] = 28422, ["x"] = 0.6,["y"] = -0.15,["z"] = -0.1,["xR"] = 315.0,["yR"] = 288.0, ["zR"] = 0.0 
    },
    ["prop_cs_trolley_01"] = { 
        ["model"] = "prop_cs_trolley_01", ["bone"] = 28422, ["x"] = 0.0,["y"] = -0.6,["z"] = -0.8,["xR"] = -180.0,["yR"] = -165.0, ["zR"] = 90.0 
    },
	["prop_cs_cardbox_01"] = { 
        ["model"] = "prop_cs_cardbox_01", ["bone"] = 28422, ["x"] = 0.01,["y"] = 0.01,["z"] = 0.0,["xR"] = -255.0,["yR"] = -120.0, ["zR"] = 40.0 
    },
	["prop_tool_box_04"] = { 
        ["model"] = "prop_tool_box_04", ["bone"] = 28422, ["x"] = 0.4,["y"] = -0.1,["z"] = -0.1,["xR"] = 315.0,["yR"] = 288.0, ["zR"] = 0.0
    },
	["prop_engine_hoist"] = { 
        ["model"] = "prop_engine_hoist", ["bone"] = 28422, ["x"] = 0.0,["y"] = -0.5,["z"] = -1.3,["xR"] = -195.0,["yR"] = -180.0, ["zR"] = 180.0 
    }
}

RegisterNetEvent('inrp_mechanicjob:attachProp')
AddEventHandler('inrp_mechanicjob:attachProp', function(attachModelSent,boneNumberSent,x,y,z,xR,yR,zR)
    exports['mythic_notify']:SendAlert('inform', "Prop Spawned. Type /re to remove Object") -- mythic_notify system
    closestEntity = 0
    holdingPackage = true
    local attachModel = GetHashKey(attachModelSent)
    boneNumber = boneNumberSent
    SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263) 
    local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumberSent)
    RequestModel(attachModel)
    while not HasModelLoaded(attachModel) do
        Citizen.Wait(100)
    end
    closestEntity = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(closestEntity, GetPlayerPed(-1), bone, x, y, z, xR, yR, zR, 1, 1, 0, true, 2, 1)

    APPbone = bone
    APPx = x
    APPy = y
    APPz = z
    APPxR = xR
    APPyR = yR
    APPzR = zR
end)

function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 10 )
    end
end

function randPickupAnim()
  local randAnim = math.random(7)
    loadAnimDict('random@domestic')
    TaskPlayAnim(GetPlayerPed(-1),'random@domestic', 'pickup_low',5.0, 1.0, 1.0, 48, 0.0, 0, 0, 0)
end

function holdAnim()
    loadAnimDict( "anim@heists@box_carry@" )
	TaskPlayAnim((GetPlayerPed(-1)),"anim@heists@box_carry@","idle",4.0, 1.0, -1,49,0, 0, 0, 0)
end

Citizen.CreateThread( function()
    while true do 
		Citizen.Wait(10)
		if ((IsDisabledControlJustPressed(0, dropkey) or (GetHashKey("WEAPON_UNARMED") ~= GetSelectedPedWeapon(GetPlayerPed(-1)))) and (closestEntity ~= 0) and (PlayerData ~= nil) and (PlayerData.job.name == 'mechanic')) then
			local trackedEntities = {
				'prop_roadcone02a',
				'prop_tool_box_04',
				'prop_cs_trolley_01',
				'prop_engine_hoist',
				'imp_prop_car_jack_01a',
				'prop_cs_cardbox_01'
			}

			local playerPed = PlayerPedId()
			local coords    = GetEntityCoords(playerPed)

			local closestDistance = -1
			closestEntity   = nil
			local closestEntityName   = nil

			for i=1, #trackedEntities, 1 do
				local object = GetClosestObjectOfType(coords, 1.5, GetHashKey(trackedEntities[i]), false, false, false)
				if DoesEntityExist(object) then
					local objCoords = GetEntityCoords(object)
					local distance  = GetDistanceBetweenCoords(coords, objCoords, true)

					if closestDistance == -1 or closestDistance > distance then
						closestDistance = distance
						closestEntity   = object
						closestEntityName = trackedEntities[i]
					end
				end
			end
			if not holdingPackage then
				local dst = GetDistanceBetweenCoords(GetEntityCoords(closestEntity) ,GetEntityCoords(GetPlayerPed(-1)),true)                 
				if dst < 2 then
					holdingPackage = true
					if (closestEntityName == 'prop_roadcone02a') or (closestEntityName == 'prop_tool_box_04') or (closestEntityName == 'prop_cs_cardbox_01') then
						randPickupAnim()
					end
					Citizen.Wait(350)
					ClearPedTasks(GetPlayerPed(-1))
					ClearPedSecondaryTask(GetPlayerPed(-1))
					if (closestEntityName == 'prop_cs_trolley_01') or (closestEntityName == 'prop_engine_hoist') or (closestEntityName == 'imp_prop_car_jack_01a') or (closestEntityName == 'prop_cs_cardbox_01') then
						holdAnim()
					end
					Citizen.Wait(350)
					AttachEntityToEntity(closestEntity, GetPlayerPed(-1),GetPedBoneIndex(GetPlayerPed(-1), attachPropList[closestEntityName]["bone"]), attachPropList[closestEntityName]["x"], attachPropList[closestEntityName]["y"], attachPropList[closestEntityName]["z"], attachPropList[closestEntityName]["xR"], attachPropList[closestEntityName]["yR"], attachPropList[closestEntityName]["zR"], 1, 1, 0, true, 2, 1)
				end
			else
				holdingPackage = false
				if (closestEntityName == 'prop_roadcone02a') or (closestEntityName == 'prop_tool_box_04') or (closestEntityName == 'prop_cs_cardbox_01')then
					randPickupAnim()
				end
				Citizen.Wait(350)
				DetachEntity(closestEntity)
				ClearPedTasks(GetPlayerPed(-1))
				ClearPedSecondaryTask(GetPlayerPed(-1))
			end
		end
	end
end)

attachedProp = 0
function removeAttachedProp()
    if DoesEntityExist(attachedProp) then
        DeleteEntity(attachedProp)
        attachedProp = 0
    end
end

RegisterNetEvent('inrp_mechanicjob:attachItem')
AddEventHandler('inrp_mechanicjob:attachItem', function(item)
    TriggerEvent("inrp_mechanicjob:attachProp",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"])
end)

--prop_cs_trolley_01
RegisterNetEvent('attach:prop_cs_trolley_01')
AddEventHandler('attach:prop_cs_trolley_01', function()
	holdAnim()
    TriggerEvent("inrp_mechanicjob:attachItem","prop_cs_trolley_01")
end)

--prop_engine_hoist
RegisterNetEvent('attach:prop_engine_hoist')
AddEventHandler('attach:prop_engine_hoist', function()
	holdAnim()
    TriggerEvent("inrp_mechanicjob:attachItem","prop_engine_hoist")
end)

--prop_tool_box_04
RegisterNetEvent('attach:prop_tool_box_04')
AddEventHandler('attach:prop_tool_box_04', function()
    TriggerEvent("inrp_mechanicjob:attachItem","prop_tool_box_04")
end)

--prop_roadcone02a
RegisterNetEvent('attach:prop_roadcone02a')
AddEventHandler('attach:prop_roadcone02a', function()
    TriggerEvent("inrp_mechanicjob:attachItem","prop_roadcone02a")
end)

--prop_cs_cardbox_01
RegisterNetEvent('attach:prop_cs_cardbox_01')
AddEventHandler('attach:prop_cs_cardbox_01', function()
	holdAnim()
    TriggerEvent("inrp_mechanicjob:attachItem","prop_cs_cardbox_01")
end)

RegisterNetEvent('inrp_mechanicjob:removeall')
AddEventHandler('inrp_mechanicjob:removeall', function()
    TriggerEvent("disabledWeapons",false)
	ClearPedTasks(GetPlayerPed(-1))
	ClearPedSecondaryTask(GetPlayerPed(-1))
	Citizen.Wait(500)
	DetachEntity(closestEntity)
end)

RegisterNetEvent("disabledWeapons")
AddEventHandler("disabledWeapons", function(sentinfo)
    SetCurrentPedWeapon(GetPlayerPed(-1), GetHashKey("weapon_unarmed"), 1)
    disabledWeapons = sentinfo
	removeAttachedProp()
	holdingPackage = false
end)





------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--------------------------------------- MECHANIC JOB ---------------------------------------
---------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------



	

function OpenMechanicActionsMenu()
	local playerPed = PlayerPedId()
	local grade = PlayerData.job.grade_name
	local elements = {
		{label = _U('vehicle_list'),   value = 'vehicle_list'},
		{label = _U('work_wear'),      value = 'cloakroom'},
		{label = _U('civ_wear'),       value = 'cloakroom2'},
		{label = _U('deposit_stock'),  value = 'put_stock'},
		{label = _U('withdraw_stock'), value = 'get_stock'}
	}

	if Config.EnablePlayerManagement and PlayerData.job and grade == 'boss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mechanic_actions', {
		title    = _U('mechanic'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'vehicle_list' then
			if Config.EnableSocietyOwnedVehicles then

				local elements = {}

				ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)
					for i=1, #vehicles, 1 do
						table.insert(elements, {
							label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']',
							value = vehicles[i]
						})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
						title    = _U('service_vehicle'),
						align    = 'top-left',
						elements = elements
					}, function(data, menu)
						menu.close()
						local vehicleProps = data.current.value

						ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, 270.0, function(vehicle)
							ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
							local playerPed = PlayerPedId()
							TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
						end)

						TriggerServerEvent('esx_society:removeVehicleFromGarage', 'mechanic', vehicleProps)
					end, function(data, menu)
						menu.close()
					end)
				end, 'mechanic')

			else

				local elements = {
					{label = _U('flat_bed'),  value = 'flatbed'},
					{label = _U('tow_truck'), value = 'towtruck2'}
				}

				if Config.EnablePlayerManagement and ESX.PlayerData.job and (ESX.PlayerData.job.grade_name == 'boss' or ESX.PlayerData.job.grade_name == 'chief' or ESX.PlayerData.job.grade_name == 'experimente') then
					table.insert(elements, {label = 'SlamVan', value = 'slamvan3'})
				end

				ESX.UI.Menu.CloseAll()

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_vehicle', {
					title    = _U('service_vehicle'),
					align    = 'top-left',
					elements = elements
				}, function(data, menu)
					if Config.MaxInService == -1 then
						ESX.Game.SpawnVehicle(data.current.value, Config.Zones.VehicleSpawnPoint.Pos, 90.0, function(vehicle)
							local playerPed = PlayerPedId()
							TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
						end)
					else
						ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
							if canTakeService then
								ESX.Game.SpawnVehicle(data.current.value, Config.Zones.VehicleSpawnPoint.Pos, 90.0, function(vehicle)
									local playerPed = PlayerPedId()
									TaskWarpPedIntoVehicle(playerPed,  vehicle, -1)
								end)
							else
								ESX.Showmythic_notify(_U('service_full') .. inServiceCount .. '/' .. maxInService)
							end
						end, 'mechanic')
					end

					menu.close()
				end, function(data, menu)
					menu.close()
					OpenMechanicActionsMenu()
				end)

			end
		elseif data.current.value == 'cloakroom' then
			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
				end
			end)
		elseif data.current.value == 'cloakroom2' then
			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
		elseif data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		elseif data.current.value == 'boss_actions' then
			TriggerEvent('esx_society:openBossMenu', 'mechanic', function(data, menu)
				menu.close()
			end)
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'mechanic_actions_menu'
		CurrentActionData = {}
	end)
end

function OpenMechanicHarvestMenu()
	if Config.EnablePlayerManagement and ESX.PlayerData.job and ESX.PlayerData.job.grade_name ~= 'recrue' then
		local elements = {
			{label = _U('gas_can'), value = 'gaz_bottle'},
			{label = _U('repair_tools'), value = 'fix_tool'},
			{label = _U('body_work_tools'), value = 'caro_tool'}
		}

		ESX.UI.Menu.CloseAll()

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mechanic_harvest', {
			title    = _U('harvest'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			if data.current.value == 'gaz_bottle' then
				TriggerServerEvent('esx_mechanicjob:startHarvest')
			elseif data.current.value == 'fix_tool' then
				TriggerServerEvent('esx_mechanicjob:startHarvest2')
			elseif data.current.value == 'caro_tool' then
				TriggerServerEvent('esx_mechanicjob:startHarvest3')
			end
		end, function(data, menu)
			menu.close()
			CurrentAction     = 'mechanic_harvest_menu'
			CurrentActionMsg  = _U('harvest_menu')
			CurrentActionData = {}
		end)
	else
		ESX.ShowNotification(_U('not_experienced_enough'))
	end
end

function OpenMechanicCraftMenu()
	if Config.EnablePlayerManagement and ESX.PlayerData.job and ESX.PlayerData.job.grade_name ~= 'recrue' then
		local elements = {
			{label = _U('blowtorch'),  value = 'blow_pipe'},
			{label = _U('repair_kit'), value = 'fix_kit'},
			{label = _U('body_kit'),   value = 'caro_kit'}
		}

		ESX.UI.Menu.CloseAll()

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mechanic_craft', {
			title    = _U('craft'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			if data.current.value == 'blow_pipe' then
				TriggerServerEvent('esx_mechanicjob:startCraft')
			elseif data.current.value == 'fix_kit' then
				TriggerServerEvent('esx_mechanicjob:startCraft2')
			elseif data.current.value == 'caro_kit' then
				TriggerServerEvent('esx_mechanicjob:startCraft3')
			end
		end, function(data, menu)
			menu.close()

			CurrentAction     = 'mechanic_craft_menu'
			CurrentActionMsg  = _U('craft_menu')
			CurrentActionData = {}
		end)
	else
		ESX.ShowNotification(_U('not_experienced_enough'))
	end
end


function RegisterCommands()
	PlayerData = ESX.GetPlayerData()
	if PlayerData.job.name == 'mechanic' then
		RegisterCommand("faturas", function(source, args, raw) --change command here
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
				title = _U('invoice_amount')
				}, function(data, menu)
				local amount = tonumber(data.value)

				if amount == nil or amount < 0 then
					exports['mythic_notify']:SendAlert('error', 'Invalid Amount!')
				else
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > Config.DrawDistance then
						exports['mythic_notify']:SendAlert('error', 'No players nearby!')
					else
						menu.close()
						TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_mechanic', _U('mechanic'), amount)
						exports['mythic_notify']:SendAlert('success', 'You sent invoice of - ₹' .. amount .. '')
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end, false)

		RegisterCommand("limparveiculo", function(source, args, raw) --change command here
			local playerPed = PlayerPedId()
			local vehicle   = ESX.Game.GetVehicleInDirection()
			local coords    = GetEntityCoords(playerPed)

			if IsPedSittingInAnyVehicle(playerPed) then
				exports['mythic_notify']:SendAlert('error', 'Get out of car to clean it!')
				return
			end

			if DoesEntityExist(vehicle) then
				isBusy = true
				TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
				Citizen.CreateThread(function()
					Citizen.Wait(10000)

					SetVehicleDirtLevel(vehicle, 0)
					ClearPedTasksImmediately(playerPed)

					exports['mythic_notify']:SendAlert('success', 'Cleaned the Vehicle!!')
					isBusy = false
				end)
			else
				exports['mythic_notify']:SendAlert('error', 'No vehicle nearby!')
			end
		end, false)

		RegisterCommand("delveiculo", function(source, args, raw) --change command here
			local playerPed = PlayerPedId()

			if IsPedSittingInAnyVehicle(playerPed) then
				local vehicle = GetVehiclePedIsIn(playerPed, false)

				if GetPedInVehicleSeat(vehicle, -1) == playerPed then
					exports['mythic_notify']:SendAlert('success', 'Successfully impounded the vehicle!')
					ESX.Game.DeleteVehicle(vehicle)
				else
					exports['mythic_notify']:SendAlert('error', 'No vehicle nearby!')
				end
			else
				local vehicle = ESX.Game.GetVehicleInDirection()

				if DoesEntityExist(vehicle) then
					exports['mythic_notify']:SendAlert('success', 'Successfully impounded the vehicle!')
					ESX.Game.DeleteVehicle(vehicle)
				else
					exports['mythic_notify']:SendAlert('error', 'No vehicle nearby!')
				end
			end
		end, false)

		RegisterCommand("rebveiculo", function(source, args, raw) --change command here
			local playerPed = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(playerPed, true)
			local towmodel = GetHashKey('flatbed')
			local isVehicleTow = IsVehicleModel(vehicle, towmodel)

			if isVehicleTow then
				local targetVehicle = ESX.Game.GetVehicleInDirection()

				if CurrentlyTowedVehicle == nil then
					if targetVehicle ~= 0 then
						if not IsPedInAnyVehicle(playerPed, true) then
							if vehicle ~= targetVehicle then
								AttachEntityToEntity(targetVehicle, vehicle, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
								CurrentlyTowedVehicle = targetVehicle
								ESX.Showmythic_notify(_U('vehicle_success_attached'))
							else
								exports['mythic_notify']:SendAlert('error', 'You cannot tow your own vehicle!')
							end
						end
					else
						exports['mythic_notify']:SendAlert('error', 'No vehicles around')
					end
				else
					AttachEntityToEntity(CurrentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
					DetachEntity(CurrentlyTowedVehicle, true, true)
					CurrentlyTowedVehicle = nil
					exports['mythic_notify']:SendAlert('sucess', 'Vehicle Successfully impounded')
				end
			else
				exports['mythic_notify']:SendAlert('error', 'Flat Bed Required!')
			end
		end, false)
		
		RegisterCommand("re", function() -- remove entity 
			TriggerEvent("disabledWeapons",false)
			DeleteEntity(closestEntity)
			ClearPedTasks(GetPlayerPed(-1))
			ClearPedSecondaryTask(GetPlayerPed(-1))
		end, false)
		
		RegisterCommand("prop_cs_trolley_01", function(source, args, raw)
			local arg = args[1]

			if arg ~= nil then
				TriggerEvent("inrp_mechanicjob:removeall")
			elseif not holdingPackage then
				holdAnim()
				TriggerEvent("attach:prop_cs_trolley_01")
			elseif holdingPackage then
				exports['mythic_notify']:SendAlert('error', 'You already have something in your hand!')
			end
			
		end, false)
		
		RegisterCommand("prop_engine_hoist", function(source, args, raw)
			local arg = args[1]

			if arg ~= nil then
				TriggerEvent("inrp_mechanicjob:removeall")
			elseif not holdingPackage then
				holdAnim()
				TriggerEvent("attach:prop_engine_hoist")
			elseif holdingPackage then
				exports['mythic_notify']:SendAlert('error', 'You already have something in your hand!')
			end
		end, false)
		
		RegisterCommand("prop_roadcone02a", function(source, args, raw)
			local arg = args[1]

			if arg ~= nil then
				TriggerEvent("inrp_mechanicjob:removeall")
			elseif not holdingPackage then
				TriggerEvent("attach:prop_roadcone02a")
			elseif holdingPackage then
				exports['mythic_notify']:SendAlert('error', 'You already have something in your hand!')
			end
		end, false)
		
		--[[RegisterCommand("imp_prop_car_jack_01a", function(source, args, raw)
			local arg = args[1]

			if arg ~= nil then
				TriggerEvent("inrp_mechanicjob:removeall")
			elseif not holdingPackage then
				holdAnim()
				TriggerEvent("attach:imp_prop_car_jack_01a")
			end
		end, false)]]
		
		RegisterCommand("prop_engine_hoist", function(source, args, raw)
			local arg = args[1]

			if arg ~= nil then
				TriggerEvent("inrp_mechanicjob:removeall")
			elseif not holdingPackage then
				holdAnim()
				TriggerEvent("attach:prop_engine_hoist")
			elseif holdingPackage then
				exports['mythic_notify']:SendAlert('error', 'You already have something in your hand!')
			end
		end, false)
		
		RegisterCommand("prop_tool_box_04", function(source, args, raw)
			local arg = args[1]

			if arg ~= nil then
				TriggerEvent("inrp_mechanicjob:removeall")
			elseif not holdingPackage then
				TriggerEvent("attach:prop_tool_box_04")
			elseif holdingPackage then
				exports['mythic_notify']:SendAlert('error', 'You already have something in your hand!')
			end
		end, false)
	else
		exports['mythic_notify']:SendAlert('error', 'You no longer have access to this command!')
	end
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_mechanicjob:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('mechanic_stock'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.Showmythic_notify(_U('invalid_quantity'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_mechanicjob:getStockItem', itemName, count)

					Citizen.Wait(1000)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('esx_mechanicjob:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type  = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.Showmythic_notify(_U('invalid_quantity'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_mechanicjob:putStockItems', itemName, count)

					Citizen.Wait(1000)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

RegisterNetEvent('esx_mechanicjob:onHijack')
AddEventHandler('esx_mechanicjob:onHijack', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		local chance = math.random(100)
		local alarm  = math.random(100)

		if DoesEntityExist(vehicle) then
			if alarm <= 33 then
				SetVehicleAlarm(vehicle, true)
				StartVehicleAlarm(vehicle)
			end

			TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)

			Citizen.CreateThread(function()
				Citizen.Wait(10000)
				if chance <= 66 then
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ClearPedTasksImmediately(playerPed)
					ESX.Showmythic_notify(_U('veh_unlocked'))
				else
					ESX.Showmythic_notify(_U('hijack_failed'))
					ClearPedTasksImmediately(playerPed)
				end
			end)
		end
	end
end)

RegisterNetEvent('esx_mechanicjob:onCarokit')
AddEventHandler('esx_mechanicjob:onCarokit', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		if DoesEntityExist(vehicle) then
			TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_HAMMERING', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(10000)
				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				ClearPedTasksImmediately(playerPed)
				ESX.Showmythic_notify(_U('body_repaired'))
			end)
		end
	end
end)

RegisterNetEvent('esx_mechanicjob:onFixkit')
AddEventHandler('esx_mechanicjob:onFixkit', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		if DoesEntityExist(vehicle) then
			TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(20000)
				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				SetVehicleUndriveable(vehicle, false)
				ClearPedTasksImmediately(playerPed)
				ESX.Showmythic_notify(_U('veh_repaired'))
			end)
		end
	end
end)

AddEventHandler('esx_mechanicjob:hasEnteredMarker', function(zone)
	

	if zone == 'MechanicActions' then
		CurrentAction     = 'mechanic_actions_menu'
		CurrentActionData = {}
	elseif zone == 'Garage' then
		CurrentAction     = 'mechanic_harvest_menu'
		CurrentActionData = {}
	elseif zone == 'Craft' then
		CurrentAction     = 'mechanic_craft_menu'
		CurrentActionData = {}
	elseif zone == 'ls1' then
		CurrentAction     = 'ls_custom'
		CurrentActionData = {}
	elseif zone == 'ls2' then
		CurrentAction     = 'ls_custom'
		CurrentActionData = {}
	elseif zone == 'ls3' then
		CurrentAction     = 'ls_custom'
		CurrentActionData = {}
	elseif zone == 'VehicleDeleter' then
		local playerPed = PlayerPedId()

		if IsPedInAnyVehicle(playerPed, true) then
			local vehicle = GetVehiclePedIsIn(playerPed,  false)

			CurrentAction     = 'delete_vehicle'
			CurrentActionData = {vehicle = vehicle}
		end
	end
end)

AddEventHandler('esx_mechanicjob:hasExitedMarker', function(zone)
	if zone =='VehicleDelivery' then
		NPCTargetDeleterZone = false
	elseif zone == 'Craft' then
		TriggerServerEvent('esx_mechanicjob:stopCraft')
		TriggerServerEvent('esx_mechanicjob:stopCraft2')
		TriggerServerEvent('esx_mechanicjob:stopCraft3')
	elseif zone == 'Garage' then
		TriggerServerEvent('esx_mechanicjob:stopHarvest')
		TriggerServerEvent('esx_mechanicjob:stopHarvest2')
		TriggerServerEvent('esx_mechanicjob:stopHarvest3')
	end

	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = _U('phone_mechanic'),
		number     = 'mechanic',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDFGQTJDRkI0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NDFGQTJDRkM0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo0MUZBMkNGOTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo0MUZBMkNGQTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PoW66EYAAAjGSURBVHjapJcLcFTVGcd/u3cfSXaTLEk2j80TCI8ECI9ABCyoiBqhBVQqVG2ppVKBQqUVgUl5OU7HKqNOHUHU0oHamZZWoGkVS6cWAR2JPJuAQBPy2ISEvLN57+v2u2E33e4k6Ngz85+9d++95/zP9/h/39GpqsqiRYsIGz8QZAq28/8PRfC+4HT4fMXFxeiH+GC54NeCbYLLATLpYe/ECx4VnBTsF0wWhM6lXY8VbBE0Ch4IzLcpfDFD2P1TgrdC7nMCZLRxQ9AkiAkQCn77DcH3BC2COoFRkCSIG2JzLwqiQi0RSmCD4JXbmNKh0+kc/X19tLtc9Ll9sk9ZS1yoU71YIk3xsbEx8QaDEc2ttxmaJSKC1ggSKBK8MKwTFQVXRzs3WzpJGjmZgvxcMpMtWIwqsjztvSrlzjYul56jp+46qSmJmMwR+P3+4aZ8TtCprRkk0DvUW7JjmV6lsqoKW/pU1q9YQOE4Nxkx4ladE7zd8ivuVmJQfXZKW5dx5EwPRw4fxNx2g5SUVLw+33AkzoRaQDP9SkFu6OKqz0uF8yaz7vsOL6ycQVLkcSg/BlWNsjuFoKE1knqDSl5aNnmPLmThrE0UvXqQqvJPyMrMGorEHwQfEha57/3P7mXS684GFjy8kreLppPUuBXfyd/ibeoS2kb0mWPANhJdYjb61AxUvx5PdT3+4y+Tb3mTd19ZSebE+VTXVGNQlHAC7w4VhH8TbA36vKq6ilnzlvPSunHw6Trc7inrp_mechanicjobZ14AyfgYeyz18crGN1Alz6e3qwNNQSv4dZox1h/BW9+O7eIaEsVv41Y4XeHJDG83Nl4mLTwzGhJYtx0PzNTjOB9KMTlc7Nkcem39YAGU7cbeBKVLMPGMVf296nMd2VbBq1wmizHoqqm/wrS1/Zf0+N19YN2PIu1fcIda4Vk66Zx/rVi+jo9eIX9wZGGcFXUMR6BHUa76/2ezioYcXMtpyAl91DSaTfDxlJbtLprHm2ecpObqPuTPzSNV9yKz4a4zJSuLo71/j8Q17ON69EmXiPIlNMe6FoyzOqWPW/MU03Lw5EFcyKghTrNDh7+/vw545mcJcWbTiGKpRdGPMXbx90sGmDaux6sXk+kimjU+BjnMkx3kYP34cXrFuZ+3nrHi6iDMt92JITcPjk3R3naRwZhpuNSqoD93DKaFVU7j2dhcF8+YzNlpErbIBTVh8toVccbaysPB+4pMcuPw25kwSsau7BIlmHpy3guaOPtISYyi/UkaJM5Lpc5agq5Xkcl6gIHkmqaMn0dtylcjIyPThCNyhaXyfR2W0I1our0v6qBii07ih5rDtGSOxNVdk1y4R2SR8jR/g7hQD9l1jUeY/WLJB5m39AlZN4GZyIQ1fFJNsEgt0duBIc5GRkcZF53mNwIzhinrp_mechanicjobDgQPoZIkiMkbTxtstDMVnmFA4cOsbz2/aKjSQjev4Mp9ZAg+hIpFhB3EH5Yal16+X+Kq3dGfxkzRY+KauBjBzREvGN0kNCTARu94AejBLMHorAQ7cEQMGs2cXvkWshYLDi6e9l728O8P1XW6hKeB2yv42q18tjj+iFTGoSi+X9jJM9RTxS9E+OHT0krhNiZqlbqraoT7RAU5bBGrEknEBhgJks7KXbLS8qERI0ErVqF/Y4K6NHZfLZB+/wzJvncacvFd91oXO3o/O40MfZKJOKu/rne+mRQByXM4lYreb1tUnkizVVA/0SpfpbWaCNBeEE5gb/UH19NLqEgDF+oNDQWcn41Cj0EXFEWqzkOIyYekslFkThsvMinrp_mechanicjobIyE2hIc6lXGZ6cPyK7Nnk5OipixRdxgUESAYmhq68VsGgy5CYKCUAJTg0+izApXne3CJFmUTwg4L3FProFxU+6krqmXu3MskkhSD2av41jLdzlnfFrSdCZxyqfMnppN6ZUa7pwt0h3fiK9DCt4IO9e7YqisvI7VYgmNv7mhBKKD/9psNi5dOMv5ZjukjsLdr0ffWsyTi6eSlfcA+dmiVyOXs+/sHNZu3M6PdxzgVO9GmDSHsSNqmTz/R6y6Xxqma4fwaS5Mn85n1ZE0Vl3CHBER3lUNEhiURpPJRFdTOcVnpUJnPIhR7cZXfoH5UYc5+E4RzRH3sfSnl9m2dSMjE+Tz9msse+o5dr7UwcQ5T3HwlWUkNuzG3dKFSTbsNs7m/Y8vExOlC29UWkMJlAxKoRQMR3IC7x85zOn6fHS50+U/2Untx2R1voinu5no+DQmz7yPXmMKZnsu0wrm0Oe3YhOVHdm8A09dBQYhTv4T7C+xUPrZh8Qn2MMr4qcDSRfoirWgKAvtgOpv1JI8Zi77X15G7L+fxeOUOiUFxZiULD5fSlNzNM62W+k1yq5gjajGX/ZHvOIyxd+Fkj+P092rWP/si0Qr7VisMaEWuCiYonXFwbAUTWWPYLV245NITnGkUXnpI9butLJn2y6iba+hlp7C09qBcvoN7FYL9mhxo1/y/LoEXK8Pv6qIC8WbBY/xr9YlPLf9dZT+OqKTUwfmDBm/GOw7ws4FWpuUP2gJEZvKqmocuinrp_mechanicjobZuWYJMzKuSsH+SNwh3bo0p6hao6HeEqwYEZ2M6aKWd3PwTCy7du/D0F1DsmzE6/WGLr5LsDF4LggnYBacCOboQLHQ3FFfR58SR+HCR1iQH8ukhA5s5o5AYZMwUqOp74nl8xvRHDlRTsnxYpJsUjtsceHt2C8Fm0MPJrphTkZvBc4It9RKLOFx91Pf0Igu0k7W2MmkOewS2QYJUJVWVz9VNbXUVVwkyuAmKTFJayrDo/4Jwe/CT0aGYTrWVYEeUfsgXssMRcpyenraQJa0VX9O3ZU+Ma1fax4xGxUsUVFkOUbcama1hf+7+LmA9juHWshwmwOE1iMmCFYEzg1jtIm1BaxW6wCGGoFdewPfvyE4ertTiv4rHC73B855dwp2a23bbd4tC1hvhOCbX7b4VyUQKhxrtSOaYKngasizvwi0RmOS4O1QZf2yYfiaR+73AvhTQEVf+rpn9/8IMAChKDrDzfsdIQAAAABJRU5ErkJggg=='
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- Create Blips
Citizen.CreateThread(function()

	local blip = AddBlipForCoord(Config.Blip.Pos.x, Config.Blip.Pos.y, Config.Blip.Pos.z)
	SetBlipSprite (blip, Config.Blip.Sprite)
	SetBlipDisplay(blip, Config.Blip.Display)
	SetBlipScale  (blip, Config.Blip.Scale)
	SetBlipColour (blip, Config.Blip.Colour)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('mechanic'))
	EndTextCommandSetBlipName(blip)

end)

-- Display markers
Citizen.CreateThread(function()
	local playerPed = PlayerPedId()
	while true do
		Citizen.Wait(10)

		if PlayerData.job and PlayerData.job.name == 'mechanic' then
			local coords, letSleep = GetEntityCoords(PlayerPedId()), true

			for k,v in pairs(Config.Zones) do
				if (v.Type ~= -1) and (GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
					DrawText3Ds(v.Pos.x, v.Pos.y, v.Pos.z, v.Text)
					letSleep = false
				end
			end

			if letSleep then
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

-- Display enter job marker
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		-- PREVENT FREE TUNING IS LS CUSTOM // THIS IS HERE FOR OTIMIZATION ONLY
		if lsMenuIsShowed then
			DisableControlAction(2, 288, true)
			DisableControlAction(2, 289, true)
			DisableControlAction(2, 170, true)
			DisableControlAction(2, 167, true)
			DisableControlAction(2, 166, true)
			DisableControlAction(2, 23, true)
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		end
		
		if Config.EnableEmploy and PlayerData.job then
			local coords = GetEntityCoords(PlayerPedId(-1))	
			if (GetDistanceBetweenCoords(coords,Config.Employ.Coords.x,Config.Employ.Coords.y,Config.Employ.Coords.z) < 3.5) and (PlayerData.job.name ~= 'mechanic') then
				for i=1,#Config.Employ.Workers do 
					if Config.Employ.Workers[i].identifier == PlayerData.identifier then
						DrawText3Ds(Config.Employ.Coords.x,Config.Employ.Coords.y,Config.Employ.Coords.z, 'Press ~g~[E] ~w~to open menu!')
						if IsControlJustReleased(0, 38) then
							TriggerServerEvent('esx_mechanicjob:setJob',PlayerData.identifier,'mechanic',Config.Employ.Workers[i].grade)
							exports['mythic_notify']:SendAlert('success', 'You need to be in Mechanic Job to do this.')
						end
					end
				end
			end
		end
	end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if PlayerData.job and PlayerData.job.name == 'mechanic' then

			local coords      = GetEntityCoords(PlayerPedId())
			local isInMarker  = false
			local currentZone = nil
			
			for k,v in pairs(Config.Zones) do
				if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
					isInMarker  = true
					currentZone = k
				end
			end

			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker = true
				LastZone                = currentZone
				TriggerEvent('esx_mechanicjob:hasEnteredMarker', currentZone)
			end

			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_mechanicjob:hasExitedMarker', LastZone)
			end

		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_mechanicjob:removeSpecialContact', 'mechanic')

		if Config.MaxInService ~= -1 then
			TriggerServerEvent('esx_service:disableService', 'mechanic')
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if CurrentAction then

			if IsControlJustReleased(0, 38) and PlayerData.job and PlayerData.job.name == 'mechanic' then

				if CurrentAction == 'mechanic_actions_menu' then
					OpenMechanicActionsMenu()
				elseif CurrentAction == 'mechanic_harvest_menu' then
					OpenMechanicHarvestMenu()
				elseif CurrentAction == 'mechanic_craft_menu' then
					OpenMechanicCraftMenu()
				elseif CurrentAction == 'ls_custom' then
					OpenLSAction()
				elseif CurrentAction == 'delete_vehicle' then

					if Config.EnableSocietyOwnedVehicles then

						local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
						TriggerServerEvent('esx_society:putVehicleInGarage', 'mechanic', vehicleProps)

					else

						if
							GetEntityModel(vehicle) == GetHashKey('flatbed')   or
							GetEntityModel(vehicle) == GetHashKey('towtruck2') or
							GetEntityModel(vehicle) == GetHashKey('slamvan3')
						then
							TriggerServerEvent('esx_service:disableService', 'mechanic')
						end

					end

					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				end
			end
		end

	end
end)

function OpenLSAction()

	if IsControlJustReleased(0, 38) and not lsMenuIsShowed then
		if ((PlayerData.job ~= nil and PlayerData.job.name == 'mechanic') or Config.IsMechanicJobOnly == false) then
			lsMenuIsShowed = true
			local coords 		= GetEntityCoords(GetPlayerPed(-1))
			local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 71)
			if (vehicle ~= nil) then
				FreezeEntityPosition(vehicle, true)
				FreezeEntityPosition(GetPlayerPed(-1), true)
				myCar = ESX.Game.GetVehicleProperties(vehicle)
				ESX.UI.Menu.CloseAll()
				GetAction({value = 'main'})
			end
		end
	end
	if isInLSMarker and not hasAlreadyEnteredMarker then
		hasAlreadyEnteredMarker = true
	end
	if not isInLSMarker and hasAlreadyEnteredMarker then
		hasAlreadyEnteredMarker = false
	end

end

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
end)



---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------RADIALMENU--------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------



Citizen.CreateThread(function()
    -- Update every frame
    while true do
        Citizen.Wait(10)
        -- Loop through all menus in config
        for _, menuConfig in pairs(menuConfigs) do
            -- Check if menu should be enabled
            if menuConfig:enableMenu() then
                -- When keybind is pressed toggle UI
                local keybindControl = menuConfig.data.keybind
				if ((IsControlJustReleased(0, keybindControl)) and (PlayerData.job.name == 'mechanic')) then
					-- Init UI
					showMenu = true
					SendNUIMessage({
						type = 'init',
						data = menuConfig.data,
						resourceName = GetCurrentResourceName()
					})

					-- Set cursor position and set focus
					SetCursorLocation(0.5, 0.5)
					SetNuiFocus(true, true)

					-- Play sound
					PlaySoundFrontend(-1, "NAV", "HUD_AMMO_SHOP_SOUNDSET", 1)
				end
            end
        end
    end
end)

RegisterCommand("MECsubmenu1", function(source, args, rawCommand)
    -- Wait for next frame just to be safe
    Citizen.Wait(10)

    -- Init UI and set focus
    showMenu = true
    SendNUIMessage({
        type = 'init',
        data = subMenuConfigs["MECsubmenu1"].data,
        resourceName = GetCurrentResourceName()
    })
    SetNuiFocus(true, true)
end, false)

RegisterCommand("MECsubmenu2", function(source, args, rawCommand)
    -- Wait for next frame just to be safe
    Citizen.Wait(10)

    -- Init UI and set focus
    showMenu = true
    SendNUIMessage({
        type = 'init',
        data = subMenuConfigs["MECsubmenu2"].data,
        resourceName = GetCurrentResourceName()
    })
    SetNuiFocus(true, true)
end, false)

-- Callback function for closing menu
RegisterNUICallback('closemenu', function(data, cb)
    -- Clear focus and destroy UI
    showMenu = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'destroy'
    })

    -- Play sound
    PlaySoundFrontend(-1, "NAV", "HUD_AMMO_SHOP_SOUNDSET", 1)

    -- Send ACK to callback function
    cb('ok')
end)

-- Callback function for when a slice is clicked, execute command
RegisterNUICallback('sliceclicked', function(data, cb)
    -- Clear focus and destroy UI
    showMenu = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'destroy'
    })

    -- Play sound
    PlaySoundFrontend(-1, "NAV", "HUD_AMMO_SHOP_SOUNDSET", 1)

    -- Run command
    ExecuteCommand(data.command)

    -- Send ACK to callback function
    cb('ok')
end)

---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------LSCUSTOM--------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	ESX.TriggerServerCallback('esx_mechanicjob:getVehiclesPrices', function(vehicles)
		Vehicles = vehicles
	end)
end)

RegisterNetEvent('esx_mechanicjob:installMod')
AddEventHandler('esx_mechanicjob:installMod', function()
	local coords 		= GetEntityCoords(GetPlayerPed(-1))
	local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
	myCar = ESX.Game.GetVehicleProperties(vehicle)
	TriggerServerEvent('esx_mechanicjob:refreshOwnedVehicle', myCar)
end)

RegisterNetEvent('esx_mechanicjob:cancelInstallMod')
AddEventHandler('esx_mechanicjob:cancelInstallMod', function()
	local coords 		= GetEntityCoords(GetPlayerPed(-1))
	local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
	ESX.Game.SetVehicleProperties(vehicle, myCar)
end)

function OpenLSMenu(elems, menuName, menuTitle, parent)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), menuName,
	{
		title    = menuTitle,
		align    = 'top-left',
		elements = elems
	}, function(data, menu)
		local isRimMod = false
		local found = false
		local coords 		= GetEntityCoords(GetPlayerPed(-1))
		local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
		if data.current.modType == "modFrontWheels" then
			isRimMod = true
		end
		RegisterLS()
		for k,v in pairs(Config.Menus) do
			if k == data.current.modType or isRimMod then
				if data.current.label == _U('by_default') or string.match(data.current.label, _U('installed')) then
					ESX.Showmythic_notify(_U('already_own', data.current.label))
					TriggerEvent('esx_mechanicjob:installMod')
				else
					local vehiclePrice = 80000
					for i=1, #Vehicles, 1 do
						if GetEntityModel(vehicle) == GetHashKey(Vehicles[i].model) then
							vehiclePrice = Vehicles[i].price
							break
						end
					end
					if data.current.price ~= nil then
						if isRimMod then
							price = math.floor(vehiclePrice * data.current.price / 100)
							TriggerServerEvent("esx_mechanicjob:buyMod", price)
						elseif v.modType == 11 or v.modType == 12 or v.modType == 13 or v.modType == 15 or v.modType == 16 then
							price = math.floor(vehiclePrice * v.price[data.current.modNum + 1] / 100)
							TriggerServerEvent("esx_mechanicjob:buyMod", price)
						elseif v.modType == 17 then
							price = math.floor(vehiclePrice * v.price[1] / 100)
							TriggerServerEvent("esx_mechanicjob:buyMod", price)
						else
							price = math.floor(vehiclePrice * v.price / 100)
							TriggerServerEvent("esx_mechanicjob:buyMod", price)
						end
					end
				end
				menu.close()
				found = true
				break
			end
		end
		if not found then
			GetAction(data.current)
		end
	end, function(data, menu) -- on cancel
		menu.close()
		TriggerEvent('esx_mechanicjob:cancelInstallMod')
		local playerPed = PlayerPedId()
		local coords 		= GetEntityCoords(GetPlayerPed(-1))
		local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
		SetVehicleDoorsShut(vehicle, false)
		if parent == nil then
			lsMenuIsShowed = false
			local coords 		= GetEntityCoords(GetPlayerPed(-1))
			local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
			FreezeEntityPosition(vehicle, false)
			FreezeEntityPosition(GetPlayerPed(-1), false)
			myCar = {}
		end
	end, function(data, menu) -- on change
		UpdateMods(data.current)
	end)
end

function DrawText3Ds(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    local scale = 0.33

    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 500
	DrawRect(_x, _y + 0.0150, 0.030 + factor , 0.030, 66, 66, 66, 150)
    end
end

function UpdateMods(data)
	local coords 		= GetEntityCoords(GetPlayerPed(-1))
	local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
	if data.modType ~= nil then
		local props = {}
		
		if data.wheelType then
			props['wheels'] = data.wheelType
			ESX.Game.SetVehicleProperties(vehicle, props)
			props = {}
		elseif data.modType == 'neonColor' then
			if data.modNum[1] == 0 and data.modNum[2] == 0 and data.modNum[3] == 0 then
				props['neonEnabled'] = { false, false, false, false }
			else
				props['neonEnabled'] = { true, true, true, true }
			end
			ESX.Game.SetVehicleProperties(vehicle, props)
			props = {}
		elseif data.modType == 'tyreSmokeColor' then
			props['modSmokeEnabled'] = true
			ESX.Game.SetVehicleProperties(vehicle, props)
			props = {}
		end
		props[data.modType] = data.modNum
		ESX.Game.SetVehicleProperties(vehicle, props)
	end
end

function GetAction(data)
	local elements  = {}
	local menuName  = ''
	local menuTitle = ''
	local parent    = nil
	local playerPed = PlayerPedId()
	local coords 		= GetEntityCoords(GetPlayerPed(-1))
	local vehicle  		= GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, false, 23)
	local currentMods = ESX.Game.GetVehicleProperties(vehicle)
	FreezeEntityPosition(vehicle, true)
	FreezeEntityPosition(GetPlayerPed(-1), true)
	myCar = currentMods
	if data.value == 'modSpeakers' or
		data.value == 'modTrunk' or
		data.value == 'modHydrolic' or
		data.value == 'modEngineBlock' or
		data.value == 'modAirFilter' or
		data.value == 'modStruts' or
		data.value == 'modTank' then
		SetVehicleDoorOpen(vehicle, 4, false)
		SetVehicleDoorOpen(vehicle, 5, false)
	elseif data.value == 'modDoorSpeaker' then
		SetVehicleDoorOpen(vehicle, 0, false)
		SetVehicleDoorOpen(vehicle, 1, false)
		SetVehicleDoorOpen(vehicle, 2, false)
		SetVehicleDoorOpen(vehicle, 3, false)
	else
		SetVehicleDoorsShut(vehicle, false)
	end
	local vehiclePrice = 80000
	for i=1, #Vehicles, 1 do
		if GetEntityModel(vehicle) == GetHashKey(Vehicles[i].model) then
			vehiclePrice = Vehicles[i].price
			break
		end
	end
	RegisterLS()
	for k,v in pairs(Config.Menus) do
		if data.value == k then
			menuName  = k
			menuTitle = v.label
			parent    = v.parent
			if v.modType ~= nil then
				
				if v.modType == 22 then
					table.insert(elements, {label = " " .. _U('by_default'), modType = k, modNum = false})
				elseif v.modType == 'neonColor' or v.modType == 'tyreSmokeColor' then -- disable neon
					table.insert(elements, {label = " " ..  _U('by_default'), modType = k, modNum = {0, 0, 0}})
				elseif v.modType == 'color1' or v.modType == 'color2' or v.modType == 'pearlescentColor' or v.modType == 'wheelColor' then
					local num = myCar[v.modType]
					table.insert(elements, {label = " " .. _U('by_default'), modType = k, modNum = num})
				elseif v.modType == 17 then
					table.insert(elements, {label = " " .. _U('no_turbo'), modType = k, modNum = false})
 				else
					table.insert(elements, {label = " " .. _U('by_default'), modType = k, modNum = -1})
				end
				if v.modType == 14 then -- HORNS
					for j = 0, 51, 1 do
						local _label = ''
						if j == currentMods.modHorns then
							_label = GetHornName(j) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price / 100)
							_label = GetHornName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
					end
				elseif v.modType == 'plateIndex' then -- PLATES
					for j = 0, 4, 1 do
						local _label = ''
						if j == currentMods.plateIndex then
							_label = GetPlatesName(j) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price / 100)
							_label = GetPlatesName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
					end
				elseif v.modType == 22 then -- NEON
					local _label = ''
					if currentMods.modXenon then
						_label = _U('neon') .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
					else
						price = math.floor(vehiclePrice * v.price / 100)
						_label = _U('neon') .. ' - <span style="color:green;">$' .. price .. ' </span>'
					end
					table.insert(elements, {label = _label, modType = k, modNum = true})
				elseif v.modType == 'neonColor' or v.modType == 'tyreSmokeColor' then -- NEON & SMOKE COLOR
					local neons = GetNeons()
					price = math.floor(vehiclePrice * v.price / 100)
					for i=1, #neons, 1 do
						table.insert(elements, {
							label = '<span style="color:rgb(' .. neons[i].r .. ',' .. neons[i].g .. ',' .. neons[i].b .. ');">' .. neons[i].label .. ' - <span style="color:green;">$' .. price .. '</span>',
							modType = k,
							modNum = { neons[i].r, neons[i].g, neons[i].b }
						})
					end
				elseif v.modType == 'color1' or v.modType == 'color2' or v.modType == 'pearlescentColor' or v.modType == 'wheelColor' then -- RESPRAYS
					local colors = GetColors(data.color)
					for j = 1, #colors, 1 do
						local _label = ''
						price = math.floor(vehiclePrice * v.price / 100)
						_label = colors[j].label .. ' - <span style="color:green;">$' .. price .. ' </span>'
						table.insert(elements, {label = _label, modType = k, modNum = colors[j].index})
					end
				elseif v.modType == 'windowTint' then -- WINDOWS TINT
					for j = 1, 5, 1 do
						local _label = ''
						if j == currentMods.modHorns then
							_label = GetWindowName(j) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price / 100)
							_label = GetWindowName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
					end
				elseif v.modType == 23 then -- WHEELS RIM & TYPE
					local props = {}
					props['wheels'] = v.wheelType
					ESX.Game.SetVehicleProperties(vehicle, props)
					local modCount = GetNumVehicleMods(vehicle, v.modType)
					for j = 0, modCount, 1 do
						local modName = GetModTextLabel(vehicle, v.modType, j)
						if modName ~= nil then
							local _label = ''
							if j == currentMods.modFrontWheels then
								_label = GetLabelText(modName) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
							else
								price = math.floor(vehiclePrice * v.price / 100)
								_label = GetLabelText(modName) .. ' - <span style="color:green;">$' .. price .. ' </span>'
							end
							table.insert(elements, {label = _label, modType = 'modFrontWheels', modNum = j, wheelType = v.wheelType, price = v.price})
						end
					end
				elseif v.modType == 11 or v.modType == 12 or v.modType == 13 or v.modType == 15 or v.modType == 16 then
					local modCount = GetNumVehicleMods(vehicle, v.modType) -- UPGRADES
					for j = 0, modCount, 1 do
						local _label = ''
						if j == currentMods[k] then
							_label = _U('level', j+1) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price[j+1] / 100)
							_label = _U('level', j+1) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
						if j == modCount-1 then
							break
						end
					end
				elseif v.modType == 17 then -- TURBO
					local _label = ''
					if currentMods[k] then
						_label = 'Turbo - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
					else
						_label = 'Turbo - <span style="color:green;">$' .. math.floor(vehiclePrice * v.price[1] / 100) .. ' </span>'
					end
					table.insert(elements, {label = _label, modType = k, modNum = true})
				else
					local modCount = GetNumVehicleMods(vehicle, v.modType) -- BODYPARTS
					for j = 0, modCount, 1 do
						local modName = GetModTextLabel(vehicle, v.modType, j)
						if modName ~= nil then
							local _label = ''
							if j == currentMods[k] then
								_label = GetLabelText(modName) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
							else
								price = math.floor(vehiclePrice * v.price / 100)
								_label = GetLabelText(modName) .. ' - <span style="color:green;">$' .. price .. ' </span>'
							end
							table.insert(elements, {label = _label, modType = k, modNum = j})
						end
					end
				end
			else
				if data.value == 'primaryRespray' or data.value == 'secondaryRespray' or data.value == 'pearlescentRespray' or data.value == 'modFrontWheelsColor' then
					for i=1, #Config.Colors, 1 do
						if data.value == 'primaryRespray' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'color1', color = Config.Colors[i].value})
						elseif data.value == 'secondaryRespray' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'color2', color = Config.Colors[i].value})
						elseif data.value == 'pearlescentRespray' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'pearlescentColor', color = Config.Colors[i].value})
						elseif data.value == 'modFrontWheelsColor' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'wheelColor', color = Config.Colors[i].value})
						end
					end
				else
					for l,w in pairs(v) do
						if l ~= 'label' and l ~= 'parent' then
							table.insert(elements, {label = w, value = l})
						end
					end
				end
			end
			break
		end
	end
	table.sort(elements, function(a, b)
		return a.label < b.label
	end)
	OpenLSMenu(elements, menuName, menuTitle, parent)
end





--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------

--------------------------- CAR LIFT -------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------




local elevatorProp = nil
local elevatorUp = false
local elevatorDown = false
local elevatorBaseX = -223.5853
local elevatorBaseY = -1327.158
local elevatorBaseZ = 29.8


function deleteObject(object)
	return Citizen.InvokeNative(0x539E0AE3E6634B9F, Citizen.PointerValueIntInitialized(object))
end

function createObject(model, x, y, z)
	RequestModel(model)
	while (not HasModelLoaded(model)) do
		Citizen.Wait(10)
	end
	return CreateObject(model, x, y, z, true, true, false)
end

function spawnProp(propName, x, y, z)
	local model = GetHashKey(propName)
	
	if IsModelValid(model) then
		local pos = GetEntityCoords(GetPlayerPed(-1), true)
	
		local forward = 5.0
		local heading = GetEntityHeading(GetPlayerPed(-1))
		local xVector = forward * math.sin(math.rad(heading)) * -1.0
		local yVector = forward * math.cos(math.rad(heading))
		
		elevatorProp = createObject(model, x, y, z)
		local propNetId = ObjToNet(elevatorProp)
		SetNetworkIdExistsOnAllMachines(propNetId, true)
		NetworkSetNetworkIdDynamic(propNetId, true)
		SetNetworkIdCanMigrate(propNetId, false)
		
		SetEntityLodDist(elevatorProp, 0xFFFF)
		SetEntityCollision(elevatorProp, true, true)
		FreezeEntityPosition(elevatorProp, true)
		SetEntityCoords(elevatorProp, x, y, z, false, false, false, false) -- Patch un bug pour certains props.
	end
end

function Main()
    Menu.SetupMenu("mainmenu", "BENNY'S")
    Menu.Switch(nil, "mainmenu")
	
	Menu.addOption("mainmenu", function() if (Menu.Option("Turn on Machine")) then
		spawnProp("nacelle", elevatorBaseX, elevatorBaseY, elevatorBaseZ)
	end end)
	
	Menu.addOption("mainmenu", function() if (Menu.Option("Turn off Machine")) then
		DeleteObject(elevatorProp)
	end end)
	
	Menu.addOption("mainmenu", function() if (Menu.Option("Lift up")) then
		if elevatorProp ~= nil then
			elevatorDown = false
			elevatorUp = true
		end
	end end)
	
    Menu.addOption("mainmenu", function() if (Menu.Option("Lift down")) then
		if elevatorProp ~= nil then
			elevatorUp = false
			elevatorDown = true
		end
	end end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
		local elevatorCoords = GetEntityCoords(elevatorProp, false)
		
		if elevatorUp then
			if elevatorCoords.z < 31.8 then
				elevatorBaseZ = elevatorBaseZ + 0.01
				SetEntityCoords(elevatorProp, elevatorBaseX, elevatorBaseY, elevatorBaseZ, false, false, false, false)
			end
		elseif elevatorDown then
			if elevatorCoords.z > 29.8 then
				elevatorBaseZ = elevatorBaseZ - 0.01
				SetEntityCoords(elevatorProp, elevatorBaseX, elevatorBaseY, elevatorBaseZ, false, false, false, false)
			end
		end
		
		if ((GetDistanceBetweenCoords(Config.Zones.CarLift.Pos.x, Config.Zones.CarLift.Pos.y, Config.Zones.CarLift.Pos.z, GetEntityCoords(GetPlayerPed(-1), false).x, GetEntityCoords(GetPlayerPed(-1), false).y, GetEntityCoords(GetPlayerPed(-1), false).z - 1) < Config.DrawDistance) and (PlayerData.job.name == 'mechanic')) then
			if IsControlJustReleased(1, 51) then
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
				garage_menu = not garage_menu
				Main()
			end
		else
			if (prevMenu == nil) then
				menuOpen = false
				if garage_menu then
					garage_menu = false
				end
				currentOption = 1
			elseif not (prevMenu == nil) then
				if not Menus[prevMenu].previous == nil then
					currentOption = 1
					Menu.Switch(nil, prevMenu)
				else
					if Menus[prevMenu].optionCount < currentOption then
						currentOption = Menus[prevMenu].optionCount
					end
					Menu.Switch(Menus[prevMenu].previous, prevMenu)
				end
			end
		end
		
        if garage_menu then
			DisableControlAction(1, 22, true)
			DisableControlAction(1, 0, true)
			DisableControlAction(1, 27, true)
			DisableControlAction(1, 140, true)
			DisableControlAction(1, 141, true)
			DisableControlAction(1, 142, true)
			DisableControlAction(1, 20, true)
			
			DisableControlAction(1, 187, true)
			
			DisableControlAction(1, 80, true)
			DisableControlAction(1, 95, true)
			DisableControlAction(1, 96, true)
			DisableControlAction(1, 97, true)
			DisableControlAction(1, 98, true)
			
			DisableControlAction(1, 81, true)
			DisableControlAction(1, 82, true)
			DisableControlAction(1, 83, true)
			DisableControlAction(1, 84, true)
			DisableControlAction(1, 85, true)
			
			DisableControlAction(1, 74, true)
			
			HideHelpTextThisFrame()
			SetCinematicButtonActive(false)
            Menu.DisplayCurMenu()
        end
    end
end)
