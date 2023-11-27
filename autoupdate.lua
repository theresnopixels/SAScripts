script_name("Lucik's autoupdater")
script_author("Mortal")
script_description("Autoupdate")

require 'lib.moonloader'
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local keys = require 'vkeys'
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

update_state = false

local version = 1
local version_text = "1.00"
local script_path = thisScript().path

local script_url = ""
local update_path = getWorkingDirectory() .. "/update.ini"
local update_url = "https://raw.githubusercontent.com/theresnopixels/SAScripts/main/update.ini"

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	
	sampRegisterChatCommand("update", cmd_update)
	
	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	nick = sampGetPlayerNickname(id)
	
	downloadUrlToFile(update_url, update_path, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			updateIni = inicfg.load(nil, update_path)
			if tonumber(updateIni.info.version) > version then
				sampAddChatMessage(u8:decode("Есть обновление! Версия: ")..updateIni.info.version_text, -1)
				update_state = true
			end
		end
		--os.remove(update_path)
	end)

	while true do
		wait(0)
		if update_state then
			downloadUrlToFile(update_url, update_path, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					--sampAddChatMessage(u8:decode("Скрипт успешно обновлен!"), -1)
					--thisScript():reload()
				end
			end)
			break
		end
		
	end
end

function cmd_update()
	updateIni = inicfg.load(nil, update_path)
	sampAddChatMessage("Нет обновления! Версия: "..updateIni.info.version_text, -1)
end