------------------------------------------------------------
--- AUTHOR: PLATINUM_DOTA2 (Pooya J.)
--- EMAIL ADDRESS: platinum.dota2@gmail.com
------------------------------------------------------------

-------
require( GetScriptDirectory().."/mode_laning_generic" )
Utility = require(GetScriptDirectory().."/Utility")
----------

local LaningStates={
	Start=0,
	Moving=1,
	WaitingForCS=2,
	CSing=3,
	WaitingForCreeps=4,
	MovingToPos=5,
	GetReadyForCS=6,
	GettingBack=7,
	MovingToLane=8
}

local CurLane = LANE_BOT;
local LaningState = LaningStates.Start;
local LanePos = 0.0;
local backTimer=-200;
local ShouldPush=false;
local IsCore=true;

local DamageThreshold=1.0;
local MoveThreshold=1.0;


local function Updates()
	local npcBot=GetBot();

	if DotaTime()<100 then
		CurLane=npcBot:GetAssignedLane();
	end

	if CurLane~=nil and GetUnitToLocationDistance(npcBot,GetLocationAlongLane(CurLane,0.0)) < 1000 then
		CurLane=Utility.ConsiderChangingLane(CurLane);
	end


	local Enemies=npcBot:GetNearbyHeroes(1200,true,BOT_MODE_NONE);

	if Enemies~=nil and #Enemies>0 and (not ShouldPush) then
		npcBot.CreepDist=550;
	else
		npcBot.CreepDist=450;
	end

	LanePos = Utility.PositionAlongLane(CurLane);


	if (Utility.IsItemInInventory("item_blight_stone")~=nil and #Enemies<2) then
		ShouldPush=true;
	end

	if ( (not(npcBot:IsAlive())) or (LanePos<0.15 and LaningState~=LaningStates.Start)) then
		LaningState=LaningStates.Moving;
	end

	local clanepos=GetLaneFrontAmount(GetTeam(),CurLane,false);
	local cpos=GetLocationAlongLane(CurLane,Max(Min(clanepos-0.05,0.8),0.15));
	--DebugDrawCircle( cpos, 300, 100, 0, 50 )


end


function OnStart()
	Updates();
	mode_generic_laning.OnStart();
	if DotaTime()>2 then
		LoadUpdates();
	end
end

function OnEnd()
	mode_generic_laning.OnEnd();
end

function GetDesire()
	return mode_generic_laning.GetDesire();
end

function GetBack()
	local npcBot=GetBot();

	local Enemies=npcBot:GetNearbyHeroes(1300,true,BOT_MODE_NONE);

	if Enemies== nil or #Enemies==0 then
		return true;
	end


	if npcBot:IsSilenced() or #Enemies>3 or npcBot:GetCurrentMovementSpeed()<240 then
		backTimer=DotaTime();
		npcBot:Action_MoveToLocation(GetLocationAlongLane(CurLane,LanePos-0.02));
		return false;
	end

	for _,enemy in pairs(Enemies) do
		if GetUnitToUnitDistance(npcBot,enemy)<=425 then
			backTimer=DotaTime();
			npcBot:Action_MoveToLocation(GetLocationAlongLane(CurLane,LanePos-0.02));
			return false;
		end
		if DotaTime()-backTimer<1 then
			npcBot:Action_MoveToLocation(GetLocationAlongLane(CurLane,LanePos-0.02));
			return false;
		end
	end

	enemy,_=Utility.GetWeakestHero(npcBot:GetAttackRange());
	if enemy==nil then
		return true;
	end

	if GetUnitToUnitDistance(npcBot,enemy)<=npcBot:GetAttackRange() then
		npcBot:Action_AttackUnit(enemy,true);
		return false;
	end

	return true;
end

function Harass()
	local npcBot = GetBot();

	if GetAbilityByName("weaver_geminate_attack"):IsCooldownReady() then
		WeakestHero,Damage,Score = Utility.FindTarget(npcBot:GetAttackRange() + 300);

		if WeakestHero ~= nil then
			npBot:Action_AttackUnit(WeakestHero, true);
		end
	end

end

function SaveUpdates()
	local npcBot=GetBot();

	npcBot.LaningState=LaningState;
	npcBot.LanePos=LanePos;
	npcBot.CurLane=CurLane;
	npcBot.MoveThreshold=MoveThreshold;
	npcBot.DamageThreshold=DamageThreshold;
	npcBot.ShouldPush=ShouldPush;
	npcBot.IsCore=IsCore;
end

function LoadUpdates()
	local npcBot=GetBot();

	LaningState=npcBot.LaningState;
	LanePos=npcBot.LanePos;
	CurLane=npcBot.CurLane;
	MoveThreshold=npcBot.MoveThreshold;
	DamageThreshold=npcBot.DamageThreshold;
	ShouldPush=npcBot.ShouldPush;
	IsCore=npcBot.IsCore;
end

function Think()
	local npcBot=GetBot();

	Updates();
	SaveUpdates();

	Harass();

	if (GetBack()) then
		mode_generic_laning.Think();
		LaningState=npcBot.LaningState;
		LoadUpdates();
	end

end

--------
