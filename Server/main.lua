local socket = require("socket")

-- Create a TCP server socket and bind it to localhost on port 8080
local server = assert(socket.bind("localhost", 8080))
local ip, port = server:getsockname()

print("Server listening on " .. ip .. ":" .. port)

-- Keep listening for connections
while true do
    -- Wait for a client to connect
    local client = server:accept()

    -- Receive a message from the client
    local message = client:receive()
    print("Client says: " .. message)

    -- Send a response to the client
    client:send("Message received: " .. message .. "\n")

    -- Close the client connection
    client:close()
end
