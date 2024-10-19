local socket = require("socket")

-- Start a TCP server and ask for IP and port
function start()
    print("Empty IP/port will set it to localhost:8080")
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
                print(usernames[i] .. " has disconnected.")
                table.remove(clients, i)
                table.remove(usernames, i)
                client:close()
                break
            end
        end
    else
        -- Broadcast message to all other clients
        local username = ""
        for i, stored_client in ipairs(clients) do
            if stored_client == client then
                username = usernames[i]
                break
            end
        end
        local full_message = username .. ": " .. message
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

                -- Store the valid username and client
                table.insert(clients, client)
                table.insert(usernames, username)
                print(username .. " has connected.")

                -- Notify other clients
                broadcast(client, username .. " has joined the chat.")
            end
        else
            -- Existing client sent a message
            handle_client_message(sock)
        end
    end
end
