-- Helper functions for drawing UI elements
function drawScaledImage(image, x, y, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, x, y, 0, width/image:getWidth(), height/image:getHeight())
end

function drawTextInBubble(text, bubbleX, bubbleY, bubbleWidth, bubbleHeight, font)
    local currentFont = love.graphics.getFont()
    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0)
    
    -- Calculate text dimensions
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    -- Position text in bubble with offset
    local textX = bubbleX + (bubbleWidth - textWidth) / 2 + 5
    local textY = bubbleY + (bubbleHeight - textHeight) / 2 - 10
    
    -- Draw text at exact pixel coordinates
    love.graphics.print(text, math.floor(textX), math.floor(textY))
    
    -- Restore original font
    love.graphics.setFont(currentFont)
end

function drawPromptText(text, font)
    local screenWidth = love.graphics.getWidth()
    local promptWidth = 200
    local promptHeight = 40
    local promptX = (screenWidth - promptWidth) / 2
    local promptY = love.graphics.getHeight() - promptHeight - 20
    
    local currentFont = love.graphics.getFont()
    love.graphics.setFont(font)
    
    -- Draw text with shadow for bold effect
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.printf(text, promptX + 1, promptY + 1, promptWidth, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, promptX, promptY, promptWidth, "center")
    
    love.graphics.setFont(currentFont)
end

-- Game entities
player = {
    speed = 250
}

npc = {
    x = 700,
    y = 540,
    width = 50,
    height = 50,
    speakRange = 100,
    speaking = false,
    greetingMessage = "Meoww!",
    longMessage = "Meow! Meow! Meow! *purrs happily* Meow meow meow! *tilts head* Meooooow!",
    message = "",
    messageTimer = 0,
    messageDisplayTime = 5,
    scale = 2,
    currentText = "",
    textSpeed = 0.05,
    textTimer = 0,
    inRange = false,
    interacted = false,
    textComplete = false,
    fontSize = 24,  -- Increased from 18 to 24
    showSpeechBubble = false,
    dialogueActive = false
}

-- Initialize game resources and state
function love.load()
    -- Load libraries
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
    
    -- Load dialogue box image
    dialogueImage = love.graphics.newImage("sprites/dialogue.png")
    
    -- Load speech bubble image
    speechBubbleImage = love.graphics.newImage("sprites/speech-bubble.png")
    
    -- Load CCRA font for dialogue
    ccraFont = love.graphics.newFont("fonts/CCRA.ttf", npc.fontSize)
    -- Load a smaller font for the 'Press E to interact' text
    boldFont = love.graphics.newFont("fonts/CCRA.ttf", 18)
    -- Load a larger font for speech bubble
    smallFont = love.graphics.newFont("fonts/CCRA.ttf", 20)

    love.graphics.setDefaultFilter('nearest', 'nearest')

    player.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)

    -- Load kitty-box sprite and animation
    npc.spriteSheet = love.graphics.newImage("sprites/kitty-box.png")
    npc.grid = anim8.newGrid(32, 32, npc.spriteSheet:getWidth(), npc.spriteSheet:getHeight())
    npc.animation = anim8.newAnimation(npc.grid('1-4', 1), 0.3)
    
    player.anim = player.animations.left

    player.collider = world:newBSGRectangleCollider(260, 150, 50, 60, 10)
    player.collider:setFixedRotation(true)
    
    -- Create NPC collider
    npc.collider = world:newRectangleCollider(npc.x, npc.y, npc.width, npc.height)
    npc.collider:setType('static')

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
    
    -- Update NPC animation
    npc.animation:update(dt)
    
    -- Check if player is near NPC
    local distance = math.sqrt((player.x - npc.x)^2 + (player.y - npc.y)^2)
    
    -- Update NPC in-range status
    if distance <= npc.speakRange then
        if not npc.inRange then
            -- Player just entered range, show speech bubble
            npc.inRange = true
            npc.showSpeechBubble = true
            npc.dialogueActive = false
            npc.interacted = false
            sounds.blip:play() -- Play sound when speech bubble appears
        end
    else
        -- Player left range
        npc.inRange = false
        npc.showSpeechBubble = false
        npc.dialogueActive = false
        npc.speaking = false
    end
    
    -- Update typewriter effect for dialogue
    if npc.speaking then
        -- Only update the text if it's not complete
        if not npc.textComplete then
            npc.textTimer = npc.textTimer + dt
            if npc.textTimer >= npc.textSpeed then
                npc.textTimer = 0
                local nextCharIndex = #npc.currentText + 1
                if nextCharIndex <= #npc.message then
                    npc.currentText = string.sub(npc.message, 1, nextCharIndex)
                else
                    -- Text is now complete
                    npc.textComplete = true
                end
            end
        end
        -- No longer using timer to auto-close dialogue
    end

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
        
        -- Draw NPC (kitty-box sprite)
        love.graphics.setColor(1, 1, 1)
        npc.animation:draw(npc.spriteSheet, npc.x, npc.y, nil, npc.scale, nil, 8, 8)
        
        -- Draw player
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 12)
        
        -- Draw speech bubble if player is in range and hasn't interacted yet
        if npc.inRange and npc.showSpeechBubble and not npc.dialogueActive then
            -- Save current font
            local currentFont = love.graphics.getFont()
            
            -- Draw speech bubble (moved slightly right)
            love.graphics.setColor(1, 1, 1)
            local bubbleWidth = 90
            local bubbleHeight = 70
            local bubbleX = npc.x - bubbleWidth/2 + 15  -- Moved 15 pixels to the right
            local bubbleY = npc.y - 80
            
            -- Draw speech bubble image with proper scaling
            drawScaledImage(speechBubbleImage, bubbleX, bubbleY, bubbleWidth, bubbleHeight)
            
            -- Draw "Meoww!" text in speech bubble with pixel-perfect positioning
            drawTextInBubble("Meoww!", bubbleX, bubbleY, bubbleWidth, bubbleHeight, smallFont)
            
            -- Restore original font
            love.graphics.setFont(currentFont)
            
            love.graphics.setColor(1, 1, 1)
        end
    cam:detach()
    
    -- Show "Press E to interact" at the bottom of the screen if player is in range but dialogue isn't active
    if npc.inRange and npc.showSpeechBubble and not npc.dialogueActive then
        drawPromptText("Press E to interact", boldFont)
    end
    
    -- Draw message box at the bottom of the screen if dialogue is active
    if npc.dialogueActive and npc.speaking then
        local screenWidth = love.graphics.getWidth()
        local boxWidth = 600  -- Increased from 500 to 600
        local boxHeight = 150  -- Increased from 120 to 150
        local boxX = (screenWidth - boxWidth) / 2
        local boxY = love.graphics.getHeight() - boxHeight - 20
        
        -- First draw the dialogue image
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(dialogueImage, boxX, boxY, 0, boxWidth/dialogueImage:getWidth(), boxHeight/dialogueImage:getHeight())
        
        -- Then draw a slightly smaller black rectangle inside the dialogue box
        -- Add some padding to keep the black rectangle inside the dialogue image border
        local padding = 10
        love.graphics.setColor(0, 0, 0, 0.8) -- Black background with some transparency
        love.graphics.rectangle("fill", boxX + padding, boxY + padding, boxWidth - (padding * 2), boxHeight - (padding * 2))
        
        -- Draw message text with typewriter effect and CCRA font
        local defaultFont = love.graphics.getFont()
        love.graphics.setFont(ccraFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(npc.currentText, boxX + 20, boxY + 30, boxWidth - 40, "left")
        
        -- Show prompt to continue when text is complete
        if npc.textComplete then
            love.graphics.printf("Press E to continue", boxX + 20, boxY + boxHeight - 30, boxWidth - 40, "right")
        end
        
        -- Reset to default font
        love.graphics.setFont(defaultFont)
    end
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
    
    -- Handle NPC interaction with E key
    if key == "e" then
        if npc.inRange then
            if npc.showSpeechBubble and not npc.dialogueActive then
                -- First interaction - activate dialogue box
                npc.dialogueActive = true
                npc.speaking = true
                npc.message = npc.longMessage
                npc.currentText = ""
                npc.textTimer = 0
                npc.textComplete = false
                npc.showSpeechBubble = false  -- Hide speech bubble when dialogue is active
                sounds.blip:play() -- Play sound for interaction
            elseif npc.dialogueActive and npc.speaking and npc.textComplete then
                -- Text is complete, close the dialogue
                npc.speaking = false
                npc.dialogueActive = false
                npc.interacted = true
                sounds.blip:play()
            end
        end
    end
end
