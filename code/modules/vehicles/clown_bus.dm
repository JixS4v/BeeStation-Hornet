/obj/vehicle/clown_bus
	name = "Clown and Mime Marvelous and Fun Bus"
	desc = "A cardboard bus made by clown and mime. Powered by the driver leg's, it somehow can store 2 people in the back and goes faster than walking. No security allowed."
	icon = 'icons/obj/2x2.dmi'
	icon_state = "clown_bus"
	max_integrity = 10
	armor = list(MELEE = 0,  BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, STAMINA = 0)
	enter_delay = 20
	max_occupants = 3
	movedelay = 0.6
	key_type = /obj/item/bikehorn
	key_type_exact = FALSE

/obj/vehicle/clown_bus/generate_actions()
	. = ..()
	initialize_controller_action_type(/datum/action/vehicle/sealed/horn/clowncar, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/sealed/Thank, VEHICLE_CONTROL_KIDNAPPED)

/obj/vehicle/clown_bus/auto_assign_occupant_flags(mob/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.mind?.assigned_role == JOB_NAME_CLOWN, JOB_NAME_MIME) //Ensures only clowns and mimes can drive the car. (Including more at once)
			add_control_flags(H, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_PERMISSION)
			RegisterSignal(H, COMSIG_MOB_CLICKON, PROC_REF(FireCannon))
			return
	add_control_flags(M, VEHICLE_CONTROL_KIDNAPPED)

/obj/vehicle/clown_bus/mob_exit(mob/M, silent = FALSE, randomstep = FALSE)
	. = ..()
	UnregisterSignal(M, COMSIG_MOB_CLICKON)







