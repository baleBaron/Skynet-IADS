do

TestSkynetIADSSAMSite = {}

function TestSkynetIADSSAMSite:setUp()
	self.skynetIADS = SkynetIADS:create()
	if self.samSiteName then
		local samSite = Group.getByName(self.samSiteName)
		self.samSite = SkynetIADSSamSite:create(samSite, self.skynetIADS)
		
		-- we overrite this method since it returns radar contacts in the DCS world which mess up the tests.
		function self.samSite:getDetectedTargets()
			return {}
		end
		
		self.samSite:setupElements()
		self.samSite:goLive()
	end
end

function TestSkynetIADSSAMSite:tearDown()
	if self.samSite then	
		self.samSite:goDark()
		self.samSite:cleanUp()
	end
	if self.skynetIADS then
		self.skynetIADS:deactivate()
	end
	self.samSite = nil
	self.samSiteName = nil
end


function TestSkynetIADSSAMSite:testCompleteDestructionOfSamSiteAndLoadDestroyedSAMSiteInToIADS()

	local samSite = SkynetIADSSamSite:create(Group.getByName("Destruction-test-sam"), self.skynetIADS):setActAsEW(true)
	samSite:setupElements()

	local samSite2 = SkynetIADSSamSite:create(Group.getByName('prefixtest-sam'), self.skynetIADS)
	samSite2:setupElements()
	
	samSite:addChildRadar(samSite2)
	samSite2:addParentRadar(samSite)
	
	lu.assertEquals(samSite2:getAutonomousState(), false)
	lu.assertEquals(samSite:isDestroyed(), false)
	lu.assertEquals(samSite:hasWorkingRadar(), true)

	local radars = samSite:getRadars()
	for i = 1, #radars do
		local radar = radars[i]
		trigger.action.explosion(radar:getDCSRepresentation():getPosition().p, 500)
		--we simulate a call to the event, since in game will be triggered to late to for later checks in this unit test
		samSite:onEvent(createDeadEvent())
	end	
	local launchers = samSite:getLaunchers()
	for i = 1, #launchers do
		local launcher = launchers[i]
		trigger.action.explosion(launcher:getDCSRepresentation():getPosition().p, 900)
		--we simulate a call to the event, since in game will be triggered to late to for later checks in this unit test
		samSite:onEvent(createDeadEvent())
	end	
	lu.assertEquals(samSite:isActive(), false)
	lu.assertEquals(samSite:isDestroyed(), true)
	lu.assertEquals(samSite:hasWorkingRadar(), false)

	lu.assertEquals(samSite:getRemainingNumberOfMissiles(), 0)
	lu.assertEquals(samSite:getInitialNumberOfMissiles(), 6)
	lu.assertEquals(samSite:hasRemainingAmmo(), false)
	
	--after destruction of samSite acting as EW samSite2 must be autonomous:
	lu.assertEquals(samSite2:getAutonomousState(), true)
	
	--test build SAM with destroyed elements
	samSite:cleanUp()
	local samSite = SkynetIADSSamSite:create(Group.getByName("Destruction-test-sam"), self.skynetIADS)
	samSite:setupElements()
	lu.assertEquals(samSite:getNatoName(), "UNKNOWN")
	lu.assertEquals(#samSite:getRadars(), 0)
	lu.assertEquals(#samSite:getLaunchers(), 0)
	
	samSite:cleanUp()
	samSite2:cleanUp()
end	

function TestSkynetIADSSAMSite:testInformOfContactInRange()
	self.samSiteName = "SAM-SA-6"
	self:setUp()
	local mockContact = {}
	function mockContact:isIdentifiedAsHARM()
		return false
	end
	function self.samSite:isTargetInRange(target)
		lu.assertIs(target, mockContact)
		return true
	end
	self.samSite:goDark()
	self.samSite:targetCycleUpdateStart()
	lu.assertEquals(self.samSite:isActive(), false)
	self.samSite:informOfContact(mockContact)
	lu.assertEquals(self.samSite:isActive(), true)
	self.samSite:targetCycleUpdateEnd()
	lu.assertEquals(self.samSite:isActive(), true)
end

function TestSkynetIADSSAMSite:testInformOfContactNotInRange()
	self.samSiteName = "SAM-SA-6"
	self:setUp()
	local mockContact = {}
	function self.samSite:isTargetInRange(target)
		lu.assertIs(target, mockContact)
		return false
	end
	self.samSite:goDark()
	self.samSite:targetCycleUpdateStart()
	lu.assertEquals(self.samSite:isActive(), false)
	self.samSite:informOfContact(mockContact)
	lu.assertEquals(self.samSite:isActive(), false)
	self.samSite:targetCycleUpdateEnd()
	lu.assertEquals(self.samSite:isActive(), false)
end

function TestSkynetIADSSAMSite:testInformOfHARMContactSAMCanEngageHARM()
	self.samSiteName = "test-SAM-SA-2-test"
	self:setUp()
	function self.samSite:isTargetInRange(contact)
		return true
	end
	local mockTarget = {}
	function mockTarget:isIdentifiedAsHARM()
		return true
	end
	self.samSite:goDark()
	lu.assertEquals(self.samSite:isActive(), false)
	self.samSite:setCanEngageHARM(true)
	self.samSite:informOfContact(mockTarget)
	lu.assertEquals(self.samSite:isActive(), true)
	
end

function TestSkynetIADSSAMSite:testInformOfHARMContactSAMCanNotEngageHARM()
	self.samSiteName = "test-SAM-SA-2-test"
	self:setUp()
	function self.samSite:isTargetInRange(contact)
		return true
	end
	local mockTarget = {}
	function mockTarget:isIdentifiedAsHARM()
		return true
	end
	self.samSite:goDark()
	lu.assertEquals(self.samSite:isActive(), false)
	self.samSite:setCanEngageHARM(false)
	self.samSite:informOfContact(mockTarget)
	lu.assertEquals(self.samSite:isActive(), false)
	
end

function TestSkynetIADSSAMSite:testSA2InformOfContactTargetNotInRange()
	self.samSiteName = "test-SAM-SA-2-test"
	self:setUp()
	self.samSite:goDark()
	local target = IADSContactFactory('test-not-in-firing-range-of-sa-2')
	self.samSite:informOfContact(target)
	lu.assertEquals(self.samSite:isTargetInRange(target), false)
	lu.assertEquals(self.samSite:isActive(), false)
end

function TestSkynetIADSSAMSite:testSA2InforOfContactInSearchRangeSAMSiteGoLiveWhenSetToSearchRange()
	self.samSiteName = "test-SAM-SA-2-test"
	self:setUp()
	self.samSite:goDark()
	lu.assertEquals(self.samSite:isActive(), false)
	self.samSite:setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE)
	lu.assertIs(self.samSite:getEngagementZone(), SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE)
	local target = IADSContactFactory('test-not-in-firing-range-of-sa-2')
	self.samSite:informOfContact(target)
	lu.assertEquals(self.samSite:isActive(), true)

end

function TestSkynetIADSSAMSite:testInformOfContactMultipleTimesOnlyOneIsTargetInRangeCall()
	self.samSiteName = "SAM-SA-6"
	self:setUp()
	
	local mockContact = {}
	function mockContact:isIdentifiedAsHARM()
		return false
	end
	local numTimesCalledTargetInRange = 0
	
	function self.samSite:isTargetInRange(target)
		numTimesCalledTargetInRange = numTimesCalledTargetInRange + 1
		lu.assertIs(target, mockContact)
		return true
	end
	self.samSite:targetCycleUpdateStart()
	self.samSite:informOfContact(mockContact)
	self.samSite:informOfContact(mockContact)
	lu.assertEquals(numTimesCalledTargetInRange, 1)
end

function TestSkynetIADSSAMSite:testSAMStaysActiveWhenInAutonomousMode()
	self.samSiteName = "test-SAM-SA-2-test"
	self:setUp()
	lu.assertEquals(self.samSite:isActive(), true)
	lu.assertEquals(self.samSite:getAutonomousState(), true)
	self.samSite:targetCycleUpdateEnd()
	lu.assertEquals(self.samSite:isActive(), true)
end

function TestSkynetIADSSAMSite:testGoLiveConstraint()
	self.samSiteName = "SAM-SA-2"
	self:setUp()
	local contact = IADSContactFactory('test-in-firing-range-of-sa-2')
	
	local function goLiveConstraint(contact)
		return ( contact:getHeightInFeetMSL() > 4000 )
	end

	lu.assertEquals(goLiveConstraint(contact), true)
	
	lu.assertEquals(self.samSite:areGoLiveConstraintsSatisfied(contact), true)
	self.samSite:addGoLiveConstraint('helicopter', goLiveConstraint)
	lu.assertEquals(self.samSite:areGoLiveConstraintsSatisfied(contact), true)
	
	--TODO: finish test to check return false if constraint is false

	local function goLiveConstraintFalse(contact)
		return ( contact:getHeightInFeetMSL() < 4000 )
	end
	
	self.samSite:addGoLiveConstraint('helicopter', goLiveConstraintFalse)
	lu.assertEquals(self.samSite:areGoLiveConstraintsSatisfied(contact), false)

end

function TestSkynetIADSSAMSite:testRemoveGoLiveConstraint()
	self.samSiteName = "SAM-SA-2"
	self:setUp()
	self.samSite:addGoLiveConstraint("constraint", {})
	
	--this marker funtion is to test if after removing the first function this one will still exist
	function testMarkerFunction(contact)
		return 3
	end
	
	self.samSite:addGoLiveConstraint("test", testMarkerFunction)
	
	local count = 0
	for constraintName, constraint in pairs(self.samSite:getGoLiveConstraints()) do
		count = count + 1
	end
	lu.assertEquals(count, 2)
	
	count = 0
	self.samSite:removeGoLiveConstraint("constraint")
	for constraintName, constraint in pairs(self.samSite:getGoLiveConstraints()) do
		count = count + 1
	end
	lu.assertEquals(count, 1)
	
	lu.assertEquals(self.samSite:getGoLiveConstraints()["test"](contact), 3)
	
	
end

function TestSkynetIADSSAMSite:testSAMSiteWillNotGoLiveIfConstraintFailesAndContactIsInRange()
	self.samSiteName = "SAM-SA-2"
	self:setUp()
	local contact = IADSContactFactory('test-in-firing-range-of-sa-2')
	
	local function goLiveConstraintFalse(contact)
		return ( contact:getHeightInFeetMSL() < 4000 )
	end

	self.samSite:addGoLiveConstraint('helicopter', goLiveConstraintFalse)
	self.samSite:goDark()
	self.samSite:targetCycleUpdateStart()
	self.samSite:informOfContact(contact)
	lu.assertEquals(self.samSite:isActive(), false)
end

end