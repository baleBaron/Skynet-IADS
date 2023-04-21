
do

-- ambush check, only go live if SAM is behind a contacts 9-3 line.
function SkynetIADSSamSite:setGoLiveNineLine(enable)
	if not enable then
		self:removeGoLiveConstraint("9line")
	else
		self:addGoLiveConstraint("9line",
		function (contact)
		local contactHeading 	= mist.getHeading(contact:getDCSRepresentation())
		local contactHeadingSAM = mist.utils.getHeadingPoints(contact:getDCSRepresentation():getPosition().p, mist.getLeadPos(self:getDCSRepresentation()))
		local absDiff 			= math.abs(mist.utils.toDegree(contactHeading) - mist.utils.toDegree(contactHeadingSAM))
		
		if absDiff > 180 then 
			absDiff = absDiff - 360 
		end
		
		return absDiff > 100
		end)
	end
	
	return self
end

-- ambush check, only go live if buddy is live, buddy is preferably not mobile
function SkynetIADSSamSite:setGoLiveWithBuddy(buddySAM)
	self:addGoLiveConstraint("golivewithbuddy",
	function (contact)
		return buddySAM.aiState
	end)
	
	return self
end

end

redIADS = SkynetIADS:create('RED')

local iadsDebug = redIADS:getDebugSettings()
iadsDebug.IADSStatus = true
iadsDebug.radarWentDark = true
iadsDebug.contacts = true
iadsDebug.radarWentLive = true
iadsDebug.noWorkingCommmandCenter = false
iadsDebug.ewRadarNoConnection = false
iadsDebug.samNoConnection = false
iadsDebug.jammerProbability = true
iadsDebug.addedEWRadar = false
iadsDebug.hasNoPower = false
iadsDebug.harmDefence = true
iadsDebug.samSiteStatusEnvOutput = true
iadsDebug.earlyWarningRadarStatusEnvOutput = true
iadsDebug.commandCenterStatusEnvOutput = true

redIADS:addEarlyWarningRadarsByPrefix('REW')
redIADS:addSAMSitesByPrefix('RSAM')


-- hide, shoot, scoot tactics: SkynetIADSSamSite:setActMobile() enable true/false, maxEmissionTime in seconds, minScootDistance in meters, maxScootDistance in meters, table of pre-defined triggerZoneNames
redIADS:getSAMSitesByNatoName("SA-11"):setActMobile(true,60*5,5000,7500,nil) 	-- bit longer emission time, will stand its ground
redIADS:getSAMSitesByNatoName("SA-6"):setActMobile(true,60*1.25,500,8000)	-- short emission time = light on its feet

-- use different emission times to avoid having all SAMs relocate at the same time
redIADS:getSAMSiteByGroupName("RSAM BUK-B"):setActMobile(true,60*20,10000,15000) -- this BUK battery will not be as light on its feet, but will move greater distances, it is allowed to call setActMobile to change parameters

-- set pre-defined locations, this is not needed, if no pre-defined zones are supplied SAM will pick arbitrary direction
redIADS:getSAMSiteByGroupName("RSAM KUB-B Zones"):setMobileScootZones({"KUB-B Zone-1","KUB-B Zone-2","KUB-B Zone-3","KUB-B Zone-4","KUB-B Zone-5"})

--setup mobile point defences for one SA-11
redIADS:getSAMSiteByGroupName("RSAM BUK-A"):addPointDefence(redIADS:getSAMSiteByGroupName("RSAM BUK-A PD"):setActMobile(true))

--this part has nothing to do with hide, shoot and scoot DEMO. it is purely for ambushing tactics
--redIADS:getSAMSitesByNatoName("SA-6"):setGoLiveWithBuddy(redIADS:getSAMSiteByGroupName("RSAM BUK-A"))
redIADS:getSAMSitesByNatoName("SA-6"):setGoLiveNineLine(true)

redIADS:addRadioMenu()
redIADS:activate()

