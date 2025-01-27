--constants
-- TYPE_MAXIMUM=0x8000
-- SUMMON_TYPE_MAXIMUM = 0x4e000000 --to check if it is correct
FLAG_MAXIMUM_CENTER=170000000 --flag for center card maximum mode
FLAG_MAXIMUM_SIDE=170000001 --flag for Left/right maximum card
if not aux.MaximumProcedure then
	aux.MaximumProcedure = {}
	Maximum = aux.MaximumProcedure
end
if not Maximum then
	Maximum = aux.MaximumProcedure
end
--Maximum Summon
function Maximum.AddProcedure(c,desc,...)
	local mats={...}
	c:GetMetatable().MaximumSet=mats
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	if desc then
		e1:SetDescription(desc)
	else
		e1:SetDescription(1079) --to update, it is the pendulum value. 179 seem free?
	end
	e1:SetCode(EFFECT_SPSUMMON_PROC_G)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(Maximum.Condition(mats))
	e1:SetOperation(Maximum.Operation(mats))
	e1:SetValue(SUMMON_TYPE_MAXIMUM)
	c:RegisterEffect(e1)
	--cannot be changed to def
	local e2=Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
	e2:SetCondition(Maximum.centerCon)
	c:RegisterEffect(e2)
	local e2=Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_CHANGE_POS_E)
	e2:SetCondition(Maximum.centerCon)
	c:RegisterEffect(e2)
	--tribute handler
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetRange(0xff)
    e3:SetCode(EVENT_RELEASE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1)
	e3:SetCondition(Maximum.tribcon)
    e3:SetOperation(Maximum.tribop)
    c:RegisterEffect(e3)
	--leave
	local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetRange(0xff)
    e4:SetCode(EVENT_BATTLE_DESTROYED)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCountLimit(1)
	e4:SetCondition(Maximum.battlecon)
    e4:SetOperation(Maximum.battleop)
    c:RegisterEffect(e4)
end
--that function check if you can maximum summon the monster and its other part(s)
function Maximum.Condition(mats)
	local ct=#mats
	return  function(e,c,og)
		if c==nil then return true end
		local tp=c:GetControler()
		local g=nil
		if og then
			g=og:Filter(Card.IsLocation,nil,LOCATION_HAND)
		else
			g=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
		end
		return Duel.GetMZoneCount(tp,Duel.GetFieldGroup(tp,LOCATION_MZONE,0))>=3 and aux.SelectUnselectGroup(g,e,tp,ct,ct,Maximum.spcheck(mats),0)
	end
end
function Maximum.spcheck(filters)
	return function(sg,e,tp,mg)
		for _,filter in ipairs(filters) do
			if not sg:IsExists(filter,1,nil) then return false end
		end
		return true
	end
end
--operation that do the maximum summon
function Maximum.Operation(mats)
	local ct=#mats
	return function(e,tp,eg,ep,ev,re,r,rp,c,sg,og)
		if c==nil then return true end
		local tp=c:GetControler()
		local g=nil
		if og then
			g=og:Filter(Card.IsLocation,nil,LOCATION_HAND)
		else
			g=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
		end
		--select side monsters
		local tg=aux.SelectUnselectGroup(g,e,tp,ct,ct,Maximum.spcheck(mats),1,tp,HINTMSG_SPSUMMON,nil,nil,true)
		if #tg==0 then return end
		--adding the "maximum mode" flag
		--center
		c:RegisterFlagEffect(FLAG_MAXIMUM_CENTER,RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,0,1)
		--side
		for tc in aux.Next(tg) do
			tc:RegisterFlagEffect(FLAG_MAXIMUM_SIDE,RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,0,1)
		end
		sg:Merge((tg+c))
		g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
		Duel.SendtoGrave(g,REASON_RULE)
	end
end
function Maximum.centerCon(e)
	return e:GetHandler():IsMaximumModeCenter()
end


--function that return if the card is in Maximum Mode or not, atm it just return true as we are lacking info on how Maximum mode work
function Card.IsMaximumMode(c)
	return c:IsMaximumModeCenter() or c:IsMaximumModeSide()
end
function Card.IsMaximumModeCenter(c)
	return c:GetFlagEffect(FLAG_MAXIMUM_CENTER)>0
end
function Card.IsMaximumModeSide(c)
	return c:GetFlagEffect(FLAG_MAXIMUM_SIDE)>0
end
--I used Gemini as a reference for that function, while waiting for more information
function Auxiliary.IsMaximumMode(effect)
	local c=effect:GetHandler()
	return not c:IsDisabled() and c:IsMaximumMode()
end
--that function add the effect that change the Original atk of the Maximum monster
function Card.AddMaximumAtkHandler(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(aux.IsMaximumMode)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(c:GetMaximumAttack())
	c:RegisterEffect(e1)
end
--function that return the value of the "maximum atk" of the monster
function Card.GetMaximumAttack(c)
	local m=c:GetMetatable(true)
	if not m then return false end
	return m.MaximumAttack
end
--function that provide effects of the center piece to the side (mainly used for protection effects)
function Card.AddCenterToSideEffectHandler(c,eff)
	--grant effect to center
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCondition(Maximum.centerCon)
	e1:SetTarget(Maximum.eftg)
	e1:SetLabelObject(eff)
	c:RegisterEffect(e1)
end
function Maximum.eftg(e,c)
	return c:IsType(TYPE_EFFECT) and c:IsMaximumModeSide()
end
function Maximum.centerCon(e)
	return e:GetHandler():IsMaximumModeCenter()
end
--function to add everything related to Left/Right Maximum Monster behaviour
--c=card to register
--tc=center maximum card
function Card.AddSideMaximumHandler(c,eff)
	--change atk
	local baseeff=Effect.CreateEffect(c)
	baseeff:SetType(EFFECT_TYPE_SINGLE)
	baseeff:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	baseeff:SetRange(LOCATION_MZONE)
	baseeff:SetCondition(Maximum.sideCon)
	
	local e1=baseeff:Clone()
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(Maximum.maxCenterVal(Card.GetMaximumAttack))
	c:RegisterEffect(e1)
	
	--change level
	local e2=baseeff:Clone()
	e2:SetCode(EFFECT_CHANGE_LEVEL)
	e2:SetValue(Maximum.maxCenterVal(Card.GetLevel))
	c:RegisterEffect(e2)
	--change name
	local e3=baseeff:Clone()
	e3:SetCode(EFFECT_CHANGE_CODE)
	e3:SetValue(Maximum.maxCenterVal(Card.GetCode))
	c:RegisterEffect(e3)
	--change Race
	local e4=baseeff:Clone()
	e4:SetCode(EFFECT_CHANGE_RACE)
	e4:SetValue(Maximum.maxCenterVal(Card.GetRace))
	c:RegisterEffect(e4)
	--change attribute
	local e5=baseeff:Clone()
	e5:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e5:SetValue(Maximum.maxCenterVal(Card.GetAttribute))
	c:RegisterEffect(e5)
	--grant effect to center
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(LOCATION_MZONE,0)
	e6:SetCondition(Maximum.sideCon)
	e6:SetTarget(Maximum.eftgMax)
	e6:SetLabelObject(eff)
	c:RegisterEffect(e6)
	
	--cannot be battle target
	local e7=baseeff:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
	e7:SetValue(aux.imval1)
	c:RegisterEffect(e7)
	
	--cannot be changed to def
	local e8=baseeff:Clone()
	e8:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
	c:RegisterEffect(e8)
	local e8=baseeff:Clone()
	e8:SetCode(EFFECT_CANNOT_CHANGE_POS_E)
	c:RegisterEffect(e8)
	
	--cannot be tributed for a tribute summon
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_SINGLE)
	e10:SetCode(EFFECT_UNRELEASABLE_SUM)
	e10:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e10:SetCondition(Maximum.sideCon)
	e10:SetValue(1)
	c:RegisterEffect(e10)
	--cannot declare attack
	local e11=Effect.CreateEffect(c)
	e11:SetType(EFFECT_TYPE_SINGLE)
	e11:SetCode(EFFECT_CANNOT_ATTACK)
	e11:SetCondition(Maximum.sideCon)
	c:RegisterEffect(e11)
	baseeff:Reset()
end
function Maximum.GetMaximumCenter(tp)
	return Duel.GetMatchingGroup(Card.IsMaximumModeCenter,tp,LOCATION_MZONE,0,nil):GetFirst()
end
function Maximum.maxCenterVal(f)
	return function(e,c)
		local tc=Maximum.GetMaximumCenter(e:GetHandlerPlayer())
		return tc and f(tc)
	end
end
function Maximum.eftgMax(e,c)
	return c:IsType(TYPE_EFFECT) and c:IsMaximumMode() and c~=e:GetHandler()
end
function Maximum.sideCon(e)
	local tc=Maximum.GetMaximumCenter(e:GetHandlerPlayer())
	return tc and e:GetHandler():IsMaximumModeSide()
end
function Maximum.sideConGrant(e)
	local tc=Maximum.GetMaximumCenter(e:GetHandlerPlayer())
	return tc and e:GetHandler():IsMaximumModeSide()
end
--function that return if the max monster used an effect 
function Card.HasUsedIgnition(c,effID)
	return c:GetFlagEffect(effID)>0
end 
--function that return false if the monster don't have defense stats
--wait for ruling
function Card.HasDefense(c)
	return not (c:IsType(TYPE_LINK) or (c:IsType(TYPE_MAXIMUM) and c:IsMaximumMode()))
end
-- function that add the flag to says "I used that effect once this turn"
function Duel.RegisterMaxIgnition(tp,effid)
	local g=Duel.GetMatchingGroup(Card.IsMaximumMode,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		tc:RegisterFlagEffect(effid,RESET_EVENT+RESETS_STANDARD,0,1)
	end
end

--functions to handle counting monsters but without the side Maximum monsters (the L/R max monsters are subtracted from the count)
function Duel.GetMatchingGroupCountRush(f,tp,LOCP1,LOCP2,exclude)
	local maxi=Duel.GetMatchingGroupCount(aux.FilterMaximumSideFunction(f),tp,LOCP1,LOCP2,exclude)
	return Duel.GetMatchingGroupCount(f,tp,LOCP1,LOCP2,exclude)-maxi
end
--function that return only the side monsters
function Auxiliary.FilterMaximumSideFunction(f,...)
	local params={...}
	return 	function(target)
				return target:IsMaximumModeSide() and f(target,table.unpack(params))
			end
end
--function that exclude L/R Maximum Mode
function Auxiliary.FilterMaximumSideFunctionEx(f,...)
	local params={...}
	return 	function(target)
				 return 
				 ((not target:IsMaximumMode()) or (not (target:IsMaximumMode() and not target:IsMaximumModeCenter()))) 
				 and f(target,table.unpack(params))
			end
end
-- function that return the count of a location P1 et P2 minus the Maximum Side
function Duel.GetFieldGroupCountRush(player, p1, p2)
	return Duel.GetMatchingGroupCount(Maximum.GroupCountFunction,player,p1,p2,nil)
end
--function used only in Duel.GetFieldGroupCountRush because the old implementation did not wanted to work
function Maximum.GroupCountFunction(c)
	return ((not c:IsMaximumMode()) or (not (c:IsMaximumMode() and not c:IsMaximumModeCenter()))) 
end
--function that add every parts of the Maximum Mode monster to the group
function Group.AddMaximumCheck(group)
	local g=group:Clone()
	for tc in aux.Next(group) do
		if tc:IsMaximumMode() then
			local g2=Duel.GetMatchingGroup(Card.IsMaximumMode,tc:GetControler(),LOCATION_MZONE,0,tc)
			g:Merge(g2)
		end
	end
	return g
end
--function used to register an effect on all part of a Maximum monster instead of just a part (for ex, if you want to update the atk, you use that effect to register the EFFECT_UPDATE_ATTACK to the 3 part of the monster)
function Card.RegisterEffectRush(c,eff)
	if c:IsMaximumMode() then
		local g=Duel.GetMatchingGroup(Card.IsMaximumMode,c:GetControler(),LOCATION_MZONE,0,nil)
		for tc in aux.Next(g) do
			local eff2=eff:Clone()
			tc:RegisterEffect(eff2)
		end
	else
		c:RegisterEffect(eff)
	end
end
-- summon only in attack
local function initial_effect()
    local e1=Effect.GlobalEffect()
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_FORCE_SPSUMMON_POSITION)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,1)
    e1:SetTarget(aux.TargetBoolFunction(Card.IsSummonType,SUMMON_TYPE_MAXIMUM))
    e1:SetValue(POS_FACEUP_ATTACK)
    Duel.RegisterEffect(e1,0)
    local e2=Effect.GlobalEffect()
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_FORCE_MZONE)
    e2:SetTargetRange(0xff,0xff)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsSummonType,SUMMON_TYPE_MAXIMUM))
    e2:SetValue(function(e,c)
					if c:IsMaximumModeCenter() then
						return 0x4
					end
					return 0xa
				end)
    Duel.RegisterEffect(e2,0)
end
initial_effect()



-- handling for tribute summon
function Maximum.cfilter(c,tp)
    return c:IsReason(REASON_SUMMON) and c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousControler(tp)
end
function Maximum.tribcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Maximum.cfilter,1,nil,tp)
end
function Maximum.tribop(e,tp,eg,ep,ev,re,r,rp)
	local c=eg:GetFirst()
	local g=Duel.GetMatchingGroup(Card.IsMaximumMode,c:GetControler(),LOCATION_MZONE,0,nil)
	Duel.Sendto(g,c:GetDestination(),0)
	for tc in aux.Next(g) do
		tc:SetReason(c:GetReason())
	end
end
--handling for battle destruction
function Maximum.battlecon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_BATTLE) and eg:IsExists(Card.IsControler,1,nil,tp)
end
function Maximum.battleop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsMaximumMode,e:GetHandler():GetControler(),LOCATION_MZONE,0,nil)
	Duel.Sendto(g,e:GetHandler():GetDestination(),nil)
	for tc in aux.Next(g) do
		tc:SetReason(eg:GetFirst():GetReason())
	end
end