GLOBAL_LIST_EMPTY(servants_of_ratvar)	//List of minds in the cult
GLOBAL_LIST_EMPTY(all_servants_of_ratvar)	//List of minds in the cult
GLOBAL_LIST_EMPTY(human_servants_of_ratvar)	//Humans in the cult
GLOBAL_LIST_EMPTY(cyborg_servants_of_ratvar)

GLOBAL_VAR(ratvar_arrival_tick)	//The world.time that Ratvar will arrive if the gateway is not disrupted

GLOBAL_VAR_INIT(installed_integration_cogs, 0)

GLOBAL_VAR(celestial_gateway)	//The celestial gateway
GLOBAL_VAR_INIT(ratvar_risen, FALSE)	//Has ratvar risen?
GLOBAL_VAR_INIT(gateway_opening, FALSE)	//Is the gateway currently active?

//A useful list containing all scriptures with the index of the name.
//This should only be used for looking up scriptures
GLOBAL_LIST_EMPTY(clockcult_all_scriptures)

GLOBAL_VAR_INIT(clockcult_power, 2500)
GLOBAL_VAR_INIT(clockcult_vitality, 200)

GLOBAL_VAR(clockcult_eminence)

//==========================
//===Clock cult Gamemode ===
//==========================

/datum/game_mode/clockcult
	name = "clockcult"
	config_tag = "clockcult"
	report_type = "clockcult"
	false_report_weight = 5
	required_players = 24
	required_enemies = 4
	recommended_enemies = 4
	role_preference = /datum/role_preference/antagonist/clock_cultist
	antag_datum = /datum/antagonist/servant_of_ratvar

	title_icon = "clockcult"
	announce_span = "danger"
	announce_text = "A powerful group of fanatics is trying to summon their deity!\n \
	" + span_danger("Servants") + ": Convert more servants and defend the Ark of the Clockwork Justicar!\n \
	" + span_notice("Crew") + ": Prepare yourselfs and destroy the Ark of the Clockwork Justicar."

	var/clock_cultists = CLOCKCULT_SERVANTS
	var/list/selected_servants = list()

	var/datum/team/clock_cult/main_cult

/datum/game_mode/clockcult/setup_maps()
	//Since we are loading in pre_setup, disable map loading.
	SSticker.gamemode_hotswap_disabled = TRUE
	LoadReebe()
	return TRUE

/datum/game_mode/clockcult/pre_setup()
	//Generate cultists
	for(var/i in 1 to clock_cultists)
		if(!antag_candidates.len)
			break
		var/datum/mind/clockie = antag_pick(antag_candidates, /datum/role_preference/antagonist/clock_cultist)
		//In case antag_pick breaks
		if(!clockie)
			continue
		antag_candidates -= clockie
		selected_servants += clockie
		clockie.assigned_role = ROLE_SERVANT_OF_RATVAR
		clockie.special_role = ROLE_SERVANT_OF_RATVAR
		GLOB.pre_setup_antags += clockie
	generate_clockcult_scriptures()
	return TRUE

/datum/game_mode/clockcult/post_setup(report)
	var/list/spawns = GLOB.servant_spawns.Copy()
	main_cult = new
	main_cult.setup_objectives()
	//Create team
	for(var/datum/mind/servant_mind in selected_servants)
		//Somehow the mind has no mob, ignore them so it doesn't break everything
		if(!(servant_mind?.current))
			continue
		//Somehow all spawns where used, reuse old spawns
		if(!length(spawns))
			spawns = GLOB.servant_spawns.Copy()
		servant_mind.current.forceMove(pick_n_take(spawns))
		servant_mind.current.set_species(/datum/species/human)
		var/datum/antagonist/servant_of_ratvar/S = add_servant_of_ratvar(servant_mind.current, team=main_cult)
		S.equip_carbon(servant_mind.current)
		S.equip_servant()
		S.prefix = CLOCKCULT_PREFIX_MASTER
		GLOB.pre_setup_antags -= S
	//Setup the conversion limits for auto opening the ark
	calculate_clockcult_values()
	return ..()

/datum/game_mode/clockcult/generate_report()
	return "Central Command's higher dimensional affairs division has been recently investigating a huge, anomalous energy spike \
	emanating from a neutron star close to your sector. It is currently theorised that an ancient group of fanatics praising an \
	eldritch deity made from brass and other outdated materials are abusing the energy of the dying star to breach dimensional \
	boundaries. The bluespace veil is faltering at your current location, making it a prime target for dangerous individuals to \
	abuse dimensional interdiction. Any evidence of tampering with bluespace fields should be reported to your local chaplain and \
	Central Command if a connection is still available at the time of discovery."

/datum/game_mode/clockcult/set_round_result()
	..()
	if(check_cult_victory())
		SSticker.mode_result = "win - clockcult win"
		SSticker.news_report = CLOCK_SUMMON
	else if(LAZYLEN(GLOB.cyborg_servants_of_ratvar))
		SSticker.mode_result = "loss - staff destroyed the ark"
		SSticker.news_report = CLOCK_SILICONS
	else
		SSticker.mode_result = "loss - staff destroyed the ark"
		SSticker.news_report = CLOCK_PROSELYTIZATION

/datum/game_mode/clockcult/check_finished(force_ending)
	return force_ending

/datum/game_mode/clockcult/proc/check_cult_victory()
	return GLOB.ratvar_risen

/datum/game_mode/clockcult/generate_credit_text()
	var/list/round_credits = list()
	var/len_before_addition

	if(GLOB.ratvar_risen)
		round_credits += "<center><h1>Ratvar has been released from his prison!</h1>"
	else
		round_credits += "<center><h1>The clock cultists failed to summon Ratvar, he will remain trapped forever to rust!</h1>"
	round_credits += "<center><h1>The Servants of Ratvar:</h1>"
	len_before_addition = round_credits.len
	for(var/datum/mind/operative in GLOB.servants_of_ratvar)
		round_credits += "<center><h2>[operative.name] as a servant of Ratvar!</h2>"
	if(len_before_addition == round_credits.len)
		round_credits += list("<center><h2>The servants were annihilated!</h2>", "<center><h2>Their remains could not be identified!</h2>")
	round_credits += "<br>"

	round_credits += ..()
	return round_credits

/datum/game_mode/proc/update_clockcult_icons_added(datum/mind/cult_mind)
	var/datum/atom_hud/antag/culthud = GLOB.huds[ANTAG_HUD_CLOCKWORK]
	culthud.join_hud(cult_mind.current)
	set_antag_hud(cult_mind.current, "clockwork")

/datum/game_mode/proc/update_clockcult_icons_removed(datum/mind/cult_mind)
	var/datum/atom_hud/antag/culthud = GLOB.huds[ANTAG_HUD_CLOCKWORK]
	culthud.leave_hud(cult_mind.current)
	set_antag_hud(cult_mind.current, null)

//==========================
//==== Clock cult procs ====
//==========================

/proc/is_servant_of_ratvar(mob/living/M)
	return M?.mind?.has_antag_datum(/datum/antagonist/servant_of_ratvar)

//Similar to cultist one, except silicons are allowed
/proc/is_convertable_to_clockcult(mob/living/M)
	if(!istype(M))
		return FALSE
	if(!M.mind)
		return FALSE
	if(ishuman(M) && (M.mind.assigned_role in list(JOB_NAME_CAPTAIN, JOB_NAME_CHAPLAIN)))
		return FALSE
	if(istype(M.get_item_by_slot(ITEM_SLOT_HEAD), /obj/item/clothing/head/costume/foilhat))
		return FALSE
	if(is_servant_of_ratvar(M))
		return FALSE
	if(M.mind.enslaved_to && !M.mind.enslaved_to.has_antag_datum(/datum/antagonist/servant_of_ratvar))
		return FALSE
	if(M.mind.unconvertable)
		return FALSE
	if(iscultist(M) || isconstruct(M) || ispAI(M))
		return FALSE
	if(HAS_TRAIT(M, TRAIT_MINDSHIELD))
		return FALSE
	return TRUE

/proc/generate_clockcult_scriptures()
	//Generate scriptures
	for(var/categorypath in subtypesof(/datum/clockcult/scripture))
		var/datum/clockcult/scripture/S = new categorypath
		GLOB.clockcult_all_scriptures[S.name] = S

/proc/flee_reebe()
	for(var/mob/living/M in GLOB.mob_list)
		if(!is_reebe(M.z))
			continue
		var/safe_place = find_safe_turf()
		M.forceMove(safe_place)
		if(!is_servant_of_ratvar(M))
			M.SetSleeping(50)

//Transmits a message to everyone in the cult
//Doesn't work if the cultists contain holy water, or are not on the station or Reebe
/proc/hierophant_message(msg, mob/living/sender, span = "<span class='srt_radio brass'>", use_sanitisation=TRUE, say=TRUE)
	if(CHAT_FILTER_CHECK(msg))
		if(sender)
			to_chat(sender, span_warning("You message contains forbidden words, please review the server rules and do not attempt to bypass this filter."))
		return
	var/hierophant_message = "[span]"
	if(sender?.reagents)
		if(sender.reagents.has_reagent(/datum/reagent/water/holywater, 1))
			to_chat(sender, span_nezbere("[pick("You fail to transmit your cries for help.", "Your calls into the void go unanswered.", "You try to transmit your message, but the hierophant network is silent.")]"))
			return FALSE
	if(!msg)
		if(sender)
			to_chat(sender, span_brass("You cannot transmit nothing!"))
		return FALSE
	if(use_sanitisation)
		msg = sanitize(msg)
	if(sender)
		if(say)
			sender.say("#[text2ratvar(msg)]")
		msg = sender.treat_message_min(msg)
		var/datum/antagonist/servant_of_ratvar/SoR = is_servant_of_ratvar(sender)
		var/prefix = "Clockbrother"
		switch(SoR.prefix)
			if(CLOCKCULT_PREFIX_EMINENCE)
				prefix = "Master"
			if(CLOCKCULT_PREFIX_MASTER)
				prefix = sender.gender == MALE\
					? "Clockfather"\
					: sender.gender == FEMALE\
						? "Clockmother"\
						: "Clockmaster"
				hierophant_message = "<span class='leader_brass'>"
			if(CLOCKCULT_PREFIX_RECRUIT)
				var/role = sender.mind?.assigned_role
				//Ew, this could be done better with a dictionary list, but this isn't much slower
				if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_COMMAND))
					prefix = "High Priest"
				else if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_ENGINEERING))
					prefix = "Cogturner"
				else if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_MEDICAL))
					prefix = "Rejuvinator"
				else if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SCIENCE))
					prefix = "Calculator"
				else if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_CARGO))
					prefix = "Pathfinder"
				else if(role in JOB_NAME_ASSISTANT)
					prefix = "Helper"
				else if(role in JOB_NAME_MIME)
					prefix = "Cogwatcher"
				else if(role in JOB_NAME_CLOWN)
					prefix = "Clonker"
				else if((role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_CIVILIAN)))
					prefix = "Cogworker"
				else if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SECURITY))
					prefix = "Warrior"
				else if(role in SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SILICON))
					prefix = "CPU"
			//Fallthrough is default of "Clockbrother"
		hierophant_message += "<b>[prefix] [sender.name]</b> transmits, \"[msg]\""
	else
		hierophant_message += msg
	if(span)
		hierophant_message += "</span>"
	for(var/datum/mind/mind in GLOB.all_servants_of_ratvar)
		send_hierophant_message_to(sender, mind, hierophant_message)
	for(var/mob/dead/observer/O in GLOB.dead_mob_list)
		if(istype(sender))
			to_chat(O, "[FOLLOW_LINK(O, sender)] [hierophant_message]", type = MESSAGE_TYPE_RADIO)
		else
			to_chat(O, hierophant_message, type = MESSAGE_TYPE_RADIO)
	sender.log_talk(msg, LOG_SAY, tag="clock cult")

/proc/send_hierophant_message_to(mob/living/sender, datum/mind/mind, hierophant_message)
	var/mob/M = mind.current
	if(!isliving(M) || QDELETED(M))
		return
	if(M.reagents)
		if(M.reagents.has_reagent(/datum/reagent/water/holywater, 1))
			if(pick(20))
				to_chat(M, span_nezbere("You hear the cogs whispering to you, but cannot understand their words."))
			return
	to_chat(M, hierophant_message, type = MESSAGE_TYPE_RADIO, avoid_highlighting = M == sender)
