local socket = require("socket")
local uv = require("luv") -- Use luv for asynchronous I/O

-- Message to instruct user
print("Send an empty message to exit")

-- Variables to store client and username
local client
local username

-- Function to connect to the server
function connect()
    io.write("Please enter server IP: ")
    local ip = io.read()

    if ip == "" then
        ip = "localhost"
        print("No IP given, defaulting to localhost")
    end
    io.write("Please enter port: ")
    local port = io.read()

    if port == "" then
        port = "8080"
        print("No port given, defaulting to 8080")
    end

    -- Create a TCP client socket
    client = assert(socket.tcp())

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

    return true
end

-- Function to send and receive messages concurrently
function send_and_receive()
    client:settimeout(0) -- Set the client socket to non-blocking mode

    -- Use uv_tty to handle non-blocking stdin
    local stdin = uv.new_tty(0, false)
    uv.read_start(stdin, function(err, data)
        if err then
            print("Error reading from stdin: " .. err)
            return
        end
        if data then
            data = data:gsub("\r?\n", "") -- Remove newline characters
            -- Send the message to the server
            client:send(data .. "\n")

            -- Exit the chat if the message is empty
            if data == "" then
                print("Exiting chat...")
                client:send("SIG_EXIT\n")
                uv.stop() -- Stop the event loop
            end
        end
    end)

    -- Get the file descriptor of the client socket
    local sock_fd = client:getfd()

    -- Create a poll handle for the client socket
    local poll = uv.new_poll(sock_fd)
    poll:start("r", function(err, events)
        if err then
            print("Error polling socket: " .. err)
            uv.stop()
            return
        end

        -- Receive message from the server
        local response, err = client:receive("*l")
        if response then
            -- Only display the message if it is not from the current user
            if not response:find(username .. ": ") then
                print("\n" .. response)
                io.flush()
            end
        elseif err ~= "timeout" then
            print("Connection error: " .. err)
            uv.stop()
        end
    end)

    -- Start the event loop
    uv.run()

    -- Clean up the poll handle after the event loop stops
    poll:stop()
    poll:close()
    stdin:close()
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
