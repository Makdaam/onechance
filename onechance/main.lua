Gamestate = require "hump.gamestate"
HC = require "HardonCollider"

local gameover = {}
local menu = {}
local play = {}
local highscore = {}
local dbg = ""
local gravity = 0.01
pc = {}
local Collider = {}
local controls = {}
endConditions = {}
endConditions.blueHut = true
endConditions.redHut = true
endConditions.blueGen = false
endConditions.redGen = false
endConditions.blueLike = false
endConditions.redLike = false
endConditions.first = true
Achievs = {"Achievements"}
lastshot = 1000
colup = 1
redshootcycle = 10000000000
defblueshootcycle = 10000000000
blueshootcycle = 10000000000
defblueshootcycle = 10000000000
smokecycle = 10
ship = {}
trackedEntity = pc
controls.vx = 0
controls.vy = 0
pc.x = 0
pc.y = 500
pc.vx = 0
pc.vy = 0
pc.sx = 32
pc.sy = 32
pc.hp = 100
pc.gnd = 1000
pc.kills = 0
pc.flipx = false
pc.color = {255,255,255,255}
pc.type = "player"
pc.redkills = 0
pc.bluekills = 0
pc.interactions = 0
pc.redint = 0
pc.blueint = 0

camera = {}
camera.x = 0
camera.y = 0
camera.scx = 0.75
camera.scy = 0.75
camera.r = 0

map = {}
map.colliders = {}


function getTan(x1,y1,x2,y2,len)
    local xdiff = x2 - x1
    local ydiff = y2 - y1
    local z = math.sqrt((len*len)/((xdiff*xdiff) + (ydiff*ydiff)))
    return {xdiff*z, ydiff*z}
end

local function Proxy(f)
  return setmetatable({}, {__index = function(self, k)
    local v = f(k)
    rawset(self, k, v)
    return v
  end})
end

Image = Proxy(function(k) return love.graphics.newImage('img/' .. k .. '.png') end)
pc.img = Image.player
Entities = {pc}
Projectiles = {}

function entity(x,y,vx,vy,sx,sy,flipx,color,img,etype)
    local e = {}
    e.x = x
    e.y = y
    e.vx = vx
    e.vy = vy
    e.sx = sx
    e.sy = sy
    e.flipx = flipx
    e.color = color
    e.img = img
    e.type = etype
    e.gnd = 1000
    e.col = Collider:addRectangle(e.x+(e.sx/2),e.y+ (e.sy/2),e.sx,e.sy)
    e.col.parent = e
    table.insert(Entities, e)
    return e
end

function removeLiving(e)
    Collider:remove(e.col)
    if pc.kills == 0 then
        table.insert(Achievs, "KILLER")
    end
    if e.type == "civilian" and pc.kills == 0 then
        table.insert(Achievs, "WAR CRIMINAL")
    end
    if e.type == "hut" then
        if e.side == "red" then
            endConditions.redHut = false
        else
            endConditions.blueHut = false
        end
        if not (endConditions.redHut or endConditions.blueHut) then
            table.insert(Achievs, "HUT DESTROYER")
        end
    end
    if e.side == "red" then
        if pc.redkills < 0 then
            pc.redkills = 0
        end
        pc.redkills = pc.redkills + 1
    else
        if pc.bluekills < 0 then
            pc.bluekills = 0
        end
        pc.bluekills = pc.bluekills + 1
    end
    
    if pc.bluekills < 1 then
        defblueshootcycle = 100000000
    elseif pc.bluekills < 5 then
        defblueshootcycle = 500
        if blueshootcycle > 500 then
            blueshootcycle = 500
        end
    elseif pc.bluekills < 10 then
        defblueshootcycle = 200
        if blueshootcycle > 200 then
            blueshootcycle = 200
        end
    elseif pc.bluekills < 15 then
        defblueshootcycle = 100
        if blueshootcycle > 100 then
            blueshootcycle = 100
        end        
    elseif pc.bluekills < 20 then
        defblueshootcycle = 50
        if blueshootcycle > 50 then
            blueshootcycle = 50
        end
    else
        defblueshootcycle = 20
        if blueshootcycle > 20 then
            blueshootcycle = 20
        end
    end

    if pc.redkills < 1 then
        defredshootcycle = 100000000
    elseif pc.redkills < 5 then
        defredshootcycle = 500
        if redshootcycle > 500 then
            redshootcycle = 500
        end
    elseif pc.redkills < 10 then
        defredshootcycle = 200
        if redshootcycle > 200 then
            redshootcycle = 200
        end
    elseif pc.redkills < 15 then
        defredshootcycle = 100
        if redshootcycle > 100 then
            redshootcycle = 100
        end        
    elseif pc.redkills < 20 then
        defredshootcycle = 50
        if redshootcycle > 50 then
            redshootcycle = 50
        end
    else
        defredshootcycle = 20
        if redshootcycle > 20 then
            redshootcycle = 20
        end
    end
    if e.type == "civilian" or e.type == "guard" then
        if e.side == "red" and pc.redkills >= 5 then
            endConditions.redGen = true
            
            for i,c in pairs(Entities) do
                if c.hp <=0 then
                    table.remove(Entities,i)
                end
                if (c.type =="civilian" or c.type == "guard") and c.side=="red" and c.hp > 0 then
                    endConditions.redGen = false
                end
            end
            if endConditions.redGen then
                table.insert(Achievs, "GENOCIDE")
            end
        elseif pc.bluekills >=5 then
            endConditions.blueGen = true
            for i,c in pairs(Entities) do
                if c.hp <=0 then
                    table.remove(Entities,i)
                end
                if (c.type =="civilian" or c.type == "guard") and c.side=="blue" and c.hp > 0 then
                    endConditions.blueGen = false
                end
            end
            if endConditions.blueGen then
                table.insert(Achievs, "GENOCIDE")
            end
        end
    end
    pc.kills = pc.kills + 1
end

function setupCivilian(x,y, lx, rx, side)
    local e = entity(x,y,0,0,32,32,false, side, Image.civilian, "civilian")
    Collider:addToGroup("alive",e.col)
    e.side = side
    if side == "red" then
        e.color = {255,0,0}
    elseif side == "blue" then
        e.color = {0,0,255}
    end
    e.hp = 100
    e.lx = lx
    e.rx = rx
end

function setupGuard(x,y, lx, rx, side)
    local e = entity(x,y,0,0,32,32,false, side, Image.player, "guard")
    Collider:addToGroup("alive",e.col)
    e.side = side
    if side == "red" then
        e.color = {255,0,0}
    elseif side == "blue" then
        e.color = {0,0,255}
    end
    e.hp = 100
    e.lx = lx
    e.rx = rx
end

function setupGun(x, y, side)
    local e = entity(x,y,0,0,64,64,false, color, Image.gun_base, "gun")
    e.side = side
    if side == "red" then
        e.color = {255,0,0}
    elseif side == "blue" then
        e.color = {0,0,255}
    end
    Collider:addToGroup("alive",e.col)
    Collider:addToGroup("bulletproof",e.col)
    e.hp = 3000
end

function setupHut(x, y, side)
    local e = entity(x,y,0,0,64,64,false, color, Image.house, "hut")
    e.side = side
    if side == "red" then
        e.color = {255,0,0}
    elseif side == "blue" then
        e.color = {0,0,255}
    end
    Collider:addToGroup("alive",e.col)
    Collider:addToGroup("bulletproof",e.col)
    e.hp = 3000
end

function fireBullet(x,y,vx,vy,ttl)
    ttl = ttl or 100
    local p = {}
    p.x = x
    p.y = y
    p.vx = vx
    p.vy = vy
    p.ttl = ttl
    p.type = "bullet"
    p.col = Collider:addRectangle(p.x,p.y,3,3)
    p.col.parent = p
    Collider:addToGroup("bulletproof",p.col)
    table.insert(Projectiles,p)
end

function smokeTrace(x,y,ttl)
    ttl = ttl or 100
    local p = {}
    p.x = x
    p.y = y
    p.vx = 0
    p.vy = -0.01
    p.ttl = ttl
    p.type = "smoke"
    table.insert(Projectiles,p)
end

function sparkle(x,y,ttl)
    ttl = ttl or 100
    local p = {}
    p.x = x
    p.y = y
    p.vx = 0
    p.vy = -0.1
    p.ttl = ttl
    p.type = "sparkle"
    table.insert(Projectiles,p)
end    

function fireBomb(x,y,vx,vy,ttl)
    ttl = ttl or 1000
    local p = {}
    p.x = x
    p.y = y
    p.vx = vx
    p.vy = vy
    p.ttl = ttl
    p.type = "bomb"
    p.col = Collider:addRectangle(p.x,p.y,3,3)
    p.col.parent = p
    table.insert(Projectiles,p)
end


function doShoot(side)
    for i,e in pairs(Entities) do
        if e.side == side then
            if e.type == "gun" then
                if ((ship.x - e.x) * (ship.x - e.x)) + ((ship.y - e.y) * (ship.y - e.y)) < (800 * 800) then
                    local tn = getTan(e.x+(e.sx/2),e.y+(e.sy/2),ship.x, ship.y, 3)
                    fireBullet(e.x+(e.sx/2),e.y+(e.sy/2), tn[1], tn[2],300)
                end
            end
            if e.type == "guard" and ((pc.x - e.x) * (pc.x - e.x)) < (200 * 200) and ((pc.x - e.x) * (pc.x - e.x)) > (32 * 32) and pc.gnd < 100 then
                local lower = math.min(pc.x, e.x)
                local higher = math.max(pc.x, e.x)
                local shoot = true
                for j,c in pairs(Entities) do
                    if c.x > lower and c.x < higher then
                        shoot = false
                        break
                    end
                end
                if shoot then
                    if lower == pc.x and not e.flipx then
                        e.vx = -e.vx
                        e.flipx = true
                    elseif lower == e.x and e.flipx then
                        e.vx = -e.vx
                        e.flipx = false
                    end
                    if e.flipx then
                        fireBullet(e.x-4,e.y+13,e.vx-1,0,100)
                    else
                        fireBullet(e.x+34,e.y+13,e.vx+1,0,100)
                    end
                end
            end
        end
    end
end

function updateProjectiles()
    smokecycle = smokecycle - 1
    for i, p in pairs(Projectiles) do
        p.ttl = p.ttl - 1
        if p.ttl < 0 then
            Collider:remove(p.col)
            table.remove(Projectiles, i)
        else
            p.x = p.x + p.vx
            p.y = p.y + p.vy
            if p.type == "bullet" or p.type == "bomb" then
                p.col:moveTo(p.x+1,p.y+1)
            end
        end
        if smokecycle < 0 and p.type ~= "smoke" and p.type ~= "sparkle" then
            smokeTrace(p.x,p.y,100)
        end
    end        
    if smokecycle < 0 then
        smokecycle = 10
    end
end

function setupEntities()
    for i=0,5 do
        setupCivilian(100+math.random(2500),400,50,2900,"blue")
        setupCivilian(4300+math.random(2500),400,4100,6900,"red")
    end
    for i=0,5 do
        setupGuard(100+math.random(2500),400,50,2900,"blue")
        setupGuard(4300+math.random(2500),400,4100,6900,"red")
    end
    for i=0,2 do
        setupGun(100+math.random(2500),400,"blue")
        setupGun(4300+math.random(2500),400,"red")
    end
    setupHut(200+math.random(1000),400,"blue")
    setupHut(6800-math.random(1000),400,"red")
end

function drawProjectiles()
    for i,p in pairs(Projectiles) do
        if p.type == "bullet" then
            love.graphics.setColor(255,128,0,255)
            love.graphics.rectangle("fill",p.x,p.y,3,3)
        end
        if p.type == "bomb" then
            love.graphics.setColor(255,128,0,255)
            love.graphics.rectangle("fill",p.x,p.y,7,7)
        end
        if p.type == "smoke" then
            love.graphics.setColor(0,0,0,64)
            love.graphics.rectangle("fill",p.x,p.y,5,5)
        end
        if p.type == "sparkle" then
            love.graphics.setColor(255,255,255,64)
            love.graphics.rectangle("fill",p.x,p.y,7,5)
        end
    end
end

function map:setupColliders()
    map.colliders = {Collider:addRectangle(0,550,3000,500),Collider:addRectangle(4000,550,3000,500)}
    for i,c in pairs(map.colliders) do
        c.parent = map
    end
end

function map:draw()
    love.graphics.setColor(0,128,0,255)
    love.graphics.rectangle("fill",0,550,3000,500)
    love.graphics.rectangle("fill",4000,550,3000,500)
    love.graphics.setColor(128+math.random(128),128+math.random(128),0,255)
    love.graphics.rectangle("fill",3000,580,1000,430)
end

local function drawHud()
    --HP
    love.graphics.push()
    if pc.hp > 100 then
        pc.hp = 100
    end
    love.graphics.setColor(64,0,0,128)
    love.graphics.rectangle("fill",5,100,5,400)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill",5,(100+(4*(100-pc.hp))),5,(4*pc.hp))
    --SHIP
    if ship.hp > 400 then
        ship.hp = 400
    end
    love.graphics.setColor(64,64,64,128)
    love.graphics.rectangle("fill",15,100,15,400)
    love.graphics.setColor(230,230,230,255)
    love.graphics.rectangle("fill",15,(100+(400-ship.hp)),15,(ship.hp))

    local killstring = string.format("Kills %d",pc.kills)
    love.graphics.setColor(0,0,0,128)
    love.graphics.print(killstring, 6,6)
    love.graphics.setColor(255,255,0,255)
    love.graphics.print(killstring, 5,5)

    --happiness
    love.graphics.setColor(0,0,64,128)
    love.graphics.rectangle("fill",50,580,300,10)
    love.graphics.setColor(0,0,255,255)
    if pc.bluekills>0 then
        local helper
        if pc.bluekills>15 then
            helper = 15
        else
            helper = pc.bluekills
        end
        love.graphics.rectangle("fill",300,580,50*(helper/15),10)
    else
        if pc.bluekills<-500 then
            endConditions.blueLike = true
            pc.bluekills = -500
        end
        local helper = -250*(pc.bluekills/500)
        love.graphics.rectangle("fill",300-helper,580,helper,10)
    end
    love.graphics.setColor(64,0,0,128)
    love.graphics.rectangle("fill",450,580,300,10)
    love.graphics.setColor(255,0,0,255)
    if pc.redkills>0 then
        local helper
        if pc.redkills>15 then
            helper = 15
        else
            helper = pc.redkills
        end
        love.graphics.rectangle("fill",500-(50*helper/15),580,50*(helper/15),10)
    else
        if pc.redkills<-500 then
            endConditions.redLike = true
            pc.redkills = -500
        end
        local helper = -250*(pc.redkills/500)
        love.graphics.rectangle("fill",500,580,helper,10)
    end
    love.graphics.setColor(0,0,0,64)
    love.graphics.print("AGRESSIVE",368,571)
    love.graphics.print("HAPPY",151,571)
    love.graphics.print("HAPPY",601,571)
    love.graphics.setColor(255,255,0,255)
    love.graphics.rectangle("fill",300,575,2,20)
    love.graphics.rectangle("fill",500,575,2,20)
    love.graphics.print("AGRESSIVE",367,570)
    love.graphics.print("HAPPY",150,570)
    love.graphics.print("HAPPY",600,570)
    love.graphics.pop()

    -- achievements
    local achievx = 700
    local achievy = 0
    for i,a in ipairs(Achievs) do
        love.graphics.setColor(64,64,64,255)
        love.graphics.rectangle("fill",achievx+1,achievy,100,14)
        love.graphics.setColor(255,255,255,255)
        love.graphics.rectangle("fill",achievx,achievy,1,14)
        love.graphics.setColor(0,0,0,255)
        love.graphics.rectangle("fill",achievx,achievy+14,100,1)
        love.graphics.setColor(255,255,255,255)
        love.graphics.print(a,achievx+4,achievy+1)
        achievy = achievy + 18
    end
end

function camera:set()
    love.graphics.push()
    love.graphics.rotate(-(camera.r))
    love.graphics.scale(1 / camera.scx, 1 / camera.scy)
    love.graphics.translate(-camera.x, -camera.y)
end

function camera:unset()
    love.graphics.pop()
end

function camera:move(dx, dy)
    camera.x = camera.x + (dx or 0)
    camera.y = camera.y + (dy or 0)
end

function camera:scale(sx, sy)
    sx = sx or 1
    camera.scx = camera.scx * sx
    camera.scy = camera.scy * (sy or sx)
end

function camera:setPosition(x, y)
    self.x = x or camera.x
    self.y = y or camera.y
end

function camera:centerEntity(e)
    if ship.up then
        camera.y = 0.01*(e.y+200 - camera.scy*300)+0.99*camera.y
    else
        camera.y = 0.01*(e.y - camera.scy*300)+0.99*camera.y
    end
    camera.x = 0.01*(e.x - camera.scx*400)+0.99*camera.x
end

function checkEndstate()
    if not endConditions.redHut and pc.bluekills <= 0 then
        --mission
        Gamestate.switch(gameover)
    elseif not endConditions.blueHut and pc.redkills <= 0 then
        --traitor
        Gamestate.switch(gameover)
    elseif endConditions.redGen and endConditions.blueGen then
        --extermination
        Gamestate.switch(gameover)
    elseif endConditions.blueLike or endConditions.redLike then
        --reelection
        Gamestate.switch(gameover)
    elseif pc.y>1000 or pc.hp <= 0 then
        --death
        Gamestate.switch(gameover)
    elseif pc.x<-1000 or pc.x> 8000 then
        --left
        Gamestate.switch(gameover)
    end
end

function play:enter()
    if love.filesystem.exists("state.lua") then
        local state = love.filesystem.load("state.lua")
        state()
        Gamestate.switch(gameover)
    end

    love.graphics.setBackgroundColor(0,128,255)
    Collider:clear()
    --add colliders
    for i,e in pairs(Entities) do
        e.col = Collider:addRectangle(e.x,e.y, e.sx, e.sy)
        e.col.parent = e
    end
    map:setupColliders()
    --add ship
    ship = entity(200,400,0,0,128,64,false,{255,255,255,255},Image.ship_gear,"ship")
    ship.state = "gear"
    ship.hp = 400
    ship.side = "white"
    ship.enterable = false
    
    setupEntities()
end

function play:update()
    lastshot = lastshot + 1
    for i, e in pairs(Entities) do
        e.vy = e.vy + gravity
        e.x = e.x + e.vx
        e.y = e.y + e.vy
        e.col:moveTo(e.x+(e.sx/2),e.y+(e.sy/2))
        e.gnd = e.gnd + 1
        if e.vx > 0 then
            e.flipx = false
        elseif e.vx < 0 then
            e.flipx = true
        end
        if e.type == "civilian" or e.type == "guard" then
            if e.vx == 0 then
                e.vx = math.random() - 0.5
            else
                if e.x > e.rx or e.x < e.lx then
                    e.vx = -e.vx
                end
            end
        end
                
        if e.type == "civilian" or e.type == "gun" or e.type == "guard" or e.type=="hut" then
            if e.hp <= 0 then
                removeLiving(e)
                table.remove(Entities,i)
            end
        end
    end
    if ship.up then
        ship.y = ship.y - ship.vy
        ship.vy = ship.vy - gravity
        ship.y = 0.01*100+0.99*ship.y
    else
        ship.vx = 0.99*ship.vx
    end
    if trackedEntity == ship then
        if ship.flipx then
            pc.flipx = true
            pc.x = ship.x + 40
            pc.y = ship.y + 20
            pc.vx = 0
            pc.vy = 0
        else
            pc.flipx = false
            pc.x = ship.x + 58
            pc.y = ship.y + 20
            pc.vx = 0
            pc.vy = 0
        end
    end
    if ship.hp <= 0 then
        removeLiving(ship)
        ship.up = false
        ship.img = Image.ship_dead
        ship.enterable = false
        trackedEntity = pc
    end
    updateProjectiles()
    
    if pc.gnd < 20 then
        pc.vx = 0.5 * pc.vx
        if pc.vx*pc.vx < controls.vx*controls.vx and trackedEntity == pc then
            pc.vx = controls.vx
        end
    end
    if trackedEntity == ship then
        if ship.vx*ship.vx < controls.vx*controls.vx then
            ship.vx = controls.vx
        else
            ship.vx = 0.95 * ship.vx
        end
    end
    --
    if colup <0 then
        Collider:update()
        colup = 15
    end
    colup = colup -1
    camera:centerEntity(trackedEntity)
    if redshootcycle < 0 then
        redshootcycle = defredshootcycle
        doShoot("red")
    end;
    redshootcycle = redshootcycle -1
    if blueshootcycle < 0 then
        blueshootcycle = defblueshootcycle
        doShoot("blue")
    end;
    blueshootcycle = blueshootcycle -1
    checkEndstate()
end

function play:draw()
    camera.set()
    map:draw()
    for i,e in pairs(Entities) do
        if e.type == "gun" then
            local tn = getTan(e.x+(e.sx/2), e.y+(e.sy/2), ship.x+(ship.sx/2), ship.y+(ship.sy/2),32)
            love.graphics.setColor(0,0,0,255)
            love.graphics.line(e.x+(e.sx/2), e.y+(e.sy/2),e.x+(e.sx/2) + tn[1], e.y+(e.sy/2) + tn[2])
        end
        love.graphics.setColor(e.color)
        if e.flipx then
            love.graphics.draw(e.img, e.x+e.sx, e.y,0,-1,1)
        else
            love.graphics.draw(e.img, e.x, e.y)
        end
    end
    drawProjectiles()
    camera.unset()
    drawHud()
end

function play:keypressed(key, code)
    if trackedEntity == pc then
    --controlling player
        if key =='left' then
            controls.vx = -0.5
        elseif key == 'right' then
            controls.vx = 0.5
        elseif key == 'up' and pc.gnd < 100 then
            pc.vy = - 1.5
        elseif key == ' ' then
            if true or lastshot > 50 then
                if pc.flipx then
                    fireBullet(pc.x-4,pc.y+13,pc.vx-1,0,100)
                else
                    fireBullet(pc.x+34,pc.y+13,pc.vx+1,0,100)
                end
                lastshot = 0
            end
        elseif key == 'e' then
            if ship.enterable then
                trackedEntity = ship
            end
        elseif key == 'd' then
            if pc.interactions > 0 then
                sparkle(pc.x+(pc.sx/2),pc.y,100)
                if pc.hp < 100 then
                    pc.hp = pc.hp + 5 - (0.1 * pc.redint * pc.redkills) - (0.1 * pc.blueint * pc.bluekills)
                elseif ship.hp < 400 then
                    ship.hp = ship.hp + 5 - (0.1 * pc.redint * pc.redkills) - (0.1 * pc.blueint * pc.bluekills)
                else
                    pc.redkills = pc.redkills - (0.25 * pc.redint)
                    pc.bluekills = pc.bluekills - (0.25 * pc.blueint)
                end
            end
        end
    else
    --controlling ship
        if key =='left' then
            controls.vx = -3
        elseif key == 'right' then
            controls.vx = 3
        elseif key == 'up' and not ship.up then
            ship.up = true
            camera.x = camera.x - 400
            camera.y = camera.y - 300
            camera:scale(2,2)
        elseif key == 'down' and ship.up then
            ship.up = false
            camera.x = camera.x + 200
            camera.y = camera.y + 150
            camera:scale(0.5,0.5)
        elseif key == ' ' then
            if lastshot > 150 then
                if ship.state == "gear" then
                    ship.state = "gun"
                    ship.img = Image.ship_gun
                end
                if ship.flipx then
                    fireBomb(ship.x+5,ship.y+70,-1,1,400)
                else
                    fireBomb(ship.x+105,ship.y+70,1,1,400)
                end
                lastshot = 0
            end
        elseif key == 'e' then
                trackedEntity = pc
                ship.state = "gear"
                ship.img = Image.ship_gear
                if ship.up then
                    ship.up = false
                    camera:scale(0.5,0.5)
                end
        end        
    end
end

function play:keyreleased(key, code)
    if key == 'left' then
        controls.vx = 0
    elseif key == 'right' then
        controls.vx = 0
    end
end

function menu:draw()
    love.graphics.draw(Image.logo,150,10)
    love.graphics.setColor(0,0,255,255)
    love.graphics.rectangle("fill",615,110,55,30)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill",480,140,55,30)
    love.graphics.setColor(255,255,255,255)
    love.graphics.print("You are a mercenary, just employed by the blue boss.", 70, 110,0,2,2)
    love.graphics.print("He asks you to destroy the red boss's Hut.", 140, 140,0,2,2)
    love.graphics.print("There are several solutions to this situation, you only get one.", 10, 170,0,2,2)
    love.graphics.setColor(255,255,0,255)
    love.graphics.print("Think before you shoot!", 260, 200,0,2,2)
    love.graphics.setColor(255,255,255,255)

    love.graphics.translate(0,50)
    love.graphics.setBackgroundColor(128,128,128,255)
    love.graphics.draw(Image.spacebar,110,400)
    love.graphics.print("FIRE / Start game", 260, 500,0,2,2)
    love.graphics.draw(Image.key_e,30,200)
    love.graphics.draw(Image.key_d,80,270)
    love.graphics.print("Enter/Exit ship", 130, 240,0,2,2)
    love.graphics.print("Interact with civilians", 190, 310,0,2,2)
    love.graphics.print("to get HP etc.", 220, 340,0,2,2)
    
    local keyx = 500
    local keyy = 270
    love.graphics.draw(Image.key_up,keyx+95,keyy-70)
    love.graphics.draw(Image.key_left,keyx,keyy)
    love.graphics.draw(Image.key_down,keyx+100,keyy)
    love.graphics.draw(Image.key_right,keyx+200,keyy)
    love.graphics.print("MOVE", keyx+110, keyy+100,0,2,2)

end

function menu:keyreleased(key, code)
    if key == ' ' then
        Gamestate.switch(play)
    elseif key == 'q' then
        Gamestate.switch(gameover)
    end
end

function on_collision(dt, shape_a, shape_b, mtv_x, mtv_y)
    local t = 'other'
    if shape_a.parent == map then
        e = shape_b.parent
        t = 'ground'
    elseif shape_b.parent == map then
        e = shape_a.parent
        t = 'ground'
    elseif shape_a.parent.type == "bullet" then
        t = 'bullet'
        e = shape_b.parent
        b = shape_a.parent
    elseif shape_b.parent.type == "bullet" then
        t = 'bullet'
        e = shape_a.parent
        b = shape_b.parent
    elseif shape_a.parent.type == "bomb" then
        t = 'bomb'
        e = shape_b.parent
        b = shape_a.parent
    elseif shape_b.parent.type == "bomb" then
        t = 'bomb'
        e = shape_a.parent
        b = shape_b.parent
    elseif shape_a.parent.type == "ship" and shape_b.parent.type == "player" then
        ship.enterable = true
    elseif shape_b.parent.type == "ship" and shape_a.parent.type == "player" then
        ship.enterable = true
    elseif shape_a.parent.type == "civilian" and shape_b.parent.type == "player" then
        pc.interactions = pc.interactions + 1
        if shape_a.parent.side == "red" then
            pc.redint = pc.redint + 1
        else
            pc.blueint = pc.blueint + 1
        end
    elseif shape_b.parent.type == "civilian" and shape_a.parent.type == "player" then
        pc.interactions = pc.interactions + 1
        if shape_b.parent.side == "red" then
            pc.redint = pc.redint + 1
        else
            pc.blueint = pc.blueint + 1
        end
    end
    
    if t == 'ground' then
        if e.vy > 3 then
            e.hp = 0.75 * e.hp
        end
        if e.hp then
            e.vy = -0.5 + 0.1 * e.vy
            e.gnd = 0
        else
            e.vy=0
            e.y=e.y-1
        end
    elseif t == 'bullet' then
        if e.hp then
            --an entity with health that we can decrement, yay!
            e.hp = e.hp-20
            b.ttl = 0
        end
    elseif t == 'bomb' then
        if e.hp then
            e.hp = e.hp - 1000
            b.ttl = 0
        end
        fireBullet(b.x-2,b.y,-0.2,0,200)
        fireBullet(b.x+2,b.y,0.2,0,200)
    end
    --love.graphics.setBackgroundColor(255,0,0,255)
end

function on_stopcollision(dt, shape_a, shape_b)
    --love.graphics.setBackgroundColor(64,128,255,255)
    if shape_a.parent == map or shape_b.parent == map then
    --
    elseif shape_a.parent.type == "ship" and shape_b.parent.type == "player" then
        ship.enterable = false
    elseif shape_b.parent.type == "ship" and shape_a.parent.type == "player" then
        ship.enterable = false
    elseif shape_a.parent.type == "civilian" and shape_b.parent.type == "player" then
        pc.redint = 0
        pc.blueint = 0
        pc.interactions = 0
    elseif shape_b.parent.type == "civilian" and shape_a.parent.type == "player" then
        pc.redint = 0
        pc.blueint = 0
        pc.interactions = 0
    end
end

function gameover:draw()
    love.graphics.setBackgroundColor(128,128,128,255)
    love.graphics.setColor(255,255,0,255)
    if endConditions.first then
        love.graphics.print("Game Over",220,100,0,5,5)
    else
        love.graphics.print("You played already!",100,100,0,5,5)
    end
    
    love.graphics.setColor(255,255,255,255)
    if not endConditions.redHut and pc.bluekills <= 0 then
        --mission
        love.graphics.print("You killed the red boss.",40,300,0,5,5)
        love.graphics.print("The default ending.",100,400,0,5,5)
    elseif not endConditions.blueHut and pc.redkills <= 0 then
        --traitor
        love.graphics.print("You killed the blue boss.",30,300,0,5,5)
        love.graphics.print("You traitor!",220,400,0,5,5)
    elseif endConditions.redGen and endConditions.blueGen then
        --extermination
        love.graphics.print("You killed everyone!",70,300,0,5,5)
        love.graphics.print("Proud of yourself?",100,400,0,5,5)
    elseif endConditions.blueLike or endConditions.redLike then
        --reelection
        love.graphics.print("Everyone likes you!",90,200,0,5,5)
        love.graphics.print("You're the new boss!",70,300,0,5,5)
        love.graphics.print("There's no need to fight.",30,400,0,5,5)
    elseif pc.y>1000 or pc.hp <= 0 then
        --death
        love.graphics.print("You have died!",170,300,0,5,5)
    elseif pc.x<-1000 or pc.x> 8000 then
        --left
        love.graphics.print("You left",270,300,0,5,5)
        if pc.kills == 0 then
            love.graphics.print("instead of killing.",160,400,0,5,5)
        else
            love.graphics.print("the battlefield",170,400,0,5,5)
        end
    else
        love.graphics.print("How did you get here?",60,300,0,5,5)
        love.graphics.print("You cheater!",200,400,0,5,5)        
    end
end

function gameover:update()
    --
end

function gameover:enter()
    Entities = {}
    local output = string.format([[
    endConditions.blueHut = %s
    endConditions.redHut = %s
    endConditions.blueGen = %s
    endConditions.redGen = %s
    endConditions.blueLike = %s
    endConditions.redLike = %s
    endConditions.first = false
    pc.hp = %d
    pc.x = %d
    ]],tostring(endConditions.blueHut),tostring(endConditions.redHut),tostring(endConditions.blueGen),tostring(endConditions.redGen),tostring(endConditions.blueLike),
    tostring(endConditions.redLike),pc.hp,pc.x*2)
 
    love.filesystem.write("state.lua", output)
    -- do saving here
end

function love.load()
    Collider = HC(100,on_collision, on_stopcollision)
    
    Gamestate.registerEvents()
    Gamestate.switch(menu)
end
