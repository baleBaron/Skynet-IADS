do

SkynetIADSSamSite = {}
SkynetIADSSamSite = inheritsFrom(SkynetIADSAbstractRadarElement)

SkynetIADSSamSite.MOBILE_PHASE_HIDE = 1
SkynetIADSSamSite.MOBILE_PHASE_SHOOT = 2
SkynetIADSSamSite.MOBILE_PHASE_SCOOT = 3

function SkynetIADSSamSite:create(samGroup, iads)
	local sam = self:superClass():create(samGroup, iads)
	setmetatable(sam, self)
	self.__index = self
	sam.targetsInRange = false
	sam.goLiveConstraints = {}
	sam.actMobile = false
	sam.mobilePhase = SkynetIADSSamSite.MOBILE_PHASE_HIDE
	sam.mobileSiteZone = nil
	sam.mobilePhaseEvaluateTaskID = nil
	sam.mobilePhaseEmissionTimeMax = 60*3     -- max time from going live until packing up and relocating
	sam.mobileScootDistanceMin = 1000
	sam.mobileScootDistanceMax = 2000
	return sam
end

function SkynetIADSSamSite:addGoLiveConstraint(constraintName, constraint)
	self.goLiveConstraints[constraintName] = constraint
end

function SkynetIADSAbstractRadarElement:areGoLiveConstraintsSatisfied(contact)
	for constraintName, constraint in pairs(self.goLiveConstraints) do
		if ( constraint(contact) ~= true ) then
			return false
		end
	end
	return true
end

function SkynetIADSAbstractRadarElement:removeGoLiveConstraint(constraintName)
	local constraints = {}
	for cName, constraint in pairs(self.goLiveConstraints) do
		if cName ~= constraintName then
			constraints[cName] = constraint
		end
	end
	self.goLiveConstraints = constraints
end

function SkynetIADSAbstractRadarElement:getGoLiveConstraints()
	return self.goLiveConstraints
end

function SkynetIADSSamSite:isDestroyed()
	local isDestroyed = true
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		if launcher:isExist() == true then
			isDestroyed = false
		end
	end
	local radars = self:getRadars()
	for i = 1, #radars do
		local radar = radars[i]
		if radar:isExist() == true then
			isDestroyed = false
		end
	end	
	return isDestroyed
end

function SkynetIADSSamSite:targetCycleUpdateStart()
	self.targetsInRange = false
end

function SkynetIADSSamSite:targetCycleUpdateEnd()
	if self.targetsInRange == false and self.actAsEW == false and self:getAutonomousState() == false and self:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI then
		self:goDark()
	end
end

function SkynetIADSSamSite:informOfContact(contact)
	-- we make sure isTargetInRange (expensive call) is only triggered if no previous calls to this method resulted in targets in range
	if ( self.targetsInRange == false and self:areGoLiveConstraintsSatisfied(contact) == true and self:isTargetInRange(contact) and ( contact:isIdentifiedAsHARM() == false or ( contact:isIdentifiedAsHARM() == true and self:getCanEngageHARM() == true ) ) ) then
		self:goLive()
		self.targetsInRange = true
	end
end

function SkynetIADSSamSite:getActMobile()
	return self.actMobile
end

function SkynetIADSSamSite:setActMobile(enable, emissionTimeMax, scootDistanceMin, scootDistanceMax)
	if not self.actMobile and enable then
		self.actMobile = true
		if emissionTimeMax then self.mobilePhaseEmissionTimeMax = emissionTimeMax end
		if scootDistanceMin then self.mobileScootDistanceMin = scootDistanceMin end
		if scootDistanceMax then self.mobileScootDistanceMax = scootDistanceMax end
		self.mobilePhaseEvaluateTaskID = mist.scheduleFunction(SkynetIADSSamSite.evaluateMobilePhase,{self},1, 5)
	elseif self.actMobile and not enable then
		--TODO: implement this
		self.actMobile = false
	end	
end

function SkynetIADSSamSite:relocateNow(newSiteZone)
	if self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_HIDE
	or self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_SHOOT then
		self.mobilePhase = SkynetIADSSamSite.MOBILE_PHASE_SCOOT
		self:goDark()
		self:addGoLiveConstraint("relocating",function () return false end)
		self:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)	
		self:getController():setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD)
			
		if self.mobilePhaseEvaluateTaskID ~= nil then 
			mist.removeFunction(self.mobilePhaseEvaluateTaskID) 
		end
		self.mobilePhaseEvaluateTaskID = mist.scheduleFunction(SkynetIADSSamSite.evaluateMobilePhase,{self},timer.getTime() + 60*5,5)
	end
	self.mobileSiteZone = newSiteZone
	mist.groupToRandomZone(self:getDCSRepresentation(), self.mobileSiteZone, "diamond", nil, 80, true)
	
	--TODO: have mobile point defences follow, if possible
end

function SkynetIADSSamSite.evaluateMobilePhase(self)
	if self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_HIDE and self.goLiveTime > 0 then
		--emission has begun, entering shooting phase
		self.mobilePhase = SkynetIADSSamSite.MOBILE_PHASE_SHOOT
		mist.removeFunction(self.mobilePhaseEvaluateTaskID)
		self.mobilePhaseEvaluateTaskID = mist.scheduleFunction(SkynetIADSSamSite.evaluateMobilePhase,{self},self.goLiveTime + self.mobilePhaseEmissionTimeMax, 5)
	elseif self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_SHOOT and not self:hasMissilesInFlight() then
		--find a new location TODO: implement possibility to supply pre-defined locations
		local vec2
		for i = 1, 10 do
			vec2 = mist.getRandPointInCircle(mist.getLeadPos(self:getDCSRepresentation()),self.mobileScootDistanceMax, self.mobileScootDistanceMin)
			if land.getSurfaceType(vec2) == land.SurfaceType.LAND and mist.terrainHeightDiff(vec2,50) < 5 then
				break
			end
		end
		
		local newZone = {}
		newZone.radius = 50
		newZone.point = {x = vec2.x, y = land.getHeight(vec2), z = vec2.y}

		self:relocateNow(newZone)
	elseif self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_SCOOT then
		--check if we are close enough to our destination
		if mist.utils.get3DDist(mist.getLeadPos(self:getDCSRepresentation()), self.mobileSiteZone.point) < self.mobileSiteZone.radius then
			--new place, setup and wait
			self.mobilePhase = SkynetIADSSamSite.MOBILE_PHASE_HIDE
			self.goLiveTime = 0
			self:removeGoLiveConstraint("relocating")
			self:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)	
			self:getController():setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
		end
	end
end

end
