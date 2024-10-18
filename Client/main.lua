local socket = require("socket")

-- Create a TCP client socket
local client = socket.tcp()

-- Message to instruct user
print("Send an empty message to exit")

-- Function to connect to the server
function connect()
    -- Enter server IP
    io.write("Please enter server IP: ")
    local ip = io.read()

    if ip == "" then -- checking if ip is empty else default it to localhost
        ip = "localhost"
        print("No ip given defaulting to localhost")
    end
    io.write("Please enter port: ")
    local port = io.read()

    if port == "" then -- checking if port is empty else default it to 8080
        port = "8080"
        print("No port given defaulting to 8080")
    end

    -- Connect to the server with error handling
    local success, err = client:connect(ip, port)
    if not success then
        print("Failed to connect: " .. err)
        return false
    end

    -- Send the username to the server
    io.write("Please enter username: ")
    username = io.read()
    client:send(username .. "\n")
    io.write("\n", "\n", "\n")

    return true
end

-- Function to send and receive messages
function send_and_receive()
    while true do
        -- Read user input
        local message = io.read()

        -- Send message to the server
        client:send(username .. ": " .. message .. "\n")

        -- Check if the message is empty (to exit)
        if message == "" then
            print("Exiting chat...")
            client:send("SIG_EXIT\n")
            break
        end

        -- Receive response from the server
        local response, err = client:receive()
        if not response then
            print("Error receiving from server: " .. (err or "unknown error"))
            break
        end

        if response == message then

        else
            print(response)
        end

        print("Message sent")
    end
end

-- Function to close the connection
function close()
    client:close()
    print("Connection closed")
end

-- Main function
function main()
    if connect() then
        send_and_receive()
        close()
    else
        print("Failed to connect to the server.")
    end
end

main()
