/obj/item/weapon/handcuffs
	name = "handcuffs"
	desc = "Use this to keep prisoners in line."
	gender = PLURAL
	icon = 'icons/obj/items.dmi'
	icon_state = "handcuff"
	flags = CONDUCT
	slot_flags = SLOT_BELT
	throwforce = 5
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 5
	origin_tech = list(TECH_MATERIAL = 1)
	matter = list(DEFAULT_WALL_MATERIAL = 500)
	var/elastic
	var/dispenser = 0
	var/breakouttime = 1200 //Deciseconds = 120s = 2 minutes
	var/cuff_sound = 'sound/weapons/handcuffs.ogg'
	var/cuff_type = "handcuffs"
	sprite_sheets = list("Teshari" = 'icons/mob/species/seromi/handcuffs.dmi')

/obj/item/weapon/handcuffs/attack(var/mob/living/carbon/C, var/mob/living/user)

	if(!user.IsAdvancedToolUser())
		return

	if ((CLUMSY in user.mutations) && prob(50))
		to_chat(user, "<span class='warning'>Uh ... how do those things work?!</span>")
		place_handcuffs(user, user)
		return

	if(!C.handcuffed)
		if (C == user)
			place_handcuffs(user, user)
			return

		//check for an aggressive grab (or robutts)
		if(can_place(C, user))
			place_handcuffs(C, user)
		else
			to_chat(user, "<span class='danger'>You need to have a firm grip on [C] before you can put \the [src] on!</span>")

/obj/item/weapon/handcuffs/proc/can_place(var/mob/target, var/mob/user)
	if(user == target)
		return 1
	if(istype(user, /mob/living/silicon/robot))
		if(user.Adjacent(target))
			return 1
	else
		for(var/obj/item/weapon/grab/G in target.grabbed_by)
			if(G.loc == user && G.state >= GRAB_AGGRESSIVE)
				return 1
	return 0

/obj/item/weapon/handcuffs/proc/place_handcuffs(var/mob/living/carbon/target, var/mob/user)
	playsound(src.loc, cuff_sound, 30, 1, -2)

	var/mob/living/carbon/human/H = target
	if(!istype(H))
		return 0

	if (!H.has_organ_for_slot(slot_handcuffed))
		to_chat(user, "<span class='danger'>\The [H] needs at least two wrists before you can cuff them together!</span>")
		return 0

	if(istype(H.gloves,/obj/item/clothing/gloves/gauntlets/rig) && !elastic) // Can't cuff someone who's in a deployed hardsuit.
		to_chat(user, "<span class='danger'>\The [src] won't fit around \the [H.gloves]!</span>")
		return 0

	user.visible_message("<span class='danger'>\The [user] is attempting to put [cuff_type] on \the [H]!</span>")

	if(!do_after(user,30))
		return 0

	if(!can_place(target, user)) //victim may have resisted out of the grab in the meantime
		return 0

	H.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been handcuffed (attempt) by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Attempted to handcuff [H.name] ([H.ckey])</font>")
	msg_admin_attack("[key_name(user)] attempted to handcuff [key_name(H)]")
	feedback_add_details("handcuffs","H")

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(H)

	user.visible_message("<span class='danger'>\The [user] has put [cuff_type] on \the [H]!</span>")

	// Apply cuffs.
	var/obj/item/weapon/handcuffs/cuffs = src
	if(dispenser)
		cuffs = new(get_turf(user))
	else
		user.drop_from_inventory(cuffs)
	cuffs.loc = target
	target.handcuffed = cuffs
	target.update_inv_handcuffed()
	return 1

var/last_chew = 0
/mob/living/carbon/human/RestrainedClickOn(var/atom/A)
	if (A != src) return ..()
	if (last_chew + 26 > world.time) return

	var/mob/living/carbon/human/H = A
	if (!H.handcuffed) return
	if (H.a_intent != I_HURT) return
	if (H.zone_sel.selecting != O_MOUTH) return
	if (H.wear_mask) return
	if (istype(H.wear_suit, /obj/item/clothing/suit/straight_jacket)) return

	var/obj/item/organ/external/O = H.organs_by_name[(H.hand ? BP_L_HAND : BP_R_HAND)]
	if (!O) return

	var/s = "<span class='warning'>[H.name] chews on \his [O.name]!</span>"
	H.visible_message(s, "<span class='warning'>You chew on your [O.name]!</span>")
	H.attack_log += text("\[[time_stamp()]\] <font color='red'>[s] ([H.ckey])</font>")
	log_attack("[s] ([H.ckey])")

	if(O.take_damage(3,0,1,1,"teeth marks"))
		H:UpdateDamageIcon()

	last_chew = world.time

/obj/item/weapon/handcuffs/fuzzy
	name = "fuzzy cuffs"
	icon_state = "fuzzycuff"
	desc = "Use this to keep... 'prisoners' in line."

/obj/item/weapon/handcuffs/cable
	name = "cable restraints"
	desc = "Looks like some cables tied together. Could be used to tie something up."
	icon_state = "cuff_white"
	breakouttime = 300 //Deciseconds = 30s
	cuff_sound = 'sound/weapons/cablecuff.ogg'
	cuff_type = "cable restraints"
	elastic = 1

/obj/item/weapon/handcuffs/cable/red
	color = "#DD0000"

/obj/item/weapon/handcuffs/cable/yellow
	color = "#DDDD00"

/obj/item/weapon/handcuffs/cable/blue
	color = "#0000DD"

/obj/item/weapon/handcuffs/cable/green
	color = "#00DD00"

/obj/item/weapon/handcuffs/cable/pink
	color = "#DD00DD"

/obj/item/weapon/handcuffs/cable/orange
	color = "#DD8800"

/obj/item/weapon/handcuffs/cable/cyan
	color = "#00DDDD"

/obj/item/weapon/handcuffs/cable/white
	color = "#FFFFFF"

/obj/item/weapon/handcuffs/cable/attackby(var/obj/item/I, mob/user as mob)
	..()
	if(istype(I, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = I
		if (R.use(1))
			var/obj/item/weapon/material/wirerod/W = new(get_turf(user))
			user.put_in_hands(W)
			to_chat(user, "<span class='notice'>You wrap the cable restraint around the top of the rod.</span>")
			qdel(src)
			update_icon(user)

/obj/item/weapon/handcuffs/cyborg
	dispenser = 1

/obj/item/weapon/handcuffs/cable/tape
	name = "tape restraints"
	desc = "DIY!"
	icon_state = "tape_cross"
	item_state = null
	icon = 'icons/obj/bureaucracy.dmi'
	breakouttime = 200
	cuff_type = "duct tape"

//Legcuffs. Not /really/ handcuffs, but its close enough.
/obj/item/weapon/handcuffs/legcuffs
	name = "legcuffs"
	desc = "Use this to keep prisoners in line."
	gender = PLURAL
	icon = 'icons/obj/items.dmi'
	icon_state = "legcuff"
	flags = CONDUCT
	throwforce = 0
	w_class = ITEMSIZE_NORMAL
	origin_tech = list(TECH_MATERIAL = 1)
	breakouttime = 300	//Deciseconds = 30s = 0.5 minute
	cuff_type = "legcuffs"
	sprite_sheets = list("Teshari" = 'icons/mob/species/seromi/handcuffs.dmi')
	elastic = 0
	cuff_sound = 'sound/weapons/handcuffs.ogg' //This shold work for now.

/obj/item/weapon/handcuffs/legcuffs/attack(var/mob/living/carbon/C, var/mob/living/user)
	if(!user.IsAdvancedToolUser())
		return

	if ((CLUMSY in user.mutations) && prob(50))
		to_chat(user, "<span class='warning'>Uh ... how do those things work?!</span>")
		place_legcuffs(user, user)
		return

	if(!C.handcuffed)
		if (C == user)
			place_legcuffs(user, user)
			return

		//check for an aggressive grab (or robutts)
		if(can_place(C, user))
			place_legcuffs(C, user)
		else
			to_chat(user, "<span class='danger'>You need to have a firm grip on [C] before you can put \the [src] on!</span>")

/obj/item/weapon/handcuffs/legcuffs/proc/place_legcuffs(var/mob/living/carbon/target, var/mob/user)
	playsound(src.loc, cuff_sound, 30, 1, -2)

	var/mob/living/carbon/human/H = target
	if(!istype(H))
		return 0

	if (!H.has_organ_for_slot(slot_legcuffed))
		to_chat(user, "<span class='danger'>\The [H] needs at least two ankles before you can cuff them together!</span>")
		return 0

	if(istype(H.shoes,/obj/item/clothing/shoes/magboots/rig) && !elastic) // Can't cuff someone who's in a deployed hardsuit.
		to_chat(user, "<span class='danger'>\The [src] won't fit around \the [H.shoes]!</span>")
		return 0

	user.visible_message("<span class='danger'>\The [user] is attempting to put [cuff_type] on \the [H]!</span>")

	if(!do_after(user,30))
		return 0

	if(!can_place(target, user)) //victim may have resisted out of the grab in the meantime
		return 0

	H.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been legcuffed (attempt) by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Attempted to legcuff [H.name] ([H.ckey])</font>")
	msg_admin_attack("[key_name(user)] attempted to legcuff [key_name(H)]")
	feedback_add_details("legcuffs","H")

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(H)

	user.visible_message("<span class='danger'>\The [user] has put [cuff_type] on \the [H]!</span>")

	// Apply cuffs.
	var/obj/item/weapon/handcuffs/legcuffs/lcuffs = src
	if(dispenser)
		lcuffs = new(get_turf(user))
	else
		user.drop_from_inventory(lcuffs)
	lcuffs.loc = target
	target.legcuffed = lcuffs
	target.update_inv_legcuffed()
	return 1
