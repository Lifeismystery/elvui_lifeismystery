local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');
local LSM = LibStub("LibSharedMedia-3.0");
UF.LSM = LSM
--Cache global variables
--Lua functions
local random = random
--WoW API / Variables
local CreateFrame = CreateFrame
local UnitIsTapDenied = UnitIsTapDenied
local UnitReaction = UnitReaction
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

function UF:Construct_HealthBar(frame, bg, text, textPos)
	local health = CreateFrame('StatusBar', nil, frame)
	health.health_backdrop = CreateFrame('StatusBar', nil, health)
    health.health_backdrop:SetReverseFill(true)
	UF['statusbars'][health] = true

	health:SetFrameLevel(10) --Make room for Portrait and Power which should be lower by default
	health.PostUpdate = self.PostUpdateHealth
	
	--[[if bg then
		health.bg = health:CreateTexture(nil, 'BORDER')
		health.bg:SetAllPoints()
		health.bg:SetTexture(E["media"].blankTex)
		health.bg.multiplier = 0.25
	end]]

	if text then
		health.value = frame.RaisedElementParent:CreateFontString(nil, 'OVERLAY')
		UF:Configure_FontString(health.value)

		local x = -2
		if textPos == 'LEFT' then
			x = 2
		end

		health.value:Point(textPos, health, textPos, x, 0)
	end

	health.colorTapping = true
	health.colorDisconnected = true
	health:CreateBackdrop('Default', nil, nil, self.thinBorders, true)

	return health
end

function UF:Configure_HealthBar(frame)
	if not frame.VARIABLES_SET then return end
	local db = frame.db
	local health = frame.Health

	health.Smooth = self.db.smoothbars

	--Text
	if health.value then
		local attachPoint = self:GetObjectAnchorPoint(frame, db.health.attachTextTo)
		health.value:ClearAllPoints()
		health.value:Point(db.health.position, attachPoint, db.health.position, db.health.xOffset, db.health.yOffset)
		frame:Tag(health.value, db.health.text_format)
	end

	--Colors
	health.colorSmooth = nil
	health.colorHealth = nil
	health.colorClass = nil
	health.colorReaction = nil

	if db.colorOverride and db.colorOverride == "FORCE_ON" then
		health.colorClass = true
		health.colorReaction = true
	elseif db.colorOverride and db.colorOverride == "FORCE_OFF" then
		if self.db['colors'].colorhealthbyvalue == true then
			health.colorSmooth = true
		else
			health.colorHealth = true
		end
	else
		if self.db.colors.healthclass ~= true then
			if self.db.colors.colorhealthbyvalue == true then
				health.colorSmooth = true
			else
				health.colorHealth = true
			end
		else
			health.colorClass = (not self.db.colors.forcehealthreaction)
			health.colorReaction = true
		end
	end

	--Position
	health:ClearAllPoints()
	health.health_backdrop:ClearAllPoints()
	if frame.ORIENTATION == "LEFT" then
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - (frame.PVPINFO_WIDTH or 0), -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			health.health_backdrop:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - (frame.PVPINFO_WIDTH or 0), -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			
			if frame.USE_POWERBAR_OFFSET then
				health:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET)
				health.health_backdrop:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET)
			elseif frame.POWERBAR_DETACHED or not frame.USE_POWERBAR or frame.USE_INSET_POWERBAR then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
			elseif frame.USE_MINI_POWERBAR then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.SPACING + (frame.POWERBAR_HEIGHT/2))
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.SPACING + (frame.POWERBAR_HEIGHT/2))
			else
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
			end
	elseif frame.ORIENTATION == "RIGHT" then
			health:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING + (frame.PVPINFO_WIDTH or 0), -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			health.health_backdrop:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING + (frame.PVPINFO_WIDTH or 0), -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)

			if frame.USE_POWERBAR_OFFSET then
				health:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
				health:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET)
				health.health_backdrop:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
				health.health_backdrop:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET)
			elseif frame.POWERBAR_DETACHED or not frame.USE_POWERBAR or frame.USE_INSET_POWERBAR then
				health:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
				health.health_backdrop:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
			elseif frame.USE_MINI_POWERBAR then
				health:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.SPACING + (frame.POWERBAR_HEIGHT/2))
				health.health_backdrop:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.SPACING + (frame.POWERBAR_HEIGHT/2))
			else
				health:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
				health.health_backdrop:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.PORTRAIT_WIDTH - frame.BORDER - frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
			end
	elseif frame.ORIENTATION == "MIDDLE" then
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - (frame.PVPINFO_WIDTH or 0), -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			health.health_backdrop:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - (frame.PVPINFO_WIDTH or 0), -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			
			if frame.USE_POWERBAR_OFFSET then
				health:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET, frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET)
				health.health_backdrop:Point("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET, frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET)
			elseif frame.POWERBAR_DETACHED or not frame.USE_POWERBAR or frame.USE_INSET_POWERBAR then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
			elseif frame.USE_MINI_POWERBAR then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.BORDER + frame.SPACING, frame.SPACING + (frame.POWERBAR_HEIGHT/2))
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.BORDER + frame.SPACING, frame.SPACING + (frame.POWERBAR_HEIGHT/2))
			else
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
				health.health_backdrop:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING, frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET)
			end
	end
	
	--[[health.bg:ClearAllPoints()
	if not frame.USE_PORTRAIT_OVERLAY then
		health.bg:SetParent(health)
		health.bg:SetAllPoints()
	else
		health.bg:Point('BOTTOMLEFT', health:GetStatusBarTexture(), 'BOTTOMRIGHT')
		health.bg:Point('TOPRIGHT', health)
		health.bg:SetParent(frame.Portrait.overlay)
	end]]
	
	
	if db.health then
		--Party/Raid Frames allow to change statusbar orientation
		if db.health.orientation then
			health:SetOrientation(db.health.orientation)
			health.health_backdrop:SetOrientation(db.health.orientation)
		end

		--Party/Raid Frames can toggle frequent updates
		if db.health.frequentUpdates then
			health.frequentUpdates = db.health.frequentUpdates
			health.health_backdrop.frequentUpdates = db.health.frequentUpdates
		end
	end

	--Transparency Settings
	--UF:ToggleTransparentStatusBar(UF.db.colors.transparentHealth, frame.Health, frame.Health.bg, (frame.USE_PORTRAIT and frame.USE_PORTRAIT_OVERLAY) ~= true)

	frame:UpdateElement("Health")
end

function UF:GetHealthBottomOffset(frame)
	local bottomOffset = 0
	if frame.USE_POWERBAR and not frame.POWERBAR_DETACHED and not frame.USE_INSET_POWERBAR then
		bottomOffset = bottomOffset + frame.POWERBAR_HEIGHT - (frame.BORDER-frame.SPACING)
	end
	if frame.USE_INFO_PANEL then
		bottomOffset = bottomOffset + frame.INFO_PANEL_HEIGHT - (frame.BORDER-frame.SPACING)
	end

	return bottomOffset
end

function UF:PostUpdateHealth(unit, min, max)
	local parent = self:GetParent()
	if parent.isForced then
		min = random(1, max)
		self:SetValue(min)
	end
	
	self.health_backdrop:SetMinMaxValues(0,max)
  
 	if(disconnected) then
		self.health_backdrop:SetValue(0)
 	else
		self.health_backdrop:SetValue(max-min)
	end

	if parent.ResurrectIndicator then
		parent.ResurrectIndicator:SetAlpha(min == 0 and 1 or 0)
	end

	local r, g, b, a = self:GetStatusBarColor()
	local colors = E.db['unitframe']['colors'];
	self.backdrop.backdropTexture:SetVertexColor(0,0,0,0)
	self.backdrop:SetBackdropColor(0,0,0,0)

	if not UF.db.colors.inverthealth then
		self:SetStatusBarColor(colors.health.r, colors.health.g, colors.health.b, colors.health.a)
		self.health_backdrop:SetStatusBarColor(P.general.backdropcolor) 
		if (((colors.healthclass == true and colors.colorhealthbyvalue == true) or (colors.colorhealthbyvalue and parent.isForced)) and not UnitIsTapDenied(unit)) then
			local newr, newg, newb = ElvUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0, r, g, b)
			local newa = colors.health.a
			self:SetStatusBarColor(newr, newg, newb, newa)
		elseif colors.healthclass then
			local reaction = UnitReaction(unit, 'player')
			local t
			if UnitIsPlayer(unit) then
				local _, class = UnitClass(unit)
				t = parent.colors.class[class]
			elseif reaction then
				t = parent.colors.reaction[reaction]
			end
			if t then
				self:SetStatusBarColor(t[1], t[2], t[3], t[4])
			end
		else 	
			self:SetStatusBarColor(colors.health.r, colors.health.g, colors.health.b, colors.health.a)
		end
		if colors.classbackdrop then
			local reaction = UnitReaction(unit, 'player')
			local t
			if UnitIsPlayer(unit) then
				local _, class = UnitClass(unit)
				t = parent.colors.class[class]
			elseif reaction then
				t = parent.colors.reaction[reaction]
			end
			if t then
				self.health_backdrop:SetStatusBarColor(t[1], t[2], t[3], t[4])
			end
		end
		if colors.customhealthbackdrop and not colors.classbackdrop then
			self.health_backdrop:SetStatusBarColor(colors.health_backdrop.r, colors.health_backdrop.g, colors.health_backdrop.b,colors.health_backdrop.a) 
		end	
		if colors.useDeadBackdrop and UnitIsDeadOrGhost(unit) then
			local backdrop = colors.health_backdrop_dead
			self.health_backdrop:SetStatusBarColor(backdrop.r, backdrop.g, backdrop.b, backdrop.a) 
		end
	else
		self:SetStatusBarColor(P.general.backdropcolor) 
		self.health_backdrop:SetStatusBarColor(colors.health.r, colors.health.g, colors.health.b, colors.health.a)
		if (((colors.healthclass == true and colors.colorhealthbyvalue == true) or (colors.colorhealthbyvalue and parent.isForced)) and not UnitIsTapDenied(unit)) then
			local newr, newg, newb = ElvUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0, r, g, b)
			local newa = colors.health.a
			self.health_backdrop:SetStatusBarColor(newr, newg, newb, newa)
		elseif colors.healthclass then
			local reaction = UnitReaction(unit, 'player')
			local t
			if UnitIsPlayer(unit) then
				local _, class = UnitClass(unit)
				t = parent.colors.class[class]
			elseif reaction then
				t = parent.colors.reaction[reaction]
			end
			if t then
				self.health_backdrop:SetStatusBarColor(t[1], t[2], t[3], t[4])
			end
		else 	
			self.health_backdrop:SetStatusBarColor(colors.health.r, colors.health.g, colors.health.b, colors.health.a or 1.0)
		end		
		if colors.classbackdrop then
			local reaction = UnitReaction(unit, 'player')
			local t
			if UnitIsPlayer(unit) then
				local _, class = UnitClass(unit)
				t = parent.colors.class[class]
			elseif reaction then
				t = parent.colors.reaction[reaction]
			end
			if t then
				self:SetStatusBarColor(t[1], t[2], t[3], t[4])
			end
		end		
		if colors.customhealthbackdrop and not colors.classbackdrop then
			self:SetStatusBarColor(colors.health_backdrop.r, colors.health_backdrop.g, colors.health_backdrop.b,colors.health_backdrop.a) 
		end	
		if colors.useDeadBackdrop and UnitIsDeadOrGhost(unit) then
			local backdrop = colors.health_backdrop_dead
			self:SetStatusBarColor(backdrop.r, backdrop.g, backdrop.b, backdrop.a) 
		end	
	end

	if UF.db.colors.texture_healh then
		self:SetStatusBarTexture(LSM:Fetch("statusbar", UF.db.statusbar))	
	else
        self:SetStatusBarTexture(self:GetStatusBarColor())
	end
	
	if UF.db.colors.backdropTex_healh then
		self.health_backdrop:SetStatusBarTexture(LSM:Fetch("statusbar", UF.db.statusbar_backdrop))		
	else
		self.health_backdrop:SetStatusBarTexture(self.health_backdrop:GetStatusBarColor())
	end
	
end