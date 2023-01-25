local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RoundTimer = {}
RoundTimer.__index = RoundTimer

local WAIT_TEXT = "Waiting for round to start..."

function RoundTimer.new(runTime, waitTime)
    local timer = {
        runTime = runTime,
        waitTime = waitTime,
        nextStartTime = 0,
        nextStopTime = 0,
        running = false,
        onStart = Instance.new("BindableEvent"),
        onStop = Instance.new("BindableEvent"),
        text = nil,
    }

    return setmetatable(timer, RoundTimer)
end

-- Client code

function RoundTimer:initClient(textLabel)
    self.text = textLabel
    self.text.Text = WAIT_TEXT

    local function update()
        self:updateText()
    end

    local function onChanged(attr)
        if attr == "Running" then
            self.running = workspace:GetAttribute("Running")
            if self.running then
                self.nextStopTime = workspace:GetServerTimeNow() + self.runTime
                RunService:BindToRenderStep("updateText", 255, update)
                self.onStart:Fire()
            else
                RunService:UnbindFromRenderStep("updateText")
                self.text.Text = WAIT_TEXT
                self.onStop:Fire()
            end
        end
    end

    workspace.AttributeChanged:Connect(onChanged)
end

function RoundTimer:updateText()
    local time = self.nextStopTime - workspace:GetServerTimeNow()

    local m, s, ms
    m = time / 60
    m, s = math.modf(m)
    s, ms = math.modf(s * 60)
    ms = math.round(ms * 1000)

    self.text.Text = string.format("%i:%02i.%03i", m, s, ms)
end

-- Server code

function RoundTimer:initServer()
    workspace:SetAttribute("Running", false)

    local function loop()
        local nextStartTime = workspace:GetServerTimeNow() + self.waitTime
        local nextStopTime = nextStartTime + self.runTime

        while true do
            local wait = nextStartTime - workspace:GetServerTimeNow()
            task.wait(wait)
            workspace:SetAttribute("Running", true)
            self.onStart:Fire()
            nextStartTime += self.runTime + self.waitTime

            wait = nextStopTime - workspace:GetServerTimeNow()
            task.wait(wait)
            workspace:SetAttribute("Running", false)
            self.onStop:Fire()
            nextStopTime += self.runTime + self.waitTime
        end
    end

    task.defer(loop)
end

return RoundTimer
