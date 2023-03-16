do
TestSkynetIADSEWRadar = {}

function TestSkynetIADSEWRadar:setUp()
	self.numEWSites = SKYNET_UNIT_TESTS_NUM_EW_SITES_RED
	if self.blue == nil then
		self.blue = ""
	end
	if self.ewRadarName then
		self.iads = SkynetIADS:create()
		self.iads:addEarlyWarningRadarsByPrefix(self.blue..'EW')
		self.ewRadar = self.iads:getEarlyWarningRadarByUnitName(self.ewRadarName)
	end
end

function TestSkynetIADSEWRadar:tearDown()
	if self.ewRadar then
		self.ewRadar:cleanUp()
	end
	if self.iads then
		self.iads:deactivate()
	end
	self.iads = nil
	self.ewRadar = nil
	self.ewRadarName = nil
	self.blue = ""
end

function TestSkynetIADSEWRadar:testCompleteDestructionOfEarlyWarningRadar()
		
		local ewRadar = SkynetIADSAWACSRadar:create(Unit.getByName('EW-west22-destroy'), SkynetIADS:create('test'))
		ewRadar:setupElements()
		ewRadar:setActAsEW(true)
		ewRadar:goLive()
		
		local sa61 = SkynetIADSSamSite:create(Group.getByName('SAM-SA-6'), SkynetIADS:create('test'))
		local sa62 = SkynetIADSSamSite:create(Group.getByName('SAM-SA-6-2'), SkynetIADS:create('test'))
	
		--build radar association
		ewRadar:addChildRadar(sa61)
		sa61:addParentRadar(ewRadar)
		ewRadar:addChildRadar(sa62)
		sa62:addParentRadar(ewRadar)
		
		sa61:setToCorrectAutonomousState()
		sa62:setToCorrectAutonomousState()
		
		lu.assertEquals(ewRadar:hasRemainingAmmo(), true)
		lu.assertEquals(ewRadar:isActive(), true)
		lu.assertEquals(ewRadar:getDCSRepresentation():isExist(), true)
		lu.assertEquals(sa61:getAutonomousState(), false)
		lu.assertEquals(sa62:getAutonomousState(), false)
		trigger.action.explosion(ewRadar:getDCSRepresentation():getPosition().p, 500)
		--we simulate a call to the event, since in game will be triggered to late to for later checks in this unit test
		ewRadar:onEvent(createDeadEvent())
		lu.assertEquals(ewRadar:getDCSRepresentation():isExist(), false)
	
		lu.assertEquals(ewRadar:isActive(), false)

		lu.assertEquals(sa61:getAutonomousState(), true)
		lu.assertEquals(sa62:getAutonomousState(), true)
		
		sa61:cleanUp()
		sa62:cleanUp()
		ewRadar:cleanUp()
end

function TestSkynetIADSEWRadar:testFinishHARMDefence()
	self.ewRadarName = "EW-west2"
	self:setUp()
	lu.assertEquals(self.ewRadar:isActive(), true)
	lu.assertEquals(self.ewRadar:hasRemainingAmmo(), true)
	self.ewRadar:goSilentToEvadeHARM()
	lu.assertEquals(self.ewRadar:isActive(), false)
	self.ewRadar.finishHarmDefence(self.ewRadar)
	lu.assertEquals(self.ewRadar.harmSilenceID, nil)
	self.iads.evaluateContacts(self.iads)
	lu.assertEquals(self.ewRadar:isActive(), true)
end

function TestSkynetIADSEWRadar:testGoDarkWhenAutonomousByDefault()
	self.ewRadarName = "EW-west2"
	self:setUp()
	lu.assertEquals(self.ewRadar:isActive(), true)
	function self.ewRadar:hasActiveConnectionNode()
		return false
	end
	self.ewRadar:goAutonomous()
	lu.assertEquals(self.ewRadar:isActive(), false)
end

function TestSkynetIADSEWRadar:test1L13EWRBoxSpring()
	self.ewRadarName = "EW-west22-destroy"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Box Spring")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testCP9S80M1SborkaDogEar()
	self.ewRadarName = "EW-Dog Ear"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Dog Ear")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:test55G6EWRTalRack()
	self.ewRadarName = "EW-west8"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Tall Rack")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testRolandEWR()
	self.ewRadarName = "BLUE-EW-Roland"
	self.blue = "BLUE-"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Roland EWR")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testEWP19FlatFace()
	self.ewRadarName = "EW-SR-P19"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Flat Face")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
	lu.assertEquals(self.ewRadar:getHARMDetectionChance(), 30)
end

function TestSkynetIADSEWRadar:testPatriotSTR()
	self.ewRadarName = "BLUE-EW"
	self.blue = "BLUE-"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Patriot str")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testSA10BigBird()
	self.ewRadarName = "EW-SA-10"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Big Bird")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testSA10ClamShell()
	self.ewRadarName = "EW-SA-10-2"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Clam Shell")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testSA11SnowDrift()
	self.ewRadarName = "EW-SA-11"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Snow Drift")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testSA6StraightFlush()
	self.ewRadarName = "EW-SA-6"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Straight Flush")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testHawk()
	self.ewRadarName = "EW-HQ7-STR"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "CSA-4")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testHQ7SearchRadar()
	self.ewRadarName = "EW-Hawk"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Hawk str")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSEWRadar:testA50AWACSAsEWRadar()
--[[
	DCS A-50 properties:
	
	Radar:
	    {
        {
            detectionDistanceAir={
                lowerHemisphere={headOn=204461.796875, tailOn=204461.796875},
                upperHemisphere={headOn=204461.796875, tailOn=204461.796875}
            },
            detectionDistanceRBM=2500,
            type=1,
            typeName="Shmel"
        }
    },
    3={{type=3, typeName="Abstract RWR"}}
}

--]]
	self.ewRadarName = "EW-AWACS-A-50"
	self:setUp()
	local unit = Unit.getByName(self.ewRadarName)
	lu.assertEquals(unit:getDesc().category, Unit.Category.AIRPLANE)
	lu.assertEquals(self.ewRadar:getNatoName(), 'A-50')
	local searchRadar = self.ewRadar:getSearchRadars()[1]
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 204461.796875)
end

function TestSkynetIADSEWRadar:testKJ2000AWACSAsEWRadar()
--[[
	DCS KJ-2000 properties:
	
	Radar:
	{
		{
			{
				detectionDistanceAir={
					lowerHemisphere={headOn=268356.125, tailOn=268356.125},
					upperHemisphere={headOn=268356.125, tailOn=268356.125}
				},
				detectionDistanceRBM=3500,
				type=1,
				typeName="AESA_KJ2000"
			}
		},
		3={{type=3, typeName="Abstract RWR"}}
	}

--]]
	self.ewRadarName = "EW-AWACS-KJ-2000"
	self:setUp()
	local unit = Unit.getByName('EW-AWACS-KJ-2000')
	local searchRadar = self.ewRadar:getSearchRadars()[1]
	lu.assertEquals(self.ewRadar:getNatoName(), 'KJ-2000')
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 268356.125)
end

--TODO: this test can only be finished once the perry class has radar data:
function TestSkynetIADSEWRadar:testOliverHazzardPerryClassShip()
--[[
Oliver Hazzard:

Launchers:
 {
    {
        count=2016,
        desc={
            _origin="",
            box={
                max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
                min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
            },
            category=0,
            displayName="12.7mm",
            life=2,
            typeName="weapons.shells.M2_12_7_T",
            warhead={caliber=12.7, explosiveMass=0, mass=0.046, type=0}
        }
    },
    {
        count=460,
        desc={
            _origin="",
            box={
                max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
                min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
            },
            category=0,
            displayName="25mm HE",
            life=2,
            typeName="weapons.shells.M242_25_HE_M792",
            warhead={caliber=25, explosiveMass=0.185, mass=0.185, type=1}
        }
    },
    {
        count=142,
        desc={
            _origin="",
            box={
                max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
                min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
            },
            category=0,
            displayName="25mm AP",
            life=2,
            typeName="weapons.shells.M242_25_AP_M791",
            warhead={caliber=25, explosiveMass=0, mass=0.155, type=0}
        }
    },
    {
        count=775,
        desc={
            _origin="",
            box={
                max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
                min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
            },
            category=0,
            displayName="20mm AP",
            life=2,
            typeName="weapons.shells.M61_20_AP",
            warhead={caliber=20, explosiveMass=0, mass=0.1, type=0}
        }
    },
    {
        count=775,
        desc={
            _origin="",
            box={
                max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
                min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
            },
            category=0,
            displayName="20mm HE",
            life=2,
            typeName="weapons.shells.M61_20_HE",
            warhead={caliber=20, explosiveMass=0.1, mass=0.1, type=1}
        }
    },
    {
        count=24,
        desc={
            Nmax=25,
            RCS=0.1765999943018,
            _origin="",
            altMax=24400,
            altMin=10,
            box={
                max={x=2.9796471595764, y=0.39923620223999, z=0.39878171682358},
                min={x=-1.5204827785492, y=-0.38143759965897, z=-0.39878168702126}
            },
            category=1,
            displayName="SM-2",
            fuseDist=15,
            guidance=4,
            life=2,
            missileCategory=2,
            rangeMaxAltMax=100000,
            rangeMaxAltMin=40000,
            rangeMin=4000,
            typeName="SM_2",
            warhead={caliber=340, explosiveMass=98, mass=98, type=1}
        }
    },
    {
        count=16,
        desc={
            Nmax=18,
            RCS=0.10580000281334,
            _origin="",
            altMax=10000,
            altMin=-1,
            box={
                max={x=2.2758972644806, y=0.13610155880451, z=0.28847914934158},
                min={x=-1.6704962253571, y=-0.4600305557251, z=-0.28847911953926}
            },
            category=1,
            displayName="AGM-84S Harpoon",
            fuseDist=0,
            guidance=1,
            life=2,
            missileCategory=4,
            rangeMaxAltMax=241401,
            rangeMaxAltMin=95000,
            rangeMin=3000,
            typeName="AGM_84S",
            warhead={caliber=343, explosiveMass=90, mass=90, type=1}
        }
    },
    {
        count=180,
        desc={
            _origin="",
            box={
			

	SENSOR:
	{
	0={{opticType=0, type=0, typeName="long-range naval optics"}},
	{
		{
			detectionDistanceAir={
				lowerHemisphere={headOn=173872.484375, tailOn=173872.484375},
				upperHemisphere={headOn=173872.484375, tailOn=173872.484375}
			},
			type=1,
			typeName="Patriot str"
		},
		{detectionDistanceRBM=336.19998168945, type=1, typeName="perry search radar"}
	}
	}	
--]]

	self.ewRadarName = "BLUE-EW-Oliver-Hazzard"
	self.blue = "BLUE-"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "PERRY")
	--as long as we don't use the PERRY as a SAM site the distance returned is irrelevant, because it's radar wil be on all the time
	lu.assertEquals(self.ewRadar:getRadars()[1]:getMaxRangeFindingTarget(), 173872.484375)
	
	--PERRY does not have radar data
	local unit = Unit.getByName(self.ewRadarName)
end

function TestSkynetIADSEWRadar:testTiconderoga()
	self.ewRadarName = "ticonderoga-class"
	lu.assertEquals(Unit.getByName(self.ewRadarName):getDesc().category, Unit.Category.SHIP)
end

end