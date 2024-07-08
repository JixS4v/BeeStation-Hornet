#define CELSIUS_TO_KELVIN(T_K)	((T_K) + T0C)

#define OPTIMAL_TEMP_K_PLA_BURN_SCALE(PRESSURE_P,PRESSURE_O,TEMP_O)	(((PRESSURE_P) * GLOB.gas_data.specific_heats[GAS_PLASMA]) / (((PRESSURE_P) * GLOB.gas_data.specific_heats[GAS_PLASMA] + (PRESSURE_O) * GLOB.gas_data.specific_heats[GAS_O2]) / PLASMA_UPPER_TEMPERATURE - (PRESSURE_O) * GLOB.gas_data.specific_heats[GAS_O2] / CELSIUS_TO_KELVIN(TEMP_O)))
#define OPTIMAL_TEMP_K_PLA_BURN_RATIO(PRESSURE_P,PRESSURE_O,TEMP_O)	(CELSIUS_TO_KELVIN(TEMP_O) * PLASMA_OXYGEN_FULLBURN * (PRESSURE_P) / (PRESSURE_O))

/obj/effect/spawner/newbomb
	name = "bomb"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "x"
	var/temp_p = 1500
	var/temp_o = 1000	// tank temperatures
	var/pressure_p = 10 * ONE_ATMOSPHERE
	var/pressure_o = 10 * ONE_ATMOSPHERE	//tank pressures
	var/assembly_type

/obj/effect/spawner/newbomb/Initialize(mapload)
	. = ..()
	var/obj/item/transfer_valve/ttv = new(loc)
	ttv.tank_one = new /obj/item/tank/internals/plasma (ttv)
	ttv.tank_two = new /obj/item/tank/internals/oxygen (ttv)
	first_gasmix = ttv.tank_one.return_air()
	second_gasmix = ttv.tank_two.return_air()
	first_gasmix.removeRatio(1)
	second_gasmix.removeRatio(1)
	first_gasmix.removeRatio(1)
	second_gasmix.removeRatio(1)

	if(assembly_type)
		var/obj/item/assembly/A = new assembly_type(V)
		V.attached_device = A
		A.holder = V

	V.update_icon()

/obj/effect/spawner/newbomb/timer/syndicate/Initialize(mapload)
	temp_p = (OPTIMAL_TEMP_K_PLA_BURN_SCALE(pressure_p, pressure_o, temp_o)/2 + OPTIMAL_TEMP_K_PLA_BURN_RATIO(pressure_p, pressure_o, temp_o)/2) - T0C
	. = ..()

/obj/effect/spawner/newbomb/timer
	assembly_type = /obj/item/assembly/timer

/obj/effect/spawner/newbomb/timer/syndicate
	pressure_o = TANK_LEAK_PRESSURE - 1
	temp_o = 20

	pressure_p = TANK_LEAK_PRESSURE - 1

/obj/effect/spawner/newbomb/proximity
	assembly_type = /obj/item/assembly/prox_sensor

/obj/effect/spawner/newbomb/radio
	assembly_type = /obj/item/assembly/signaler


#undef CELSIUS_TO_KELVIN

#undef OPTIMAL_TEMP_K_PLA_BURN_SCALE
#undef OPTIMAL_TEMP_K_PLA_BURN_RATIO
