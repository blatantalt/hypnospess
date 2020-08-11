#define DICK_MOVEMENT_SPEED "hugedick"
#define BREAST_MOVEMENT_SPEED "megamilk"

/datum/status_effect/chem/SGDF
	id = "SGDF"
	var/mob/living/fermi_Clone
	var/mob/living/original
	var/datum/mind/originalmind
	var/status_set = FALSE
	alert_type = null

/datum/status_effect/chem/SGDF/on_apply()
	log_reagent("FERMICHEM: SGDF status appied on [owner], ID: [owner.key]")
	fermi_Clone = owner
	return ..()

/datum/status_effect/chem/SGDF/tick()
	if(!status_set)
		return ..()
	if(original.stat == DEAD || original == null || !original)
		if((fermi_Clone && fermi_Clone.stat != DEAD) || (fermi_Clone == null))
			if(originalmind)
				owner.remove_status_effect(src)
	..()

/datum/status_effect/chem/SGDF/on_remove()
	log_reagent("FERMICHEM: SGDF mind shift applied. [owner] is now playing as their clone and should not have memories after their clone split (look up SGDF status applied). ID: [owner.key]")
	originalmind.transfer_to(fermi_Clone)
	to_chat(owner, "<span class='warning'>Lucidity shoots to your previously blank mind as your mind suddenly finishes the cloning process. You marvel for a moment at yourself, as your mind subconciously recollects all your memories up until the point when you cloned yourself. Curiously, you find that you memories are blank after you ingested the synthetic serum, leaving you to wonder where the other you is.</span>")
	fermi_Clone = null
	return ..()

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/status_effect/chem/breast_enlarger
	id = "breast_enlarger"
	alert_type = null
	var/moveCalc = 1
	var/cachedmoveCalc = 1
	var/last_checked_size //used to prevent potential cpu waste from happening every tick.

/datum/status_effect/chem/breast_enlarger/on_apply()//Removes clothes, they're too small to contain you. You belong to space now.
	log_reagent("FERMICHEM: [owner]'s breasts has reached comical sizes. ID: [owner.key]")
	return ..()

/datum/status_effect/chem/breast_enlarger/tick()//If you try to wear clothes, you fail. Slows you down if you're comically huge
	var/mob/living/carbon/human/H = owner
	var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!B)
		H.remove_status_effect(src)
		return
	moveCalc = 1+((round(B.cached_size) - 9)/3) //Afffects how fast you move, and how often you can click.

	if(last_checked_size != B.cached_size)
		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/status_effect/breast_hypertrophy, multiplicative_slowdown = moveCalc)

	if (B.size == "huge")
		if(prob(1))
			to_chat(owner, "<span class='notice'>Your back is feeling sore.</span>")
			var/target = H.get_bodypart(BODY_ZONE_CHEST)
			H.apply_damage(0.1, BRUTE, target)
	else
		if(prob(1))
			to_chat(H, "<span class='notice'>Your back is feeling a little sore.</span>")
	last_checked_size = B.cached_size
	..()

/datum/status_effect/chem/breast_enlarger/on_remove()
	log_reagent("FERMICHEM: [owner]'s breasts has reduced to an acceptable size. ID: [owner.key]")
	to_chat(owner, "<span class='notice'>Your expansive chest has become a more managable size, liberating your movements.</b></span>")
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/breast_hypertrophy)
	return ..()

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/status_effect/chem/penis_enlarger
	id = "penis_enlarger"
	alert_type = null
	var/bloodCalc
	var/moveCalc
	var/last_checked_size //used to prevent potential cpu waste, just like the above.

/datum/status_effect/chem/penis_enlarger/on_apply()//Removes clothes, they're too small to contain you. You belong to space now.
	log_reagent("FERMICHEM: [owner]'s dick has reached comical sizes. ID: [owner.key]")
	return ..()


/datum/status_effect/chem/penis_enlarger/tick()
	var/mob/living/carbon/human/H = owner
	var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!P)
		owner.remove_status_effect(src)
		return
	moveCalc = 1+((round(P.length) - 21)/3) //effects how fast you can move
	bloodCalc = 1+((round(P.length) - 21)/15) //effects how much blood you need (I didn' bother adding an arousal check because I'm spending too much time on this organ already.)
	if(P.length < 22 && H.has_movespeed_modifier(/datum/movespeed_modifier/status_effect/penis_hypertrophy))
		to_chat(owner, "<span class='notice'>Your rascally willy has become a more managable size, liberating your movements.</b></span>")
		H.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/penis_hypertrophy)
	else if(P.length >= 22 && !H.has_movespeed_modifier(/datum/movespeed_modifier/status_effect/penis_hypertrophy))
		to_chat(H, "<span class='warning'>Your indulgent johnson is so substantial, it's taking all your blood and affecting your movements!</b></span>")
		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/status_effect/penis_hypertrophy, multiplicative_slowdown = moveCalc)
	H.AdjustBloodVol(bloodCalc)
	..()

/datum/status_effect/chem/penis_enlarger/on_remove()
	log_reagent("FERMICHEM: [owner]'s dick has reduced to an acceptable size. ID: [owner.key]")
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/penis_hypertrophy)
	owner.ResetBloodVol()
	return ..()

///////////////////////////////////////////////
//			Astral INSURANCE
///////////////////////////////////////////////
//Makes sure people can't get trapped in each other's bodies if lag causes a deync between proc calls.


/datum/status_effect/chem/astral_insurance
	id = "astral_insurance"
	var/mob/living/original
	var/datum/mind/originalmind
	alert_type = null

/datum/status_effect/chem/astral_insurance/tick(mob/living/carbon/M)
	. = ..()
	if(owner.reagents.has_reagent(/datum/reagent/fermi/astral))
		return
	if(owner.mind == originalmind) //If they're home, let the chem deal with deletion.
		return
	if(owner.mind)
		var/mob/living/simple_animal/astral/G = new(get_turf(M.loc))
		owner.mind.transfer_to(G)//Just in case someone else is inside of you, it makes them a ghost and should hopefully bring them home at the end.
		to_chat(G, "<span class='warning'>[M]'s conciousness snaps back to them as their astrogen runs out, kicking your projected mind out!'</b></span>")
		log_reagent("FERMICHEM: [M]'s possesser has been booted out into a astral ghost!")
	originalmind.transfer_to(original)

/datum/status_effect/chem/astral_insurance/on_remove() //God damnit get them home!
	if(owner.mind != originalmind) //If they're home, HOORAY
		if(owner.mind)
			var/mob/living/simple_animal/astral/G = new(get_turf(owner))
			owner.mind.transfer_to(G)//Just in case someone else is inside of you, it makes them a ghost and should hopefully bring them home at the end.
			to_chat(G, "<span class='warning'>[owner]'s conciousness snaps back to them as their astrogen runs out, kicking your projected mind out!'</b></span>")
			log_reagent("FERMICHEM: [owner]'s possesser has been booted out into a astral ghost!")
		originalmind.transfer_to(original)
	return ..()

/*//////////////////////////////////////////
		Mind control functions!
///////////////////////////////////////////
*/

/*/////////////////////////////////////////
	The Big Enthrall Rework
	We want enthrall to be independant of MKUltra.
	This means that MKUltra will grant enthrall when consumed,
	and will update the enthrall variables as before.

	This might mean we'd want to make enthrall
	datum/status_effect/<something else?>/enthrall
	rather than
	datum/status_effect/chem/enthrall
	as it's no longer directly tied to a chem.
////////////////////////////////////////////
*/

//Preamble

/mob/living/verb/toggle_hypno()
	set category = "IC"
	set name = "Toggle Lewd Hypno"
	set desc = "Allows you to toggle if you'd like lewd flavour messages for hypno features, such as MKUltra."
	client.prefs.cit_toggles ^= HYPNO
	to_chat(usr, "You [((client.prefs.cit_toggles & HYPNO) ?"will":"will no longer")] receive lewd flavour messages for hypno.")

/datum/status_effect/chem/enthrall
	id = "enthrall"
	alert_type = null
	//examine_text TODO
	var/enthrallTally = 1 //Keeps track of the enthralling process
	var/resistanceTally = 0 //Keeps track of the resistance
	var/deltaResist //The total resistance added per resist click

	var/phase = 1 //-1: resisted state, due to be removed.0: sleeper agent, no effects unless triggered 1: initial, 2: 2nd stage - more commands, 3rd: fully enthralled, 4th Mindbroken
	var/phaselimit = 4 //the maximum allowed phase of the effect. By default, all phases are available, but it may depend on the source.

	var/status = null //status effects
	var/statusStrength = 0 //strength of status effect

	var/mob/living/master //Enchanter's person
	var/enthrallID //Enchanter's ckey
	var/enthrallTitle //Enchanter's title
	var/subjectTerm //Subject's term

	var/initialSetup = FALSE //has the status effect been set up and logged
	var/isExposed = FALSE //Registers whether or not the player is actually exposed to the thing that's causing their enthrallment (MKUltra in bloodstream, hypnotic eyes, etc.)
	var/list/enthrallSources = list() //List of all enthrall sources.

	var/mental_capacity //Higher it is, lower the cooldown on commands, capacity reduces with resistance.

	var/distancelist = list(2,1.5,1,0.8,0.6,0.5,0.4,0.3,0.2) //Distance multipliers

	var/withdrawal = FALSE //withdrawl
	var/withdrawalTick = 0 //counts how long withdrawl is going on for

	var/list/customTriggers = list() //the list of custom triggers

	var/cooldown = 0 //cooldown on commands
	var/cooldownMsg = TRUE //If cooldown message has been sent
	var/cTriggered = FALSE //If someone is triggered (so they can't trigger themselves with what they say for infinite loops)
	var/resistGrowth = 0 //Resistance accrues over time
	var/DistApart = 1 //Distance between master and owner
	var/tranceTime = 0 //how long trance effects apply on trance status

	var/customEcho	//Custom looping text in owner
	var/customSpan	//Custom spans for looping text

	var/lewd = FALSE // Set on on_apply. Will only be true if both individuals involved have opted in.

/datum/status_effect/chem/enthrall/on_apply()
	. = ..()
	var/mob/living/carbon/M = owner
	if(!istype(M))
		return FALSE
	//We're gonna make a proc that defines the master and such
	//be ready to delete the next three lines and remove the args if they cause problems
	//enthrallID = masterID
	//enthrallTitle = masterTitle
	//phaselimit = maxPhase

	subjectTerm = M.client?.prefs.custom_names["subject"]
	//if(M.ckey == enthrallID)
	//	owner.remove_status_effect(src)//At the moment, a user can enthrall themselves, toggle this back in if that should be removed.
	RegisterSignal(owner, COMSIG_LIVING_RESIST, .proc/owner_resist) //Do resistance calc if resist is pressed#
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, .proc/owner_hear)
	mental_capacity = 500 - M.getOrganLoss(ORGAN_SLOT_BRAIN)//It's their brain!

/datum/status_effect/chem/enthrall/tick()
	var/mob/living/carbon/M = owner
	//Before doing anything else! Make sure that the vars are properly set up!
	if(!master || !enthrallID || !enthrallTitle || !phaselimit)
		return //the values aren't set up yet so do nothing.
	if(initialSetup == FALSE)
		var/message = "[(lewd ? "I am a good [subjectTerm] for [enthrallTitle]." : "[master] always knows just what to say.")]"
		SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "enthrall", /datum/mood_event/enthrall, message)
		to_chat(owner, "<span class='[(lewd ?"big velvet":"big warning")]'><b>You feel inexplicably drawn towards [master], their words having a demonstrable effect on you. It seems the closer you are to them, the stronger the effect is. However you aren't fully swayed yet and can fight against their effects by resisting repeatedly!</b></span>")
		log_reagent("FERMICHEM: Enthrallment: Status applied on [owner] ckey: [owner.key] with a master of [master] ckey: [enthrallID].")
		SSblackbox.record_feedback("tally", "fermi_chem", 1, "Enthrall attempts")
		initialSetup = TRUE
	if(phase > phaselimit)
		phase = phaselimit //just make sure we don't surpass the phase limit.
	//breaking free
	if(!enthrallSources.len)
		if (phase < 3 && phase != 0)
			deltaResist += 3//If you're not exposed, then you break out quickly
			if(prob(5))
				to_chat(owner, "<span class='notice'><i>Your mind regains some of it's clarity as you're no longer exposed to the source of your enthrallment.</i></span>")

	//chem calculations
	if (mental_capacity <= 500 || phase == 4)
		if (owner.reagents.has_reagent(/datum/reagent/medicine/mannitol))
			mental_capacity += 5
		if (owner.reagents.has_reagent(/datum/reagent/medicine/neurine))
			mental_capacity += 10

	//mindshield check
	if(HAS_TRAIT(M, TRAIT_MINDSHIELD))//If you manage to enrapture a head, wow, GJ. (resisting gives a bigger bonus with a mindshield) From what I can tell, this isn't possible.
		resistanceTally += 2
		if(prob(10))
			to_chat(owner, "<span class='notice'><i>You feel lucidity returning to your mind as the mindshield buzzes, attempting to return your brain to its normal functions.</i></span>")
		if(phase == 4)
			mental_capacity += 5

	//phase specific events
	switch(phase)
		if(-1)//fully removed
			SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "enthrall")
			log_reagent("FERMICHEM: Enthrallment: Status REMOVED from [owner] ckey: [owner.key] with a master of [master] ckey: [enthrallID].")
			owner.remove_status_effect(src)
			return
		if(0)// sleeper agent
			if (cooldown > 0)
				cooldown -= 1
			return
		if(1)//Initial enthrallment
			if (enthrallTally > 125 && phaselimit >= 2)
				phase += 1
				mental_capacity -= resistanceTally//leftover resistance per step is taken away from mental_capacity.
				resistanceTally /= 2
				enthrallTally = 0
				SSblackbox.record_feedback("tally", "fermi_chem", 1, "Enthralled to state 2")
				if(lewd)
					to_chat(owner, "<span class='big velvet'><i>Your conciousness slips as you sink deeper into trance and servitude to your [enthrallTitle].</i></span>")
				else
					to_chat(owner, "<span class='big velvet'><i>Your conciousness slips, and you find [master]'s words even more agreeable.'.</i></span>")

			else if (resistanceTally > 125)
				phase = -1
				to_chat(owner, "<span class='warning'><i>You break free of the influence in your mind, your thoughts suddenly turning lucid!</i></span>")
				if(DistApart < 10)
					to_chat(master, "<span class='warning'>[(lewd?"Your [subjectTerm]":"Your thrall")] seems to have broken free of your enthrallment!</i></span>")
				SSblackbox.record_feedback("tally", "fermi_chem", 1, "Thralls broken free")
				owner.remove_status_effect(src) //If resisted in phase 1, effect is removed.
			if(prob(10))
				if(lewd)
					to_chat(owner, "<span class='small velvet'><i>[pick("It feels so good to listen to [master].", "You can't keep your eyes off [master].", "[master]'s voice is making you feel so sleepy.",  "You feel so comfortable with [master]", "[master] is so dominant, it feels right to obey them.","[master]'s words soothe you and make you feel safe.")].</b></span>")
		if (2) //partially enthralled
			if(enthrallTally > 200 && phaselimit >= 3)
				phase += 1
				mental_capacity -= resistanceTally//leftover resistance per step is taken away from mental_capacity.
				enthrallTally = 0
				resistanceTally /= 2
				if(lewd)
					to_chat(owner, "<span class='love'><b><i>Your mind gives, eagerly obeying and serving [enthrallTitle].</b></i></span>")
					to_chat(owner, "<span class='big warning'><b>You are now fully enthralled to [master], and eager to follow their commands. In your submissive state you cannot stand the thought of being permanently separated from your [enthrallTitle] - the idea of becoming violent or committing suicide, even if ordered to, is unthinkable.</i></span>")//If people start using this as an excuse to be violent I'll just make them all pacifists so it's not OP.
				else
					to_chat(owner, "<span class='big nicegreen'><i>You are unable to put up a resistance any longer, and are now [master]'s faithful follower. In your loyal state you cannot stand the thought of being permanently separated from your [enthrallTitle] - the idea of becoming violent or committing suicide, even if ordered to, is unthinkable.</i></span>")
				to_chat(master, "<span class='notice'><i>Your [(lewd? "[subjectTerm]":"follower")] [owner] appears to have fully fallen under your sway.</i></span>")
				log_reagent("FERMICHEM: Enthrallment: Status on [owner] ckey: [owner.key] has been fully enthralled (state 3) with a master of [master] ckey: [enthrallID].")
				SSblackbox.record_feedback("tally", "fermi_chem", 1, "thralls fully enthralled.")
			else if (resistanceTally > 200)
				enthrallTally *= 0.5
				phase -= 1
				resistanceTally = 0
				resistGrowth = 0
				to_chat(owner, "<span class='notice'><i>You manage to shake some of the effects from your addled mind, however you can still feel yourself drawn towards [master].</i></span>")
			if(lewd && prob(10))
				to_chat(owner, "<span class='velvet'><i>[pick("It feels so good to listen to [enthrallTitle].", "You can't keep your eyes off [enthrallTitle].", "[enthrallTitle]'s voice is making you feel so sleepy.",  "You feel so comfortable with [enthrallTitle]", "[enthrallTitle] is so dominant, it feels right to obey them.","[master]'s words soothe you and make you feel safe.")].</i></span>")
		if (3)//fully entranced
			if ((resistanceTally >= 200 && withdrawalTick >= 150) || (HAS_TRAIT(M, TRAIT_MINDSHIELD) && (resistanceTally >= 100)))
				enthrallTally = 0
				phase -= 1
				resistanceTally = 0
				resistGrowth = 0
				to_chat(owner, "<span class='notice'><i>The separation from [(lewd?"your [enthrallTitle]":"[master]")] sparks a small flame of resistance in yourself, as your mind slowly starts to return to normal.</i></span>")
				REMOVE_TRAIT(owner, TRAIT_PACIFISM, "Enthrallment")
			if(lewd && prob(1) && !customEcho)
				to_chat(owner, "<span class='love'><i>[pick("I belong to [enthrallTitle].", "I obey [enthrallTitle].","[enthrallTitle] knows what's best for me.", "Obedence is pleasure.",  "I exist to serve [enthrallTitle].", "[enthrallTitle] is so dominant, it feels right to obey them.","I am [enthrallTitle]'s loyal [subjectTerm]")].</i></span>")
		if (4) //mindbroken
			if (phaselimit >= 4)
				if (mental_capacity >= 499 && (owner.getOrganLoss(ORGAN_SLOT_BRAIN) <=0 || HAS_TRAIT(M, TRAIT_MINDSHIELD)) && !owner.reagents.has_reagent(/datum/reagent/fermi/enthrall))
					phase = 2
					mental_capacity = 500
					customTriggers = list()
					to_chat(owner, "<span class='notice'><i>Your mind starts to heal, fixing the damage caused by the massive amounts of chemical injected into your system earlier, returning clarity to your mind. Though stragely, you still feel drawn towards [master]'s words...'</i></span>")
					M.slurring = 0
					M.confused = 0
					resistGrowth = 0
				else
					if (cooldown > 0)
						cooldown -= (0.8 + (mental_capacity/500))
						cooldownMsg = FALSE
					else if (cooldownMsg == FALSE)
						if(DistApart < 10)
							if(lewd)
								to_chat(master, "<span class='notice'><i>Your [subjectTerm] [owner] appears to have finished internalising your last command.</i></span>")
								cooldownMsg = TRUE
							else
								to_chat(master, "<span class='notice'><i>Your thrall [owner] appears to have finished internalising your last command.</i></span>")
								cooldownMsg = TRUE
					if(get_dist(master, owner) > 10)
						if(prob(10))
							to_chat(owner, "<span class='velvet'><i>You feel [(lewd ?"a deep <b>NEED</b> to return to your [enthrallTitle]":"like you have to return to [master]")].</i></span>")
							//M.throw_at(get_step_towards(master,owner), 5, 1)
					return//If you break the mind of someone, you can't use status effects on them.
			else
				phase = 3


	//distance calculations
	DistApart = get_dist(master, owner)
	switch(DistApart)
		if(0 to 8)//If the enchanter is within range, increase enthrallTally, remove withdrawal subproc and undo withdrawal effects.
			if(phase <= 2)
				enthrallTally += distancelist[get_dist(master, owner)+1]
			if(withdrawalTick > 0)
				withdrawalTick -= 1
			//calming effects
			M.hallucination = max(0, M.hallucination - 5)
			M.stuttering = max(0, M.stuttering - 5)
			M.jitteriness = max(0, M.jitteriness - 5)
			if(owner.getOrganLoss(ORGAN_SLOT_BRAIN) >=20)
				owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, -0.2)
			if(withdrawal == TRUE)
				REMOVE_TRAIT(owner, TRAIT_PACIFISM, "Enthrallment")
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing1")
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing2")
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing3")
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing4")
				withdrawal = FALSE
		if(9 to INFINITY)//If they're not nearby, enable withdrawl effects.
			withdrawal = TRUE

	//Withdrawal subproc:
	if (withdrawal == TRUE)//Your minions are really REALLY needy.
		switch(withdrawalTick)//denial
			if(5)//To reduce spam
				to_chat(owner, "<span class='big warning'><b>You are unable to complete [(lewd?"your [enthrallTitle]":"[master]")]'s orders without their presence, and any commands and objectives previously given to you are not in effect until you are reunited.</b></span>")
				ADD_TRAIT(owner, TRAIT_PACIFISM, "Enthrallment") //IMPORTANT
			if(10 to 35)//Gives wiggle room, so you're not SUPER needy
				if(prob(5))
					to_chat(owner, "<span class='notice'><i>You're starting to miss [(lewd?"your [enthrallTitle]":"[master]")].</i></span>")
				if(prob(5))
					owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.1)
					to_chat(owner, "<i>Surely [(lewd?"[enthrallTitle]":"[master]")] will be back soon.</i>") //denial
			if(36)
				var/message = "[(lewd?"I feel empty when [enthrallTitle]'s not around..":"I miss [master]'s presence")]"
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "EnthMissing1", /datum/mood_event/enthrallmissing1, message)
			if(37 to 65)//barganing
				if(prob(10))
					to_chat(owner, "<i>They are coming back, right...?</i>")
					owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.5)
				if(prob(10))
					if(lewd)
						to_chat(owner, "<i>I just need to be a good [subjectTerm] for [enthrallTitle], they'll surely return if I'm a good [subjectTerm].</i>")
					owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1.5)
			if(66)
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing1")
				var/message = "[(lewd?"I feel so lost in this complicated world without [enthrallTitle]..":"I have to return to [master]!")]"
				to_chat(owner, "<span class='warning'>You start to feel really angry about how you're not with [(lewd?"your [enthrallTitle]":"[master]")]!</span>")
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "EnthMissing2", /datum/mood_event/enthrallmissing2, message)
				owner.stuttering += 50
				owner.jitteriness += 250
			if(67 to 89) //anger
				if(prob(10))
					addtimer(CALLBACK(M, /mob/verb/a_intent_change, INTENT_HARM), 2)
					addtimer(CALLBACK(M, /mob/proc/click_random_mob), 2)
					if(lewd)
						to_chat(owner, "<span class='warning'>You are overwhelmed with anger at the lack of [enthrallTitle]'s presence and suddenly lash out!</span>")
					else
						to_chat(owner, "<span class='warning'>You are overwhelmed with anger and suddenly lash out!</span>")
			if(90)
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing2")
				var/message = "[(lewd?"Where are you [enthrallTitle]??!":"I need to find [master]!")]"
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "EnthMissing3", /datum/mood_event/enthrallmissing3, message)
				if(lewd)
					to_chat(owner, "<span class='warning'><i>You need to find your [enthrallTitle] at all costs, you can't hold yourself back anymore!</i></span>")
				else
					to_chat(owner, "<span class='warning'><i>You need to find [master] at all costs, you can't hold yourself back anymore!</i></span>")
			if(91 to 100)//depression
				if(prob(10))
					M.gain_trauma_type(BRAIN_TRAUMA_MILD)
					owner.stuttering += 35
					owner.jitteriness += 35
				else if(prob(25))
					M.hallucination += 10
			if(101)
				SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing3")
				var/message = "[(lewd?"I'm all alone, It's so hard to continue without [enthrallTitle]...":"I really need to find [master]!!")]"
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "EnthMissing4", /datum/mood_event/enthrallmissing4, message)
				to_chat(owner, "<span class='warning'><i>You can hardly find the strength to continue without [(lewd?"your [enthrallTitle]":"[master]")].</i></span>")
				M.gain_trauma_type(BRAIN_TRAUMA_SEVERE)
			if(102 to 140) //depression 2, revengeance
				if(prob(20))
					owner.Stun(50)
					owner.emote("cry")//does this exist?
					if(lewd)
						to_chat(owner, "<span class='warning'><i>You're unable to hold back your tears, suddenly sobbing as the desire to see your [enthrallTitle] once more overwhelms you.</i></span>")
					else
						to_chat(owner, "<span class='warning'><i>You are overwheled with withdrawl from [master].</i></span>")
					owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1)
					owner.stuttering += 35
					owner.jitteriness += 35
					if(prob(10))//2% chance
						switch(rand(1,5))//Now let's see what hopefully-not-important part of the brain we cut off
							if(1 to 3)
								M.gain_trauma_type(BRAIN_TRAUMA_MILD)
							if(4)
								M.gain_trauma_type(BRAIN_TRAUMA_SEVERE)
							if(5)//0.4% chance
								M.gain_trauma_type(BRAIN_TRAUMA_SPECIAL)
				if(prob(5))
					deltaResist += 5
			if(140 to INFINITY) //acceptance
				if(prob(15))
					deltaResist += 5
					owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1)
					if(prob(20))
						if(lewd)
							to_chat(owner, "<i><span class='small green'>Maybe you'll be okay without your [enthrallTitle].</i></span>")
						else
							to_chat(owner, "<i><span class='small green'>You feel your mental functions slowly begin to return.</i></span>")
				if(prob(5))
					owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1)
					M.hallucination += 30

		withdrawalTick += 0.5//Enough to leave you with a major brain trauma, but not kill you.

	//Status subproc - statuses given to you from your Master
	//currently 3 statuses; antiresist -if you press resist, increases your enthrallment instead, HEAL - which slowly heals the pet, CHARGE - which breifly increases speed, PACIFY - makes pet a pacifist, ANTIRESIST - frustrates resist presses.
	if (status)

		if(status == "Antiresist")
			if (statusStrength < 0)
				status = null
				to_chat(owner, "<span class='notice'><i>Your mind feels able to resist once more.</i></span>")
			else
				statusStrength -= 1

		else if(status == "heal")
			if (statusStrength < 0)
				status = null
				to_chat(owner, "<span class='notice'><i>You finish licking your wounds.</i></span>")
			else
				statusStrength -= 1
				owner.heal_overall_damage(1, 1, 0, FALSE, FALSE)
				cooldown += 1 //Cooldown doesn't process till status is done

		else if(status == "charge")
			owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/mkultra)
			status = "charged"
			if(lewd)
				to_chat(owner, "<span class='notice'><i>Your [enthrallTitle]'s order fills you with a burst of speed!</i></span>")
			else
				to_chat(owner, "<span class='notice'><i>[master]'s command fills you with a burst of speed!</i></span>")

		else if (status == "charged")
			if (statusStrength < 0)
				status = null
				owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/mkultra)
				owner.DefaultCombatKnockdown(50)
				to_chat(owner, "<span class='notice'><i>Your body gives out as the adrenaline in your system runs out.</i></span>")
			else
				statusStrength -= 1
				cooldown += 1 //Cooldown doesn't process till status is done

		else if (status == "pacify")
			ADD_TRAIT(owner, TRAIT_PACIFISM, "EnthrallmentStatus")
			status = null

			//Truth serum?
			//adrenals?

	//customEcho
	if(customEcho && withdrawal == FALSE && lewd)
		if(prob(2))
			if(!customSpan) //just in case!
				customSpan = "notice"
			to_chat(owner, "<span class='[customSpan]'><i>[customEcho].</i></span>")

	//final tidying
	resistanceTally  += deltaResist
	deltaResist = 0
	if(cTriggered >= 0)
		cTriggered -= 1
	if (cooldown > 0)
		cooldown -= (0.8 + (mental_capacity/500))
		cooldownMsg = FALSE
	else if (cooldownMsg == FALSE)
		if(DistApart < 10)
			if(lewd)
				to_chat(master, "<span class='notice'><i>Your [subjectTerm] [owner] appears to have finished internalising your last command.</i></span>")
			else
				to_chat(master, "<span class='notice'><i>Your thrall [owner] appears to have finished internalising your last command.</i></span>")
		cooldownMsg = TRUE
		cooldown = 0
	if (tranceTime > 0 && tranceTime != 51) //custom trances only last 50 ticks.
		tranceTime -= 1
	else if (tranceTime == 0) //remove trance after.
		M.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY)
		M.remove_status_effect(/datum/status_effect/trance)
		tranceTime = 51
	//..()

//Remove all stuff
/datum/status_effect/chem/enthrall/on_remove()
	var/mob/living/carbon/M = owner
	M.mind?.remove_antag_datum(/datum/antagonist/brainwashed)
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "enthrall")
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "enthrallpraise")
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "enthrallscold")
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing1")
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing2")
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing3")
	SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "EnthMissing4")
	UnregisterSignal(M, COMSIG_LIVING_RESIST)
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "Enthrallment")
	to_chat(owner, "<span class='big redtext'><i>You're now free of [master]'s influence, and fully independent!'</i></span>")
	UnregisterSignal(owner, COMSIG_GLOB_LIVING_SAY_SPECIAL)
	return ..()

/datum/status_effect/chem/enthrall/proc/setup_vars(masterID, masterTitle, maxPhase)
	//this proc just sets up the big important variables, and is how the master is set up
	//It should ALWAYS BE CALLED when adding enthrall, or else you'll run into Fun Issues(tm)
	enthrallID = masterID
	enthrallTitle = masterTitle
	if (!isnum(maxPhase))
		return
	switch (maxPhase)
		if (0 to 4)
			phaselimit = maxPhase
		if (5 to INFINITY)
			log_reagent("WARNING: FERMICHEM: ENTHRALL: Failed to setup values for status on [owner] ckey: [owner.key]! Maximum phase greater than 4.")
	master = get_mob_by_key(enthrallID)
	log_reagent("FERMICHEM: ENTHRALL: Status applied on [owner] ckey: [owner.key] with a master of [master] ckey: [enthrallID], and maximum phase of [phaselimit].")
	lewd = (owner.client?.prefs.cit_toggles & HYPNO) && (master.client?.prefs.cit_toggles & HYPNO)
	return

/datum/status_effect/chem/enthrall/proc/owner_hear(datum/source, list/hearing_args)
	if(lewd == FALSE)
		return
	if (cTriggered > 0)
		return
	var/mob/living/carbon/C = owner
	var/raw_message = lowertext(hearing_args[HEARING_RAW_MESSAGE])
	for (var/trigger in customTriggers)
		var/cached_trigger = lowertext(trigger)
		if (findtext(raw_message, cached_trigger))//if trigger1 is the message
			cTriggered = 5 //Stops triggerparties and as a result, stops servercrashes.
			log_reagent("FERMICHEM: Enthrallment: [owner] ckey: [owner.key] has been triggered with [cached_trigger] from [hearing_args[HEARING_SPEAKER]] saying: \"[hearing_args[HEARING_MESSAGE]]\". (their master being [master] ckey: [enthrallID].)")

			//Speak (Forces player to talk)
			if (lowertext(customTriggers[trigger][1]) == "speak")//trigger2
				var/saytext = "Your mouth moves on it's own before you can even catch it."
				addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, C, "<span class='notice'><i>[saytext]</i></span>"), 5)
				addtimer(CALLBACK(C, /atom/movable/proc/say, "[customTriggers[trigger][2]]"), 5)
				log_reagent("FERMICHEM: Enthrallment: [owner] ckey: [owner.key] has been forced to say: \"[customTriggers[trigger][2]]\" from previous trigger.")


			//Echo (repeats message!) allows customisation, but won't display var calls! Defaults to hypnophrase.
			else if (lowertext(customTriggers[trigger][1]) == "echo")//trigger2
				addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, C, "<span class='velvet'><i>[customTriggers[trigger][2]]</i></span>"), 5)
				//(to_chat(owner, "<span class='hypnophrase'><i>[customTriggers[trigger][2]]</i></span>"))//trigger3

			//Shocking truth!
			else if (lowertext(customTriggers[trigger]) == "shock")
				if (lewd && ishuman(C))
					var/mob/living/carbon/human/H = C
					H.adjust_arousal(5)
				C.jitteriness += 100
				C.stuttering += 25
				C.DefaultCombatKnockdown(60)
				C.Stun(60)
				to_chat(owner, "<span class='warning'><i>Your muscles seize up, then start spasming wildy!</i></span>")

			//wah intensifies wah-rks
			else if (lowertext(customTriggers[trigger]) == "cum")//aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
				if (lewd)
					if(ishuman(C))
						var/mob/living/carbon/human/H = C
						H.mob_climax(forced_climax=TRUE)
					C.SetStun(10)//We got your stun effects in somewhere, Kev.
				else
					C.throw_at(get_step_towards(hearing_args[HEARING_SPEAKER],C), 3, 1) //cut this if it's too hard to get working

			//kneel (knockdown)
			else if (lowertext(customTriggers[trigger]) == "kneel")//as close to kneeling as you can get, I suppose.
				to_chat(owner, "<span class='notice'><i>You drop to the ground unsurreptitiously.</i></span>")
				C.lay_down()

			//strip (some) clothes
			else if (lowertext(customTriggers[trigger]) == "strip")//This wasn't meant to just be a lewd thing oops.
				var/mob/living/carbon/human/o = owner
				var/items = o.get_contents()
				for(var/obj/item/W in items)
					if(W == o.w_uniform || W == o.wear_suit)
						o.dropItemToGround(W, TRUE)
				to_chat(owner,"<span class='notice'><i>You feel compelled to strip your clothes.</i></span>")

			//trance
			else if (lowertext(customTriggers[trigger]) == "trance")//Maaaybe too strong. Weakened it, only lasts 50 ticks.
				var/mob/living/carbon/human/o = owner
				o.apply_status_effect(/datum/status_effect/trance, 200, TRUE)
				tranceTime = 50
				log_reagent("FERMICHEM: Enthrallment: [owner] ckey: [owner.key] has been tranced from previous trigger.")

	return

/datum/status_effect/chem/enthrall/proc/owner_resist()
	var/mob/living/carbon/M = owner
	to_chat(owner, "<span class='notice'><i>You attempt to fight against [master]'s influence!</i></span>")

	//Able to resist checks
	if (status == "Sleeper" || phase == 0)
		return
	else if (phase == 4)
		if(lewd)
			to_chat(owner, "<span class='warning'><i>Your mind is too far gone to even entertain the thought of resisting. Unless you can fix the brain damage, you won't be able to break free of your [enthrallTitle]'s control.</i></span>")
		else
			to_chat(owner, "<span class='warning'><i>Your brain is too overwhelmed with from the high volume of chemicals in your system, rendering you unable to resist, unless you can fix the brain damage.</i></span>")
		return
	else if (phase == 3 && withdrawal == FALSE)
		if(lewd)
			to_chat(owner, "<span class='hypnophrase'><i>The presence of your [enthrallTitle] fully captures the horizon of your mind, removing any thoughts of resistance. If you get split up from them, then you might be able to entertain the idea of resisting.</i></span>")
		else
			to_chat(owner, "<span class='hypnophrase'><i>You are unable to resist [master] in your current state. If you get split up from them, then you might be able to resist.</i></span>")
		return
	else if (status == "Antiresist")//If ordered to not resist; resisting while ordered to not makes it last longer, and increases the rate in which you are enthralled.
		if (statusStrength > 0)
			if(lewd)
				to_chat(owner, "<span class='warning'><i>The order from your [enthrallTitle] to give in is conflicting with your attempt to resist, drawing you deeper into trance! You'll have to wait a bit before attemping again, lest your attempts continue to be frustrated.</i></span>")
			else
				to_chat(owner, "<span class='warning'><i>The order from your [master] to give in is conflicting with your attempt to resist. You'll have to wait a bit before attemping again, lest your attempts continue to be frustrated.</i></span>")
			statusStrength += 1
			enthrallTally += 1
			return
		else
			status = null

	//base resistance
	if (deltaResist != 0)//So you can't spam it, you get one deltaResistance per tick.
		deltaResist += 0.1 //Though I commend your spamming efforts.
		return
	else
		deltaResist = 1.8 + resistGrowth
		resistGrowth += 0.05

	//distance modifer
	switch(DistApart)
		if(0)
			deltaResist *= 0.8
		if(1 to 8)//If they're far away, increase resistance.
			deltaResist *= (1+(DistApart/10))
		if(9 to INFINITY)//If
			deltaResist *= 2


	if(prob(5))
		M.emote("me",1,"squints, shaking their head for a moment.")//shows that you're trying to resist sometimes
		deltaResist *= 1.5

	//chemical resistance, brain and annaphros are the key to undoing, but the subject has to to be willing to resist.
	if (owner.reagents.has_reagent(/datum/reagent/medicine/mannitol))
		deltaResist *= 1.25
	if (owner.reagents.has_reagent(/datum/reagent/medicine/neurine))
		deltaResist *= 1.5
	if (!(owner.client?.prefs.cit_toggles & NO_APHRO) && lewd)
		if (owner.reagents.has_reagent(/datum/reagent/drug/anaphrodisiac))
			deltaResist *= 1.5
		if (owner.reagents.has_reagent(/datum/reagent/drug/anaphrodisiacplus))
			deltaResist *= 2
		if (owner.reagents.has_reagent(/datum/reagent/drug/aphrodisiac))
			deltaResist *= 0.75
		if (owner.reagents.has_reagent(/datum/reagent/drug/aphrodisiacplus))
			deltaResist *= 0.5
	//Antag resistance
	//cultists are already brainwashed by their god
	if(iscultist(owner))
		deltaResist *= 1.3
	else if (is_servant_of_ratvar(owner))
		deltaResist *= 1.3
	//antags should be able to resist, so they can do their other objectives. This chem does frustrate them, but they've all the tools to break free when an oportunity presents itself.
	else if (owner.mind.assigned_role in GLOB.antagonists)
		deltaResist *= 1.2

	//role resistance
	//Chaplains are already brainwashed by their god
	if(owner.mind.assigned_role == "Chaplain")
		deltaResist *= 1.2
	//Command staff has authority,
	if(owner.mind.assigned_role in GLOB.command_positions)
		deltaResist *= 1.1
	//Chemists should be familiar with drug effects
	if(owner.mind.assigned_role == "Chemist")
		deltaResist *= 1.2

	//Happiness resistance
	//Your Thralls are like pets, you need to keep them happy.
	if(owner.nutrition < 300)
		deltaResist += (300-owner.nutrition)/6
	if(owner.health < 100)//Harming your thrall will make them rebel harder.
		deltaResist *= ((120-owner.health)/100)+1
	//if(owner.mood.mood) //datum/component/mood TO ADD in FERMICHEM 2
	//Add cold/hot, oxygen, sanity, happiness? (happiness might be moot, since the mood effects are so strong)
	//Mental health could play a role too in the other direction

	//If you've a collar, you get a sense of pride
	if(istype(M.wear_neck, /obj/item/clothing/neck/petcollar))
		deltaResist *= 0.5
	if(HAS_TRAIT(M, TRAIT_MINDSHIELD))
		deltaResist += 5//even faster!

	return
