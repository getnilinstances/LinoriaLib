local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func)
    return func
end)

local httprequest = request or http_request or (http and http.request)
local getassetfunc = getcustomasset

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

local assert = function(condition, errorMessage)
    if (not condition) then
        error(if errorMessage then errorMessage else "assert failed", 3)
    end
end

if typeof(clonefunction) == "function" then
    local ok_c, isfolder_copy = pcall(clonefunction, isfolder)
    local ok_f, isfile_copy   = pcall(clonefunction, isfile)
    local ok_l, listfiles_copy = pcall(clonefunction, listfiles)
    if not ok_c then isfolder_copy = nil end
    if not ok_f then isfile_copy   = nil end
    if not ok_l then listfiles_copy = nil end

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {} do
    local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "VideoLink" }
    ThemeManager.Folder = "LinoriaLibSettings"

    ThemeManager.Library = nil
    ThemeManager.BuiltInThemes = {
        ["Default"] = { 1, { FontColor = "ffffff", MainColor = "131313", AccentColor = "a2cdff", BackgroundColor = "151515", OutlineColor = "212121" } },
        ["Tokyo Night"] = { 1, { FontColor = "ffffff", MainColor = "191925", AccentColor = "6956cb", BackgroundColor = "15151e", OutlineColor = "272727" } },
        ["Nord"] = { 1, { FontColor = "ffffff", MainColor = "1c1e20", AccentColor = "9effc8", BackgroundColor = "1c1e20", OutlineColor = "24282d" } },
        ["Skeet"] = { 1, { FontColor = "ffffff", MainColor = "131313", AccentColor = "81ff54", BackgroundColor = "151515", OutlineColor = "2a2a2a" } },
        ["Fatality"] = { 1, { FontColor = "ffffff", MainColor = "181537", AccentColor = "ca0756", BackgroundColor = "201c46", OutlineColor = "39335a" } },
        ["Neverlose"] = { 1, { FontColor = "ffffff", MainColor = "0c1014", AccentColor = "01a3f1", BackgroundColor = "0c0f14", OutlineColor = "191919" } },
        ["Onetap"] = { 1, { FontColor = "ffffff", MainColor = "1e1d22", AccentColor = "faa614", BackgroundColor = "18181c", OutlineColor = "313033" } },
        ["Imgui"] = { 1, { FontColor = "ffffff", MainColor = "151617", AccentColor = "406ba8", BackgroundColor = "151617", OutlineColor = "242424" } },
        ["Iniuria"] = { 1, { FontColor = "ffffff", MainColor = "1e1d1e", AccentColor = "c41275", BackgroundColor = "1e1d1e", OutlineColor = "33252b" } },
        ["Primordial"] = { 1, { FontColor = "ffffff", MainColor = "181818", AccentColor = "d7a6b0", BackgroundColor = "1f1f1f", OutlineColor = "2a2a2a" } },
        ["Monolith"] = { 1, { FontColor = "ffffff", MainColor = "141115", AccentColor = "c707bd", BackgroundColor = "171417", OutlineColor = "272427" } },
        ["V3rmillion"] = { 1, { FontColor = "ffffff", MainColor = "202020", AccentColor = "cd1818", BackgroundColor = "202020", OutlineColor = "2a2a2a" } },
        ["Dark"] = { 1, { FontColor = "ffffff", MainColor = "0a0a0a", AccentColor = "5945ff", BackgroundColor = "0a0a0a", OutlineColor = "171717" } },
    }

    function ApplyBackgroundVideo(videoLink)
        if
            typeof(videoLink) ~= "string" or
            not (getassetfunc and writefile and readfile and isfile) or
            not (ThemeManager.Library and ThemeManager.Library.InnerVideoBackground)
        then return end

        local videoInstance = ThemeManager.Library.InnerVideoBackground
        local extension = videoLink:match(".*/(.-)?") or videoLink:match(".*/(.-)$")
        extension = tostring(extension)
        local filename = string.sub(extension, 0, -6)
        local _, domain = videoLink:match("^(https?://)([^/]+)")
        domain = tostring(domain or "")

        if videoLink == "" then
            videoInstance:Pause()
            videoInstance.Video = ""
            videoInstance.Visible = false
            return
        end
        if #extension > 5 and string.sub(extension, -5) ~= ".webm" then return end

        local videoFile = ThemeManager.Folder .. "/themes/" .. string.sub(domain .. filename, 1, 249) .. ".webm"
        if not isfile(videoFile) then
            local success, requestRes = pcall(httprequest, { Url = videoLink, Method = 'GET' })
            if not (success and typeof(requestRes) == "table" and typeof(requestRes.Body) == "string") then return end
            writefile(videoFile, requestRes.Body)
        end

        videoInstance.Video = getassetfunc(videoFile)
        videoInstance.Visible = true
        videoInstance:Play()
    end

    function ThemeManager:SetLibrary(library)
        self.Library = library
    end

    function ThemeManager:GetPaths()
        local paths = {}
        local parts = {}

        if type(self.Folder) == "string" and self.Folder:find("/") then
            if string.split then
                parts = self.Folder:split('/')
            else
                for part in string.gmatch(self.Folder, "[^/]+") do
                    table.insert(parts, part)
                end
            end
        else
            parts = { self.Folder }
        end

        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, '/', 1, idx)
        end
        paths[#paths + 1] = self.Folder .. '/themes'
        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()
        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then continue end
            makefolder(str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) and isfolder(self.Folder .. '/themes') then return end
        self:BuildFolderTree()
        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function ThemeManager:ApplyTheme(theme)
        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]
        if not data then return end

        if self.Library.InnerVideoBackground ~= nil then
            self.Library.InnerVideoBackground.Visible = false
        end

        -- Built-in themes are { index, dict }; custom themes are plain dicts
        local scheme = (type(data) == "table" and data[2]) or data

        -- Only touch real theme fields; anything else (ItemType, SwordMaterial, ...)
        -- must not be treated as a Color3.fromHex() argument.
        for _, idx in next, ThemeFields do
            local col = scheme[idx]
            if col == nil then continue end

            if idx == "VideoLink" then
                self.Library[idx] = col
                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(col)
                end
                ApplyBackgroundVideo(col)
            else
                local ok, color = pcall(Color3.fromHex, col)
                if not ok or not color then continue end
                self.Library[idx] = color
                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValueRGB(color)
                end
            end
        end

        self:ThemeUpdate()
    end

    function ThemeManager:ThemeUpdate()
        if self.Library.InnerVideoBackground ~= nil then
            self.Library.InnerVideoBackground.Visible = false
        end

        for _, field in next, ThemeFields do
            if self.Library.Options and self.Library.Options[field] then
                self.Library[field] = self.Library.Options[field].Value
                if field == "VideoLink" then
                    ApplyBackgroundVideo(self.Library.Options[field].Value)
                end
            end
        end

        self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        self.Library:UpdateColorsUsingRegistry()
    end

    function ThemeManager:GetCustomTheme(file)
        local path = self.Folder .. '/themes/' .. file .. '.json'
        if not isfile(path) then return nil end

        local data = readfile(path)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
        if not success then return nil end
        return decoded
    end

    function ThemeManager:LoadDefault()
        local theme = 'Default'
        local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

        local isDefault = true
        if content then
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
                isDefault = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end

        if isDefault then
            self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
        else
            self:ApplyTheme(theme)
        end
    end

    function ThemeManager:SaveDefault(theme)
        writefile(self.Folder .. '/themes/default.txt', theme)
    end

    function ThemeManager:SaveCustomTheme(file)
        if file:gsub(' ', '') == '' then
            self.Library:Notify('Invalid file name for theme (empty)', 3)
            return
        end

        local theme = {}
        for _, field in next, ThemeFields do
            if field == "VideoLink" then
                theme[field] = self.Library.Options[field].Value
            else
                theme[field] = self.Library.Options[field].Value:ToHex()
            end
        end
        writefile(self.Folder .. '/themes/' .. file .. '.json', HttpService:JSONEncode(theme))
    end

    function ThemeManager:Delete(name)
        if not name then return false, 'no config file is selected' end
        local file = self.Folder .. '/themes/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end
        local success = pcall(delfile, file)
        if not success then return false, 'delete file error' end
        return true
    end

    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. '/themes')
        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                local pos = file:find('.json', 1, true)
                local start = pos
                local char = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end
                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end
        return out
    end

    function ThemeManager:CreateThemeManager(groupbox)
        groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
        groupbox:AddLabel('Main color')    :AddColorPicker('MainColor', { Default = self.Library.MainColor })
        groupbox:AddLabel('Accent color')  :AddColorPicker('AccentColor', { Default = self.Library.AccentColor })
        groupbox:AddLabel('Outline color') :AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
        groupbox:AddLabel('Font color')    :AddColorPicker('FontColor', { Default = self.Library.FontColor })
        groupbox:AddInput('VideoLink', { Text = '.webm Video Background (Link)', Default = self.Library.VideoLink })

        local ThemesArray = {}
        for Name in next, self.BuiltInThemes do
            table.insert(ThemesArray, Name)
        end
        table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

        groupbox:AddDivider()
        groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })
        groupbox:AddButton('Set as default', function()
            self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
            self.Library:Notify(string.format('Set default theme to %q', self.Library.Options.ThemeManager_ThemeList.Value))
        end)

        self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
            self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
        end)

        groupbox:AddDivider()
        groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
        groupbox:AddButton('Create theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeName.Value
            if name:gsub(" ", "") == "" then
                self.Library:Notify("Invalid theme name (empty)", 2)
                return
            end
            self:SaveCustomTheme(name)
            self.Library:Notify(string.format("Created theme %q", name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        groupbox:AddDivider()
        groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
        groupbox:AddButton('Load theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value
            self:ApplyTheme(name)
            self.Library:Notify(string.format('Loaded theme %q', name))
        end)
        groupbox:AddButton('Overwrite theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value
            self:SaveCustomTheme(name)
            self.Library:Notify(string.format('Overwrote config %q', name))
        end)
        groupbox:AddButton('Delete theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value
            local success, err = self:Delete(name)
            if not success then
                self.Library:Notify('Failed to delete theme: ' .. tostring(err))
                return
            end
            self.Library:Notify(string.format('Deleted theme %q', name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton('Refresh list', function()
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton('Set as default', function()
            if self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil and self.Library.Options.ThemeManager_CustomThemeList.Value ~= '' then
                self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
                self.Library:Notify(string.format('Set default theme to %q', self.Library.Options.ThemeManager_CustomThemeList.Value))
            end
        end)
        groupbox:AddButton('Reset default', function()
            local success = pcall(delfile, self.Folder .. '/themes/default.txt')
            if not success then
                self.Library:Notify('Failed to reset default: delete file error')
                return
            end
            self.Library:Notify('Set default theme to nothing')
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        self:LoadDefault()

        local function UpdateTheme() self:ThemeUpdate() end
        self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
        self.Library.Options.MainColor:OnChanged(UpdateTheme)
        self.Library.Options.AccentColor:OnChanged(UpdateTheme)
        self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
        self.Library.Options.FontColor:OnChanged(UpdateTheme)
    end

    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, 'ThemeManager:CreateGroupBox -> Must set ThemeManager.Library first!')
        return tab:AddLeftGroupbox('Themes')
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, 'ThemeManager:ApplyToTab -> Must set ThemeManager.Library first!')
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, 'ThemeManager:ApplyToGroupbox -> Must set ThemeManager.Library first!')
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

getgenv().LinoriaThemeManager = ThemeManager
return ThemeManager
