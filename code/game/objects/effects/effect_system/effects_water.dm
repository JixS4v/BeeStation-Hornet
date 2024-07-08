//WATER EFFECTS

/obj/effect/particle_effect/water
	name = "water"
	icon_state = "extinguish"
	var/life = 15
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT


/obj/effect/particle_effect/water/Initialize(mapload)
	. = ..()
	QDEL_IN(src, 70)

/obj/effect/particle_effect/water/Move(turf/newloc)
	//WOW. OKAY. THIS IS REALLY HACKY. THIS NEEDS TO BE STANDARDIZED.
	var/datum/gas_mixture/env = get_step(src, 0)?.return_air()
	var/diff_temp = (temperature - env.temperature) / env.group_multiplier / 2 //MAGIC NUMBER ALERT!!!!!!!
	if(abs(diff_temp) >= ATOM_TEMPERATURE_EQUILIBRIUM_THRESHOLD)
		var/altered_temp = max(env.temperature + (ATOM_TEMPERATURE_EQUILIBRIUM_CONSTANT * diff_temp), 0)
		env.temperature = (diff_temp > 0) ? min(temperature, altered_temp) : max(temperature, altered_temp)

	if (--src.life < 1)
		qdel(src)
		return 0
	if(newloc.density)
		return 0
	.=..()

/obj/effect/particle_effect/water/Bump(atom/A)
	if(reagents)
		reagents.reaction(A)
	return ..()

///Extinguisher snowflake
/obj/effect/particle_effect/water/extinguisher

/obj/effect/particle_effect/water/extinguisher/Initialize(mapload)
	. = ..()
	if(reagents)
		temperature = reagents.chem_temp

/obj/effect/particle_effect/water/extinguisher/Move()
	. = ..()
	if(!reagents)
		return
	reagents.reaction(get_turf(src))
	for(var/atom/thing as anything in get_turf(src))
		reagents.reaction(thing)

/////////////////////////////////////////////
// GENERIC STEAM SPREAD SYSTEM

//Usage: set_up(number of bits of steam, use North/South/East/West only, spawn location)
// The attach(atom/atom) proc is optional, and can be called to attach the effect
// to something, like a smoking beaker, so then you can just call start() and the steam
// will always spawn at the items location, even if it's moved.

/* Example:
 var/datum/effect_system/steam_spread/steam = new /datum/effect_system/steam_spread() -- creates new system
steam.set_up(5, 0, mob.loc) -- sets up variables
OPTIONAL: steam.attach(mob)
steam.start() -- spawns the effect
*/
/////////////////////////////////////////////
/obj/effect/particle_effect/steam
	name = "steam"
	icon_state = "extinguish"
	density = FALSE

/obj/effect/particle_effect/steam/Initialize(mapload)
	. = ..()
	QDEL_IN(src, 20)

/datum/effect_system/steam_spread
	effect_type = /obj/effect/particle_effect/steam
