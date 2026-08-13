script_name('AutoBodyCamera')
script_author('by KuDo')

require 'lib.moonloader'
local sampev = require 'lib.samp.events'

-- Настройки
local MOVE_THRESHOLD = 0.3   -- минимальное расстояние (в игровых единицах), чтобы считать это движением
local CHECK_INTERVAL = 200   -- как часто проверять позицию (мс)
local ACTIVATE_DELAY = 10000  -- задержка перед отправкой команды после обнаружения движения (мс)

local lastX, lastY, lastZ = nil, nil, nil
local waitingForMovement = false
local alreadyTriggered = false

-- Функция запуска бодикамеры
local function activateBodyCamera()
    if alreadyTriggered then return end
    alreadyTriggered = true

    lua_thread.create(function()
        wait(ACTIVATE_DELAY)
        sampSendChat('/bodycamera')
        sampAddChatMessage('{00FF00}[AutoBodyCamera]{FFFFFF} Боди камера активирована', -1)
    end)
end

-- Сброс состояния (например, при смерти/новом спавне)
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
