do
TestSkynetIADSREDSAMSitesAndEWRadars = {}

function TestSkynetIADSREDSAMSitesAndEWRadars:setUp()
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
	
	if self.ewRadarName then
		self.skynetIADS:addEarlyWarningRadarsByPrefix('EW')
		self.ewRadar = self.skynetIADS:getEarlyWarningRadarByUnitName(self.ewRadarName)
	end
end

function TestSkynetIADSREDSAMSitesAndEWRadars:tearDown()
	if self.samSite then	
		self.samSite:goDark()
		self.samSite:cleanUp()
	end
	
	if self.ewRadar then
		self.ewRadar:cleanUp()
	end
	
	if self.skynetIADS then
		self.skynetIADS:deactivate()
	end
	self.ewRadarName = nil
	self.samSiteName = nil
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testCheckSA6GroupNumberOfLaunchersAndRangeValuesAndSearchRadarsAndNatoName()
--[[
	DCS properties SA-6 (Kub / Gainful) 
	
	Radar:
	{
		{
			{
				detectionDistanceAir={
					lowerHemisphere={headOn=46811.82421875, tailOn=46811.82421875},
					upperHemisphere={headOn=46811.82421875, tailOn=46811.82421875}
					upperHemisphere={headOn=46811.82421875, tailOn=46811.82421875}
				},
				type=1,
				typeName="Kub 1S91 str"
			}
		}
	}

	Launcher:
    {
        count=3,
        desc={
            Nmax=16,
            RCS=0.1059999987483,
            _origin="",
            altMax=8000,
            altMin=30,
            box={
                max={x=2.9061908721924, y=0.43574807047844, z=0.4395649433136},
                min={x=-2.9048342704773, y=-0.43574807047844, z=-0.4395649433136}
            },
            category=1,
            displayName="3M9M Kub (SA-6 Gainful)",
            fuseDist=12,
            guidance=4,
            life=2,
            missileCategory=2,
            rangeMaxAltMax=25000,
            rangeMaxAltMin=25000,
            rangeMin=4000,
            typeName="SA3M9M",
            warhead={caliber=330, explosiveMass=59, mass=59, type=1}
        }
    }
}
--]]
	self.samSiteName = "SAM-SA-6-2"
	self:setUp()
	lu.assertEquals(#self.samSite:getLaunchers(), 1)
	lu.assertEquals(#self.samSite:getSearchRadars(), 1)
	
	local searchRadar = self.samSite:getSearchRadars()[1]
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 46811.82421875)
	
	lu.assertEquals(self.samSite:getNatoName(), "SA-6")
	
	local launcher = self.samSite:getLaunchers()[1]
	lu.assertEquals(launcher:getRange(), 25000)
	
	lu.assertEquals(self.samSite:getRemainingNumberOfMissiles(), 3)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testCheckSA10GroupNumberOfLaunchersAndSearchRadarsAndNatoName()
--[[
	DCS properties SA-10 (S-300 / SA-10 Grumble)
	
	Launcher:
	{
		{
			count=4,
			desc={
				Nmax=25,
				RCS=0.17800000309944,
				_origin="",
				altMax=30000,
				altMin=25,
				box={
					max={x=3.6516976356506, y=0.81190091371536, z=0.81109911203384},
					min={x=-3.6131811141968, y=-0.80982387065887, z=-0.81062549352646}
				},
				category=1,
				displayName="5V55 S-300PS (SA-10B Grumble)",
				fuseDist=20,
				guidance=4,
				life=2,
				missileCategory=2,
				rangeMaxAltMax=75000,
				rangeMaxAltMin=40000,
				rangeMin=5000,
				typeName="SA5B55",
				warhead={caliber=508, explosiveMass=133, mass=133, type=1}
			}
		}
	}

--]]
	self.samSiteName = "SAM-SA-10"
	self:setUp()
	lu.assertEquals(#self.samSite:getLaunchers(), 2)
	lu.assertEquals(#self.samSite:getSearchRadars(), 3)
	lu.assertEquals(#self.samSite:getTrackingRadars(), 2)
	lu.assertEquals(#self.samSite:getRadars(), 5)
	lu.assertEquals(self.samSite:getNatoName(), "SA-10")
	lu.assertEquals(self.samSite:getCanEngageHARM(), true)
	
	
	local launchers = self.samSite:getLaunchers()
	local numLoops = 0
	-- seems like currently both launcher types of the SA-10 have the same range values
	for i = 1, #launchers do
		local launcher = launchers[i]
		lu.assertEquals(launcher:getInitialNumberOfMissiles(), 4)
		lu.assertEquals(launcher:getRange(), 75000)
		lu.assertEquals(launcher:getMaximumFiringAltitude(), 25000)
		numLoops = numLoops + 1
	end
	lu.assertEquals(numLoops, 2)
	
	local radars = self.samSite:getRadars()
	
	--for some strange reason the s300 does not have any range values in getSensors(), all the data there is empty
	local tr = self.samSite:getTrackingRadars()[1]
	lu.assertEquals(tr:getMaxRangeFindingTarget(),0)
	
	local tr = self.samSite:getTrackingRadars()[2]
	lu.assertEquals(tr:getMaxRangeFindingTarget(),0)

	local sr = self.samSite:getSearchRadars()[1]
	lu.assertEquals(sr:getMaxRangeFindingTarget(), 0)
	
	local sr = self.samSite:getSearchRadars()[2]
	lu.assertEquals(sr:getMaxRangeFindingTarget(), 0)
	
	local sr = self.samSite:getSearchRadars()[3]
	lu.assertEquals(sr:getMaxRangeFindingTarget(), 0)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testCheckSA11GroupNumberOfLaunchersAndSearchRadarsAndNatoName()
--[[
	DCS properties SA-10 (S-300 / SA-10 Grumble)
	
	Radar:	
	{
		{
			{
				detectionDistanceAir={
					lowerHemisphere={headOn=53499.2265625, tailOn=53499.2265625},
					upperHemisphere={headOn=53499.2265625, tailOn=53499.2265625}
				},
				type=1,
				typeName="S-300PS 40B6M tr"
			}
		}
	}
	
	Launcher:
	{
		{
			count=4,
			desc={
				Nmax=25,
				RCS=0.17800000309944,
				_origin="",
				altMax=30000,
				altMin=25,
				box={
					max={x=3.6516976356506, y=0.81190091371536, z=0.81109911203384},
					min={x=-3.6131811141968, y=-0.80982387065887, z=-0.81062549352646}
				},
				category=1,
				displayName="5V55 S-300PS (SA-10B Grumble)",
				fuseDist=20,
				guidance=4,
				life=2,
				missileCategory=2,
				rangeMaxAltMax=75000,
				rangeMaxAltMin=40000,
				rangeMin=5000,
				typeName="SA5B55",
				warhead={caliber=508, explosiveMass=133, mass=133, type=1}
			}
		}
	}

--]]
	self.samSiteName = "SAM-SA-11"
	self:setUp()
	lu.assertEquals(#self.samSite:getLaunchers(), 1)
	lu.assertEquals(#self.samSite:getSearchRadars(), 1)
	lu.assertEquals(#self.samSite:getTrackingRadars(), 0)
	lu.assertEquals(#self.samSite:getRadars(), 1)
	lu.assertEquals(self.samSite:getNatoName(), "SA-11")
	
	local launchers = self.samSite:getLaunchers()
	local launcher = launchers[1]
	lu.assertEquals(launcher:getInitialNumberOfMissiles(), 4)
	lu.assertEquals(launcher:getRange(), 35000)
	lu.assertEquals(launcher:getMaximumFiringAltitude(), 22000)
	
	local radars = self.samSite:getRadars()
	local radar = radars[1]
	lu.assertEquals(radar:getMaxRangeFindingTarget(), 66874.03125)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testCheckSA3GroupNumberOfLaunchersAndRangeValuesAndSearchRadarsAndNatoName()
--[[
	DCS properties SA-3 (s-125 / SA-3 Goa)
	
	Radar:
	{
        {
            detectionDistanceAir={
                lowerHemisphere={headOn=53499.2265625, tailOn=53499.2265625},
                upperHemisphere={headOn=53499.2265625, tailOn=53499.2265625}
            },
            type=1,
            typeName="p-19 s-125 sr"
        }
    }
	
	Launcher:
	{
		{
			count=4,
			desc={
				Nmax=16,
				RCS=0.1676000058651,
				_origin="",
				altMax=18000,
				altMin=20,
				box={
					max={x=3.7270171642303, y=0.94484841823578, z=0.95312494039536},
					min={x=-2.6432721614838, y=-0.94484841823578, z=-0.95312494039536}
				},
				category=1,
				displayName="5V27 S-125 Neva (SA-3 Goa)",
				fuseDist=14,
				guidance=4,
				life=2,
				missileCategory=2,
				rangeMaxAltMax=25000,
				rangeMaxAltMin=11000,
				rangeMin=3500,
				typeName="SA5B27",
				warhead={caliber=400, explosiveMass=60, mass=60, type=1}
			}
		}
	}
	
--]]
	self.samSiteName = "test-SA-3"
	self:setUp()
	
	local array = {}
	local unitData = {
		['p-19 s-125 sr'] = {
		},
	}
	self.samSite:analyseAndAddUnit(SkynetIADSSAMSearchRadar, array, unitData)
	local searchRadar = array[1]
	lu.assertEquals(#array, 1)
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 53499.2265625)
	
	array = {}
	unitData = {
		['5p73 s-125 ln'] = {
		},
	}
	self.samSite:analyseAndAddUnit(SkynetIADSSAMLauncher, array, unitData)
	local launcher = array[1]
	lu.assertEquals(launcher:getRange(), 25000)
	lu.assertEquals(launcher:getMaximumFiringAltitude(), 18000)
	array = {}
	unitData = {
		['snr s-125 tr'] = {
		},
	}	
	self.samSite:analyseAndAddUnit(SkynetIADSSAMTrackingRadar, array, unitData)
	local searchRadar = array[1]
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(),  53499.2265625)
	
	lu.assertEquals(#self.samSite:getLaunchers(), 1)	
	lu.assertEquals(#self.samSite:getSearchRadars(), 1)
	lu.assertEquals(#self.samSite:getTrackingRadars(), 1)
	lu.assertEquals(#self.samSite:getRadars(), 2)
	lu.assertEquals(self.samSite:getHARMDetectionChance(), 30)
	lu.assertEquals(self.samSite:setHARMDetectionChance(100), self.samSite)
	
	lu.assertEquals(self.samSite:getNatoName(), "SA-3")
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testShilkaGroupLaunchersSearchRadarRangesAndHARMDefenceChance()
	--[[
	
	DCS Properties Shilka / Zues:
	
	Radar:	
	{
        {
            detectionDistanceAir={
                lowerHemisphere={headOn=5015.552734375, tailOn=5015.552734375},
                upperHemisphere={headOn=5015.552734375, tailOn=5015.552734375}
            },
            type=1,
            typeName="ZSU-23-4 Shilka"
        }
    }
		
		
	Launcher:
	{
		{
			count=503,
			desc={
				_origin="",
				box={
					max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
					min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
				},
				category=0,
				displayName="23mm AP",
				life=2,
				typeName="weapons.shells.2A7_23_AP",
				warhead={caliber=23, explosiveMass=0, mass=0.189, type=0}
			}
		},
		{
			count=1501,
			desc={
				_origin="",
				box={
					max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
					min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
				},
				category=0,
				displayName="23mm HE",
				life=2,
				typeName="weapons.shells.2A7_23_HE",
				warhead={caliber=23, explosiveMass=0.189, mass=0.189, type=1}
			}
		}
	}
	--]]
	self.samSiteName = "SAM-Shilka"
	self:setUp()
	lu.assertEquals(self.samSite:getHARMDetectionChance(), 10)
	lu.assertEquals(#self.samSite:getRadars(),1)
	lu.assertEquals(#self.samSite:getLaunchers(), 1)
	lu.assertEquals(#self.samSite:getTrackingRadars(), 0)
	local searchRadar = self.samSite:getSearchRadars()[1]
	
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 5015.552734375)
	
	local target = IADSContactFactory("Harrier Pilot")
	
	local launcher = self.samSite:getLaunchers()[1]
	
	--shilka has no missiles
	lu.assertEquals(launcher:getInitialNumberOfMissiles(), 0)
	lu.assertEquals(launcher:getRemainingNumberOfMissiles(), 0)
	
	lu.assertEquals(#launcher:getDCSRepresentation():getAmmo(), 2)
	
	lu.assertEquals(launcher:getInitialNumberOfShells(), 2004)
	lu.assertEquals(launcher:getRemainingNumberOfShells(), 2004)
	
	lu.assertEquals(launcher:getRange(), 5015.552734375)
	--dcs has no maximum height data for AAA
	lu.assertEquals(launcher:getMaximumFiringAltitude(), 0)
	lu.assertEquals(launcher:isWithinFiringHeight(target), true)
	lu.assertEquals(mist.utils.round(launcher:getHeight(target)), 1909)

	--this target is at 25k feet
	local target = IADSContactFactory("test-not-in-firing-range-of-sa-2")
	lu.assertEquals(launcher:isWithinFiringHeight(target), false)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA15LaunchersSearchRadarRangeAndHARMDefenceChance()
	--[[ 
	DCS SA-15: properties:
	Launcher
    {
        count=8,
        desc={
            Nmax=30,
            RCS=0.03070000000298,
            _origin="",
            altMax=6000,
            altMin=10,
            box={
                max={x=1.8263295888901, y=0.26701140403748, z=0.26600670814514},
                min={x=-1.678077340126, y=-0.26701140403748, z=-0.26600670814514}
            },
            category=1,
            displayName="9M330 Tor (SA-15 Gauntlet)",
            fuseDist=7,
            guidance=4,
            life=2,
            missileCategory=2,
            rangeMaxAltMax=12000,
            rangeMaxAltMin=12000,
            rangeMin=1500,
            typeName="SA9M330",
            warhead={caliber=220, explosiveMass=14.5, mass=14.5, type=1}
        }
    }
	
	Radar:
{
    0={{opticType=0, type=0, typeName="generic SAM search visir"}},
    {
        {
            detectionDistanceAir={
                lowerHemisphere={headOn=16718.5078125, tailOn=16718.5078125},
                upperHemisphere={headOn=16718.5078125, tailOn=16718.5078125}
            },
            type=1,
            typeName="Tor 9A331"
        }
    }
}	--]]

	self.samSiteName = "SAM-SA-15"
	self:setUp()

	lu.assertEquals(self.samSite:getNatoName(),'SA-15')
	lu.assertEquals(self.samSite:getHARMDetectionChance(), 90)
	lu.assertEquals(#self.samSite:getRadars(),1)	
	lu.assertEquals(self.samSite:getCanEngageHARM(), true)
	
	local target = IADSContactFactory("Harrier Pilot")
	
	local searchRadar = self.samSite:getSearchRadars()[1]
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 16718.5078125)
	lu.assertEquals(searchRadar:isInRange(target), false)
	
	lu.assertEquals(#self.samSite:getSearchRadars(), 1)
	lu.assertEquals(#self.samSite:getTrackingRadars(), 0)
	lu.assertEquals(#self.samSite:getLaunchers(), 1)
	
	local launcher = self.samSite:getLaunchers()[1]
	lu.assertEquals(launcher:getRange(), 12000)
	lu.assertEquals(launcher:getMaximumFiringAltitude(), 6000)
	
	lu.assertEquals(launcher:isInRange(target), false)

	lu.assertEquals(mist.utils.round(launcher:getHeight(target)), 1930)
	lu.assertEquals(launcher:getMaximumFiringAltitude(), 6000)
	lu.assertEquals(launcher:isWithinFiringHeight(target), true)
	lu.assertEquals(launcher:getRemainingNumberOfMissiles(), 8)
	
	launcher.maximumFiringAltitude = 400
	lu.assertEquals(launcher:isWithinFiringHeight(target), false)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA13LaunchersSearchRadarRangeAndHARMDefence()
--[[
DCS SA-13 Properties (Strela-10M3 / Gopher):
{
    {
        count=8,
        desc={
            Nmax=16,
            RCS=0.050000000745058,
            _origin="",
            altMax=3500,
            altMin=25,
            box={
                max={x=1.1227556467056, y=0.13098473846912, z=0.13213211297989},
                min={x=-1.1213990449905, y=-0.13098473846912, z=-0.13213211297989}
            },
            category=1,
            displayName="9M333 Strela-10 (SA-13 Gopher)",
            fuseDist=3,
            guidance=2,
            life=2,
            missileCategory=2,
            rangeMaxAltMax=5000,
            rangeMaxAltMin=5000,
            rangeMin=800,
            typeName="SA9M333",
            warhead={caliber=120, explosiveMass=3.5, mass=3.5, type=1}
        }
    },
    {
	count=1009,
        desc={
            _origin="",
            box={
                max={x=2.2344591617584, y=0.12504191696644, z=0.12113922089338},
                min={x=-6.61008644104, y=-0.12504199147224, z=-0.12113920599222}
            },
            category=0,
            displayName="7.62mm",
            life=2,
            typeName="weapons.shells.7_62x54",
            warhead={caliber=7.62, explosiveMass=0, mass=0.0119, type=0}
        }
    }
	Does not have any Radar Properties in DCS
--]]

	self.samSiteName = "SAM-SA-13"
	self:setUp()
	lu.assertEquals(#self.samSite:getRadars(), 1)
	lu.assertEquals(#self.samSite:getSearchRadars(), 1)
	lu.assertEquals(#self.samSite:getTrackingRadars(), 0)
	lu.assertEquals(#self.samSite:getLaunchers(), 1)
	lu.assertEquals(self.samSite:getCanEngageHARM(), false)
	
	local searchRadar = self.samSite:getSearchRadars()[1]
	
	--this asset has no radar sensor information, we load the launcher data instead, to keep interface consistent:
	lu.assertEquals(searchRadar:getDCSRepresentation():getSensors(), nil)
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 5000)
	
	local launcher = self.samSite:getLaunchers()[1]
	lu.assertEquals(launcher:getRange(), 5000)
	lu.assertEquals(launcher:getMaximumFiringAltitude(), 3500)
	lu.assertEquals(launcher:getRemainingNumberOfMissiles(), 8)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testHQ7LauncherAndRadar()
--[[
HQ-7:

Radar:
{
    0={
        {opticType=0, type=0, typeName="TKN-3B day"},
        {opticType=2, type=0, typeName="TKN-3B night"},
        {opticType=0, type=0, typeName="Tunguska optic sight"}
    },
    {
        {
            detectionDistanceAir={
                lowerHemisphere={headOn=10090.756835938, tailOn=6727.1713867188},
                upperHemisphere={headOn=8408.9638671875, tailOn=6727.1713867188}
            },
            type=1,
            typeName="HQ-7 TR"
        }
    }
}

Launcher:
{
    {
        count=4,
        desc={
            Nmax=18,
            RCS=0.0099999997764826,
            _origin="",
            altMax=5500,
            altMin=14.5,
            box={
                max={x=1.245908498764, y=0.20055842399597, z=0.20074887573719},
                min={x=-1.754227399826, y=-0.20056092739105, z=-0.20036999881268}
            },
            category=1,
            displayName="HQ-7",
            fuseDist=7,
            guidance=4,
            life=2,
            missileCategory=2,
            rangeMaxAltMax=12000,
            rangeMaxAltMin=12000,
            rangeMin=500,
            typeName="HQ-7",
            warhead={caliber=156, explosiveMass=15, mass=15, type=1}
        }
    }
}
--]]
	self.samSiteName = "SAM-HQ-7"
	self:setUp()
	
	local group = Group.getByName(self.samSiteName)
--[[
	local units = group:getUnits()
	for i = 1, #units do
		local unit = units[i]
		if unit:getAmmo() then
		--	lu.assertEquals(unit:getAmmo(), false)
		end
	end
--]]
	lu.assertEquals(self.samSite:getNatoName(), "CSA-4")
	lu.assertEquals(self.samSite:getLaunchers()[1]:getRange(), 12000)
	lu.assertEquals(mist.utils.round(self.samSite:getRadars()[1]:getMaxRangeFindingTarget()), 12613)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA5()
	self.samSiteName = "SAM-SA-5"
	self:setUp()
	lu.assertEquals(self.samSite:getNatoName(), "SA-5")
	local searchRadar = self.samSite:getSearchRadars()[1]
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 100311.046875)
	local trackingRadar = self.samSite:getTrackingRadars()[1]
	lu.assertEquals(trackingRadar:getMaxRangeFindingTarget(), 100311.046875)
	lu.assertEquals(self.samSite:getLaunchers()[1]:getRange(), 240000)
	lu.assertEquals(self.samSite:getLaunchers()[1]:getInitialNumberOfMissiles(), 1)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA5P19()
	self.samSiteName = "SAM-SA-5-p-19"
	self:setUp()
	lu.assertEquals(self.samSite:getNatoName(), "SA-5")
	local searchRadar = self.samSite:getSearchRadars()[1]
	lu.assertEquals(searchRadar:getMaxRangeFindingTarget(), 53499.2265625)
	local trackingRadar = self.samSite:getTrackingRadars()[1]
	lu.assertEquals(trackingRadar:getMaxRangeFindingTarget(), 53499.2265625)
	lu.assertEquals(self.samSite:getLaunchers()[1]:getRange(), 240000)
	lu.assertEquals(self.samSite:getLaunchers()[1]:getInitialNumberOfMissiles(), 1)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:test1L13EWRBoxSpring()
	self.ewRadarName = "EW-west2"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Box Spring")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testCP9S80M1SborkaDogEar()
	self.ewRadarName = "EW-Dog Ear"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Dog Ear")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:test55G6EWRTalRack()
	self.ewRadarName = "EW-west8"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Tall Rack")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testEWP19FlatFace()
	self.ewRadarName = "EW-SR-P19"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Flat Face")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
	lu.assertEquals(self.ewRadar:getHARMDetectionChance(), 30)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA10BigBird()
	self.ewRadarName = "EW-SA-10"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Big Bird")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA10ClamShell()
	self.ewRadarName = "EW-SA-10-2"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Clam Shell")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA11SnowDrift()
	self.ewRadarName = "EW-SA-11"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Snow Drift")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testSA6StraightFlush()
	self.ewRadarName = "EW-SA-6"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "Straight Flush")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end

function TestSkynetIADSREDSAMSitesAndEWRadars:testHQ7()
	self.ewRadarName = "EW-HQ7-STR"
	self:setUp()
	lu.assertEquals(self.ewRadar:getNatoName(), "CSA-4")
	lu.assertEquals(self.ewRadar:hasWorkingRadar(), true)
end


function TestSkynetIADSREDSAMSitesAndEWRadars:testA50AWACSAsEWRadar()
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

function TestSkynetIADSREDSAMSitesAndEWRadars:testKJ2000AWACSAsEWRadar()
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

end
