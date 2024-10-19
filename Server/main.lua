local socket = require("socket")

-- ANSI color codes
local colors = {
    "\27[31m", -- Red
    "\27[32m", -- Green
    "\27[33m", -- Yellow
    "\27[34m", -- Blue
    "\27[35m", -- Magenta
    "\27[36m", -- Cyan
    "\27[37m", -- White
}
local RESET = "\27[0m"

-- Start a TCP server and ask for IP and port
function start()
    print("Empty IP/port will set it to localhost:8080\n")
    print("Please set IP: ")
    local ip = io.read()
    if ip == "" then
        ip = "localhost"
    end

    print("Please set port: ")
    local port = io.read()
    if port == "" then
        port = "8080"
    end

    local server = assert(socket.bind(ip, port))
    print("Server listening on " .. ip .. ":" .. port)
    return server
end

-- Start the server and store the server socket
local server = start()

-- Arrays for storing connected clients
local clients = {}
local usernames = {}
local client_colors = {} -- Array to store colors assigned to clients

-- Function to broadcast a message to all clients except the sender
local function broadcast(sender, message)
    for i, client in ipairs(clients) do
        if client ~= sender then
            client:send(message .. "\n")
        end
    end
end

-- Function to handle messages from a client
local function handle_client_message(client)
    local message, err = client:receive()

    if not message then
        -- Error means the client disconnected
        for i, stored_client in ipairs(clients) do
            if stored_client == client then
                local username = usernames[i]
                local user_color = client_colors[i]
                print(username .. " has disconnected.")
                table.remove(clients, i)
                table.remove(usernames, i)
                table.remove(client_colors, i)
                client:close()
                -- Notify other clients
                broadcast(nil, user_color .. username .. " has left the chat." .. RESET)
                break
            end
        end
    else
        -- Broadcast message to all other clients
        local username = ""
        local user_color = ""
        for i, stored_client in ipairs(clients) do
            if stored_client == client then
                username = usernames[i]
                user_color = client_colors[i]
                break
            end
        end
        local full_message = user_color .. username .. ": " .. message .. RESET
        print(full_message) -- Print the message on the server console

        -- Broadcast to all clients except the sender
        broadcast(client, full_message)
    end
end

-- Main loop to accept and handle multiple clients using select
while true do
    -- Add server socket to the list of readable sockets
    local readable = {server}

    -- Add all connected clients to the readable list
    for _, client in ipairs(clients) do
        table.insert(readable, client)
    end

    -- Wait for any socket to become readable
    local ready = socket.select(readable, nil)

    -- Handle all ready sockets
    for _, sock in ipairs(ready) do
        if sock == server then
            -- New client is trying to connect
            local client = server:accept()
            client:settimeout(nil)  -- Set to blocking mode to wait for the username

            -- Try to receive the username
            local username, err = client:receive()

            -- If no username is received or there's an error, close the connection
            if not username or username == "" then
                print("Failed to receive username or username is empty.")
                client:send("Invalid username. Disconnecting...\n")
                client:close()
            else
                -- Switch back to non-blocking mode after receiving the username
                client:settimeout(0)

                -- Assign a unique color to the client
                local color_index = (#client_colors % #colors) + 1
                local user_color = colors[color_index]

                -- Store the valid username, client, and color
                table.insert(clients, client)
                table.insert(usernames, username)
                table.insert(client_colors, user_color)
                print(username .. " has connected.")

                -- Notify other clients
                broadcast(client, user_color .. username .. " has joined the chat." .. RESET)
            end
        else
            -- Existing client sent a message
            handle_client_message(sock)
        end
    end
end
