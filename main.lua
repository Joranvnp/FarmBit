love.graphics.setDefaultFilter("nearest")
io.stdout:setvbuf('no')

local Inventory = require("Inventory")

TILESIZE = 8

imgPerso = love.graphics.newImage("images/Minifantasy_CreaturesHumanTownsfolkWalk.png")
imgTileSet = love.graphics.newImage("images/Minifantasy_FarmTileset.png")
imgTilePlants = love.graphics.newImage("images/Minifantasy_FarmSeedsAndCrops.png")
imgActions = love.graphics.newImage("images/Minifantasy_FarmActionInProgress(16x16).png")

ACTION_DIG = 1
ACTION_SEED = 2
ACTION_CUT = 3
ACTION_WATER = 4

Actions = {}
currentAction = 1
currentFrameAction = 1

Player = {}
Player.x = 16
Player.y = 16
Player.speed = 60
Player.direction = "right"
Player.flip = 1
Player.target = {}
Player.target.column = 0
Player.target.line = 0
Player.Frames = {}
Player.Frames[1] = love.graphics.newQuad(8,8,16,16, imgPerso:getWidth(), imgPerso:getHeight())
Player.Frames[2] = love.graphics.newQuad(40,8,16,16, imgPerso:getWidth(), imgPerso:getHeight())
Player.Frames[3] = love.graphics.newQuad(72,8,16,16, imgPerso:getWidth(), imgPerso:getHeight())
Player.Frames[4] = love.graphics.newQuad(104,8,16,16, imgPerso:getWidth(), imgPerso:getHeight())
Player.currentFrame = 1

Plants = {}
Plants[1] = {
    name = "Pumpkin",
    id = "Pumpkin",
    tilex = 8,
    tiley = 0,
    steps = 5
}
Plants[2] = {
    name = "Tomato",
    id = "Tomato",
    tilex = 88,
    tiley = 0,
    steps = 5
}
Plants[3] = {
    name = "Corn",
    id = "Corn",
    tilex = 88,
    tiley = 32,
    steps = 5
}
Plants[4] = {
    name = "Eggplant",
    id = "Eggplant",
    tilex = 8,
    tiley = 16,
    steps = 5
}
Plants[5] = {
    name = "Lettuce",
    id = "Lettuce",
    tilex = 88,
    tiley = 64,
    steps = 5
}
Plants[6] = {
    name = "Beet",
    id = "Beet",
    tilex = 8,
    tiley = 48,
    steps = 5
}
currentPlant = 1
growTimer = 0
growSpeed = 5

MAPWIDTH = 25
MAPHEIGHT = 18
Map = {}

-- Plant types
TYPE_NONE = 0

-- Ground types
GROUND_GRASS = 1
GROUND_SOIL = 2

Ground = {}
Ground.Frames = {}
Ground.Frames[GROUND_GRASS] = love.graphics.newQuad(40,48,8,8, imgTileSet:getWidth(), imgTileSet:getHeight())
Ground.Frames[GROUND_SOIL] = love.graphics.newQuad(48,40,8,8, imgTileSet:getWidth(), imgTileSet:getHeight())

function AddAction(pPos)
    local a = {}
    a.Frames = {}
    for n=1,4 do
        a.Frames[n] = love.graphics.newQuad(
            0 + (n - 1) * 16,
            (pPos - 1) * 16,
            16,
            16,
            imgActions:getWidth(),
            imgActions:getHeight()
        )
    end
    table.insert(Actions, a)
end

function ChangePlantOnMap(pColumn, pLine, pID, pGrow)
    local tile = Map[pLine][pColumn]
    tile.Content.id = pID
    tile.Content.Grow = pGrow
    if pID == TYPE_NONE then
        tile.Content.WaterLevel = 0
    end
end

function InitPlants()
    for n=1,#Plants do
        -- Sachet de graine
        Plants[n].Bag = 
            love.graphics.newQuad(
            Plants[n].tilex,
            Plants[n].tiley + 8,
            8,
            8,
            imgTilePlants:getWidth(),
            imgTilePlants:getHeight()
        )
        Plants[n].Frames = {}
        for i=1,Plants[n].steps do
            Plants[n].Frames[i] = 
                love.graphics.newQuad(
                Plants[n].tilex + 8 + (i - 1) * 8,
                Plants[n].tiley,
                8,
                16,
                imgTilePlants:getWidth(),
                imgTilePlants:getHeight()
            )
        end
        Plants[n].Frames[Plants[n].steps+1] = 
        love.graphics.newQuad(
        Plants[n].tilex + 8 + (Plants[n].steps + 1) * 8,
        Plants[n].tiley,
        8,
        16,
        imgTilePlants:getWidth(),
        imgTilePlants:getHeight()
    )
    end
end

function InitMap()
    Map = {}
    for l=1, MAPHEIGHT do
        Map[l] = {}
        for c=1, MAPWIDTH do
            Map[l][c] = {
                Ground = GROUND_GRASS,
                Content = {
                    id = TYPE_NONE,
                    Grow = 0,
                    WaterLevel = 0
                }
            }
        end
    end
end

function PixelToMap(px, py)
    local col = math.floor(px/TILESIZE) + 1
    local lig = math.floor(py/TILESIZE) + 1
    return col, lig
end

function isInMap(pcol, plig)
    return pcol>=1 and pcol<= MAPWIDTH and plig>=1 and plig<=MAPHEIGHT
end

function love.load()
    love.window.setMode((8 * MAPWIDTH)*4, (8 * MAPHEIGHT)*4)
    InitMap()
    InitPlants()
    AddAction(2)
    AddAction(5)
    AddAction(7)
    AddAction(9)

    local font = love.graphics.newFont("font/Oxanium-ExtraBold.ttf",20)
    font:setFilter("nearest")
    love.graphics.setFont(font)
end

function GrowPlants(dt)
    -- pousse des plantes
    growTimer = growTimer + dt
    if growTimer >= growSpeed then
        growTimer  = 0
        -- chaque plante pousse
        for l = 1,MAPHEIGHT do
            for c =1,MAPWIDTH do
                local tile = Map[l][c]
                if tile.Content.id ~= TYPE_NONE then
                    if tile.Content.Grow <= Plants[tile.Content.id].steps then
                        if tile.Content.WaterLevel > 0 then
                            tile.Content.Grow = tile.Content.Grow + 1
                        end
                    end
                    if tile.Content.Grow <= Plants[tile.Content.id].steps + 1 then
                        tile.Content.WaterLevel = tile.Content.WaterLevel - 1
                        if tile.Content.WaterLevel <= -8 then
                            tile.Content.Grow = 0
                            tile.Content.id = 0
                            tile.Content.WaterLevel = 0
                        end
                    end
                end
            end
        end
    end
end

function love.update(dt)
    Player.currentFrame = Player.currentFrame + dt * 3
    if Player.currentFrame > #Player.Frames + 1 then
        Player.currentFrame = 1
    end
    --Anim action
    currentFrameAction = currentFrameAction + dt * 3
    if currentFrameAction > #Actions[currentAction].Frames + 1 then
        currentFrameAction = 1
    end

    if love.keyboard.isDown("d") then
        Player.x = Player.x + Player.speed * dt
        Player.direction = "right"
        Player.flip = 1
    end

    if love.keyboard.isDown("q") then
        Player.x = Player.x - Player.speed * dt
        Player.direction = "left"
        Player.flip = -1
    end

    if love.keyboard.isDown("z") then
        Player.y = Player.y - Player.speed * dt
        Player.direction = "up"
    end

    if love.keyboard.isDown("s") then
        Player.y = Player.y + Player.speed * dt
        Player.direction = "down"
    end

    -- Calcul de la case devant le joueur
    local x = Player.x
    local y = Player.y + 3
    -- x = x + (16 / 2 * Player.flip)
    local col
    local lig
    col, lig = PixelToMap(x, y)
    Player.target = {}
    if isInMap(col, lig) then
        Player.target.column = col
        Player.target.line = lig
    else
        Player.target.column = 0
        Player.target.line = 0
    end

    GrowPlants(dt)

end
function love.draw()
    love.graphics.scale(4, 4)

    for l=1, MAPHEIGHT do
        for c=1, MAPWIDTH do
            local x = (c-1) * TILESIZE
            local y = (l-1) * TILESIZE
            local tile = Map[l][c]
            love.graphics.draw(imgTileSet, Ground.Frames[tile.Ground], x, y)
            if tile.Content.id ~= TYPE_NONE then
                -- love.graphics.print(Map[l][c].Content.Type, x+5, y+5)
                love.graphics.draw(imgTilePlants, Plants[tile.Content.id].Frames[tile.Content.Grow], x, y, 0, 1, 1, 0, 8)
            end
            if c == Player.target.column and l == Player.target.line then
                love.graphics.setColor(0.2,1,0.2,0.3)
                love.graphics.rectangle("fill", x, y, TILESIZE, TILESIZE)
                love.graphics.setColor(1,1,1,1)
                -- dessin niveau eau
                if tile.Content.WaterLevel > 0 then
                    love.graphics.setColor(0,0,.8,.8)
                    love.graphics.line(x, y+7, x + tile.Content.WaterLevel, y+7)
                    love.graphics.setColor(1,1,1,1)
                end
            end
            if tile.Content.WaterLevel < 0 then
                love.graphics.setColor(1,0,0,.8)
                love.graphics.line(x, y+7, x + math.abs(tile.Content.WaterLevel), y+7)
                love.graphics.setColor(1,1,1,1)
            end
        end
    end

    -- Perso
    love.graphics.draw(
        imgPerso,
        Player.Frames[math.floor(Player.currentFrame)],
        Player.x,
        Player.y,
        0,
        Player.flip,
        1,
        16 / 2,
        16 / 2
    )

    --Action courante
    love.graphics.draw(imgActions, Actions[currentAction].Frames[math.floor(currentFrameAction)], Player.x-8, Player.y - (8 + 16))

    -- liste sacs de graines
    for n = 1,#Plants do
        local yy = 1 + (n-1)*9
        if n == currentPlant then
            -- love.graphics.setColor(0,1,0)
            love.graphics.line(1, yy, 1, yy + 8)
        end
        -- love.graphics.print(Plants[n].name, 5, 5 +((n-1) * 16))
        love.graphics.draw(imgTilePlants, Plants[n].Bag, 1, yy) 
        love.graphics.setColor(1,1,1)
    end

    -- Inventaire
    for n=1, #Inventory.List do
        local item = Inventory.Get(n)
        love.graphics.draw(imgTilePlants, Plants[item.id].Frames[Plants[item.id].steps + 1], (love.graphics.getWidth() / 4) - 20, (n-1)*10)
        love.graphics.print(item.quantity, (love.graphics.getWidth() / 4) - 12, ((n-1) * 10) + 4, 0, 0.3, 0.3)
    end

end

function love.keypressed(key)
    if key == "e" then
        currentPlant = currentPlant + 1
        if currentPlant > #Plants then
            currentPlant = 1
        end
    end

    if key == "a" then
        currentPlant = currentPlant - 1
        if currentPlant < 1 then
            currentPlant = #Plants
        end
    end

    
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 and isInMap(Player.target.column, Player.target.line) then
        local tile = Map[Player.target.line][Player.target.column]
        if currentAction == ACTION_DIG then
            tile.Ground = GROUND_SOIL
        elseif currentAction == ACTION_SEED then
            if tile.Ground == GROUND_SOIL then
                if tile.Content.id == TYPE_NONE then
                    ChangePlantOnMap(Player.target.column, Player.target.line, currentPlant, 1)
                end
            end
        elseif currentAction == ACTION_CUT then
            if tile.Content.id ~= TYPE_NONE then
                if tile.Content.Grow == Plants[tile.Content.id].steps + 1 then
                    -- ajout dans l'Inventory
                    Inventory.Ajoute(tile.Content.id)
                    -- supprime sur la map
                    ChangePlantOnMap(Player.target.column, Player.target.line, TYPE_NONE, 0)
                end
            end
        elseif currentAction == ACTION_WATER then
            if tile.Content.WaterLevel < 0 then
                tile.Content.WaterLevel = 0
            end
            tile.Content.WaterLevel = tile.Content.WaterLevel + 2
        end
        -- Map[Player.target.line][Player.target.column].Content.Grow = Plants[currentPlant].id
    end

    
end

function love.wheelmoved(x, y)
    if y > 0 then
        currentAction = currentAction + 1
        if currentAction > #Actions then
            currentAction = 1
        end
    end

    if y < 0 then
        currentAction = currentAction - 1
        if currentAction < 1 then
            currentAction = #Actions
        end
    end

    if key == "e" then
        currentPlant = currentPlant + 1
        if currentPlant > #Plants then
            currentPlant = 1
        end
    end

    if key == "a" then
        currentPlant = currentPlant - 1
        if currentPlant < 1 then
            currentPlant = #Plants
        end
    end
end