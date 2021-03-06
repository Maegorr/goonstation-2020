/*=========================*/
/*----------Heart----------*/
/*=========================*/

/obj/item/organ/heart
	name = "heart"
	organ_name = "heart"
	desc = "Offal, just offal."
	icon_state = "heart"
	item_state = "heart"
	// var/broken = 0		//Might still want this. As like a "dead organ var", maybe not needed at all tho?
	module_research = list("medicine" = 1, "efficiency" = 5)
	module_research_type = /obj/item/organ/heart
	var/list/diseases = null
	var/body_image = null // don't have time to completely refactor this, but, what name does the heart icon have in human.dmi?
	var/transplant_XP = 3

	disposing()
		if (holder)
			holder.heart = null
		..()

	on_transplant(var/mob/M as mob)
		..()
		if (src.robotic)
			if (src.emagged)
				src.donor.add_stam_mod_regen("heart", 15)
				src.donor.add_stam_mod_max("heart", 90)
				src.donor.add_stun_resist_mod("heart", 30)
			else
				src.donor.add_stam_mod_regen("heart", 5)
				src.donor.add_stam_mod_max("heart", 40)
				src.donor.add_stun_resist_mod("heart", 15)

		if (src.donor)
			for (var/datum/ailment_data/disease in src.donor.ailments)
				if (disease.cure == "Heart Transplant")
					src.donor.cure_disease(disease)
		if (ishuman(M) && islist(src.diseases))
			var/mob/living/carbon/human/H = M
			for (var/datum/ailment_data/AD in src.diseases)
				H.contract_disease(null, null, AD, 1)
				src.diseases.Remove(AD)
			return

	on_removal()
		..()
		if (donor)
			if (src.robotic)
				src.donor.remove_stam_mod_regen("heart")
				src.donor.remove_stam_mod_max("heart")
				src.donor.remove_stun_resist_mod("heart")

			var/datum/ailment_data/malady/HD = donor.find_ailment_by_type(/datum/ailment/malady/heartdisease)
			if (HD)
				if (!islist(src.diseases))
					src.diseases = list()
				HD.master.on_remove(donor,HD)
				donor.ailments.Remove(HD)
				HD.affected_mob = null
				src.diseases.Add(HD)
		return

	attack(var/mob/living/carbon/M as mob, var/mob/user as mob)
		if (!ismob(M))
			return

		src.add_fingerprint(user)

		if (user.zone_sel.selecting != "chest")
			return ..()
		if (!surgeryCheck(M, user))
			return ..()

		var/mob/living/carbon/human/H = M
		if (!H.organHolder)
			return ..()

		if (!H.organHolder.heart && H.organHolder.chest.op_stage == 9.0)

			var/fluff = pick("insert", "shove", "place", "drop", "smoosh", "squish")

			H.tri_message("<span style=\"color:red\"><b>[user]</b> [fluff][fluff == "smoosh" || fluff == "squish" ? "es" : "s"] [src] into [H == user ? "[his_or_her(H)]" : "[H]'s"] chest!</span>",\
			user, "<span style=\"color:red\">You [fluff] [src] into [user == H ? "your" : "[H]'s"] chest!</span>",\
			H, "<span style=\"color:red\">[H == user ? "You" : "<b>[user]</b>"] [fluff][fluff == "smoosh" || fluff == "squish" ? "es" : "s"] [src] into your chest!</span>")

			user.u_equip(src)
			H.organHolder.receive_organ(src, "heart", 3.0)
			H.update_body()
			if (!isdead(H))
				JOB_XP(user, "Medical Doctor", H.health > 0 ? transplant_XP*2 : transplant_XP)

		else
			..()
		return

/obj/item/organ/heart/synth
	name = "synthheart"
	desc = "A synthetic heart, made out of some odd, meaty plant thing."
	synthetic = 1
	item_state = "plant"
	made_from = "pharosium"
	transplant_XP = 5
	New()
		..()
		src.icon_state = pick("plant_heart", "plant_heart_bloom")

/obj/item/organ/heart/cyber
	name = "cyberheart"
	desc = "A cybernetic heart. Is this thing really medical-grade?"
	icon_state = "heart_robo1"
	item_state = "heart_robo1"
	//created_decal = /obj/decal/cleanable/oil
	edible = 0
	robotic = 1
	mats = 8
	made_from = "pharosium"
	transplant_XP = 7

	emp_act()
		..()
		if (src.broken)
			boutput(donor, "<span style=\"color:red\"><B>Your cyberheart malfunctions and shuts down!</B></span>")
			donor.contract_disease(/datum/ailment/malady/flatline,null,null,1)

/obj/item/organ/heart/flock
	name = "pulsing octahedron"
	desc = "It beats ceaselessly to a peculiar rhythm. Like it's trying to tap out a distress signal."
	icon_state = "flockdrone_heart"
	item_state = "flockdrone_heart"
	body_image = "heart_flock"
	created_decal = /obj/decal/cleanable/flockdrone_debris/fluid
	made_from = "gnesis"
	var/resources = 0 // reagents for humans go in heart, resources for flockdrone go in heart, now, not the brain
	var/flockjuice_limit = 20 // pump flockjuice into the human host forever, but only a small bit
	var/min_blood_amount = 450

	on_transplant(var/mob/M as mob)
		..()
		if (ishuman(M))
			M:blood_color = "#4d736d"
			// there is no undo for this. wear the stain of your weird alien blood, pal
	//was do_process
	on_life()
		var/mob/living/M = src.holder.donor
		if(!M || !ishuman(M)) // flockdrones shouldn't have these problems
			return
		var/mob/living/carbon/human/H = M
		// handle flockjuice addition and capping
		if(H.reagents)
			var/datum/reagents/R = H.reagents
			var/flockjuice = R.get_reagent_amount("flockdrone_fluid")
			if(flockjuice <= 0)
				R.add_reagent("flockdrone_fluid", 10)
			if(flockjuice > flockjuice_limit)
				R.remove_reagent("flockdrone_fluid", flockjuice - flockjuice_limit)
			// handle blood synthesis
			if(H.blood_volume < min_blood_amount)
				// consume flockjuice, convert into blood
				var/converted_amt = min(flockjuice, min_blood_amount - H.blood_volume)
				R.remove_reagent("flockdrone_fluid", converted_amt)
				H.blood_volume += converted_amt