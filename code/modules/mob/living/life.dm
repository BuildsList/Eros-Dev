/mob/living/Life()
	set invisibility = 0
	set background = BACKGROUND_ENABLED

	..()

	if (transforming)
		return
	if(!loc)
		return
	var/datum/gas_mixture/environment = loc.return_air()

	handle_modifiers() // Do this early since it might affect other things later.

	handle_light()

	if(stat != DEAD)
		//Breathing, if applicable
		handle_breathing()

		//Mutations and radiation
		handle_mutations_and_radiation()



		//Blood
		handle_blood()

		//Random events (vomiting etc)
		handle_random_events()

		attempt_vr(src,"handle_internal_contents",args) //VOREStation Code

		. = 1

	//Chemicals in the body, this is moved over here so that blood can be added after death
	handle_chemicals_in_body()

	//Handle temperature/pressure differences between body and environment
	if(environment)
		handle_environment(environment)

	//Check if we're on fire
	handle_fire()

	//stuff in the stomach
	//handle_stomach() //VOREStation Code

	update_gravity(mob_has_gravity())

	update_pulling()

	for(var/obj/item/weapon/grab/G in src)
		G.process()

	if(handle_regular_status_updates()) // Status & health update, are we dead or alive etc.
		handle_disabilities() // eye, ear, brain damages
		handle_statuses() //all special effects, stunned, weakened, jitteryness, hallucination, sleeping, etc

	handle_actions()

	update_canmove()

	handle_regular_hud_updates()

/mob/living/proc/handle_breathing()
	return

/mob/living/proc/handle_mutations_and_radiation()
	return

/mob/living/proc/handle_chemicals_in_body()
	return

/mob/living/proc/handle_blood()
	return

/mob/living/proc/handle_random_events()
	return

/mob/living/proc/handle_environment(var/datum/gas_mixture/environment)
	return

/mob/living/proc/handle_stomach()
	return

/mob/living/proc/update_pulling()
	if(pulling)
		if(incapacitated())
			stop_pulling()

//This updates the health and status of the mob (conscious, unconscious, dead)
/mob/living/proc/handle_regular_status_updates()
	updatehealth()
	if(stat != DEAD)
		if(paralysis)
			stat = UNCONSCIOUS
		else if (status_flags & FAKEDEATH)
			stat = UNCONSCIOUS
		else
			stat = CONSCIOUS
		return 1

/mob/living/proc/handle_statuses()
	handle_stunned()
	handle_weakened()
	handle_paralysed()
	handle_stuttering()
	handle_silent()
	handle_drugged()
	handle_slurring()

/mob/living/proc/handle_stunned()
	if(stunned)
		AdjustStunned(-1)
		if(!stunned)
			update_icons()
	return stunned

/mob/living/proc/handle_weakened()
	if(weakened)
		weakened = max(weakened-1,0)
		if(!weakened)
			update_icons()
	return weakened

/mob/living/proc/handle_stuttering()
	if(stuttering)
		stuttering = max(stuttering-1, 0)
	return stuttering

/mob/living/proc/handle_silent()
	if(silent)
		silent = max(silent-1, 0)
	return silent

/mob/living/proc/handle_drugged()
	if(druggy)
		druggy = max(druggy-1, 0)
	return druggy

/mob/living/proc/handle_slurring()
	if(slurring)
		slurring = max(slurring-1, 0)
	return slurring

/mob/living/proc/handle_paralysed()
	if(paralysis)
		AdjustParalysis(-1)
		if(!paralysis)
			update_icons()
	return paralysis

/mob/living/proc/handle_disabilities()
	//Eyes
	if(sdisabilities & BLIND || stat)	//blindness from disability or unconsciousness doesn't get better on its own
		SetBlinded(1)
	else if(eye_blind)			//blindness, heals slowly over time
		AdjustBlinded(-1)
	else if(eye_blurry)			//blurry eyes heal slowly
		eye_blurry = max(eye_blurry-1, 0)

	//Ears
	if(sdisabilities & DEAF)		//disabled-deaf, doesn't get better on its own
		setEarDamage(-1, max(ear_deaf, 1))
	else
		// deafness heals slowly over time, unless ear_damage is over 100
		if(ear_damage < 100)
			adjustEarDamage(-0.05,-1)

//this handles hud updates. Calls update_vision() and handle_hud_icons()
/mob/living/handle_regular_hud_updates()
	if(!client)
		return 0
	..()

	handle_vision()
	handle_hud_icons()

	return 1

/mob/living/proc/handle_vision()
	return

/mob/living/proc/update_sight()
	if(!seedarkness)
		see_invisible = SEE_INVISIBLE_NOLIGHTING
	else
		see_invisible = initial(see_invisible)
	return

/mob/living/proc/handle_hud_icons()
	handle_hud_icons_health()
	return

/mob/living/proc/handle_hud_icons_health()
	return

/mob/living/proc/handle_light()
	if(instability >= TECHNOMANCER_INSTABILITY_MIN_GLOW)
		var/distance = round(sqrt(instability / 2))
		if(distance)
			set_light(distance, distance * 4, l_color = "#660066")
			return TRUE

	else if(on_fire)
		set_light(light_range + 3, round(fire_stacks), l_color = "#FF9933")
		return TRUE

	else
		set_light(0)
		return FALSE

