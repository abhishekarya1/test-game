player = {
    speed = 250
}

function love.load()
    wf = require 'libs/windfield'
    world = wf.newWorld(0, 0)
    sti = require 'libs/sti'
    anim8 = require 'libs/anim8'
    camera = require 'libs/camera'
    cam = camera()

    sounds = {}
    sounds.blip = love.audio.newSource('sounds/blip.wav', 'static')
    sounds.music = love.audio.newSource('sounds/music.mp3', 'stream')
    sounds.music:setLooping(true)
    sounds.music:play()

    love.graphics.setDefaultFilter('nearest', 'nearest')

    player.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)

    player.anim = player.animations.left

    player.collider = world:newBSGRectangleCollider(260, 150, 50, 60, 10)
    player.collider:setFixedRotation(true)

    gameMap = sti("maps/test-map.lua")

    local walls = {}
    if gameMap.layers["walls"] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
            local width = math.max(obj.width, 0.1)
            local height = math.max(obj.height, 0.1)
            local wall = world:newRectangleCollider(obj.x,obj.y,width,height)
            wall:setType('static')
            table.insert(walls,wall)
        end
    end
end

function love.update(dt)
    local isMoving = false
    local vx = 0
    local vy = 0

    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        vy = player.speed * -1
        player.anim = player.animations.up
        isMoving = true
    end
    
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        vy = player.speed
        player.anim = player.animations.down
        isMoving = true
    end
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        vx = player.speed * -1
        player.anim = player.animations.left
        isMoving = true
    end
    
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        vx = player.speed
        player.anim = player.animations.right
        isMoving = true
    end

    player.collider:setLinearVelocity(vx, vy)

    if not isMoving then
        player.anim:gotoFrame(2)
    end

    world:update(dt)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    player.anim:update(dt)

    cam:lookAt(player.x, player.y)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight
    if cam.x < w/2 then
        cam.x = w/2
    end
    if cam.y < h/2 then
        cam.y = h/2
    end
    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end
    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2)
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Use arrow keys or WASD to move the player", 10, 10)
    cam:attach()
        gameMap:drawLayer(gameMap.layers['ground'])
        gameMap:drawLayer(gameMap.layers['trees'])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 12)
    cam:detach()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "space" then
        sounds.blip:play()
    end
    if key == "m" then
        sounds.music:stop()
    end
end
