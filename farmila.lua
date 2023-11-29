script_name("Mortal's farmila script")
script_author("Mortal")
script_description("Farmila to farm money")

-- >>>>>>>> REQUIRES
require "lib.moonloader"
local res, inicfg  	 	= pcall(require, 'inicfg')      assert(res, 'Lib INICFG not found')
local events        	= require 'lib.samp.events'
local imgui         	= require "imgui"
local encoding      	= require 'encoding'
local imgadd        	= require 'imgui_addons'
local fa 				= require 'faIcons'
local dkjson 			= require 'dkjson'
imgui.BufferingBar 		= require('imgui_addons').BufferingBar
local dlstatus 			= require('moonloader').download_status
local inicfg 			= require 'inicfg'
local ev 				= require "moonloader".audiostream_state

local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0, font_config, fa_glyph_ranges)
    end
end
-- <<<<<<<<

-- WINDOW STATES

local main_window_state = imgui.ImBool(false)
local notification_window_state = imgui.ImBool(false)

-- WINDOW DISPLAYING
local currentWindow = 0
local themeSelected = 0
local selectedPreset = nil

-- <<<<<<<<

-- SOME PLAYER DATA
local _, id = nil


encoding.default = 'CP1251'
u8 = encoding.UTF8

-- UPDATE

update_state = false

local version = 3
local version_text = "1.02"
local script_path = thisScript().path

local script_url = "https://raw.githubusercontent.com/theresnopixels/SAScripts/main/farmila.lua"
local update_path = getWorkingDirectory() .. "/update.ini"
local update_url = "https://raw.githubusercontent.com/theresnopixels/SAScripts/main/update.ini"

-- INPUTS

local vr_message = imgui.ImBuffer(244)
local vr_presetName = imgui.ImBuffer(144)
local vr_presetText = imgui.ImBuffer(244)
local searchFrom = imgui.ImBuffer(11)
local searchTo = imgui.ImBuffer(11)
local vr_cooldown = imgui.ImInt(0)

-- settings
local autoLomka = imgui.ImBool(false)
local lAfk = imgui.ImBool(false)
local numberToCb = imgui.ImBool(false)

-- VARIABLES
local isAdEnabled = false
local isPaused = false
local autoAdStartedAt = 0
local currentAdTime = 0
local skipDialog = false
local discoveringBuissneses = false
local notifyText = "Тут пусто, хм.."
local boxProcessorStatus = false
local phoneNumberHook = false

-- DATA

local configPath	= getGameDirectory().."\\moonloader\\Farmila\\data.json"
local rentEarningPath	= getGameDirectory().."\\moonloader\\Farmila\\rentEarning.json"
local allMoneyDataPath	= getGameDirectory().."\\moonloader\\Farmila\\allMoneyData.json"
local presetsDataPath	= getGameDirectory().."\\moonloader\\Farmila\\presetsData.json"



config = {
	mainInfo = {
		lastConnect = "",
		onConnectMoney = 0,
		rouletteBox = -1,
		platinumBox = -1,
		secretLosSantosBox = -1,
		secretElonMuskBox = -1,
	},
	vipChat = {
		vr_text = "",
		vr_cooldown = 100
	},
	rentItemList = {
	
	},
	settings = {
		autolomka = false,
		theme = 0,
		lAfk = true,
		numberToClipboard = false
	}
}
lastWeekData = {}
vrPresets = {}
rentItems = {}
moneyToChart = {}
rentEarnings = {}

local notificationSound = loadAudioStream("moonloader/resource/Farmila/notf.mp3")

function loadRentEarnings()
	local file = io.open(rentEarningPath, "r")

    if not file then
		createDirectory(getGameDirectory().."\\moonloader\\Farmila")
        file = io.open(rentEarningPath, "w")
		file:write("{}")
    end
	file:close()
	
	-- ===========

	local file = io.open(rentEarningPath, "r")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных (RentEarnings)", 0xFF4444)
		return nil
	end
	
	local content = file:read("*a")
	local data, pos, err = dkjson.decode(content)
	if err and string.find(err, "no valid JSON") == false then
		sampAddChatMessage("[ERROR] Ошибка при чтении данных (RentEarnings)", 0xFF4444)
		return nil
	end
	
	rentEarnings = data
	sampAddChatMessage("Данные были успешно загружены (RentEarnings)", 0xFFFFFF)
	
	file:close()
end

function saveRentEarning()
	local file = io.open(rentEarningPath, "w")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных", 0xFF4444)
		return nil
	end
	
	local jsonString = dkjson.encode(rentEarnings, { indent = true })
	file:write(jsonString)
	file:close()
end

function loadJson()
	local file = io.open(configPath, "r")

    if not file then
		createDirectory(getGameDirectory().."\\moonloader\\Farmila")
		local jsonString = dkjson.encode(config, { indent = true })
        file = io.open(configPath, "w")
		file:write(jsonString)
    end
	
    file:close()
	
	-- =====

	local file = io.open(configPath, "r")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных", 0xFF4444)
		return nil
	end
	
	local content = file:read("*a")
	local data, pos, err = dkjson.decode(content)
	if err and string.find(err, "no valid JSON") == false then
		sampAddChatMessage("[ERROR] Ошибка при чтении данных", 0xFF4444)
		return nil
	end
	
	config = data
	sampAddChatMessage("Данные были успешно загружены", 0xFFFFFF)
	
	file:close()
end

function saveJson()
	local file = io.open(configPath, "w")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных", 0xFF4444)
		return nil
	end
	
	local jsonString = dkjson.encode(config, { indent = true })
	file:write(jsonString)
	file:close()
end

function loadPresetsData()
	local file = io.open(presetsDataPath, "r")

    if not file then
		createDirectory(getGameDirectory().."\\moonloader\\Farmila")
        file = io.open(presetsDataPath, "w")
		file:write("{}")
    end

    file:close()
	
	-- ========

	local file = io.open(presetsDataPath, "r")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных (Presets)", 0xFF4444)
		return nil
	end
	
	local content = file:read("*a")
	local data, pos, err = dkjson.decode(content)
	if err and string.find(err, "no valid JSON") == false then
		sampAddChatMessage("[ERROR] Ошибка при чтении данных (Presets)", 0xFF4444)
		return nil
	end
	
	vrPresets = data
	sampAddChatMessage("Данные были успешно загружены (Presets)", 0xFFFFFF)
	
	file:close()
end

function savePresetsData()
	local file = io.open(presetsDataPath, "w")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных", 0xFF4444)
		return nil
	end

	local jsonString = dkjson.encode(vrPresets, { indent = true })
	file:write(jsonString)
	file:close()
end

function loadPreviousMoneyData()
	local file = io.open(allMoneyDataPath, "r")
    if not file then
		createDirectory(getGameDirectory().."\\moonloader\\Farmila")
        file = io.open(allMoneyDataPath, "w")
		file:write("{}")
	end
	file:close()
	
	-- =====

	local file = io.open(allMoneyDataPath, "r")
    if not file then
        sampAddChatMessage("[ERROR] Ошибка при загрузке данных (MoneyData)", 0xFF4444)
        return nil
    end
    
    local content = file:read("*a")
    file:close()  -- Закрываем файл сразу после чтения

    local data, pos, err = dkjson.decode(content)
    if err then  -- Если есть ошибка, выводим сообщение об ошибке
        sampAddChatMessage("[ERROR] Ошибка при декодировании JSON: " .. tostring(err), 0xFF4444)
        return nil
    end

    -- Поскольку data является таблицей, необходимо преобразовать ее в строку для вывода
    if next(data) == nil then
        sampAddChatMessage("[ERROR] Нет данных в загруженном JSON", 0xFF4444)
        return
    end

    for key, value in pairs(data) do
        moneyToChart[key] = value
		lastWeekData[key] = value
    end


    sampAddChatMessage("Данные были успешно загружены (MoneyData)", 0xFFFFFF)
end

function saveLastWeekData()
	local file = io.open(allMoneyDataPath, "w")
	if not file then
		sampAddChatMessage("[ERROR] Ошибка при загрузке данных", 0xFF4444)
		return nil
	end
	
	local jsonString = dkjson.encode(lastWeekData, { indent = true })
	file:write(jsonString)
	file:close()
end
-- <<<<<<<

function main()

    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
	
	loadJson()
	loadPreviousMoneyData()
	loadPresetsData()
	loadPreviousMoneyData()
	loadRentEarnings()
	
	vr_message.v = config.vipChat.vr_text
	vr_cooldown.v = config.vipChat.vr_cooldown
	
	-- THREADS
	dateViewer = lua_thread.create_suspended(dateViewer)
	vrProcessor = lua_thread.create_suspended(vrProcessor)
	rentProcessor = lua_thread.create_suspended(rentProcessor)
	boxProcessor = lua_thread.create_suspended(boxProcessor)
	updater = lua_thread.create_suspended(updater)
	updater:run()
	vrProcessor:run()
	rentProcessor:run()
	
	config.mainInfo.rouletteBox = 5
	
	sampRegisterChatCommand("update", cmd_update)
	
	-- load settings
	autoLomka.v = config.settings.autolomka
	themeSelected = config.settings.theme
	apply_custom_style()
	
	lAfk.v = config.settings.lAfk
	

	while true do
		wait(0)
		
		if isKeyJustPressed(VK_F2) and not (sampIsChatInputActive() or sampIsDialogActive()) then -- OPEN HOTKEY
			main_window_state.v = not main_window_state.v
			imgui.Process = main_window_state.v
		end
		
		local result, button, list, input = sampHasDialogRespond(1000)
		
		if result then
			if button == 1 then
				if update_state then
					downloadUrlToFile(script_url, script_path, function(id, status)
						if status == dlstatus.STATUS_ENDDOWNLOADDATA then
							sampShowDialog(1003, "Обновление", "Скрипт был успешно обновлен!", "Окей", "", 0)
							thisScript():reload()
						end
					end)
					break
				end
			end
		end
		
	end
end

first_update_notification = true

function updater()
	while first_update_notification do
		downloadUrlToFile(update_url, update_path, function(id, status)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				updateIni = inicfg.load(nil, update_path)
				if updateIni ~= nil then
					if tonumber(updateIni.info.version) > version then
						sampShowDialog(1000, "Обновление", "Доступна новая версия скрипта Farmila v"..updateIni.info.version_text, "Обновить", "Закрыть", 0)
						update_state = true
						first_update_notification = false
					end
				else
					print("UpdateIni is nil")
				end
			end
			--os.remove(update_path)
		end)
		wait(30000)
	end
end

function cmd_update()
	if update_state then
		sampShowDialog(1000, "Обновление", "Доступна новая версия скрипта Farmila v"..updateIni.info.version_text, "Обновить", "Закрыть", 0)
	else
		sampAddChatMessage("[ERROR] Новые обновления не найдены :(", 0xFF4444)
	end
end

-- EVENTS
function events.onServerMessage(color, text)
	if string.find(text, "Вы успешно сдали предмет") then
		local itemName = text:match("предмет (.-) в аренду")
		local time = text:match("на (%d+) час")
		local price = text:match("за %$(%d+)")
		
		local exists = 0
		for k, v in pairs(config.rentItemList) do
			if itemName == string.sub(k, 0, -4) then
				exists = exists + 1
			end
		end
	
		itemName = itemName .. " #"..exists
		
		config.rentItemList[itemName] = {rentTime = currentTime() + time * 60 * 60, rentPrice = price}
		saveJson()
		
		sampAddChatMessage("[ОК] {FFFFFF}Вы успешно сдали предмет {C84949}" .. itemName .. "{FFFFFF} в аренду", 0x54C353)
		
		local currentDate = os.date("%Y-%m-%d")
		if rentEarnings[currentDate] ~= nil then
			rentEarnings[currentDate] = rentEarnings[currentDate] + tonumber(price)
		else
			rentEarnings[currentDate] = tonumber(price)
		end
		saveRentEarning()
	end
	
	if string.find(text, "Вы использовали") then
		if string.find(text, "Вы использовали сундук с рулетками") then
			config.mainInfo.rouletteBox = 120 * 60
		elseif string.find(text, "Вы использовали платиновый сундук") then
			config.mainInfo.platinumBox = 120 * 60
		elseif string.find(text, "Вы использовали Тайник Лос Сантоса") then
			config.mainInfo.secretLosSantosBox = 60 * 60
		elseif string.find(text, "Вы использовали тайник Илона Маска") then
			config.mainInfo.secretElonMuskBox = 120 * 60
		end
		saveJson()
		if boxProcessorStatus == false then
			boxProcessorStatus = true
			boxProcessor:run()
		end
	end
	
	if string.find(text, "У вас началась сильная ломка") then
		if autoLomka.v then
			sampSendChat("/usedrugs 3")
		end
	end
	
	if string.find(text, "На сервере есть инвентарь") and lAfk.v then
		sampSendChat("/lafk")
	end
	
	local words = {"возьму", "супер%-кирка", "супер%-кирку", "супер%-грабли", "кирка", "супер", "кирку", "грабли", "аренду","дфт"}

	for _, word in ipairs(words) do
		if string.find(text, word) then
			sampAddChatMessage(string.gsub(text, word, "{FF4444}"..word.."{FFFFFF}"), color)
			setAudioStreamVolume(notificationSound, 15.0)
			setAudioStreamState(notificationSound, ev.PLAY)
			
			if config.settings.numberToClipboard then
				local pattern = "%[([^%]]+)%]%:"
				local phoneNumber = string.match(text, pattern)
				if phoneNumber ~= nil then
					phoneNumberHook = true
					sampSendChat("/number "..phoneNumber)
				end
			end
			return false
		end
	end
	
	if phoneNumberHook and config.settings.numberToClipboard then
	
		local pattern = "{33CCFF}(%d+)"
		
		if string.match(text, pattern) ~= nil then
			setClipboardText("/call "..string.match(text, pattern))
			phoneNumberHook = false
			sampAddChatMessage("{33CCFF}[NUMBER] {FFFFFF} Номер был скопирован в буфер обмена! Номер - {33CCFF}"..string.match(text, pattern), -1)
		end
	end
end

function events.onShowDialog(dialogId, style, title, button1, button2, text)
	local lines = {}
	if dialogId == 25622 and skipDialog then
		sampSendDialogResponse(dialogId, 1, nil, nil)
		skipDialog = false
		return false
	end
end

function events.onSendSpawn()
	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local currentDate = os.date("%Y-%m-%d")
	if config.mainInfo.lastConnect ~= currentDate then
		local secondsInDay = 60 * 60 * 24
		local dayAgoDate = os.date("%Y-%m-%d", os.time() - 1 * secondsInDay)
		local weekDay = os.date("*t").wday
		weekDay = weekDay - 1
		if weekDay == 0 then
			weekDay = 7
		end
		lastWeekData[dayAgoDate] = getPlayerMoney(Player) - config.mainInfo.onConnectMoney
		config.mainInfo.lastConnect = currentDate
		config.mainInfo.onConnectMoney = getPlayerMoney(Player)
		saveLastWeekData()
		saveJson()
	end
	

	
	dateViewer:run()

	
end

function events.onPlayerQuit(playerId, reason)
	if playerId == id then
		saveJson()
		saveLastWeekData()
	end
end

function getLastWeekDate()
	local today = os.date("*t")
	local weekDay = today.wday 
	local daysSinceMonday = (weekDay - 2) % 7 
	local mondayThisWeek = os.time{year=today.year, month=today.month, day=today.day - daysSinceMonday}
	local mondayLastWeek = os.time{year=today.year, month=today.month, day=today.day - daysSinceMonday - 7}
	local sundayLastWeek = os.time{year=today.year, month=today.month, day=today.day - daysSinceMonday - 1}
	local format = "%Y-%m-%d"
	local mondayLastWeekStr = os.date(format, mondayLastWeek)
	local sundayLastWeekStr = os.date(format, sundayLastWeek)

	return mondayLastWeekStr .. " - " .. sundayLastWeekStr
end

function findIndex(array, value)
    for index, currentValue in ipairs(array) do
        if currentValue == value then
            return index
        end
    end
    return nil -- Возвращаем nil, если элемент не найден
end


-- THREADS FUNCTIONS
local daysOfWeek = {"monday", "tuesday", "wednsday", "thursday", "friday", "saturday", "sunday"}
function dateViewer()
	while true do
		local currentDate = os.date("%Y-%m-%d")
		if config.mainInfo.lastConnect ~= currentDate then
			local secondsInDay = 60 * 60 * 24
			local dayAgoDate = os.date("%Y-%m-%d", os.time() - 1 * secondsInDay)
			lastWeekData[dayAgoDate] = getPlayerMoney(Player) - config.mainInfo.onConnectMoney
			config.mainInfo.lastConnect = currentDate
			config.mainInfo.onConnectMoney = getPlayerMoney(Player)
			saveLastWeekData()
			saveJson()
		end

		wait(1000)
	end
end

function vrProcessor()
	while true do
		if isAdEnabled then
			if isPaused then
				autoAdStartedAt = autoAdStartedAt + 1
			else
				if currentTime() - autoAdStartedAt >= config.vipChat.vr_cooldown then
					skipDialog = true
					sampSendChat("/vr "..u8:decode(config.vipChat.vr_text))
					autoAdStartedAt = currentTime()
				end
			end
		end
		wait(1000)
	end
end

function rentProcessor()
	while true do
		for k, v in pairs(config.rentItemList) do
			if config.rentItemList[k].rentTime - currentTime() < 0 then
				sampAddChatMessage("[АРЕНДА] {FFFFFF}Аренда предмета {54C353}".. k .. " {FFFFFF}закончилась. Предмет вернулся!", 0xC84949)
				config.rentItemList[k] = nil
				saveJson()
			end
		end
		wait(1000)
	end
end

function boxProcessor()
	local totalDone = 0
	while boxProcessor do
		if config.mainInfo.rouletteBox ~= -1 then
			if config.mainInfo.rouletteBox > 1 then
				config.mainInfo.rouletteBox = config.mainInfo.rouletteBox - 1
			else
				notifyText = "Кейс рулетки готов к повторному использованию!"
				notification_window_state.v = true
				imgui.Process = true
				wait(5000)
				notification_window_state.v = false
				if main_window_state.v == false then
					imgui.Process = false
				end
				totalDone = totalDone + 1
				config.mainInfo.rouletteBox = -1
				
			end
		end
		
		if config.mainInfo.platinumBox ~= -1 then
			if config.mainInfo.platinumBox > 1 then
				config.mainInfo.platinumBox = config.mainInfo.platinumBox - 1
			else
				notifyText = "Платиновый кейс готов к повторному использованию!"
				notification_window_state.v = true
				imgui.Process = true
				wait(5000)
				notification_window_state.v = false
				if main_window_state.v == false then
					imgui.Process = false
				end
				totalDone = totalDone + 1
				config.mainInfo.platinumBox = -1
			end
		end
		
		if config.mainInfo.secretLosSantosBox ~= -1 then
			if config.mainInfo.secretLosSantosBox > 1 then
				config.mainInfo.secretLosSantosBox = config.mainInfo.secretLosSantosBox - 1
			else
				notifyText = "Тайник Лос-Сантоса готов к повторному использованию!"
				notification_window_state.v = true
				imgui.Process = true
				wait(5000)
				notification_window_state.v = false
				if main_window_state.v == false then
					imgui.Process = false
				end
				totalDone = totalDone + 1
				config.mainInfo.secretLosSantosBox = -1
			end
		end
		
		if config.mainInfo.secretElonMuskBox ~= -1 then
			if config.mainInfo.secretElonMuskBox > 1 then
				config.mainInfo.secretElonMuskBox = config.mainInfo.secretElonMuskBox - 1
			else
				notifyText = "Тайник Илона Маска готов к повторному использованию!"
				notification_window_state.v = true
				imgui.Process = true
				wait(5000)
				notification_window_state.v = false
				if main_window_state.v == false then
					imgui.Process = false
				end
				totalDone = totalDone + 1
				config.mainInfo.secretElonMuskBox = -1
			end
			if totalDone == 4 then
				boxProcessor = false
			end
		end
		saveJson()
		wait(1000)
	end
end

-- END OF EVENTS



-- USEFUL STUFF

function currentTime()
	return os.time()
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end


-- THEME
function apply_custom_style()
	if themeSelected == 0 then
		imgui.SwitchContext()
		local style = imgui.GetStyle()
		local colors = style.Colors
		local clr = imgui.Col
		local ImVec4 = imgui.ImVec4

		style.WindowPadding = imgui.ImVec2(8, 8)
		style.WindowRounding = 9
		style.ChildWindowRounding = 5
		style.FramePadding = imgui.ImVec2(5, 3)
		style.FrameRounding = 3.0
		style.ItemSpacing = imgui.ImVec2(5, 4)
		style.ItemInnerSpacing = imgui.ImVec2(4, 4)
		style.IndentSpacing = 21
		style.ScrollbarSize = 10.0
		style.ScrollbarRounding = 13
		style.GrabMinSize = 8
		style.GrabRounding = 1
		style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
		style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

		colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
		colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
		colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
		colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 0.00)
		colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
		colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
		colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
		colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
		colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
		colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
		colors[clr.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
		colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
		colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1.00)
		colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
		colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
		colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
		colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
		colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
		colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
		colors[clr.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
		colors[clr.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
		colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
		colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
		colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
		colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
		colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
		colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
		colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
		colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
		colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
		colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
		colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
		colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
		colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
		colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
		colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
		colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
		colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
		colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
	elseif themeSelected == 1 then
		imgui.SwitchContext()
		local style = imgui.GetStyle()
		local colors = style.Colors
		local clr = imgui.Col
		local ImVec4 = imgui.ImVec4
		local ImVec2 = imgui.ImVec2

		style.WindowPadding = imgui.ImVec2(8, 8)
		style.WindowRounding = 9
		style.ChildWindowRounding = 5
		style.FramePadding = imgui.ImVec2(5, 3)
		style.FrameRounding = 3.0
		style.ItemSpacing = imgui.ImVec2(5, 4)
		style.ItemInnerSpacing = imgui.ImVec2(4, 4)
		style.IndentSpacing = 21
		style.ScrollbarSize = 10.0
		style.ScrollbarRounding = 13
		style.GrabMinSize = 8
		style.GrabRounding = 1
		style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
		style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

		colors[clr.Text]                   = ImVec4(0.00, 0.00, 0.00, 1.00);
		colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00);
		colors[clr.WindowBg]               = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.PopupBg]                = ImVec4(0.79, 0.79, 0.79, 1.00);
		colors[clr.Border]                 = ImVec4(0.00, 0.00, 0.00, 0.36);
		colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.10);
		colors[clr.FrameBg]                = ImVec4(0.00, 0.00, 0.00, 0.10);
		colors[clr.FrameBgHovered]         = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.FrameBgActive]          = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TitleBg]                = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TitleBgActive]          = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TitleBgCollapsed]       = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.MenuBarBg]              = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.ScrollbarBg]            = ImVec4(1.00, 1.00, 1.00, 0.86);
		colors[clr.ScrollbarGrab]          = ImVec4(0.37, 0.37, 0.37, 1.00);
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.60, 0.60, 0.60, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.21, 0.21, 0.21, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.61, 0.61, 0.61, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.42, 0.42, 0.42, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.51, 0.51, 0.51, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.65, 0.65, 0.65, 1.00);
		colors[clr.Button]                 = ImVec4(0.42, 0.47, 1.00, 1.00);
		colors[clr.ButtonHovered]          = ImVec4(0.42, 0.47, 1.00, 0.90);
		colors[clr.ButtonActive]           = ImVec4(0.44, 0.44, 0.44, 0.83);
		colors[clr.Header]                 = ImVec4(0.65, 0.65, 0.65, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.73, 0.73, 0.73, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.53, 0.53, 0.53, 1.00);
		colors[clr.Separator]              = ImVec4(0.46, 0.46, 0.46, 1.00);
		colors[clr.SeparatorHovered]       = ImVec4(0.45, 0.45, 0.45, 1.00);
		colors[clr.SeparatorActive]        = ImVec4(0.45, 0.45, 0.45, 1.00);
		colors[clr.ResizeGrip]             = ImVec4(0.23, 0.23, 0.23, 1.00);
		colors[clr.ResizeGripHovered]      = ImVec4(0.32, 0.32, 0.32, 1.00);
		colors[clr.ResizeGripActive]       = ImVec4(0.14, 0.14, 0.14, 1.00);
		colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
		colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
		colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
		colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
		colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.PlotHistogram]          = ImVec4(0.70, 0.70, 0.70, 1.00);
		colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TextSelectedBg]         = ImVec4(0.62, 0.62, 0.62, 1.00);
		colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
	elseif themeSelected == 2 then
		imgui.SwitchContext()
		local style  = imgui.GetStyle()
		local colors = style.Colors
		local clr    = imgui.Col
		local ImVec4 = imgui.ImVec4
		local ImVec2 = imgui.ImVec2

		style.WindowPadding = imgui.ImVec2(8, 8)
		style.WindowRounding = 9
		style.ChildWindowRounding = 5
		style.FramePadding = imgui.ImVec2(5, 3)
		style.FrameRounding = 3.0
		style.ItemSpacing = imgui.ImVec2(5, 4)
		style.ItemInnerSpacing = imgui.ImVec2(4, 4)
		style.IndentSpacing = 21
		style.ScrollbarSize = 10.0
		style.ScrollbarRounding = 13
		style.GrabMinSize = 8
		style.GrabRounding = 1
		style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
		style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

		colors[clr.Text]                 = ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.TextDisabled]         = ImVec4(0.22, 0.22, 0.22, 1.00)
		colors[clr.WindowBg]             = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.ChildWindowBg]        = ImVec4(0.92, 0.92, 0.92, 0.00)
		colors[clr.PopupBg]              = ImVec4(1.00, 1.00, 1.00, 0.94)
		colors[clr.Border]               = ImVec4(1.00, 1.00, 1.00, 0.50)
		colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.70)
		colors[clr.FrameBg]              = ImVec4(0.77, 0.49, 0.66, 0.54)
		colors[clr.FrameBgHovered]       = ImVec4(1.00, 1.00, 1.00, 0.40)
		colors[clr.FrameBgActive]        = ImVec4(1.00, 1.00, 1.00, 0.67)
		colors[clr.TitleBg]              = ImVec4(0.76, 0.51, 0.66, 1.00)
		colors[clr.TitleBgActive]        = ImVec4(0.97, 0.74, 0.88, 1.00)
		colors[clr.TitleBgCollapsed]     = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.MenuBarBg]            = ImVec4(1.00, 1.00, 1.00, 0.54)
		colors[clr.ScrollbarBg]          = ImVec4(0.81, 0.81, 0.81, 0.54)
		colors[clr.ScrollbarGrab]        = ImVec4(0.78, 0.28, 0.58, 0.13)
		colors[clr.ScrollbarGrabHovered] = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
		colors[clr.ComboBg]              = ImVec4(0.20, 0.20, 0.20, 0.99)
		colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.SliderGrab]           = ImVec4(0.71, 0.39, 0.39, 1.00)
		colors[clr.SliderGrabActive]     = ImVec4(0.76, 0.51, 0.66, 0.46)
		colors[clr.Button]               = ImVec4(0.78, 0.28, 0.58, 0.54)
		colors[clr.ButtonHovered]        = ImVec4(0.77, 0.52, 0.67, 0.54)
		colors[clr.ButtonActive]         = ImVec4(0.20, 0.20, 0.20, 0.50)
		colors[clr.Header]               = ImVec4(0.78, 0.28, 0.58, 0.54)
		colors[clr.HeaderHovered]        = ImVec4(0.78, 0.28, 0.58, 0.25)
		colors[clr.HeaderActive]         = ImVec4(0.79, 0.04, 0.48, 0.63)
		colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
		colors[clr.SeparatorHovered]     = ImVec4(0.79, 0.44, 0.65, 0.64)
		colors[clr.SeparatorActive]      = ImVec4(0.79, 0.17, 0.54, 0.77)
		colors[clr.ResizeGrip]           = ImVec4(0.87, 0.36, 0.66, 0.54)
		colors[clr.ResizeGripHovered]    = ImVec4(0.76, 0.51, 0.66, 0.46)
		colors[clr.ResizeGripActive]     = ImVec4(0.76, 0.51, 0.66, 0.46)
		colors[clr.CloseButton]          = ImVec4(0.41, 0.41, 0.41, 1.00)
		colors[clr.CloseButtonHovered]   = ImVec4(0.76, 0.46, 0.64, 0.71)
		colors[clr.CloseButtonActive]    = ImVec4(0.78, 0.28, 0.58, 0.79)
		colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
		colors[clr.PlotLinesHovered]     = ImVec4(0.92, 0.92, 0.92, 1.00)
		colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
		colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
		colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
	end
end
apply_custom_style()
  
  -- imgui
  
chartNames = {}
chartValues = {}

chartRentNames = {}
chartRentValues = {}
  
function imgui.OnDrawFrame()

	local sw, sh = getScreenResolution()
	if main_window_state.v then
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sw / 2.22, sh / 1.2), imgui.Cond.FirstUseEver)

		imgui.Begin(fa.ICON_MONEY..u8"    FARMILA", main_window_state)
			
			imgui.SetCursorPosX(20)
			imgui.SetCursorPosY(80)
			
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
			if imgui.Button(fa.ICON_HOME.."    Home", imgui.ImVec2(200, 50)) then
				currentWindow = 0
			end
			imgui.PopStyleColor()
			
			imgui.SetCursorPosX(30 + 200)
			imgui.SetCursorPosY(80)
			
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
			if imgui.Button(fa.ICON_ENVELOPE.."    Advertisement", imgui.ImVec2(200, 50)) then
				currentWindow = 1
			end
			imgui.PopStyleColor()
			
			imgui.SetCursorPosX(40 + 200 * 2)
			imgui.SetCursorPosY(80)
			
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
			if imgui.Button(fa.ICON_MONEY.."    Item Rent", imgui.ImVec2(200, 50)) then
				currentWindow = 2
			end
			imgui.PopStyleColor()
			
			imgui.SetCursorPosX(50 + 200 * 3)
			imgui.SetCursorPosY(80)
			
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
			if imgui.Button(fa.ICON_QRCODE.."    Other Settings", imgui.ImVec2(200, 50)) then
				currentWindow = 3
			end
			imgui.PopStyleColor()
			
			local windowSize = imgui.GetWindowSize()
			if currentWindow == 1 then
				imgui.BeginChild("displayList", imgui.ImVec2(200, windowSize.y - 150), true, imgui.WindowFlags.NoScrollbar)
					imgui.CenterTextColoredRGB("PRESET")
					for k, v in pairs(vrPresets) do
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.0, 0.0, 0.0, 0.80))
						if imgui.Button(u8:decode(k), imgui.ImVec2(172, 25)) then
							vr_presetName.v = k
							vr_presetText.v = vrPresets[k].presetText
							selectedPreset = k
							vr_message.v = vrPresets[k].presetText
						end
						imgui.PopStyleColor()
					end
					imgui.EndChild()
					
					imgui.SetCursorPosX(220)
					imgui.SetCursorPosY(138)
					imgui.BeginChild("displayContent", imgui.ImVec2(windowSize.x - 235, windowSize.y - 150), true, imgui.WindowFlags.NoScrollbar)
						imgui.SetWindowFontScale(1.5)
						imgui.CenterTextColoredRGB("Advertisement")
						imgui.SetWindowFontScale(1)
						
						imgui.CenterTextColoredRGB("Текущий текст рекламы")
						imgui.CenterTextColoredRGB("{566DFF}"..u8:decode(config.vipChat.vr_text))
						
						imgui.CenterTextColoredRGB("Количество символов")
						imgui.CenterTextColoredRGB("{C84949}"..#u8:decode(config.vipChat.vr_text))
						imgui.CenterTextColoredRGB("{342C34}Лимит чата - 144 символа, учитывайте ник и префиксы, если таковые имеются")
						
						imgui.Spacing()
						imgui.Separator()
						imgui.Spacing()
						
						imgui.CenterTextColoredRGB("Введите текст для рекламы")
						imgui.centerInputText("##", vr_message, imgui.GetWindowWidth() - 20)
						
						imgui.Spacing()
						
						imgui.CenterTextColoredRGB("Выберите К/Д рекламы")
						imgui.centerInputInt("## #", vr_cooldown, 150)
						
						imgui.Spacing()
						imgui.Spacing()
						
						local windowWidth = imgui.GetWindowWidth()
						local cursorPosX = (windowWidth - 200) * 0.5
						imgui.PushItemWidth(200)
						imgui.SetCursorPosX(cursorPosX)
						imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
						if imgui.Button(fa.ICON_FLOPPY_O..u8"   Save", imgui.ImVec2(200, 40)) then
							config.vipChat.vr_text = vr_message.v
							config.vipChat.vr_cooldown = vr_cooldown.v
							sampAddChatMessage("[ОК] {FFFFFF}Изменения были сохранены", 0x54C353)
							saveJson()
						end
						imgui.PopStyleColor()
						imgui.PopItemWidth()
						
						local windowWidth = imgui.GetWindowWidth()
						local cursorPosX = (windowWidth - 200) * 0.5
						imgui.PushItemWidth(200)
						imgui.SetCursorPosX(cursorPosX)

						local buttonText = ""
						if isAdEnabled then
							buttonText = "Disable"
							imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.78, 0.28, 0.28, 1.00))
						else
							buttonText = "Enable"
							imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.32, 0.76, 0.32, 1.00))
							autoAdStartedAt = currentTime()
						end
						imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
						if imgui.Button(fa.ICON_HEART..u8"   "..buttonText, imgui.ImVec2(200, 40)) then
							if #vr_message.v > 0 and vr_cooldown.v > 20 then
								isAdEnabled = not isAdEnabled
							else
								sampAddChatMessage("[ERR] {FFFFFF}Не удалось запустить рекламу {C84949}(input is empty or cooldown is too low)", 0xC84949)
							end
						end
						imgui.SameLine()
						imgui.PopStyleColor()
						imgui.PopStyleColor()
						if isAdEnabled then
							if isPaused then
								imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.43, 0.46, 1.00, 1.00))
							else
								imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.09, 0.12, 1.00))
							end
							if imgui.Button(fa.ICON_PAUSE, imgui.ImVec2(40, 40)) then
								isPaused = not isPaused
							end
							imgui.PopStyleColor()
						end
						imgui.PopItemWidth()
						
						if isAdEnabled then
							imgui.CenterTextColoredRGB("До отправки рекламы осталось {C84949}"..config.vipChat.vr_cooldown-(currentTime() - autoAdStartedAt).. "{000000} сек.")
							local progress = (currentTime() - autoAdStartedAt) / config.vipChat.vr_cooldown
							progress = math.max(0, math.min(progress, 1))
							imgui.centerBufferingBar(progress, imgui.GetWindowWidth() / 1.5)
						end
						
						
						imgui.Spacing()
						imgui.Spacing()
						
						imgui.BeginChild("adPresets", imgui.ImVec2(windowSize.x - 268, windowSize.y - 470), true, imgui.WindowFlags.NoScrollbar)
							imgui.SetWindowFontScale(1.5)
							imgui.CenterTextColoredRGB("PRESETS")
							imgui.SetWindowFontScale(1)
							
							imgui.Spacing()
							imgui.Separator()
							imgui.Spacing()
							
							imgui.CenterTextColoredRGB("Введите название пресета")
							imgui.centerInputText("## ## #", vr_presetName, 250)
							
							imgui.Spacing()
							
							imgui.CenterTextColoredRGB("Текст пресета")
							imgui.centerInputText("## ## # #", vr_presetText, 250)
							
							
							imgui.Spacing()
							imgui.Spacing()
							
							local windowWidth = imgui.GetWindowWidth()
							local cursorPosX = (windowWidth - 200) * 0.5
							imgui.PushItemWidth(200)
							imgui.SetCursorPosX(cursorPosX)
							imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
							if imgui.Button(fa.ICON_BOOK..u8"   Create", imgui.ImVec2(200, 40)) then
								if #vr_presetName.v > 0 and #vr_presetText.v > 0 then
									vrPresets[vr_presetName.v] = {presetText = vr_presetText.v}
									savePresetsData()
									sampAddChatMessage("[ОК] {FFFFFF}Пресет был создан", 0x54C353)
								else
									sampAddChatMessage("[ERR] {FFFFFF}Не удалось создать пресет {C84949}(Empty Inputs)", 0xC84949)
								end
							end
							imgui.PopStyleColor()
							imgui.PopItemWidth()
							
							local windowWidth = imgui.GetWindowWidth()
							local cursorPosX = (windowWidth - 200) * 0.5
							imgui.PushItemWidth(200)
							imgui.SetCursorPosX(cursorPosX)
							imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.09, 0.09, 0.09, 1.00))
							imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
							if imgui.Button(fa.ICON_TRASH..u8"   Delete", imgui.ImVec2(200, 40)) then
								if selectedPreset ~= nil then
									vrPresets[selectedPreset] = nil
									vr_presetName.v = ""
									vr_presetText.v = ""
									sampAddChatMessage("[ОК] {FFFFFF}Пресет был удален", 0x54C353)
									selectedPreset = nil
									savePresetsData()
								else
									sampAddChatMessage("[ERR] {FFFFFF}Не удалось удалить пресет {C84949}(nothing selected)", 0xC84949)
								end
							end
							imgui.PopStyleColor()
							imgui.PopStyleColor()
							imgui.PopItemWidth()
						imgui.EndChild()
				imgui.EndChild()
			elseif currentWindow == 0 then
				imgui.Spacing()
				imgui.Spacing()
				imgui.SetWindowFontScale(1.5)
				imgui.CenterTextColoredRGB("Добро пожаловать, "..sampGetPlayerNickname(id))
				imgui.SetWindowFontScale(1)
				imgui.CenterTextColoredRGB("Текущий баланс: {54C353}" .. getPlayerMoney(Player) .. "$")
				if getPlayerMoney(Player) - config.mainInfo.onConnectMoney > 0 then
					imgui.CenterTextColoredRGB("Доход за сегодня: {54C353}" .. getPlayerMoney(Player) - config.mainInfo.onConnectMoney .. "$")
				else
					imgui.CenterTextColoredRGB("Доход за сегодня: {C84949}" .. getPlayerMoney(Player) - config.mainInfo.onConnectMoney .. "$")
				end
				local currentDate = os.date("%Y-%m-%d")
				if rentEarnings[currentDate] ~= nil then
					imgui.CenterTextColoredRGB("Доход от аренды сегодня: {54C353}" .. rentEarnings[currentDate] .. "$")
				end
				imgui.Spacing()
				imgui.Spacing()
				
				function isValidDate(str)
					local pattern = "^%d%d%d%d%-%d%d%-%d%d$"
					if string.match(str, pattern) then
						return true
					else
						return false
					end
				end
				
				function dateToTimestamp(dateStr)
					local y, m, d = dateStr:match("(%d+)%-(%d+)%-(%d+)")
					if not (y and m and d) then return nil end  -- Возвращаем nil, если формат неверен
					return os.time{year=y, month=m, day=d}
				end
			
				function fillChart(days)
					for index, i in ipairs(days) do
						if moneyToChart[i] then
							table.insert(chartNames, i)
							table.insert(chartValues, moneyToChart[i])
						else
							table.insert(chartNames, i)
							table.insert(chartValues, 0)
						end
						
						if rentEarnings[i] then
							table.insert(chartRentNames, i)
							table.insert(chartRentValues, rentEarnings[i])
						else
							table.insert(chartRentNames, i)
							table.insert(chartRentValues, 0)
						end
					end
				end
			
				if #chartValues > 0 then
					imgui.chartLine("moneyChart", chartValues, chartNames, windowSize.x - 50, 400, "График дохода за неделю", imgui.GetColorU32(imgui.ImVec4(0.37, 0.42, 1.00, 0.50)))
				else
					local dates = {}
					for i = 0, 6 do
						local dayTime = 24 * 60 * 60
						local date = os.date("%Y-%m-%d", os.time() - i * dayTime)
						table.insert(dates, date)
					end
					fillChart(dates)
				end
				
				if #chartRentValues > 0 then
					imgui.chartLine("moneyChart2", chartRentValues, chartRentNames, windowSize.x - 50, 400, "График дохода от аренды за неделю", imgui.GetColorU32(imgui.ImVec4(0.24, 0.75, 0.25, 0.50)))
				else
					local dates = {}
					for i = 0, 6 do
						local dayTime = 24 * 60 * 60
						local date = os.date("%Y-%m-%d", os.time() - i * dayTime)
						table.insert(dates, date)
					end
					fillChart(dates)
				end
				imgui.Spacing()
				imgui.Spacing()
				imgui.Spacing()
				imgui.Separator()
				imgui.Spacing()
				imgui.Spacing()
				imgui.Spacing()
				imgui.SetWindowFontScale(1.5)
				imgui.CenterTextColoredRGB("Поиск данных")
				imgui.SetWindowFontScale(1)
				
				imgui.CenterTextColoredRGB("Поиск от")
				imgui.centerInputText("## ## ## ### ##", searchFrom, 200)
				imgui.CenterTextColoredRGB("Поиск до")
				imgui.centerInputText("## ## ## # ## ####", searchTo, 200)
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.00, 0.00, 0.00, 0.30))
				imgui.CenterTextColoredRGB("Примечание: Вводите дату в формате YYYY-MM-DD")
				imgui.PopStyleColor()
				
				imgui.Spacing()
				imgui.Spacing()

				
				local windowWidth = imgui.GetWindowWidth()
				local cursorPosX = (windowWidth - 200) * 0.5
				imgui.PushItemWidth(200)
				imgui.SetCursorPosX(cursorPosX)
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
				if imgui.Button(fa.ICON_SEARCH..u8"   Search", imgui.ImVec2(200, 40)) then
					if isValidDate(searchFrom.v) and isValidDate(searchTo.v) then
						local timestamp1 = dateToTimestamp(searchFrom.v)
						local timestamp2 = dateToTimestamp(searchTo.v)
						
						local dayDurationTime = 24 * 60 * 60
						
						local dates = {}
						for timestamp = timestamp1, timestamp2, dayDurationTime do
							table.insert(dates, os.date("%Y-%m-%d", timestamp))
						end
						chartNames = {}
						chartValues = {}
						chartRentNames = {}
						chartRentValues = {}
						fillChart(dates)
					else
						sampAddChatMessage("[ERR] {FFFFFF}Не удалось получить информацию {C84949}(date format)", 0xC84949)
					end
				end
				imgui.PopStyleColor()
				imgui.PopItemWidth()
				
			elseif currentWindow == 3 then
						
				imgui.Spacing()
				imgui.Spacing()
				imgui.SetCursorPosX(20)
				imgui.BeginChild("settingsCont", imgui.ImVec2(windowSize.x - 35, windowSize.y - 170), true, imgui.WindowFlags.NoScrollbar)
					imgui.SetWindowFontScale(1.5)
					imgui.CenterTextColoredRGB("Settings")
					imgui.SetWindowFontScale(1)
					
					imgui.Spacing()
					imgui.Spacing()
					
					imgui.Separator()
					
					imgui.Spacing()
					imgui.Spacing()
					
					if imgui.Button(u8"Выберите тему", imgui.ImVec2(200, 30)) then
						imgui.OpenPopup("themesMenu")
					end
					
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text(u8"Измените внешний вид скрипта")
						imgui.EndTooltip()
					end
					
				
					if imgui.BeginPopup("themesMenu") then
						if imgui.MenuItem(u8"Темная") then
							themeSelected = 0
							config.settings.theme = 0
							apply_custom_style()
							saveJson()
						end
						if imgui.MenuItem(u8"Белая") then
							themeSelected = 1
							config.settings.theme = 1
							apply_custom_style()
							saveJson()
						end
						if imgui.MenuItem(u8"Розовая") then
							themeSelected = 2
							config.settings.theme = 2
							apply_custom_style()
							saveJson()
						end
						-- можно добавить больше опций
						imgui.EndPopup()
					end
					
					
					
					imgui.Spacing()
					imgui.Spacing()
		
					if imgui.Checkbox(u8'Автоломка', autoLomka) then
						config.settings.autolomka = autoLomka.v
						saveJson()
					end
					
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text(u8"Использует 3-шт наркотиков при начале ломки")
						imgui.EndTooltip()
					end
					
					if imgui.Checkbox(u8'Антиафк', lAfk) then
						config.settings.lAfk = lAfk.v
						saveJson()
					end
					
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text(u8"Отключает антиафк при спавне")
						imgui.EndTooltip()
					end
					
					if imgui.Checkbox(u8'Номера из /vr', numberToCb) then
						config.settings.numberToClipboard = numberToCb.v
						saveJson()
					end
					
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text(u8"Копирует номера игроков из /vr, если в строке было найдено нужное слово")
						imgui.EndTooltip()
					end
				
				imgui.EndChild()
			
			elseif currentWindow == 2 then
				
				imgui.Spacing()
				imgui.Spacing()
				imgui.SetWindowFontScale(1.5)
				imgui.CenterTextColoredRGB("ITEM RENT")
				imgui.SetWindowFontScale(1)

				local itemsCount = 0
				for k, v in pairs(config.rentItemList) do
					itemsCount = itemsCount + 1
				end
				
				if itemsCount > 0 then
					for k, v in pairs(config.rentItemList) do
						if imgui.Button(u8(k), imgui.ImVec2(windowSize.x - 30, 55)) then
							
						end
						local left = config.rentItemList[k].rentTime - currentTime()
						local hours = math.floor(left / 3600)
						local mins = math.floor((left % 300) / 60)
						local secs = left % 60

						imgui.CenterTextColoredRGB("Оставшееся время аренды: {C84949}"..string.format("%02d:%02d:%02d", hours, mins, secs))
						imgui.CenterTextColoredRGB("Вы сдали предмет за: {C84949}"..config.rentItemList[k].rentPrice .. "$")
					end
				else
					imgui.SetWindowFontScale(1.5)
					imgui.CenterTextColoredRGB("{C84949}Вы пока ничего не сдаете :(")
					imgui.SetWindowFontScale(1)
				end
			end
		
		imgui.End()
	end
	if notification_window_state.v then
		imgui.SetNextWindowPos(imgui.ImVec2(sw - 200, sh / 1.1), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sw / 5, sh / 10), imgui.Cond.FirstUseEver)
			
		imgui.Begin(fa.ICON_COMMENTS..u8"    Оповещение", main_window_state)
			imgui.SetCursorPosY(sh / 10 / 2)
			imgui.SetCursorPosX(30)
			imgui.CenterTextColoredRGB(notifyText)
		imgui.End()
	end
end

function imgui.inputTextWithPlaceholder(inputId, buffer, placeholder, width)
	imgui.PushItemWidth(width)
	imgui.InputText(inputId, buffer)
	imgui.PopItemWidth()
	
	local buttonPos = imgui.GetCursorPos()
	imgui.SetCursorPosX(buttonPos.x + 10)
	imgui.SetCursorPosY(buttonPos.y - 22)
	imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.00, 0.00, 0.00, 0.60))
	imgui.Text(u8(placeholder))
	imgui.PopStyleColor()
end

local function findMaxAbsValue(array)
    local max = math.abs(array[1])
    for i = 2, #array do
        local absValue = math.abs(array[i])
        if absValue > max then
            max = absValue
        end
    end
    return max
end

local function normalizeValues(array, maxVal, maxPix)
    local normalized = {}
    for i, value in ipairs(array) do
        normalized[i] = (value / maxVal) * maxPix
    end
    return normalized
end

function findMaxNumber(table)
    local max = nil
    for _, value in pairs(table) do
        if type(value) == "number" then
            if max == nil or value > max then
                max = value
            end
        end
    end
    return max
end

function imgui.chartLine(chartId, data, names, width, height, title, color)
	local windowWidth = imgui.GetWindowWidth()
	local cursorPosX = (windowWidth - width) * 0.5
	imgui.PushItemWidth(width)
	imgui.SetCursorPosX(cursorPosX)
	imgui.BeginChild(chartId, imgui.ImVec2(width, height), true, imgui.WindowFlags.NoScrollbar)
		imgui.CenterTextColoredRGB(title)
		local draw_list = imgui.GetWindowDrawList()
		local p = imgui.GetCursorScreenPos()
		local ws = imgui.GetWindowSize()
		
		local wp = imgui.GetWindowPos()
		
		local savedData = data
		
		data = normalizeValues(data, findMaxAbsValue(data), height / 2 - 70)
		
		local oneStepWidth = width / #data
		local biggestInteger = findMaxNumber(data)
		
		local rawCorY = wp.y + height / 2
		
		local corX = wp.x 
		local corY = wp.y + height / 2
		
		local linesData = {}
		
		for index, i in ipairs(data) do
			p = i
			imgui.drawClickableLine(corX, corY, corX + oneStepWidth, rawCorY-p, color, savedData[index], names[index])
			corX = corX + oneStepWidth
			corY = rawCorY - p 
			
			local cursorPos = imgui.GetMousePos()
		end
		
		if #names < 20 then
			for _, i in pairs(names) do
				imgui.SetCursorPosX(-90 + oneStepWidth * _)
				imgui.SetCursorPosY(ws.y * 0.90)
				imgui.Text(i)
			end
		end
	imgui.EndChild()
	imgui.PopItemWidth()
	
end

function imgui.drawClickableLine(corX, corY, toCorX, toCorY, color, value, name)
	local cursorPos = imgui.GetMousePos()
	local minY = math.min(corY, toCorY)
	local maxY = math.max(corY, toCorY)
	if cursorPos.x >= corX and cursorPos.x <= toCorX and cursorPos.y >= minY - 5 and cursorPos.y <= maxY + 5 then
		color = imgui.GetColorU32(imgui.ImVec4(0.78, 0.28, 0.28, 1.00))
		imgui.BeginChild("dialog", imgui.ImVec2(175, 50), true, imgui.WindowFlags.NoScrollbar)
			imgui.Text(""..name)
			if value > 0 then
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.32, 0.76, 0.32, 1.00))
			else
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.78, 0.28, 0.28, 1.00))
			end
			imgui.Text("".. value .. "$")
			imgui.PopStyleColor()
		imgui.EndChild()
	end
	imgui.GetWindowDrawList():AddLine(imgui.ImVec2(corX,corY), imgui.ImVec2(toCorX, toCorY), color, 2)
end

function imgui.centerInputText(id, buffer, width)
	local windowWidth = imgui.GetWindowWidth()
	local cursorPosX = (windowWidth - width) * 0.5
	imgui.PushItemWidth(width)
    imgui.SetCursorPosX(cursorPosX)
	imgui.InputText(id, buffer)
	imgui.PopItemWidth()
end

function imgui.centerBufferingBar(progress, width)
	local windowWidth = imgui.GetWindowWidth()
	local cursorPosX = (windowWidth - width) * 0.5
	imgui.PushItemWidth(width)
    imgui.SetCursorPosX(cursorPosX)
	imgui.BufferingBar("# ## ### ## ##", progress, imgui.ImVec2(width, 10), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.Button]), imgui.GetColorU32(imgui.ImVec4(0.32, 0.76, 0.32, 1.00)))
	imgui.PopItemWidth()
end


function imgui.centerInputInt(id, buffer, width)
	local windowWidth = imgui.GetWindowWidth()
	local cursorPosX = (windowWidth - width) * 0.5
	imgui.PushItemWidth(width)
    imgui.SetCursorPosX(cursorPosX)
	imgui.InputInt(id, buffer)
	imgui.PopItemWidth()
end