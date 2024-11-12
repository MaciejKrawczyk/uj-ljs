json = require "dkjson"

local window_width, window_height = 400, 600
local grid_width, grid_height = 10, 20
local cell_size = 30
local grid = {}
local current_piece, next_piece
local pieces = {
    {{1, 1, 1, 1}}, 
    {{1, 1, 0}, {0, 1, 1}},
    {{0, 1, 1}, {1, 1, 0}},
    {{1, 1, 1}, {0, 1, 0}},
    {{1, 1}, {1, 1}}, 
    {{1, 1, 1}, {1, 0, 0}}, 
    {{1, 1, 1}, {0, 0, 1}}
}
local colors = {
    {0, 1, 1}, {1, 0, 0}, {0, 1, 0},
    {1, 0, 1}, {1, 1, 0}, {1, 0.5, 0},
    {0, 0, 1}
}
local piece_x, piece_y
local fall_time = 0.5
local timer = 0

-- Variables for line clear animation
local clearing_rows = {}
local clearing_timer = 0
local clearing_duration = 0.3

-- Save the game state to a file
function save_game()
    local game_state = {
        grid = grid,
        piece_x = piece_x,
        piece_y = piece_y,
        current_piece = current_piece,
        next_piece = next_piece,
        current_color = current_color,
    }
    local encoded = json.encode(game_state)
    love.filesystem.write("tetris_save.json", encoded)
    print("Game saved!")
end

-- Load the game state from a file
function load_game()
    if love.filesystem.getInfo("tetris_save.json") then
        local contents, size = love.filesystem.read("tetris_save.json")
        local game_state = json.decode(contents)
        
        -- Restore game state
        grid = game_state.grid
        piece_x = game_state.piece_x
        piece_y = game_state.piece_y
        current_piece = game_state.current_piece
        next_piece = game_state.next_piece
        current_color = game_state.current_color
        print("Game loaded!")
    else
        print("No save file found.")
    end
end

function love.load()
    love.window.setMode(window_width, window_height)
    reset_grid()
    spawn_piece()

    -- Load sound effects
    hit_sound = love.audio.newSource("hit.wav", "static")
    clear_sound = love.audio.newSource("clear.wav", "static")
end

function reset_grid()
    for y = 1, grid_height do
        grid[y] = {}
        for x = 1, grid_width do
            grid[y][x] = 0
        end
    end
end

function spawn_piece()
    local idx = love.math.random(#pieces)
    current_piece = pieces[idx]
    next_piece = pieces[love.math.random(#pieces)]
    current_color = colors[idx]
    piece_x = math.floor(grid_width / 2) - math.floor(#current_piece[1] / 2)
    piece_y = 1
end

function can_place_piece(px, py, piece)
    for y = 1, #piece do
        for x = 1, #piece[y] do
            if piece[y][x] ~= 0 then
                local nx, ny = px + x, py + y
                if nx < 1 or nx > grid_width or ny > grid_height or grid[ny][nx] ~= 0 then
                    return false
                end
            end
        end
    end
    return true
end

function lock_piece()
    -- Play the hit sound effect
    love.audio.play(hit_sound)
    
    for y = 1, #current_piece do
        for x = 1, #current_piece[y] do
            if current_piece[y][x] ~= 0 then
                grid[piece_y + y][piece_x + x] = current_color
            end
        end
    end
    check_for_clearing_rows()
    spawn_piece()
    
    if not can_place_piece(piece_x, piece_y, current_piece) then
        reset_grid() -- Game over
    end
end

function check_for_clearing_rows()
    clearing_rows = {}
    for y = grid_height, 1, -1 do
        local full = true
        for x = 1, grid_width do
            if grid[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            -- Mark row for clearing and start clearing animation
            table.insert(clearing_rows, y)
        end
    end
    if #clearing_rows > 0 then
        -- Start the clear sound and timer
        love.audio.play(clear_sound)
        clearing_timer = clearing_duration
    end
end

function clear_lines()
    -- Shift rows down once clearing animation completes
    for _, y in ipairs(clearing_rows) do
        for yy = y, 2, -1 do
            grid[yy] = grid[yy - 1]
        end
        grid[1] = {}
        for x = 1, grid_width do
            grid[1][x] = 0
        end
    end
    clearing_rows = {} -- Reset cleared rows
end

function rotate_piece()
    local rotated = {}
    for x = 1, #current_piece[1] do
        rotated[x] = {}
        for y = 1, #current_piece do
            rotated[x][y] = current_piece[#current_piece - y + 1][x]
        end
    end
    if can_place_piece(piece_x, piece_y, rotated) then
        current_piece = rotated
    end
end

function love.update(dt)
    if clearing_timer > 0 then
        -- Handle clearing animation timing
        clearing_timer = clearing_timer - dt
        if clearing_timer <= 0 then
            clear_lines()
        end
    else
        -- Normal game update
        timer = timer + dt
        if timer >= fall_time then
            timer = 0
            if can_place_piece(piece_x, piece_y + 1, current_piece) then
                piece_y = piece_y + 1
            else
                lock_piece()
            end
        end
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    -- Define the size of the touch zones (you may adjust these based on your layout)
    local touch_zone_size = 100

    -- Left side touch zone (move left)
    if x < touch_zone_size and y < window_height then
        if can_place_piece(piece_x - 1, piece_y, current_piece) then
            piece_x = piece_x - 1
        end
    -- Right side touch zone (move right)
    elseif x > window_width - touch_zone_size and y < window_height then
        if can_place_piece(piece_x + 1, piece_y, current_piece) then
            piece_x = piece_x + 1
        end
    -- Bottom-left corner (move down)
    elseif x < touch_zone_size and y > window_height - touch_zone_size then
        if can_place_piece(piece_x, piece_y + 1, current_piece) then
            piece_y = piece_y + 1
        end
    -- Bottom-right corner (rotate piece)
    elseif x > window_width - touch_zone_size and y > window_height - touch_zone_size then
        rotate_piece()
    -- "Save" button area (middle-left bottom section)
    elseif x < window_width / 2 and y > window_height - touch_zone_size * 2 then
        save_game()
    -- "Load" button area (middle-right bottom section)
    elseif x > window_width / 2 and y > window_height - touch_zone_size * 2 then
        load_game()
    end
end

function love.keypressed(key)
    if key == "left" and can_place_piece(piece_x - 1, piece_y, current_piece) then
        piece_x = piece_x - 1
    elseif key == "right" and can_place_piece(piece_x + 1, piece_y, current_piece) then
        piece_x = piece_x + 1
    elseif key == "down" and can_place_piece(piece_x, piece_y + 1, current_piece) then
        piece_y = piece_y + 1
    elseif key == "up" then
        rotate_piece()
    elseif key == "space" then
        while can_place_piece(piece_x, piece_y + 1, current_piece) do
            piece_y = piece_y + 1
        end
        lock_piece()
    elseif key == "s" then
        save_game()
    elseif key == "l" then
        load_game()
    end
end

function love.draw()
    -- Draw grid with special animation for clearing rows
    for y = 1, grid_height do
        for x = 1, grid_width do
            if grid[y][x] ~= 0 then
                if not is_row_clearing(y) then
                    love.graphics.setColor(grid[y][x])
                else
                    love.graphics.setColor(1, 1, 1, math.abs(math.sin(love.timer.getTime() * 10))) -- Flashing effect
                end
                love.graphics.rectangle("fill", (x - 1) * cell_size, (y - 1) * cell_size, cell_size, cell_size)
            end
        end
    end

    -- Draw current piece
    love.graphics.setColor(current_color)
    for y = 1, #current_piece do
        for x = 1, #current_piece[y] do
            if current_piece[y][x] ~= 0 then
                love.graphics.rectangle("fill", (piece_x + x - 1) * cell_size, (piece_y + y - 1) * cell_size, cell_size, cell_size)
            end
        end
    end
end

function is_row_clearing(row)
    for _, y in ipairs(clearing_rows) do
        if y == row then
            return true
        end
    end
    return false
end
