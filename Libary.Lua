--[[
    Lurnai UI Library
    Created by Havoc
    
    A beautiful, mobile-friendly UI library for Roblox
    with multiple color themes and a clean tab system
]]

local Lurnai = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

-- Constants
local TWEEN_SPEED = 0.25
local DRAG_SPEED = 10

-- Themes
Lurnai.Themes = {
    Default = {
        Background = Color3.fromRGB(30, 30, 35),
        DarkBackground = Color3.fromRGB(25, 25, 30),
        LightBackground = Color3.fromRGB(40, 40, 45),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(113, 93, 255),
        DarkAccent = Color3.fromRGB(93, 73, 235),
        LightAccent = Color3.fromRGB(133, 113, 255),
        Error = Color3.fromRGB(255, 64, 64),
        Success = Color3.fromRGB(64, 255, 128)
    },
    Ocean = {
        Background = Color3.fromRGB(25, 35, 45),
        DarkBackground = Color3.fromRGB(20, 30, 40),
        LightBackground = Color3.fromRGB(35, 45, 55),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(64, 157, 255),
        DarkAccent = Color3.fromRGB(44, 137, 235),
        LightAccent = Color3.fromRGB(84, 177, 255),
        Error = Color3.fromRGB(255, 64, 64),
        Success = Color3.fromRGB(64, 255, 128)
    },
    Crimson = {
        Background = Color3.fromRGB(35, 25, 30),
        DarkBackground = Color3.fromRGB(30, 20, 25),
        LightBackground = Color3.fromRGB(45, 35, 40),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(255, 64, 87),
        DarkAccent = Color3.fromRGB(235, 44, 67),
        LightAccent = Color3.fromRGB(255, 84, 107),
        Error = Color3.fromRGB(255, 64, 64),
        Success = Color3.fromRGB(64, 255, 128)
    },
    Forest = {
        Background = Color3.fromRGB(30, 35, 30),
        DarkBackground = Color3.fromRGB(25, 30, 25),
        LightBackground = Color3.fromRGB(40, 45, 40),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(64, 205, 113),
        DarkAccent = Color3.fromRGB(44, 185, 93),
        LightAccent = Color3.fromRGB(84, 225, 133),
        Error = Color3.fromRGB(255, 64, 64),
        Success = Color3.fromRGB(64, 255, 128)
    }
}

-- Utility Functions
local function createTween(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or TWEEN_SPEED, easingStyle or Enum.EasingStyle.Quint, easingDirection or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    
    handle = handle or frame
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function createRipple(parent, startPosition)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.Parent = parent
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.8
    ripple.BorderSizePixel = 0
    ripple.Position = UDim2.new(0, startPosition.X - parent.AbsolutePosition.X, 0, startPosition.Y - parent.AbsolutePosition.Y)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = parent.ZIndex + 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    
    createTween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.5)
    
    game:GetService("Debris"):AddItem(ripple, 0.5)
    return ripple
end

-- Main Library Functions
function Lurnai.new(title, theme)
    local currentTheme = Lurnai.Themes[theme or "Default"]
    local window = {}
    local tabs = {}
    local currentTab = nil
    local minimized = false
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LurnaiUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Parent the ScreenGui properly
    if RunService:IsStudio() then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    else
        pcall(function()
            screenGui.Parent = CoreGui
        end)
        if not screenGui.Parent then
            screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end
    
    -- Create Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainFrame.BackgroundColor3 = currentTheme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = -1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = mainFrame
    
    -- Create Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = currentTheme.DarkBackground
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleBarBottom = Instance.new("Frame")
    titleBarBottom.Name = "TitleBarBottom"
    titleBarBottom.Size = UDim2.new(1, 0, 0, 10)
    titleBarBottom.Position = UDim2.new(0, 0, 1, -10)
    titleBarBottom.BackgroundColor3 = currentTheme.DarkBackground
    titleBarBottom.BorderSizePixel = 0
    titleBarBottom.ZIndex = 0
    titleBarBottom.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -120, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = title or "Lurnai UI"
    titleText.TextColor3 = currentTheme.Text
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Create Control Buttons
    local controlsHolder = Instance.new("Frame")
    controlsHolder.Name = "Controls"
    controlsHolder.Size = UDim2.new(0, 70, 1, 0)
    controlsHolder.Position = UDim2.new(1, -80, 0, 0)
    controlsHolder.BackgroundTransparency = 1
    controlsHolder.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.BackgroundColor3 = currentTheme.Error
    closeButton.BackgroundTransparency = 0.8
    closeButton.Text = ""
    closeButton.AutoButtonColor = false
    closeButton.Parent = controlsHolder
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Name = "Icon"
    closeIcon.Size = UDim2.new(0, 16, 0, 16)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = "rbxassetid://7072725342"
    closeIcon.ImageColor3 = currentTheme.Text
    closeIcon.Parent = closeButton
    
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(0, 5, 0.5, -15)
    minimizeButton.BackgroundColor3 = currentTheme.Accent
    minimizeButton.BackgroundTransparency = 0.8
    minimizeButton.Text = ""
    minimizeButton.AutoButtonColor = false
    minimizeButton.Parent = controlsHolder
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeButton
    
    local minimizeIcon = Instance.new("ImageLabel")
    minimizeIcon.Name = "Icon"
    minimizeIcon.Size = UDim2.new(0, 16, 0, 16)
    minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.BackgroundTransparency = 1
    minimizeIcon.Image = "rbxassetid://7072719338"
    minimizeIcon.ImageColor3 = currentTheme.Text
    minimizeIcon.Parent = minimizeButton
    
    -- Create Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 130, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = currentTheme.DarkBackground
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.Name = "ListLayout"
    tabListLayout.Padding = UDim.new(0, 5)
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Parent = tabContainer
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.Name = "Padding"
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.Parent = tabContainer
    
    -- Create Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -130, 1, -40)
    contentContainer.Position = UDim2.new(0, 130, 0, 40)
    contentContainer.BackgroundColor3 = currentTheme.Background
    contentContainer.BorderSizePixel = 0
    contentContainer.ClipsDescendants = true
    contentContainer.Parent = mainFrame
    
    -- Create Watermark
    local watermark = Instance.new("TextLabel")
    watermark.Name = "Watermark"
    watermark.Size = UDim2.new(0, 100, 0, 20)
    watermark.Position = UDim2.new(1, -110, 1, -25)
    watermark.BackgroundTransparency = 1
    watermark.Text = "Lurnai by Havoc"
    watermark.TextColor3 = currentTheme.SubText
    watermark.TextSize = 12
    watermark.Font = Enum.Font.Gotham
    watermark.TextXAlignment = Enum.TextXAlignment.Right
    watermark.TextTransparency = 0.5
    watermark.Parent = contentContainer
    
    -- Button Hover Effects
    closeButton.MouseEnter:Connect(function()
        createTween(closeButton, {BackgroundTransparency = 0.5})
    end)
    
    closeButton.MouseLeave:Connect(function()
        createTween(closeButton, {BackgroundTransparency = 0.8})
    end)
    
    minimizeButton.MouseEnter:Connect(function()
        createTween(minimizeButton, {BackgroundTransparency = 0.5})
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        createTween(minimizeButton, {BackgroundTransparency = 0.8})
    end)
    
    -- Button Functionality
    closeButton.MouseButton1Click:Connect(function()
        createRipple(closeButton, UserInputService:GetMouseLocation())
        createTween(mainFrame, {Size = UDim2.new(0, 500, 0, 0), Position = UDim2.new(0.5, -250, 0.5, 0)}, 0.3)
        wait(0.3)
        screenGui:Destroy()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        createRipple(minimizeButton, UserInputService:GetMouseLocation())
        minimized = not minimized
        
        if minimized then
            createTween(mainFrame, {Size = UDim2.new(0, 500, 0, 40)}, 0.3)
            createTween(minimizeIcon, {Rotation = 180}, 0.3)
        else
            createTween(mainFrame, {Size = UDim2.new(0, 500, 0, 350)}, 0.3)
            createTween(minimizeIcon, {Rotation = 0}, 0.3)
        end
    end)
    
    -- Make window draggable
    makeDraggable(mainFrame, titleBar)
    
    -- Tab Functions
    function window:Tab(name, icon)
        local tab = {}
        local tabSelected = #tabs == 0
        
        -- Create Tab Button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = name.."Tab"
        tabButton.Size = UDim2.new(0, 110, 0, 32)
        tabButton.BackgroundColor3 = tabSelected and currentTheme.Accent or currentTheme.LightBackground
        tabButton.BorderSizePixel = 0
        tabButton.Text = ""
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabButton
        
        local tabIcon
        if icon then
            tabIcon = Instance.new("ImageLabel")
            tabIcon.Name = "Icon"
            tabIcon.Size = UDim2.new(0, 18, 0, 18)
            tabIcon.Position = UDim2.new(0, 10, 0.5, 0)
            tabIcon.AnchorPoint = Vector2.new(0, 0.5)
            tabIcon.BackgroundTransparency = 1
            tabIcon.Image = icon
            tabIcon.ImageColor3 = tabSelected and currentTheme.Text or currentTheme.SubText
            tabIcon.Parent = tabButton
            
            local tabLabel = Instance.new("TextLabel")
            tabLabel.Name = "Label"
            tabLabel.Size = UDim2.new(1, -38, 1, 0)
            tabLabel.Position = UDim2.new(0, 33, 0, 0)
            tabLabel.BackgroundTransparency = 1
            tabLabel.Text = name
            tabLabel.TextColor3 = tabSelected and currentTheme.Text or currentTheme.SubText
            tabLabel.TextSize = 14
            tabLabel.Font = Enum.Font.Gotham
            tabLabel.TextXAlignment = Enum.TextXAlignment.Left
            tabLabel.Parent = tabButton
        else
            local tabLabel = Instance.new("TextLabel")
            tabLabel.Name = "Label"
            tabLabel.Size = UDim2.new(1, -20, 1, 0)
            tabLabel.Position = UDim2.new(0, 10, 0, 0)
            tabLabel.BackgroundTransparency = 1
            tabLabel.Text = name
            tabLabel.TextColor3 = tabSelected and currentTheme.Text or currentTheme.SubText
            tabLabel.TextSize = 14
            tabLabel.Font = Enum.Font.Gotham
            tabLabel.TextXAlignment = Enum.TextXAlignment.Left
            tabLabel.Parent = tabButton
        end
        
        -- Create Tab Content
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = name.."Content"
        tabContent.Size = UDim2.new(1, -20, 1, -20)
        tabContent.Position = UDim2.new(0, 10, 0, 10)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = currentTheme.Accent
        tabContent.Visible = tabSelected
        tabContent.Parent = contentContainer
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Name = "ListLayout"
        contentLayout.Padding = UDim.new(0, 10)
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = tabContent
        
        local contentPadding = Instance.new("UIPadding")
        contentPadding.Name = "Padding"
        contentPadding.PaddingTop = UDim.new(0, 5)
        contentPadding.PaddingBottom = UDim.new(0, 10)
        contentPadding.Parent = tabContent
        
        -- Auto-size the scrolling frame content
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- Tab Selection Logic
        tabButton.MouseButton1Click:Connect(function()
            createRipple(tabButton, UserInputService:GetMouseLocation())
            
            if not tabSelected then
                -- Deselect current tab
                if currentTab then
                    local currentButton = currentTab.Button
                    local currentContent = currentTab.Content
                    
                    createTween(currentButton, {BackgroundColor3 = currentTheme.LightBackground})
                    
                    if currentButton:FindFirstChild("Icon") then
                        createTween(currentButton.Icon, {ImageColor3 = currentTheme.SubText})
                    end
                    
                    createTween(currentButton.Label, {TextColor3 = currentTheme.SubText})
                    currentContent.Visible = false
                end
                
                -- Select this tab
                createTween(tabButton, {BackgroundColor3 = currentTheme.Accent})
                
                if tabButton:FindFirstChild("Icon") then
                    createTween(tabButton.Icon, {ImageColor3 = currentTheme.Text})
                end
                
                createTween(tabButton.Label, {TextColor3 = currentTheme.Text})
                tabContent.Visible = true
                
                tabSelected = true
                currentTab = {Button = tabButton, Content = tabContent}
            end
        end)
        
        -- Add tab to tabs table
        table.insert(tabs, {Button = tabButton, Content = tabContent})
        
        -- Set as current tab if it's the first one
        if #tabs == 1 then
            currentTab = {Button = tabButton, Content = tabContent}
        end
        
        -- Element Creation Functions
        function tab:Section(title)
            local section = {}
            
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Name = title.."Section"
            sectionFrame.Size = UDim2.new(1, -20, 0, 40) -- Will be auto-sized
            sectionFrame.BackgroundColor3 = currentTheme.LightBackground
            sectionFrame.BorderSizePixel = 0
            sectionFrame.Parent = tabContent
            
            local sectionCorner = Instance.new("UICorner")
            sectionCorner.CornerRadius = UDim.new(0, 6)
            sectionCorner.Parent = sectionFrame
            
            local sectionTitle = Instance.new("TextLabel")
            sectionTitle.Name = "Title"
            sectionTitle.Size = UDim2.new(1, -20, 0, 30)
            sectionTitle.Position = UDim2.new(0, 10, 0, 0)
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Text = title
            sectionTitle.TextColor3 = currentTheme.Text
            sectionTitle.TextSize = 16
            sectionTitle.Font = Enum.Font.GothamBold
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            sectionTitle.Parent = sectionFrame
            
            local sectionContent = Instance.new("Frame")
            sectionContent.Name = "Content"
            sectionContent.Size = UDim2.new(1, -20, 0, 0) -- Will be auto-sized
            sectionContent.Position = UDim2.new(0, 10, 0, 30)
            sectionContent.BackgroundTransparency = 1
            sectionContent.Parent = sectionFrame
            
            local sectionLayout = Instance.new("UIListLayout")
            sectionLayout.Name = "ListLayout"
            sectionLayout.Padding = UDim.new(0, 8)
            sectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            sectionLayout.Parent = sectionContent
            
            -- Auto-size the section
            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sectionContent.Size = UDim2.new(1, -20, 0, sectionLayout.AbsoluteContentSize.Y)
                sectionFrame.Size = UDim2.new(1, -20, 0, sectionContent.Size.Y.Offset + 40)
            end)
            
            -- Button
            function section:Button(text, callback)
                callback = callback or function() end
                
                local buttonFrame = Instance.new("Frame")
                buttonFrame.Name = text.."Button"
                buttonFrame.Size = UDim2.new(1, 0, 0, 35)
                buttonFrame.BackgroundTransparency = 1
                buttonFrame.Parent = sectionContent
                
                local button = Instance.new("TextButton")
                button.Name = "Button"
                button.Size = UDim2.new(1, 0, 1, 0)
                button.BackgroundColor3 = currentTheme.DarkBackground
                button.BorderSizePixel = 0
                button.Text = ""
                button.AutoButtonColor = false
                button.ClipsDescendants = true
                button.Parent = buttonFrame
                
                local buttonCorner = Instance.new("UICorner")
                buttonCorner.CornerRadius = UDim.new(0, 6)
                buttonCorner.Parent = button
                
                local buttonLabel = Instance.new("TextLabel")
                buttonLabel.Name = "Label"
                buttonLabel.Size = UDim2.new(1, -20, 1, 0)
                buttonLabel.Position = UDim2.new(0, 10, 0, 0)
                buttonLabel.BackgroundTransparency = 1
                buttonLabel.Text = text
                buttonLabel.TextColor3 = currentTheme.Text
                buttonLabel.TextSize = 14
                buttonLabel.Font = Enum.Font.Gotham
                buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
                buttonLabel.Parent = button
                
                -- Button Effects
                button.MouseEnter:Connect(function()
                    createTween(button, {BackgroundColor3 = currentTheme.Accent})
                end)
                
                button.MouseLeave:Connect(function()
                    createTween(button, {BackgroundColor3 = currentTheme.DarkBackground})
                end)
                
                button.MouseButton1Click:Connect(function()
                    createRipple(button, UserInputService:GetMouseLocation())
                    callback()
                end)
                
                return buttonFrame
            end
            
            -- Toggle
            function section:Toggle(text, default, callback)
                default = default or false
                callback = callback or function() end
                
                local toggleValue = default
                
                local toggleFrame = Instance.new("Frame")
                toggleFrame.Name = text.."Toggle"
                toggleFrame.Size = UDim2.new(1, 0, 0, 35)
                toggleFrame.BackgroundTransparency = 1
                toggleFrame.Parent = sectionContent
                
                local toggleButton = Instance.new("TextButton")
                toggleButton.Name = "Button"
                toggleButton.Size = UDim2.new(1, 0, 1, 0)
                toggleButton.BackgroundColor3 = currentTheme.DarkBackground
                toggleButton.BorderSizePixel = 0
                toggleButton.Text = ""
                toggleButton.AutoButtonColor = false
                toggleButton.ClipsDescendants = true
                toggleButton.Parent = toggleFrame
                
                local toggleCorner = Instance.new("UICorner")
                toggleCorner.CornerRadius = UDim.new(0, 6)
                toggleCorner.Parent = toggleButton
                
                local toggleLabel = Instance.new("TextLabel")
                toggleLabel.Name = "Label"
                toggleLabel.Size = UDim2.new(1, -50, 1, 0)
                toggleLabel.Position = UDim2.new(0, 10, 0, 0)
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.Text = text
                toggleLabel.TextColor3 = currentTheme.Text
                toggleLabel.TextSize = 14
                toggleLabel.Font = Enum.Font.Gotham
                toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                toggleLabel.Parent = toggleButton
                
                local toggleIndicator = Instance.new("Frame")
                toggleIndicator.Name = "Indicator"
                toggleIndicator.Size = UDim2.new(0, 40, 0, 20)
                toggleIndicator.Position = UDim2.new(1, -50, 0.5, 0)
                toggleIndicator.AnchorPoint = Vector2.new(0, 0.5)
                toggleIndicator.BackgroundColor3 = toggleValue and currentTheme.Accent or currentTheme.DarkBackground
                toggleIndicator.BorderSizePixel = 0
                toggleIndicator.Parent = toggleButton
                
                local indicatorCorner = Instance.new("UICorner")
                indicatorCorner.CornerRadius = UDim.new(1, 0)
                indicatorCorner.Parent = toggleIndicator
                
                local toggleCircle = Instance.new("Frame")
                toggleCircle.Name = "Circle"
                toggleCircle.Size = UDim2.new(0, 16, 0, 16)
                toggleCircle.Position = UDim2.new(toggleValue and 1 or 0, toggleValue and -18 or 2, 0.5, 0)
                toggleCircle.AnchorPoint = Vector2.new(0, 0.5)
                toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                toggleCircle.BorderSizePixel = 0
                toggleCircle.Parent = toggleIndicator
                
                local circleCorner = Instance.new("UICorner")
                circleCorner.CornerRadius = UDim.new(1, 0)
                circleCorner.Parent = toggleCircle
                
                -- Toggle Effects
                toggleButton.MouseEnter:Connect(function()
                    if not toggleValue then
                        createTween(toggleIndicator, {BackgroundColor3 = currentTheme.LightBackground})
                    end
                end)
                
                toggleButton.MouseLeave:Connect(function()
                    if not toggleValue then
                        createTween(toggleIndicator, {BackgroundColor3 = currentTheme.DarkBackground})
                    end
                end)
                
                toggleButton.MouseButton1Click:Connect(function()
                    createRipple(toggleButton, UserInputService:GetMouseLocation())
                    toggleValue = not toggleValue
                    
                    if toggleValue then
                        createTween(toggleIndicator, {BackgroundColor3 = currentTheme.Accent})
                        createTween(toggleCircle, {Position = UDim2.new(1, -18, 0.5, 0)})
                    else
                        createTween(toggleIndicator, {BackgroundColor3 = currentTheme.LightBackground})
                        createTween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, 0)})
                    end
                    
                    callback(toggleValue)
                end)
                
                -- Set default state
                if default then
                    callback(true)
                end
                
                -- Toggle API
                local toggleAPI = {}
                
                function toggleAPI:Set(value)
                    toggleValue = value
                    
                    if toggleValue then
                        createTween(toggleIndicator, {BackgroundColor3 = currentTheme.Accent})
                        createTween(toggleCircle, {Position = UDim2.new(1, -18, 0.5, 0)})
                    else
                        createTween(toggleIndicator, {BackgroundColor3 = currentTheme.DarkBackground})
                        createTween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, 0)})
                    end
                    
                    callback(toggleValue)
                end
                
                function toggleAPI:Get()
                    return toggleValue
                end
                
                return toggleAPI
            end
            
            -- Slider
            function section:Slider(text, options, callback)
                options = options or {}
                options.min = options.min or 0
                options.max = options.max or 100
                options.default = options.default or options.min
                options.increment = options.increment or 1
                callback = callback or function() end
                
                local sliderValue = options.default
                local isDragging = false
                
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Name = text.."Slider"
                sliderFrame.Size = UDim2.new(1, 0, 0, 50)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Parent = sectionContent
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Name = "Label"
                sliderLabel.Size = UDim2.new(1, 0, 0, 20)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Text = text
                sliderLabel.TextColor3 = currentTheme.Text
                sliderLabel.TextSize = 14
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.Parent = sliderFrame
                
                local sliderValueLabel = Instance.new("TextLabel")
                sliderValueLabel.Name = "Value"
                sliderValueLabel.Size = UDim2.new(0, 50, 0, 20)
                sliderValueLabel.Position = UDim2.new(1, -50, 0, 0)
                sliderValueLabel.BackgroundTransparency = 1
                sliderValueLabel.Text = tostring(sliderValue)
                sliderValueLabel.TextColor3 = currentTheme.SubText
                sliderValueLabel.TextSize = 14
                sliderValueLabel.Font = Enum.Font.Gotham
                sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                sliderValueLabel.Parent = sliderFrame
                
                local sliderContainer = Instance.new("Frame")
                sliderContainer.Name = "Container"
                sliderContainer.Size = UDim2.new(1, 0, 0, 8)
                sliderContainer.Position = UDim2.new(0, 0, 0, 30)
                sliderContainer.BackgroundColor3 = currentTheme.DarkBackground
                sliderContainer.BorderSizePixel = 0
                sliderContainer.Parent = sliderFrame
                
                local sliderContainerCorner = Instance.new("UICorner")
                sliderContainerCorner.CornerRadius = UDim.new(1, 0)
                sliderContainerCorner.Parent = sliderContainer
                
                local sliderFill = Instance.new("Frame")
                sliderFill.Name = "Fill"
                sliderFill.Size = UDim2.new((sliderValue - options.min) / (options.max - options.min), 0, 1, 0)
                sliderFill.BackgroundColor3 = currentTheme.Accent
                sliderFill.BorderSizePixel = 0
                sliderFill.Parent = sliderContainer
                
                local sliderFillCorner = Instance.new("UICorner")
                sliderFillCorner.CornerRadius = UDim.new(1, 0)
                sliderFillCorner.Parent = sliderFill
                
                local sliderCircle = Instance.new("Frame")
                sliderCircle.Name = "Circle"
                sliderCircle.Size = UDim2.new(0, 16, 0, 16)
                sliderCircle.Position = UDim2.new((sliderValue - options.min) / (options.max - options.min), 0, 0.5, 0)
                sliderCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                sliderCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sliderCircle.BorderSizePixel = 0
                sliderCircle.Parent = sliderContainer
                
                local sliderCircleCorner = Instance.new("UICorner")
                sliderCircleCorner.CornerRadius = UDim.new(1, 0)
                sliderCircleCorner.Parent = sliderCircle
                
                -- Update slider function
                local function updateSlider(input)
                    local sizeX = math.clamp((input.Position.X - sliderContainer.AbsolutePosition.X) / sliderContainer.AbsoluteSize.X, 0, 1)
                    local value = options.min + ((options.max - options.min) * sizeX)
                    
                    -- Apply increment
                    value = math.floor(value / options.increment + 0.5) * options.increment
                    value = math.clamp(value, options.min, options.max)
                    
                    -- Update UI
                    sliderValue = value
                    sliderValueLabel.Text = tostring(sliderValue)
                    sliderFill.Size = UDim2.new((sliderValue - options.min) / (options.max - options.min), 0, 1, 0)
                    sliderCircle.Position = UDim2.new((sliderValue - options.min) / (options.max - options.min), 0, 0.5, 0)
                    
                    callback(value)
                end
                
                -- Slider interaction
                sliderContainer.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        updateSlider(input)
                    end
                end)
                
                sliderContainer.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)
                
                -- Set default value
                callback(sliderValue)
                
                -- Slider API
                local sliderAPI = {}
                
                function sliderAPI:Set(value)
                    value = math.clamp(value, options.min, options.max)
                    sliderValue = value
                    sliderValueLabel.Text = tostring(value)
                    sliderFill.Size = UDim2.new((value - options.min) / (options.max - options.min), 0, 1, 0)
                    sliderCircle.Position = UDim2.new((value - options.min) / (options.max - options.min), 0, 0.5, 0)
                    callback(value)
                end
                
                function sliderAPI:Get()
                    return sliderValue
                end
                
                return sliderAPI
            end
            
            -- Dropdown
            function section:Dropdown(text, options, callback)
                options = options or {}
                callback = callback or function() end
                
                local dropdownOpen = false
                local selectedOption = options[1] or "Select..."
                
                local dropdownFrame = Instance.new("Frame")
                dropdownFrame.Name = text.."Dropdown"
                dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
                dropdownFrame.BackgroundTransparency = 1
                dropdownFrame.Parent = sectionContent
                
                local dropdownButton = Instance.new("TextButton")
                dropdownButton.Name = "Button"
                dropdownButton.Size = UDim2.new(1, 0, 1, 0)
                dropdownButton.BackgroundColor3 = currentTheme.DarkBackground
                dropdownButton.BorderSizePixel = 0
                dropdownButton.Text = ""
                dropdownButton.AutoButtonColor = false
                dropdownButton.ClipsDescendants = true
                dropdownButton.Parent = dropdownFrame
                
                local dropdownCorner = Instance.new("UICorner")
                dropdownCorner.CornerRadius = UDim.new(0, 6)
                dropdownCorner.Parent = dropdownButton
                
                local dropdownLabel = Instance.new("TextLabel")
                dropdownLabel.Name = "Label"
                dropdownLabel.Size = UDim2.new(0, 100, 1, 0)
                dropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                dropdownLabel.BackgroundTransparency = 1
                dropdownLabel.Text = text
                dropdownLabel.TextColor3 = currentTheme.Text
                dropdownLabel.TextSize = 14
                dropdownLabel.Font = Enum.Font.Gotham
                dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                dropdownLabel.Parent = dropdownButton
                
                local dropdownSelected = Instance.new("TextLabel")
                dropdownSelected.Name = "Selected"
                dropdownSelected.Size = UDim2.new(1, -150, 1, 0)
                dropdownSelected.Position = UDim2.new(0, 110, 0, 0)
                dropdownSelected.BackgroundTransparency = 1
                dropdownSelected.Text = selectedOption
                dropdownSelected.TextColor3 = currentTheme.SubText
                dropdownSelected.TextSize = 14
                dropdownSelected.Font = Enum.Font.Gotham
                dropdownSelected.TextXAlignment = Enum.TextXAlignment.Left
                dropdownSelected.TextTruncate = Enum.TextTruncate.AtEnd
                dropdownSelected.Parent = dropdownButton
                
                local dropdownIcon = Instance.new("ImageLabel")
                dropdownIcon.Name = "Icon"
                dropdownIcon.Size = UDim2.new(0, 20, 0, 20)
                dropdownIcon.Position = UDim2.new(1, -30, 0.5, 0)
                dropdownIcon.AnchorPoint = Vector2.new(0, 0.5)
                dropdownIcon.BackgroundTransparency = 1
                dropdownIcon.Image = "rbxassetid://7072706318"
                dropdownIcon.ImageColor3 = currentTheme.SubText
                dropdownIcon.Parent = dropdownButton

                -- Dropdown Menu
                local dropdownMenu = Instance.new("Frame")
                dropdownMenu.Name = "Menu"
                dropdownMenu.Size = UDim2.new(1, 0, 0, 0)
                dropdownMenu.Position = UDim2.new(0, 0, 1, 5)
                dropdownMenu.BackgroundColor3 = currentTheme.DarkBackground
                dropdownMenu.BorderSizePixel = 0
                dropdownMenu.ClipsDescendants = true
                dropdownMenu.Visible = false
                dropdownMenu.ZIndex = 5
                dropdownMenu.Parent = dropdownFrame
                
                local dropdownMenuCorner = Instance.new("UICorner")
                dropdownMenuCorner.CornerRadius = UDim.new(0, 6)
                dropdownMenuCorner.Parent = dropdownMenu
                
                local dropdownMenuLayout = Instance.new("UIListLayout")
                dropdownMenuLayout.Name = "ListLayout"
                dropdownMenuLayout.Padding = UDim.new(0, 5)
                dropdownMenuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                dropdownMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
                dropdownMenuLayout.Parent = dropdownMenu
                
                local dropdownMenuPadding = Instance.new("UIPadding")
                dropdownMenuPadding.Name = "Padding"
                dropdownMenuPadding.PaddingTop = UDim.new(0, 5)
                dropdownMenuPadding.PaddingBottom = UDim.new(0, 5)
                dropdownMenuPadding.Parent = dropdownMenu
                
                -- Create dropdown options
                for i, option in ipairs(options) do
                    local optionButton = Instance.new("TextButton")
                    optionButton.Name = option.."Option"
                    optionButton.Size = UDim2.new(1, -10, 0, 30)
                    optionButton.BackgroundColor3 = currentTheme.LightBackground
                    optionButton.BackgroundTransparency = 0.8
                    optionButton.BorderSizePixel = 0
                    optionButton.Text = option
                    optionButton.TextColor3 = currentTheme.Text
                    optionButton.TextSize = 14
                    optionButton.Font = Enum.Font.Gotham
                    optionButton.ZIndex = 6
                    optionButton.ClipsDescendants = true
                    optionButton.Parent = dropdownMenu
                    
                    local optionCorner = Instance.new("UICorner")
                    optionCorner.CornerRadius = UDim.new(0, 6)
                    optionCorner.Parent = optionButton
                    
                    -- Option button effects
                    optionButton.MouseEnter:Connect(function()
                        createTween(optionButton, {BackgroundTransparency = 0.5})
                    end)
                    
                    optionButton.MouseLeave:Connect(function()
                        createTween(optionButton, {BackgroundTransparency = 0.8})
                    end)
                    
                    optionButton.MouseButton1Click:Connect(function()
                        createRipple(optionButton, UserInputService:GetMouseLocation())
                        selectedOption = option
                        dropdownSelected.Text = option
                        
                        -- Close dropdown
                        dropdownOpen = false
                        createTween(dropdownIcon, {Rotation = 0})
                        createTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        wait(0.2)
                        dropdownMenu.Visible = false
                        
                        callback(option)
                    end)
                end
                
                -- Update dropdown menu size based on content
                dropdownMenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if dropdownOpen then
                        dropdownMenu.Size = UDim2.new(1, 0, 0, dropdownMenuLayout.AbsoluteContentSize.Y + 10)
                    end
                end)
                
                -- Dropdown button effects
                dropdownButton.MouseEnter:Connect(function()
                    createTween(dropdownButton, {BackgroundColor3 = currentTheme.LightBackground})
                end)
                
                dropdownButton.MouseLeave:Connect(function()
                    createTween(dropdownButton, {BackgroundColor3 = currentTheme.DarkBackground})
                end)
                
                dropdownButton.MouseButton1Click:Connect(function()
                    createRipple(dropdownButton, UserInputService:GetMouseLocation())
                    dropdownOpen = not dropdownOpen
                    
                    if dropdownOpen then
                        dropdownMenu.Visible = true
                        createTween(dropdownIcon, {Rotation = 180})
                        createTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, dropdownMenuLayout.AbsoluteContentSize.Y + 10)}, 0.2)
                    else
                        createTween(dropdownIcon, {Rotation = 0})
                        createTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        wait(0.2)
                        dropdownMenu.Visible = false
                    end
                end)
                
                -- Close dropdown when clicking outside
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if dropdownOpen and not dropdownButton:IsDescendantOf(game) then return end
                        
                        local mousePos = UserInputService:GetMouseLocation()
                        local inBounds = mousePos.X >= dropdownFrame.AbsolutePosition.X and
                                         mousePos.X <= dropdownFrame.AbsolutePosition.X + dropdownFrame.AbsoluteSize.X and
                                         mousePos.Y >= dropdownFrame.AbsolutePosition.Y and
                                         mousePos.Y <= dropdownFrame.AbsolutePosition.Y + dropdownFrame.AbsoluteSize.Y + dropdownMenu.AbsoluteSize.Y
                        
                        if not inBounds and dropdownOpen then
                            dropdownOpen = false
                            createTween(dropdownIcon, {Rotation = 0})
                            createTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                            wait(0.2)
                            dropdownMenu.Visible = false
                        end
                    end
                end)
                
                -- Dropdown API
                local dropdownAPI = {}
                
                function dropdownAPI:Set(option)
                    if table.find(options, option) then
                        selectedOption = option
                        dropdownSelected.Text = option
                        callback(option)
                    end
                end
                
                function dropdownAPI:Get()
                    return selectedOption
                end
                
                function dropdownAPI:Refresh(newOptions)
                    options = newOptions
                    selectedOption = newOptions[1] or "Select..."
                    dropdownSelected.Text = selectedOption
                    
                    -- Clear existing options
                    for _, child in pairs(dropdownMenu:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    
                    -- Create new options
                    for i, option in ipairs(options) do
                        local optionButton = Instance.new("TextButton")
                        optionButton.Name = option.."Option"
                        optionButton.Size = UDim2.new(1, -10, 0, 30)
                        optionButton.BackgroundColor3 = currentTheme.LightBackground
                        optionButton.BackgroundTransparency = 0.8
                        optionButton.BorderSizePixel = 0
                        optionButton.Text = option
                        optionButton.TextColor3 = currentTheme.Text
                        optionButton.TextSize = 14
                        optionButton.Font = Enum.Font.Gotham
                        optionButton.ZIndex = 6
                        optionButton.ClipsDescendants = true
                        optionButton.Parent = dropdownMenu
                        
                        local optionCorner = Instance.new("UICorner")
                        optionCorner.CornerRadius = UDim.new(0, 6)
                        optionCorner.Parent = optionButton
                        
                        -- Option button effects
                        optionButton.MouseEnter:Connect(function()
                            createTween(optionButton, {BackgroundTransparency = 0.5})
                        end)
                        
                        optionButton.MouseLeave:Connect(function()
                            createTween(optionButton, {BackgroundTransparency = 0.8})
                        end)
                        
                        optionButton.MouseButton1Click:Connect(function()
                            createRipple(optionButton, UserInputService:GetMouseLocation())
                            selectedOption = option
                            dropdownSelected.Text = option
                            
                            -- Close dropdown
                            dropdownOpen = false
                            createTween(dropdownIcon, {Rotation = 0})
                            createTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                            wait(0.2)
                            dropdownMenu.Visible = false
                            
                            callback(option)
                        end)
                    end
                end
                
                return dropdownAPI
            end
            
            -- TextBox
            function section:TextBox(text, placeholder, callback)
                placeholder = placeholder or ""
                callback = callback or function() end
                
                local textBoxFrame = Instance.new("Frame")
                textBoxFrame.Name = text.."TextBox"
                textBoxFrame.Size = UDim2.new(1, 0, 0, 35)
                textBoxFrame.BackgroundTransparency = 1
                textBoxFrame.Parent = sectionContent
                
                local textBoxLabel = Instance.new("TextLabel")
                textBoxLabel.Name = "Label"
                textBoxLabel.Size = UDim2.new(1, 0, 0, 20)
                textBoxLabel.BackgroundTransparency = 1
                textBoxLabel.Text = text
                textBoxLabel.TextColor3 = currentTheme.Text
                textBoxLabel.TextSize = 14
                textBoxLabel.Font = Enum.Font.Gotham
                textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
                textBoxLabel.Parent = textBoxFrame
                
                local textBoxContainer = Instance.new("Frame")
                textBoxContainer.Name = "Container"
                textBoxContainer.Size = UDim2.new(1, 0, 0, 30)
                textBoxContainer.Position = UDim2.new(0, 0, 0, 20)
                textBoxContainer.BackgroundColor3 = currentTheme.DarkBackground
                textBoxContainer.BorderSizePixel = 0
                textBoxContainer.Parent = textBoxFrame
                
                local textBoxContainerCorner = Instance.new("UICorner")
                textBoxContainerCorner.CornerRadius = UDim.new(0, 6)
                textBoxContainerCorner.Parent = textBoxContainer
                
                local textBox = Instance.new("TextBox")
                textBox.Name = "Input"
                textBox.Size = UDim2.new(1, -20, 1, 0)
                textBox.Position = UDim2.new(0, 10, 0, 0)
                textBox.BackgroundTransparency = 1
                textBox.Text = ""
                textBox.PlaceholderText = placeholder
                textBox.TextColor3 = currentTheme.Text
                textBox.PlaceholderColor3 = currentTheme.SubText
                textBox.TextSize = 14
                textBox.Font = Enum.Font.Gotham
                textBox.TextXAlignment = Enum.TextXAlignment.Left
                textBox.ClearTextOnFocus = false
                textBox.Parent = textBoxContainer
                
                -- TextBox effects
                textBoxContainer.MouseEnter:Connect(function()
                    if textBox:IsFocused() then return end
                    createTween(textBoxContainer, {BackgroundColor3 = currentTheme.LightBackground})
                end)
                
                textBoxContainer.MouseLeave:Connect(function()
                    if textBox:IsFocused() then return end
                    createTween(textBoxContainer, {BackgroundColor3 = currentTheme.DarkBackground})
                end)
                
                textBox.Focused:Connect(function()
                    createTween(textBoxContainer, {BackgroundColor3 = currentTheme.Accent})
                end)
                
                textBox.FocusLost:Connect(function(enterPressed)
                    createTween(textBoxContainer, {BackgroundColor3 = currentTheme.DarkBackground})
                    callback(textBox.Text, enterPressed)
                end)
                
                -- TextBox API
                local textBoxAPI = {}
                
                function textBoxAPI:Set(value)
                    textBox.Text = value
                    callback(value, false)
                end
                
                function textBoxAPI:Get()
                    return textBox.Text
                end
                
                return textBoxAPI
            end
            
            -- Label
            function section:Label(text)
                local labelFrame = Instance.new("Frame")
                labelFrame.Name = "Label"
                labelFrame.Size = UDim2.new(1, 0, 0, 20)
                labelFrame.BackgroundTransparency = 1
                labelFrame.Parent = sectionContent
                
                local label = Instance.new("TextLabel")
                label.Name = "Text"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = currentTheme.SubText
                label.TextSize = 14
                label.Font = Enum.Font.Gotham
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = labelFrame
                
                -- Label API
                local labelAPI = {}
                
                function labelAPI:Set(value)
                    label.Text = value
                end
                
                function labelAPI:SetColor(color)
                    label.TextColor3 = color
                end
                
                return labelAPI
            end
            
            -- Divider
            function section:Divider()
                local dividerFrame = Instance.new("Frame")
                dividerFrame.Name = "Divider"
                dividerFrame.Size = UDim2.new(1, 0, 0, 10)
                dividerFrame.BackgroundTransparency = 1
                dividerFrame.Parent = sectionContent
                
                local divider = Instance.new("Frame")
                divider.Name = "Line"
                divider.Size = UDim2.new(1, 0, 0, 1)
                divider.Position = UDim2.new(0, 0, 0.5, 0)
                divider.BackgroundColor3 = currentTheme.LightBackground
                divider.BorderSizePixel = 0
                divider.Parent = dividerFrame
                
                return dividerFrame
            end
