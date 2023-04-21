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
	sam.mobileSiteZone = nil -- current site we are moving towards
	sam.mobileScootZones = nil -- pre defined nice spots to select, may be nil
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
		
		--this way we make all units aware of the first contact that triggered this SAM site
		for i, unit in pairs(self:getDCSRepresentation():getUnits()) do 
			unit:getController():knowTarget(contact:getDCSRepresentation())
		end
	end
end

function SkynetIADSSamSite:getActMobile()
	return self.actMobile
end

function SkynetIADSSamSite:setActMobile(enable, emissionTimeMax, scootDistanceMin, scootDistanceMax, scootZones)
	if not self.actMobile and enable then
		self.actMobile = true
		if emissionTimeMax then self.mobilePhaseEmissionTimeMax = emissionTimeMax end
		if scootDistanceMin then self.mobileScootDistanceMin = scootDistanceMin end
		if scootDistanceMax then self.mobileScootDistanceMax = scootDistanceMax end
		self.mobileScootZones = scootZones
		self.mobilePhaseEvaluateTaskID = mist.scheduleFunction(SkynetIADSSamSite.evaluateMobilePhase,{self},1, 5)
	elseif self.actMobile and not enable then
		--TODO: implement this
		self.actMobile = false
	end	
	return self
end

function SkynetIADSSamSite:setMobileScootZones(triggerZoneNameTable)
	self.mobileScootZones = triggerZoneNameTable
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
		self.mobilePhaseEvaluateTaskID = mist.scheduleFunction(SkynetIADSSamSite.evaluateMobilePhase,{self},1,5)
	end
	self.mobileSiteZone = newSiteZone
	
	local formation
	local ignoreRoads
	if land.getSurfaceType({x = self.mobileSiteZone.point.x,y = self.mobileSiteZone.point.z}) == land.SurfaceType.ROAD then
		formation = "On road"
		ignoreRoads = false
	else
		formation = "Diamond"
		ignoreRoads = true
	end
	
	local mistZone = {}
	mistZone.point = self.mobileSiteZone.point
	mistZone.radius = 1 --move dead center
	mist.groupToRandomZone(self:getDCSRepresentation(), mistZone, formation, nil, 80, ignoreRoads)
	
	--have mobile point defences follow, if possible
	for i = 1, #self.pointDefences do
		if self.pointDefences[i]:getActMobile() then
			self.pointDefences[i]:relocateNow(newSiteZone)
		end
	end
end

function SkynetIADSSamSite:selectNewLocation()
	local newZone
	if self.mobileScootZones == nil then --no pre-defined zones found, pick arbitrary direction, prefer to be on road
		local currentPosition = mist.getLeadPos(self:getDCSRepresentation())
		local vec2Rand
		
		for i = 1, 10 do
			vec2Rand = mist.getRandPointInCircle(currentPosition,self.mobileScootDistanceMax, self.mobileScootDistanceMin)
			
			if i <= 5 then
				local vec2Road = {}
				local distance
				vec2Road.x, vec2Road.y = land.getClosestPointOnRoads("roads",vec2Rand.x,vec2Rand.y)
				distance = mist.utils.get2DDist(currentPosition, vec2Road)
				if distance < self.mobileScootDistanceMax and distance > self.mobileScootDistanceMin then
					vec2Rand = vec2Road
				end
			end
			
			local surfaceType = land.getSurfaceType(vec2Rand)
			if (surfaceType == land.SurfaceType.LAND or surfaceType == land.SurfaceType.ROAD) and mist.terrainHeightDiff(vec2Rand,50) < 5 then
				break
			end
		end
		
		newZone = {}
		newZone.radius = 50
		newZone.point = {x = vec2Rand.x, y = land.getHeight(vec2Rand), z = vec2Rand.y}
	else -- use pre-defined zones
		--TODO: keep track of hot spots 
		--TODO: coordinate within battalion
		local currentPosition = mist.getLeadPos(self:getDCSRepresentation())
		for i = 1, 10 do
			newZone = mist.DBs.zonesByName[self.mobileScootZones[math.random(1, #self.mobileScootZones)]]
			local distance = mist.utils.get3DDist(currentPosition, newZone.point)
			if distance > self.mobileScootDistanceMin and distance < self.mobileScootDistanceMax then
				break
			end
		end
	end
	
	return newZone
end

function SkynetIADSSamSite.evaluateMobilePhase(self)
	if self:isDestroyed() then 
		if self.mobilePhaseEvaluateTaskID ~= nil then
			mist.removeFunction(self.mobilePhaseEvaluateTaskID)
			self.mobilePhaseEvaluateTaskID = nil
		end
		return 
	end

	if self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_HIDE and self.goLiveTime > 0 then
		--emission has begun, entering shooting phase
		self.mobilePhase = SkynetIADSSamSite.MOBILE_PHASE_SHOOT
		mist.removeFunction(self.mobilePhaseEvaluateTaskID)
		self.mobilePhaseEvaluateTaskID = mist.scheduleFunction(SkynetIADSSamSite.evaluateMobilePhase,{self},self.goLiveTime + self.mobilePhaseEmissionTimeMax, 5)
	elseif self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_SHOOT and not self:hasMissilesInFlight() and not self:getIsAPointDefence() then
		--find a new location
		self:relocateNow(self:selectNewLocation())
	elseif self.mobilePhase == SkynetIADSSamSite.MOBILE_PHASE_SCOOT then
		--check if we are close enough to our destination
		--TODO: better check
		if mist.utils.get3DDist(mist.getLeadPos(self:getDCSRepresentation()), self.mobileSiteZone.point) < self.mobileSiteZone.radius then
			--close enough, setup and wait
			self.mobilePhase = SkynetIADSSamSite.MOBILE_PHASE_HIDE
			self.goLiveTime = 0
			self:removeGoLiveConstraint("relocating")
			self:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)	
			self:getController():setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
		end
	end
end

end
