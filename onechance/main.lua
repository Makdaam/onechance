Gamestate = require "hump.gamestate"
HC = require "HardonCollider"

local gameover = {}
local menu = {}
local play = {}
local highscore = {}
local dbg = ""
local gravity = 0.01
local pc = {}
local Collider = {}
local controls = {}
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

camera = {}
camera.x = 0
camera.y = 0
camera.scx = 0.75
camera.scy = 0.75
camera.r = 0

map = {}
map.colliders = {}


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

function updateProjectiles()
    for i, p in pairs(Projectiles) do
        p.ttl = p.ttl - 1
        if p.ttl < 0 then
            Collider:remove(p.col)
            table.remove(Projectiles, i)
        else
            p.x = p.x + p.vx
            p.y = p.y + p.vy
            p.col:moveTo(p.x+1,p.y+1)
        end
    end
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
    love.graphics.setColor(64,0,0,128)
    love.graphics.rectangle("fill",5,100,5,400)
    love.graphics.setColor(255,0,0,128)
    love.graphics.rectangle("fill",5,(100+(4*(100-pc.hp))),5,(4*pc.hp))
    love.graphics.setColor(0,0,0,128)
    --SHIP
    love.graphics.setColor(64,64,64,128)
    love.graphics.rectangle("fill",15,100,15,400)
    love.graphics.setColor(230,230,230,128)
    love.graphics.rectangle("fill",15,(100+(400-ship.hp)),15,(ship.hp))
    love.graphics.setColor(0,0,0,128)

    local killstring = string.format("Kills %d",pc.kills)
    love.graphics.print(killstring, 6,6)
    love.graphics.setColor(255,255,0,255)
    love.graphics.print(killstring, 5,5)
    love.graphics.pop()
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
function play:enter()
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
    ship.enterable = false
end

function play:update()
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
    if pc.y>1000 or pc.hp <= 0 then
        Gamestate.switch(gameover)
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
    Collider:update()
    camera:centerEntity(trackedEntity)
end

function play:draw()
    camera.set()
    map:draw()
    for i,e in pairs(Entities) do
        love.graphics.setColor(e.color)
        if e.flipx then
            love.graphics.draw(e.img, e.x+e.sx, e.y,0,-1,1)
        else
            love.graphics.draw(e.img, e.x, e.y)
        end
    end
    love.graphics.print(pc.gnd, 400, 300)
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
            if pc.flipx then
                fireBullet(pc.x-4,pc.y+13,pc.vx-1,0,100)
            else
                fireBullet(pc.x+34,pc.y+13,pc.vx+1,0,100)
            end
        elseif key == 'e' then
            if ship.enterable then
                trackedEntity = ship
            end
        end
    else
    --controlling ship
        if key =='left' then
            controls.vx = -0.75
        elseif key == 'right' then
            controls.vx = 0.75
        elseif key == 'up' and not ship.up then
            ship.up = true
            camera:scale(2,2)
            camera.x = camera.x - 100
            camera.y = camera.y - 200
        elseif key == 'down' and ship.up then
            ship.up = false
            camera:scale(0.5,0.5)
        elseif key == ' ' then
            if ship.state == "gear" then
                ship.state = "gun"
                ship.img = Image.ship_gun
            end
            if ship.flipx then
                fireBomb(ship.x+5,ship.y+65,ship.vx-1,1,500)
            else
                fireBomb(ship.x+105,ship.y+65,ship.vx+1,1,500)
            end
        elseif key == 'e' then
                trackedEntity = pc
                ship.state = "gear"
                ship.img = Image.ship_gear
                ship.up = false
                camera:scale(0.5,0.5)
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
    love.graphics.print("Press space to start", 400, 300)
    love.graphics.print(dbg, 400, 200)
end

function menu:keyreleased(key, code)
    dbg = key
    if key == ' ' then
        Gamestate.switch(play)
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
            e.hp = e.hp-5
            b.ttl = 0
        end
    elseif t == 'bomb' then
        if e.hp then
            e.hp = e.hp - 10
            b.ttl = 0
        end
        fireBullet(b.x-2,b.y,-0.1,0,50)
        fireBullet(b.x-2,b.y-2,-0.1,-0.1,50)
        fireBullet(b.x,b.y-2,0,-0.1,50)
        fireBullet(b.x+2,b.y-2,0.1,-0.1,50)
        fireBullet(b.x+2,b.y,0.1,0,50)
        fireBullet(b.x+2,b.y+2,0.1,0.1,50)
        fireBullet(b.x,b.y+2,0,0.1,50)
        fireBullet(b.x-2,b.y+2,-0.1,0.1,50)
    end
    love.graphics.setBackgroundColor(255,0,0,255)
end

function on_stopcollision(dt, shape_a, shape_b)
    love.graphics.setBackgroundColor(64,128,255,255)
    if shape_a.parent == map or shape_b.parent == map then
    --
    elseif shape_a.parent.type == "ship" and shape_b.parent.type == "player" then
        ship.enterable = false
    elseif shape_b.parent.type == "ship" and shape_a.parent.type == "player" then
        ship.enterable = false
    end
end

function gameover:draw()
    love.graphics.print("Game Over",400,300)
end

function gameover:update()
    --
end

function gameover:enter()
    Entities = {}
    -- do saving here
end

function love.load()
    Collider = HC(100,on_collision, on_stopcollision)
    
    Gamestate.registerEvents()
    Gamestate.switch(menu)
end
