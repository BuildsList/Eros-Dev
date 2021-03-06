//Config stuff
#define SUPPLY_DOCKZ 2          //Z-level of the Dock.
#define SUPPLY_STATIONZ 1       //Z-level of the Station.
#define SUPPLY_STATION_AREATYPE "/area/supply/station" //Type of the supply shuttle area for station
#define SUPPLY_DOCK_AREATYPE "/area/supply/dock"    //Type of the supply shuttle area for dock

//Supply packs are in /code/defines/obj/supplypacks.dm
//Computers are in /code/game/machinery/computer/supply.dm

var/datum/controller/supply/supply_controller = new()

var/list/mechtoys = list(
    /obj/item/toy/prize/ripley,
    /obj/item/toy/prize/fireripley,
    /obj/item/toy/prize/deathripley,
    /obj/item/toy/prize/gygax,
    /obj/item/toy/prize/durand,
    /obj/item/toy/prize/honk,
    /obj/item/toy/prize/marauder,
    /obj/item/toy/prize/seraph,
    /obj/item/toy/prize/mauler,
    /obj/item/toy/prize/odysseus,
    /obj/item/toy/prize/phazon
)

/obj/item/weapon/paper/manifest
    name = "supply manifest"
    var/is_copy = 1

/area/supply/station
	name = "Supply Shuttle"
	icon_state = "shuttle3"
	requires_power = 0
	base_turf = /turf/simulated/floor/plating

/area/supply/dock
    name = "Supply Shuttle"
    icon_state = "shuttle3"
    requires_power = 0
    base_turf = /turf/space

/obj/structure/plasticflaps //HOW DO YOU CALL THOSE THINGS ANYWAY
    name = "\improper plastic flaps"
    desc = "Completely impassable - or are they?"
    icon = 'icons/obj/stationobjs.dmi' //Change this.
    icon_state = "plasticflaps"
    density = 0
    anchored = 1
    layer = 4
    explosion_resistance = 5
    var/list/mobs_can_pass = list(
        /mob/living/bot,
        /mob/living/simple_animal/slime,
        /mob/living/simple_animal/mouse,
        /mob/living/silicon/robot/drone
        )

/obj/structure/plasticflaps/attackby(obj/item/P, mob/user)
    if(istype(P, /obj/item/weapon/wirecutters))
        playsound(src, P.usesound, 50, 1)
        user << "<span class='notice'>You start to cut the plastic flaps.</span>"
        if(do_after(user, 10 * P.toolspeed))
            user << "<span class='notice'>You cut the plastic flaps.</span>"
            var/obj/item/stack/material/plastic/A = new /obj/item/stack/material/plastic( src.loc )
            A.amount = 4
            qdel(src)
        return
    else
        return

/obj/structure/plasticflaps/CanPass(atom/A, turf/T)
    if(istype(A) && A.checkpass(PASSGLASS))
        return prob(60)

    var/obj/structure/bed/B = A
    if (istype(A, /obj/structure/bed) && B.buckled_mob)//if it's a bed/chair and someone is buckled, it will not pass
        return 0

    if(istype(A, /obj/vehicle)) //no vehicles
        return 0

    var/mob/living/M = A
    if(istype(M))
        if(M.lying)
            return ..()
        for(var/mob_type in mobs_can_pass)
            if(istype(A, mob_type))
                return ..()
        return issmall(M)

    return ..()

/obj/structure/plasticflaps/ex_act(severity)
    switch(severity)
        if (1)
            qdel(src)
        if (2)
            if (prob(50))
                qdel(src)
        if (3)
            if (prob(5))
                qdel(src)

/obj/structure/plasticflaps/mining //A specific type for mining that doesn't allow airflow because of them damn crates
    name = "airtight plastic flaps"
    desc = "Heavy duty, airtight, plastic flaps."

    New() //set the turf below the flaps to block air
        var/turf/T = get_turf(loc)
        if(T)
            T.blocks_air = 1
        ..()

    Destroy() //lazy hack to set the turf to allow air to pass if it's a simulated floor
        var/turf/T = get_turf(loc)
        if(T)
            if(istype(T, /turf/simulated/floor))
                T.blocks_air = 0
        ..()

/*
/obj/effect/marker/supplymarker
    icon_state = "X"
    icon = 'icons/misc/mark.dmi'
    name = "X"
    invisibility = 101
    anchored = 1
    opacity = 0
*/

/datum/supply_order
    var/ordernum
    var/datum/supply_packs/object = null
    var/orderedby = null
    var/comment = null

/datum/controller/supply
    //supply points
    var/points = 50
    var/points_per_process = 1.5
    var/points_per_slip = 2
    var/points_per_platinum = 5 // 5 points per sheet
    var/points_per_phoron = 5
    var/points_per_money = 0.02
    //control
    var/ordernum
    var/list/shoppinglist = list()
    var/list/requestlist = list()
    var/list/supply_packs = list()
    //shuttle movement
    var/movetime = 1200
    var/datum/shuttle/ferry/supply/shuttle

    New()
        ordernum = rand(1,9000)

        for(var/typepath in (typesof(/datum/supply_packs) - /datum/supply_packs))
            var/datum/supply_packs/P = new typepath()
            supply_packs[P.name] = P

    // Supply shuttle ticker - handles supply point regeneration
    // This is called by the process scheduler every thirty seconds
    proc/process()
        points += points_per_process

    //To stop things being sent to CentCom which should not be sent to centcomm. Recursively checks for these types.
    proc/forbidden_atoms_check(atom/A)
        if(istype(A,/mob/living))
            return 1
        if(istype(A,/obj/item/weapon/disk/nuclear))
            return 1
        if(istype(A,/obj/machinery/nuclearbomb))
            return 1
        if(istype(A,/obj/item/device/radio/beacon))
            return 1

        for(var/i=1, i<=A.contents.len, i++)
            var/atom/B = A.contents[i]
            if(.(B))
                return 1

    //Sellin
    proc/sell()
        var/area/area_shuttle = shuttle.get_location_area()
        if(!area_shuttle)   return

        callHook("sell_shuttle", list(area_shuttle));

        var/phoron_count = 0
        var/plat_count = 0
        var/money_count = 0

        for(var/atom/movable/MA in area_shuttle)
            if(MA.anchored) continue

            // Must be in a crate!
            if(istype(MA,/obj/structure/closet/crate))
                var/obj/structure/closet/crate/CR = MA
                callHook("sell_crate", list(CR, area_shuttle))

                points += CR.points_per_crate
                var/find_slip = 1

                for(var/atom in CR)
                    // Sell manifests
                    var/atom/A = atom
                    if(find_slip && istype(A,/obj/item/weapon/paper/manifest))
                        var/obj/item/weapon/paper/manifest/slip = A
                        if(!slip.is_copy && slip.stamped && slip.stamped.len) //yes, the clown stamp will work. clown is the highest authority on the station, it makes sense
                            points += points_per_slip
                            find_slip = 0
                        continue

                    // Sell phoron and platinum
                    if(istype(A, /obj/item/stack))
                        var/obj/item/stack/P = A
                        switch(P.get_material_name())
                            if("phoron") phoron_count += P.get_amount()
                            if("platinum") plat_count += P.get_amount()

                    //Sell spacebucks
                    if(istype(A, /obj/item/weapon/spacecash))
                        var/obj/item/weapon/spacecash/cashmoney = A
                        money_count += cashmoney.worth
            qdel(MA)

        if(phoron_count)
            points += phoron_count * points_per_phoron

        if(plat_count)
            points += plat_count * points_per_platinum

        if(money_count)
            points += money_count * points_per_money

    //Buyin
    proc/buy()
        if(!shoppinglist.len) return

        var/area/area_shuttle = shuttle.get_location_area()
        if(!area_shuttle)   return

        var/list/clear_turfs = list()

        for(var/turf/T in area_shuttle)
            if(T.density)   continue
            var/contcount
            for(var/atom/A in T.contents)
                if(!A.simulated)
                    continue
                contcount++
            if(contcount)
                continue
            clear_turfs += T

        for(var/S in shoppinglist)
            if(!clear_turfs.len)    break
            var/i = rand(1,clear_turfs.len)
            var/turf/pickedloc = clear_turfs[i]
            clear_turfs.Cut(i,i+1)
            shoppinglist -= S

            var/datum/supply_order/SO = S
            var/datum/supply_packs/SP = SO.object

            var/obj/A = new SP.containertype(pickedloc)
            A.name = "[SP.containername] [SO.comment ? "([SO.comment])":"" ]"

            //supply manifest generation begin

            var/obj/item/weapon/paper/manifest/slip
            if(!SP.contraband)
                slip = new /obj/item/weapon/paper/manifest(A)
                slip.is_copy = 0
                slip.info = "<h3>[command_name()] Shipping Manifest</h3><hr><br>"
                slip.info +="Order #[SO.ordernum]<br>"
                slip.info +="Destination: [station_name()]<br>"
                slip.info +="[shoppinglist.len] PACKAGES IN THIS SHIPMENT<br>"
                slip.info +="CONTENTS:<br><ul>"

            //spawn the stuff, finish generating the manifest while you're at it
            if(SP.access)
                if(isnum(SP.access))
                    A.req_access = list(SP.access)
                else if(islist(SP.access))
                    var/list/L = SP.access // access var is a plain var, we need a list
                    A.req_access = L.Copy()
                else
                    world << "<span class='danger'>Supply pack with invalid access restriction [SP.access] encountered!</span>"

            var/list/contains
            if(istype(SP,/datum/supply_packs/randomised))
                var/datum/supply_packs/randomised/SPR = SP
                contains = list()
                if(SPR.contains.len)
                    for(var/j=1,j<=SPR.num_contained,j++)
                        contains += pick(SPR.contains)
            else
                contains = SP.contains

            for(var/typepath in contains)
                if(!typepath)   continue
                var/number_of_items = max(1, contains[typepath])
                for(var/j = 1 to number_of_items)
                    var/atom/B2 = new typepath(A)
                    if(slip) slip.info += "<li>[B2.name]</li>" //add the item to the manifest

            //manifest finalisation
            if(slip)
                slip.info += "</ul><br>"
                slip.info += "CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"

        return
