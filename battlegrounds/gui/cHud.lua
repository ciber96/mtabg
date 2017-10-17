--[[

				MTA:BG
			MTA Battlegrounds
	Developed By: Null System Works

]]--


local dangerBlip = false
local safeBlip = false
local x,y,z = 0,0,0
local x2,y2,z2 = 0,0,0
local dangerZoneRadius = 0
local safeZoneRadius = 0
local zoneTimer

local screenW, screenH = guiGetScreenSize()
local r,g,b = 218,218,218
local alpha = 150
local playerAmount = 0
local playersInLobby = 0
local gameStatus = false
local countDown = 120 -- 180
local countDownHasStarted = false

local maxDistance = 100 --max distance represented by littleDude
local littleDudeDistance = maxDistance --relative distance from littleDude to safe area
local distanceToSafeArea --distance from player to safe area
local safeAreaCol
local guiPlayerHealth = 100

fuelLabel = guiCreateLabel(0.02, 0.48, 0.19, 0.04, str("vehicleFuel", 0), true)
guiSetVisible(fuelLabel,false)
local fuelAmount = 0
local isPlayerInsideVehicle = false



function createZoneRadius(dangerZone,safeZone,radius,initialZoneRadius,timer)
	if dangerBlip then
		exports.customblips:destroyCustomBlip(dangerBlip)
		exports.customblips:destroyCustomBlip(safeBlip)
	end
	if not dangerZone and not safeZone and not radius then
		dangerBlip = false
		safeBlip = false
		return
	end
	x,y,z = getElementPosition(dangerZone)
	x2,y2,z2 = getElementPosition(safeZone)
	local radiusDivide = 1
	local screenX, screenY = guiGetScreenSize()
	if screenX == 800 then
		radiusDivide = 4.2
	elseif screenX == 1024 then
		radiusDivide = 3.28
	elseif screenX == 1366 then
		radiusDivide = 3.2
	elseif screenX == 1920 then
		radiusDivide = 2.34
	end
	dangerBlip = exports.customblips:createCustomBlip(x,y,radius/radiusDivide,radius/radiusDivide,"gui/img/radius.png",radius)
	safeBlip = exports.customblips:createCustomBlip(x2,y2,initialZoneRadius/radiusDivide,initialZoneRadius/radiusDivide,"gui/img/radius2.png",initialZoneRadius)
	exports.customblips:setCustomBlipRadarScale(dangerBlip,1)
	exports.customblips:setCustomBlipStreamRadius(dangerBlip,0)
	exports.customblips:setCustomBlipRadarScale(safeBlip,1)
	exports.customblips:setCustomBlipStreamRadius(safeBlip,0)
	dangerZoneRadius = radius
	safeZoneRadius = initialZoneRadius
	safeAreaCol = false
	maxDistance = radius-safeZoneRadius
	safeAreaCol = safeZone
	if isTimer(zoneTimer) then killTimer(zoneTimer) end
	zoneTimer = setTimer(function() end,timer,0)
	local radiusTimer = setTimer(setRadiusTimerToClient,1000,0,zoneTimer)
	for i=1,3 do
		if not guiGetVisible(zoneIndicators.image[i]) then
			guiSetVisible(zoneIndicators.image[i],true)
		end
	end
	guiSetVisible(zoneIndicators.label[1],true)
end
addEvent("mtabg_createZoneRadius",true)
addEventHandler("mtabg_createZoneRadius",root,createZoneRadius)

function formatMilliseconds(milliseconds)
	if milliseconds then
		local totalseconds = math.floor( milliseconds / 1000 )
		local seconds = totalseconds % 60
		local minutes = math.floor( totalseconds / 60 )
		minutes = minutes % 60
		return string.format( "%02d:%02d", minutes, seconds)
	end
end


local lobbyLabel = {}
local helpText = {
	str("lobbyHelpText1"),
	str("lobbyHelpText2"),
	str("lobbyHelpText3"),
	str("lobbyHelpText4"),
	str("lobbyHelpText5"),
	str("lobbyHelpText6")
}

local countdown = ""
lobbyLabel[1] = guiCreateLabel(0.02, 0.31, 0.32, 0.05, "", true)
lobbyLabel[2] = guiCreateLabel(0.02, 0.36, 0.32, 0.05, "", true)
lobbyLabel[3] = guiCreateLabel(0.26, 0.70, 0.48, 0.13, "", true)
lobbyLabel[4] = guiCreateLabel(0.02, 0.46, 0.32, 0.29, "", true)
lobbyLabel["font_big"] = guiCreateFont("/font/tahomab.ttf",20)
lobbyLabel["font_small"] = guiCreateFont("/font/tahomab.ttf",12)
guiLabelSetHorizontalAlign(lobbyLabel[3], "center", true)
guiLabelSetVerticalAlign(lobbyLabel[3], "center")
guiLabelSetHorizontalAlign(lobbyLabel[4], "left", true)
guiSetVisible(lobbyLabel[1],false)
guiSetVisible(lobbyLabel[2],false)
guiSetVisible(lobbyLabel[3],false)
guiSetVisible(lobbyLabel[4],false)
guiSetFont(lobbyLabel[1],lobbyLabel["font_big"])
guiSetFont(lobbyLabel[2],lobbyLabel["font_big"])
guiSetFont(lobbyLabel[3],lobbyLabel["font_big"])
guiSetFont(lobbyLabel[4],lobbyLabel["font_small"])


function displayHealthGUI()
	if guiGetVisible(homeScreen.staticimage[1]) then return end
	if getElementData(localPlayer,"inLobby") then
		guiSetVisible(lobbyLabel[1],true)
		guiSetVisible(lobbyLabel[2],true)
		guiSetVisible(lobbyLabel[3],true)
		guiSetVisible(lobbyLabel[4],true)
		guiSetText(lobbyLabel[1], str("lobbyCountdownTimer", tostring(countdown)))
		guiSetText(lobbyLabel[2], str("lobbyPlayerCount", tostring(playersInLobby)))
	else
		guiSetVisible(lobbyLabel[1],false)
		guiSetVisible(lobbyLabel[2],false)
		guiSetVisible(lobbyLabel[3],false)
		guiSetVisible(lobbyLabel[4],false)
	end
	if gameStatus then
		if not isInventoryShowing() then
			if alpha > 150 then
				alpha = math.max(170,alpha-1)
			end
			dxDrawLine((screenW * 0.2612) - 1, (screenH * 0.9017) - 1, (screenW * 0.2612) - 1, screenH * 0.9450, tocolor(0, 0, 0, 150), 1, true)
			dxDrawLine(screenW * 0.7688, (screenH * 0.9017) - 1, (screenW * 0.2612) - 1, (screenH * 0.9017) - 1, tocolor(0, 0, 0, 150), 1, true)
			dxDrawLine((screenW * 0.2612) - 1, screenH * 0.9450, screenW * 0.7688, screenH * 0.9450, tocolor(0, 0, 0, 150), 1, true)
			dxDrawLine(screenW * 0.7688, screenH * 0.9450, screenW * 0.7688, (screenH * 0.9017) - 1, tocolor(0, 0, 0, 150), 1, true)
			if guiPlayerHealth < 0 then
				guiPlayerHealth = 0
			end
			dxDrawRectangle(screenW * 0.2612, screenH * 0.9017, screenW * (0.5075/(100/guiPlayerHealth)), screenH * 0.0433, tocolor(r,g,b, alpha), true)
			if playerAmount > 0 then
				dxDrawText(str("matchAliveCount"), (screenW * 0.8488) - 1, (screenH * 0.0483) - 1, (screenW * 0.9375) - 1, (screenH * 0.1050) - 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(str("matchAliveCount"), (screenW * 0.8488) + 1, (screenH * 0.0483) - 1, (screenW * 0.9375) + 1, (screenH * 0.1050) - 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(str("matchAliveCount"), (screenW * 0.8488) - 1, (screenH * 0.0483) + 1, (screenW * 0.9375) - 1, (screenH * 0.1050) + 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(str("matchAliveCount"), (screenW * 0.8488) + 1, (screenH * 0.0483) + 1, (screenW * 0.9375) + 1, (screenH * 0.1050) + 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(str("matchAliveCount"), screenW * 0.8488, screenH * 0.0483, screenW * 0.9375, screenH * 0.1050, tocolor(255, 255, 255, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(playerAmount, (screenW * 0.9437) - 1, (screenH * 0.0483) - 1, (screenW * 1.0325) - 1, (screenH * 0.1050) - 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(playerAmount, (screenW * 0.9437) + 1, (screenH * 0.0483) - 1, (screenW * 1.0325) + 1, (screenH * 0.1050) - 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(playerAmount, (screenW * 0.9437) - 1, (screenH * 0.0483) + 1, (screenW * 1.0325) - 1, (screenH * 0.1050) + 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(playerAmount, (screenW * 0.9437) + 1, (screenH * 0.0483) + 1, (screenW * 1.0325) + 1, (screenH * 0.1050) + 1, tocolor(0, 0, 0, 255), 2.00, "default", "left", "top", false, false, false, false, false)
				dxDrawText(playerAmount, screenW * 0.9437, screenH * 0.0483, screenW * 1.0325, screenH * 0.1050, tocolor(255, 255, 255, 255), 2.00, "default", "left", "top", false, false, false, false, false)
			end
			if isPlayerInsideVehicle then
				if not inventoryIsShowing then
					if not guiGetVisible(fuelLabel) then
						guiSetVisible(fuelLabel,true)
						guiSetText(fuelLabel,str("vehicleFuel", tostring(fuelAmount)))
					end
					guiSetText(fuelLabel, str("vehicleFuel", tostring(fuelAmount)))
					dxDrawLine((screenW * 0.0220) - 1, (screenH * 0.5078) - 1, (screenW * 0.0220) - 1, screenH * 0.5326, tocolor(0, 0, 0, 255), 1, true)
					dxDrawLine(screenW * 0.2101, (screenH * 0.5078) - 1, (screenW * 0.0220) - 1, (screenH * 0.5078) - 1, tocolor(0, 0, 0, 255), 1, true)
					dxDrawLine((screenW * 0.0220) - 1, screenH * 0.5326, screenW * 0.2101, screenH * 0.5326, tocolor(0, 0, 0, 255), 1, true)
					dxDrawLine(screenW * 0.2101, screenH * 0.5326, screenW * 0.2101, (screenH * 0.5078) - 1, tocolor(0, 0, 0, 255), 1, true)
					dxDrawRectangle(screenW * 0.0220, screenH * 0.5078, screenW * (0.1881/(100/fuelAmount)), screenH * 0.0247, tocolor(255, 255, 255, 255), true)
				end
			end
		else
			local armorValue = getPedArmor(localPlayer)
			if armorValue <= 0 then
				guiSetVisible(inventoryGUI.staticimage[10],false)
				guiSetVisible(inventoryGUI.progressbar[2],false)
			else
				guiProgressBarSetProgress(inventoryGUI.progressbar[2],armorValue)
			end
		end
	end
end
addEventHandler("onClientRender",root,displayHealthGUI)

local currentHelpTextIndex
local function updateHelpText()
	if currentHelpTextIndex then
		guiSetText(lobbyLabel[4],helpText[currentHelpTextIndex])
	end
end

function setRandomHelpText()
	if getElementData(localPlayer,"inLobby") then
		currentHelpTextIndex = math.random(1, #helpText)
		updateHelpText()
	end
end
setTimer(setRandomHelpText,10000,0)


function onPlayerIsInsideVehicle(fuel)
	if not fuel then isPlayerInsideVehicle = false fuelAmount = 0 guiSetVisible(fuelLabel,false) return end
	isPlayerInsideVehicle = true
	fuelAmount = fuel
end
addEvent("mtabg_onPlayerIsInsideVehicle",true)
addEventHandler("mtabg_onPlayerIsInsideVehicle",root,onPlayerIsInsideVehicle)

function onClientBattleGroundsGetPlayerHealthGUI(player)
	if gameStatus then
		return guiPlayerHealth
	end
end
addEvent("mtabg_onClientBattleGroundsGetPlayerHealthGUI",true)
addEventHandler("mtabg_onClientBattleGroundsGetPlayerHealthGUI",root,onClientBattleGroundsGetPlayerHealthGUI)

function onClientBattleGroundsSetPlayerHealthGUI(action,value)
	if action == "damage" then
		guiPlayerHealth = guiPlayerHealth-value
	else
		guiPlayerHealth = value
	end
	r,g,b = 255,170,170
	alpha = 255
	setTimer(function()
		r,g,b = 218,218,218
	end,2000,1)
end
addEvent("mtabg_onClientBattleGroundsSetPlayerHealthGUI",true)
addEventHandler("mtabg_onClientBattleGroundsSetPlayerHealthGUI",root,onClientBattleGroundsSetPlayerHealthGUI)

function onClientBattleGroundsSetGameStatus(status,inLobby)
	gameStatus = status
	playersInLobby = inLobby
end
addEvent("mtabg_onClientBattleGroundsSetStatus",true)
addEventHandler("mtabg_onClientBattleGroundsSetStatus",root,onClientBattleGroundsSetGameStatus)

function onClientBattleGroundsSetCountdown(number)
	countdown = number
end
addEvent("mtabg_onClientBattleGroundsSetCountdown",true)
addEventHandler("mtabg_onClientBattleGroundsSetCountdown",root,onClientBattleGroundsSetCountdown)

local lobbyLabelNumber
function onClientBattleGroundsAnnounceMatchStart(number)
	number = number or lobbyLabelNumber
	lobbyLabelNumber = number
	if number == "More players needed" then
		guiSetText(lobbyLabel[3], str("lobbyInsuficientPlayersError"))
	elseif number == "Match running" then
		guiSetText(lobbyLabel[3], str("lobbyMatchAlreadyRunningError"))
	else
		guiSetText(lobbyLabel[3], str("lobbyStartMatchCountdown", tostring(number)))
		setTimer(guiSetText,3000,1,lobbyLabel[3],"")
	end
end
addEvent("mtabg_onClientBattleGroundsAnnounceMatchStart",true)
addEventHandler("mtabg_onClientBattleGroundsAnnounceMatchStart",root,onClientBattleGroundsAnnounceMatchStart)

function onClientBattleGroundsSetAliveCount(amount)
	playerAmount = amount
end
addEvent("mtabg_onClientBattleGroundsSetAliveCount",true)
addEventHandler("mtabg_onClientBattleGroundsSetAliveCount",root,onClientBattleGroundsSetAliveCount)

endScreen = {
    label = {},
    button = {},
	image = {},
	font = {}
}

local rank = ""

endScreen.font[1] = guiCreateFont("/font/etelka.ttf",11)
endScreen.font[2] = guiCreateFont("/font/etelka.ttf",15)
endScreen.font[3] = guiCreateFont("/font/etelka.ttf",20)
endScreen.font[4] = guiCreateFont("/font/etelka.ttf",25)

endScreen.image[1] = guiCreateStaticImage(0.00, 0.00, 1.00, 1.17, "/gui/img/solo_slot.png", true)
endScreen.image[2] = guiCreateStaticImage(0.73, 0.87, 0.20, 0.06,"/gui/img/solo_slot.png", true)
guiSetProperty(endScreen.image[1], "ImageColours", "tl:EB000000 tr:EB000000 bl:EB000000 br:EB000000")
endScreen.label[1] = guiCreateLabel(0.02, 0.06, 0.38, 0.08, getPlayerName(localPlayer), true, endScreen.image[1])
endScreen.label[2] = guiCreateLabel(0.02, 0.14, 1, 0.09, "", true, endScreen.image[1])
guiLabelSetVerticalAlign(endScreen.label[2], "center")
endScreen.label[3] = guiCreateLabel(0.05, 0.39, 0.20, 0.04, str("endScreenRank"), true, endScreen.image[1])
guiLabelSetHorizontalAlign(endScreen.label[3], "center", false)
endScreen.label[4] = guiCreateLabel(0.05, 0.47, 0.20, 0.04, str("endScreenKills"), true, endScreen.image[1])
guiLabelSetHorizontalAlign(endScreen.label[4], "center", false)
endScreen.label[5] = guiCreateLabel(0.25, 0.39, 0.20, 0.04, "# ", true, endScreen.image[1])
endScreen.label[6] = guiCreateLabel(0.25, 0.47, 0.20, 0.04, "N/A", true, endScreen.image[1])
endScreen.label[7] = guiCreateLabel(0.73, 0.87, 0.20, 0.06, str("endScreenBackToHomeButton"), true, endScreen.image[1])
guiLabelSetHorizontalAlign(endScreen.label[7], "center", true)
guiLabelSetVerticalAlign(endScreen.label[7], "center")
guiLabelSetColor(endScreen.label[2],255,255,0)
guiSetFont(endScreen.label[1],endScreen.font[4])
guiSetFont(endScreen.label[2],endScreen.font[3])
guiSetFont(endScreen.label[7],endScreen.font[1])
for i=3,6 do
	guiSetFont(endScreen.label[i],endScreen.font[2])
end
guiSetVisible(endScreen.image[1],false)
guiSetVisible(endScreen.image[2],false)

local endScreenRank
local function updateEndScreenText()
	if endScreenRank ~= 1 then
		guiSetText(endScreen.label[2], str("endScreenYouLost"))
	else
		guiSetText(endScreen.label[2], str("endScreenYouWon"))
	end
	guiSetText(endScreen.label[5],"#"..tostring(endScreenRank))
end

local homeScreenDimension = 500
function showEndScreen(rank,dimension)
	endScreenRank = rank
	updateEndScreenText()
	guiSetVisible(endScreen.image[1],true)
	guiSetVisible(endScreen.image[2],true)
	guiBringToFront(endScreen.label[7])
	showCursor(true)
	playerAmount = 0
	gameStatus = false
	countDown = 120
	inventoryIsShowing = false
	for i=1,3 do
		if zoneIndicators.image[i] then
			guiSetVisible(zoneIndicators.image[i],false)
		end
	end
	homeScreenDimension = dimension
end
addEvent("mtabg_showEndscreen",true)
addEventHandler("mtabg_showEndscreen",root,showEndScreen)

local function showDeathMessage(aliveCount, killedName, killerName)
	if killerName then
		outputSideChat(str("matchPlayerKilled", killedName, killerName, aliveCount), 255, 255, 255)
	else
		outputSideChat(str("matchPlayerDied", killedName, aliveCount), 255, 255, 255)
	end
end
addEvent("onShowDeathMessage", true)
addEventHandler("onShowDeathMessage", localPlayer, showDeathMessage)

function onMouseOverBackToHomeScreenLabelSelect()
	guiSetProperty(endScreen.image[2], "ImageColours", "tl:B93C3C3C tr:B93C3C3C bl:B93C3C3C br:B93C3C3C")
end
addEventHandler("onClientMouseEnter",endScreen.label[7],onMouseOverBackToHomeScreenLabelSelect,false)

function onMouseOverBackToHomeScreenLabelDeselect()
	guiSetProperty(endScreen.image[2], "ImageColours", "tl:FFFFFFFF tr:FFFFFFFF bl:FFFFFFFF br:FFFFFFFF")
end
addEventHandler("onClientMouseLeave",endScreen.label[7],onMouseOverBackToHomeScreenLabelDeselect,false)

function sendPlayerBackToHomeScreenOnDeath()
	guiSetVisible(homeScreen.staticimage[1],true)
	LanguageSelection.setShowing(true)
	guiSetVisible(endScreen.image[1],false)
	guiSetVisible(endScreen.image[2],false)
	sendToHomeScreen(homeScreenDimension)
	setElementData(localPlayer,"participatingInGame",false)
	guiPlayerHealth = 100
	guiSetText(zoneIndicators.label[1],"")
	guiSetVisible(zoneIndicators.label[1],false)
end
addEventHandler("onClientGUIClick",endScreen.label[7],sendPlayerBackToHomeScreenOnDeath,false)

function setRadiusTimerToClient(timer)
	if isTimer(timer) then
		local timeDetails = getTimerDetails(timer)
		local time = formatMilliseconds(timeDetails)
		guiSetText(zoneIndicators.label[1],tostring(time))
	end
end
addEvent("mtabg_setRadiusTimerToClient",true)
addEventHandler("mtabg_setRadiusTimerToClient",root,setRadiusTimerToClient)

zoneIndicators = {
	label = {},
	image = {},
}

zoneIndicators.label[1] = guiCreateLabel(0.02, 0.73, 0.24, 0.03, "", true)
zoneIndicators.image[1] = guiCreateStaticImage (0.02, 0.71, 0.01, 0.02, "/gui/img/solo_slot.png", true) --starting position
guiSetProperty(zoneIndicators.image[1], "ImageColours", "tl:FEFB0000 tr:FEFB0000 bl:FEFB0000 br:FEFB0000")
zoneIndicators.image[2] = guiCreateStaticImage (0.25, 0.71, 0.01, 0.02, "/gui/img/solo_slot.png", true) --finishing position
guiSetProperty(zoneIndicators.image[2], "ImageColours", "tl:FE000CFA tr:FE000CFA bl:FE000CFA br:FE000CFA")
zoneIndicators.image[3] = guiCreateStaticImage (0.02, 0.69, 0.04, 0.04, "gui/img/running.png", true) --our littledude

for i=1,3 do
	guiSetVisible(zoneIndicators.image[i],false)
end

local mapValues = mapValues
local getDistanceBetweenPoints2D = getDistanceBetweenPoints2D
local localPlayer = localPlayer
local math = math
local function calculateLittleDudeDistance()
	local px, py = localPlayer.position.x, localPlayer.position.y --player coordinates
	local sx,sy
	if isElement(safeAreaCol) then
		sx, sy = safeAreaCol.position.x, safeAreaCol.position.y --safe area coords
	else
		return maxDistance
	end
	distanceToSafeArea = (getDistanceBetweenPoints2D(px, py, sx, sy) - safeZoneRadius) > 0 and
	getDistanceBetweenPoints2D(px, py, sx, sy) - safeZoneRadius or 0 --show positive or 0
	if distanceToSafeArea > maxDistance then --if too far
		return 0 --stay at max
	else
		return mapValues(distanceToSafeArea, 0, maxDistance, 0.23, 0.02) --calculate relative distance
	end
end

local guiSetPosition = guiSetPosition
local dxDrawText = dxDrawText
local function moveLittleDude() --moves littleDude
	if gameStatus then
		littleDudeDistance = calculateLittleDudeDistance()
		guiSetPosition(zoneIndicators.image[3], littleDudeDistance, 0.69, true) --set littleDudes position
	end
end
addEventHandler("onClientRender", root, moveLittleDude)

local function changeLanguage(newLang)
	helpText = {
		str("lobbyHelpText1"),
		str("lobbyHelpText2"),
		str("lobbyHelpText3"),
		str("lobbyHelpText4"),
		str("lobbyHelpText5"),
		str("lobbyHelpText6")
	}
	updateHelpText()
	fuelLabel:setText(str("vehicleFuel"))
	fuelLabel:setText(str("vehicleFuel", tostring(fuelAmount)))
	endScreen.label[3]:setText(str("endScreenRank"))
	endScreen.label[4]:setText(str("endScreenKills"))
	endScreen.label[7]:setText(str("endScreenBackToHomeButton"))
	onClientBattleGroundsAnnounceMatchStart()
	updateEndScreenText()
end
addEventHandler("onUserLanguageChange", resourceRoot, changeLanguage)