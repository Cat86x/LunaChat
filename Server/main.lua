local socket = require("socket")

-- Create a TCP server socket and bind it to localhost on port 8080
local server = assert(socket.bind("localhost", 8080))
local ip, port = server:getsockname()

print("Server listening on " .. ip .. ":" .. port)

-- Global array for usernames and counter
local usernames = {}
local counter = 1

-- Function to handle client communication
function handle_client(client)
    -- Receive username from the client and insert it into the array
    local username = client:receive()
    table.insert(usernames, username)
    print(username .. " has connected.")

    while true do
        -- Receive a message from the client
        local message, err = client:receive()

        -- If there's an error or the client sends an empty message, exit the loop
        if not message or message == "" then
            print(username .. " has disconnected.")
            client:send("Goodbye!\n")
            client:close()

            -- Remove the username from the array
            for i, stored_username in ipairs(usernames) do
                if stored_username == username then
                    table.remove(usernames, i)
                    break
                end
            end
            break
        end

        -- Check for the exit signal
        if message == "SIG_EXIT" then
            print(username .. " sent exit signal.")
            client:send("Goodbye!\n")
            client:close()

            -- Remove the username from the array
            for i, stored_username in ipairs(usernames) do
                if stored_username == username then
                    table.remove(usernames, i)
                    break
                end
            end
            break
        end

        -- Print the received message
        print(message)

        -- Send a response back to the client
        client:send("Message received: " .. message .. "\n")
    end
end

-- Keep listening for connections
while true do
    -- Wait for a client to connect
    local client = server:accept()

    -- Handle the client in a separate function
    handle_client(client)
end
