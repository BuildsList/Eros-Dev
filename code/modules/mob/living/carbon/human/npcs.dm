/obj/item/clothing/under/punpun
	name = "fancy uniform"
	desc = "It looks like it was tailored for a monkey."
	icon_state = "punpun"
	worn_state = "punpun"
	species_restricted = list("Monkey")

/mob/living/carbon/human/monkey/punpun/New()
	spawn(1)
		// VoreStation Edit - Move Constructor inside Spawn
		..()
		// End Vore Station Edit
		name = "Pun Pun"
		real_name = name
		w_uniform = new /obj/item/clothing/under/punpun(src)
