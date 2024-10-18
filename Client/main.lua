local socket = require("socket")

-- Create a TCP client socket
local client = socket.tcp()

-- Connect to the server
client:connect("localhost", 8080)

-- Send a message to the server
client:send("Hello from the client!\n")

-- Receive a response from the server
local response = client:receive()
print("Server replied: " .. response)

-- Close the connection
client:close()
