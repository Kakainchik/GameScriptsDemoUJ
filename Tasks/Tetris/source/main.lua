local mapWidth = 10
local mapHeight = 20
local blockSize = 30
local dropTimer = 0
local dropInterval = 0.5
local gameOver = false
local map = {}
local currentShape = {}
local mergeSound = {}

local shapes = {
    {
        -- I
        color = {0, 1, 1},
        grid = {
            {0,0,0,0},
            {1,1,1,1},
            {0,0,0,0},
            {0,0,0,0}
        }
    },
    {
        -- J
        color = {0, 0, 1},
        grid = {
            {1,0,0},
            {1,1,1},
            {0,0,0}
        }
    }, 
    {
        -- L
        color = {1, 0.5, 0},
        grid = {
            {0,0,1},
            {1,1,1},
            {0,0,0}
        }
    },
    {
        -- O
        color = {1, 1, 0},
        grid = {
            {1,1},
            {1,1}
        }
    },
    {
        -- S
        color = {0, 1, 0},
        grid = {
            {0,1,1},
            {1,1,0},
            {0,0,0}
        }
    },
    {
        -- T
        color = {0.5, 0, 1},
        grid = {
            {0,1,0},
            {1,1,1},
            {0,0,0}
        }
    },
    {
        -- Z
        color = {1, 0, 0},
        grid = {
            {1,1,0},
            {0,1,1},
            {0,0,0}
        }
    }                   
}

function SpawnShape()
    local shape = shapes[math.random(#shapes)]
    currentShape = {
        grid = shape.grid,
        color = shape.color,
        x = math.floor(mapWidth / 2) - math.floor(#shape.grid[1] / 2) + 1,
        y = 1
    }
    
    -- Game over if there no place to spawn
    if CheckCollision(currentShape.grid, currentShape.x, currentShape.y) then
        gameOver = true
        -- TODO: Add saving and loading the game
        -- love.load()
    end
end

function CheckCollision(shapeData, posX, posY)
    for y, row in ipairs(shapeData) do
        for x, val in ipairs(row) do
            if val ~= 0 then
                local fx = posX + x - 1
                local fy = posY + y - 1
                -- Check if out of bounds or collides with existing blocks
                if fx < 1 or fx > mapWidth or fy > mapHeight or (fy > 0 and map[fy] and map[fy][fx] ~= nil) then
                    return true
                end
            end
        end
    end
    return false
end

function MergeShape()
    for y, row in ipairs(currentShape.grid) do
        for x, val in ipairs(row) do
            if val ~= 0 then
                local fy, fx = currentShape.y + y - 1, currentShape.x + x - 1
                if fy > 0 then
                    map[fy][fx] = currentShape.color
                end
            end
        end
    end
    ClearLines()
    SpawnShape()
end

function ClearLines()
    local y = mapHeight
    while y > 0 do
        local isFull = true
        for x = 1, mapWidth do
            if map[y][x] == nil then
                isFull = false
                break
            end
        end
        
        if isFull then
            table.remove(map, y)
            local newRow = {}
            for x = 1, mapWidth do newRow[x] = nil end
            table.insert(map, 1, newRow)
        else
            y = y - 1
        end
    end
end

function Rotate(pGrid)
    local newGrid = {}
    local size = #pGrid
    for y = 1, size do
        newGrid[y] = {}
        for x = 1, size do
            newGrid[y][x] = pGrid[size - x + 1][y]
        end
    end
    return newGrid
end

function love.load()
    mergeSound = love.audio.newSource("merge.wav", "static")

    love.window.setMode(mapWidth * blockSize, mapHeight * blockSize)
    
    math.randomseed(os.time())
    
    -- Initialize empty map
    for y = 1, mapHeight do
        map[y] = {}
        for x = 1, mapWidth do
            map[y][x] = nil
        end
    end
    
    SpawnShape()
end

function love.update(dt)
    if gameOver then return end

    dropTimer = dropTimer + dt
    if dropTimer >= dropInterval then
        dropTimer = 0
        if not CheckCollision(currentShape.grid, currentShape.x, currentShape.y + 1) then
            currentShape.y = currentShape.y + 1
        else
            love.audio.play(mergeSound)
            MergeShape()
        end
    end
end

function love.keypressed(key)
    if key == "left" then
        if not CheckCollision(currentShape.grid, currentShape.x - 1, currentShape.y) then
            currentShape.x = currentShape.x - 1
        end
    elseif key == "right" then
        if not CheckCollision(currentShape.grid, currentShape.x + 1, currentShape.y) then
            currentShape.x = currentShape.x + 1
        end
    elseif key == "down" then
        if not CheckCollision(currentShape.grid, currentShape.x, currentShape.y + 1) then
            currentShape.y = currentShape.y + 1
            dropTimer = 0
        end
    elseif key == "up" then
        local rotatedGrid = Rotate(currentShape.grid)
        if not CheckCollision(rotatedGrid, currentShape.x, currentShape.y) then
            currentShape.grid = rotatedGrid
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.clear(0.7, 0.7, 0.7)
    
    if gameOver then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("Game Over", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        return
    end
    
    for y = 1, mapHeight do
        for x = 1, mapWidth do
            if map[y][x] then
                love.graphics.setColor(map[y][x])
                love.graphics.rectangle("fill", (x - 1) * blockSize, (y - 1) * blockSize, blockSize - 1, blockSize - 1)
            end
        end
    end
    
    if currentShape.grid then
        love.graphics.setColor(currentShape.color)
        for y, row in ipairs(currentShape.grid) do
            for x, val in ipairs(row) do
                if val ~= 0 then
                    local px = (currentShape.x + x - 2) * blockSize
                    local py = (currentShape.y + y - 2) * blockSize
                    love.graphics.rectangle("fill", px, py, blockSize - 1, blockSize - 1)
                end
            end
        end
    end
    
    love.graphics.setColor(0.1, 0.1, 0.1, 0.1)
    for x = 0, mapWidth do
        love.graphics.line(x * blockSize, 0, x * blockSize, mapHeight * blockSize)
    end
    for y = 0, mapHeight do
        love.graphics.line(0, y * blockSize, mapWidth * blockSize, y * blockSize)
    end
    
    love.graphics.setColor(1, 1, 1)
end