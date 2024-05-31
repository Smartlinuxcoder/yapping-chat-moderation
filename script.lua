local username = get("username-input")
local password = get("password-input")

local loginbutton = get("login")

local result = get("result")
local messagesitem = get("messages")
local publicChat = get("public-chat")

local publicMessage = get("publicsend-message")

local publicSendButton = get("publicsend")

local refreshButton = get("refresh")

local token

result.set_content(".")

local function formatMessages(data)
    local formattedData = {}
    for _, message in ipairs(data) do
        local success, formattedMessage = pcall(function()
            return string.format(
                "[%d] - Sender: %s, Receiver: %s, Message: %s, Timestamp: %s\n",
                message.id,
                message.sender,
                message.receiver,
                message.message,
                message.timestamp
            )
        end)
        if success then
            table.insert(formattedData, formattedMessage)
        else
            print("Error formatting message:", formattedMessage)
        end
    end
    return table.concat(formattedData)
end

loginbutton.on_click(function()
    local body = "{"
        .. '"username": "'
        .. username.get_content()
        .. '", '
        .. '"password": "'
        .. password.get_content()
        .. '"'
        .. "}"
    print(body)
    local res = fetch({
        url = "https://chat.smartlinux.xyz/api/login",
        method = "POST",
        headers = { ["Content-Type"] = "application/json" },
        body = body,
    })
    print(res)
    if res and res.status then
        if res.status == 429 then
            result.set_content("Failed due to ratelimit.")
        else
            result.set_content("Failed due to error: " .. res.status)
        end
    elseif res and res.token then
        token = res.token
        result.set_content("Login successful")
        local messages = fetch({
            url = "https://chat.smartlinux.xyz/api/messages",
            method = "GET",
            headers = { 
                ["Content-Type"] = "application/json",
                ["Authorization"] = token 
            },
        })
        messagesitem.set_content(formatMessages(messages.messages))
		local messages = fetch({
            url = "https://chat.smartlinux.xyz/api/public-messages",
            method = "GET",
            headers = { 
                ["Content-Type"] = "application/json",
                ["Authorization"] = token 
            },
        })
        publicChat.set_content(formatMessages(messages.messages))
    else
        result.set_content("Failed due to unknown error.")
    end
end)

publicSendButton.on_click(function()
    local body = "{"
        .. '"messageId": "'
        .. publicMessage.get_content()
        .. '"'
        .. "}"
    print(body)
    local res = fetch({
        url = "https://chat.smartlinux.xyz/api/delete-message",
        method = "POST",
        headers = { ["Content-Type"] = "application/json",
                    ["Authorization"] = token 
                },
        body = body,
    })
    print(res)
    if res.status == 200 then
        result.set_content("message deleted successfully")
        local messages = fetch({
            url = "https://chat.smartlinux.xyz/api/public-messages",
            method = "GET",
            headers = { 
                ["Content-Type"] = "application/json",
                ["Authorization"] = token 
            },
        })
        publicChat.set_content(formatMessages(messages.messages))
    else
        result.set_content(res)
    end
end)

refreshButton.on_click(function()
    local messages = fetch({
        url = "https://chat.smartlinux.xyz/api/messages",
        method = "GET",
        headers = { 
            ["Content-Type"] = "application/json",
            ["Authorization"] = token 
        },
    })
    messagesitem.set_content(formatMessages(messages.messages))
    local messages = fetch({
        url = "https://chat.smartlinux.xyz/api/public-messages",
        method = "GET",
        headers = { 
            ["Content-Type"] = "application/json",
            ["Authorization"] = token 
        },
    })
    publicChat.set_content(formatMessages(messages.messages))

    result.set_content("Refreshed")
end)