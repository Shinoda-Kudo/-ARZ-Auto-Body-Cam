local CURRENT_VERSION = '1.0.1'

script_name('AutoBodyCamera')
script_author('by KuDo')
script_version(CURRENT_VERSION)
script_version_number(1)
script_description('Скрипт для Авто Боди камеры')

require 'lib.moonloader'
local sampev = require 'lib.samp.events'
local encoding = require("encoding")
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ==============================
--    Update Settings
-- ==============================
local VERSION_URL = 'https://raw.githubusercontent.com/Shinoda-Kudo/-ARZ-Auto-Body-Cam/main/BodyCam.lua'
local SCRIPT_PATH = thisScript().path

local function checkUpdate()
    local tmpPath = SCRIPT_PATH .. '.ver.json'

    downloadUrlToFile(VERSION_URL, tmpPath, function(id, status)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            local file = io.open(tmpPath, 'r')
            if not file then
                print('[AutoBodyCamera Updater] Не удалось открыть ver.json')
                return
            end

            local content = file:read('*a')
            file:close()
            os.remove(tmpPath)

            local ok, data = pcall(decodeJson, content)
            if not ok or not data or not data.version then
                print('[AutoBodyCamera Updater] Ошибка чтения ver.json')
                return
            end

            if data.version ~= CURRENT_VERSION then
                sampAddChatMessage(('{00FF00}[AutoBodyCamera]{FFFFFF} Найдена новая версия %s (у вас %s). Обновляю...')
                    :format(data.version, CURRENT_VERSION), -1)

                downloadUrlToFile(data.url, SCRIPT_PATH, function(id2, status2)
                    if status2 == dlstatus.STATUSEX_ENDDOWNLOAD then
                        sampAddChatMessage('{00FF00}[AutoBodyCamera]{FFFFFF} Обновление завершено! Перезапуск...', -1)
                        thisScript():reload()
                    elseif status2 == dlstatus.STATUSEX_ERROR then
                        sampAddChatMessage('{FF0000}[AutoBodyCamera]{FFFFFF} Ошибка скачивания новой версии', -1)
                    end
                end)
            end

        elseif status == dlstatus.STATUSEX_ERROR then
            print('[AutoBodyCamera Updater] Не удалось проверить обновление.')
        end
    end)
end

-- ==============================
--   Cam Settings
-- ==============================
local MOVE_THRESHOLD = 0.3      -- минимальное расстояние для расчета движений
local CHECK_INTERVAL = 200      -- проверка позиции
local ACTIVATE_DELAY = 10000    -- задержка перед отправкой команды после движения (мс) [не советую опускать ниже иначе может сработать раньше времени]

local lastX, lastY, lastZ = nil, nil, nil
local waitingForMovement = false
local alreadyTriggered = false

-- start
local function activateBodyCamera()
    if alreadyTriggered then return end
    alreadyTriggered = true

    lua_thread.create(function()
        wait(ACTIVATE_DELAY)
        sampSendChat('/bodycamera')
        sampAddChatMessage('{00FF00}[AutoBodyCamera]{FFFFFF} Боди камера активирована', -1)
    end)
end

-- hp 0 && new spawn
local function resetState()
    waitingForMovement = true
    alreadyTriggered = false
    lastX, lastY, lastZ = nil, nil, nil
end

function sampev.onSpawn()
    resetState()
end

function main()
    while not isSampfuncsLoaded() or not isSampLoaded() do wait(0) end
    while not isSampAvailable() do wait(0) end

    sampAddChatMessage('{00FF00}[AutoBodyCamera]{FFFF00} by KuDo.{FFFFFF} Скрип успешно загружен', -1)

    checkUpdate()

    resetState()

    while true do
        wait(CHECK_INTERVAL)

        if waitingForMovement and not alreadyTriggered then
            if doesCharExist(PLAYER_PED) and getCharHealth(PLAYER_PED) > 0 then
                local x, y, z = getCharCoordinates(PLAYER_PED)

                if lastX == nil then
                    lastX, lastY, lastZ = x, y, z
                else
                    local dist = math.sqrt((x - lastX)^2 + (y - lastY)^2 + (z - lastZ)^2)

                    if dist >= MOVE_THRESHOLD then
                        activateBodyCamera()
                        waitingForMovement = false
                    else
                        lastX, lastY, lastZ = x, y, z
                    end
                end
            end
        end
    end
end
