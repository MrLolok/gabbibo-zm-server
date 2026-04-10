#include maps\mp\_utility;
#include common_scripts\utility;

debug_complete_active_step(player)
{
    step_id = scripts\zm\ee\ee_progress::get_active_step_id();
    if ( step_id == "" )
        return;

    scripts\zm\ee\ee_progress::complete_step(step_id, "debug");
    player iprintln("^3[EE Debug] ^7Step completato: " + step_id);
}

debug_complete_substep(player, step_id, substep_id)
{
    if ( scripts\zm\ee\ee_progress::complete_substep(step_id, substep_id, "debug") )
        player iprintln("^3[EE Debug] ^7Substep completato: " + step_id + " / " + substep_id);
    else
        player iprintln("^1[EE Debug] ^7Substep non valido o gia' completato.");
}

debug_complete_step_full(player, step_id)
{
    if ( !scripts\zm\ee\ee_progress::complete_step_substeps(step_id, "debug_batch") )
    {
        player iprintln("^1[EE Debug] ^7Step non trovato.");
        return false;
    }

    player iprintln("^3[EE Debug] ^7Step completato in batch: " + step_id);
    return true;
}

debug_dump_status(player)
{
    player iprintln("^3[EE Debug] ^7Quest: " + level.ee.quest_id + " | Active: " + scripts\zm\ee\ee_progress::get_active_step_id());

    for ( i = 0; i < level.ee.steps.size; i++ )
    {
        step = level.ee.steps[i];
        state = scripts\zm\ee\ee_progress::get_step_state(step.id);
        done = scripts\zm\ee\ee_progress::get_step_substep_done_count(step.id);
        total = scripts\zm\ee\ee_progress::get_step_substep_total(step.id);
        player iprintln("^3[EE Debug] ^7" + step.id + " ^8(" + state + " " + done + "/" + total + "^8)");
    }
}

debug_apply_origins_preset(player, preset)
{
    if ( !isDefined( level.ee_map_id ) || level.ee_map_id != "origins" )
    {
        player iprintln("^1[EE Debug] ^7Preset disponibile solo su Origins.");
        return false;
    }

    if ( preset == "open" || preset == "prep" )
    {
        steps = [];
        steps[0] = "open_map";
        steps[1] = "gramophone";
        return apply_preset_steps(player, "Preset Origins prep applicato.", "build_wind_staff", steps);
    }

    if ( preset == "staffs" )
    {
        steps = [];
        steps[0] = "open_map";
        steps[1] = "gramophone";
        steps[2] = "build_wind_staff";
        steps[3] = "build_lightning_staff";
        steps[4] = "build_ice_staff";
        steps[5] = "build_fire_staff";
        return apply_preset_steps(player, "Preset Origins staffs applicato.", "upgrade_wind_staff", steps);
    }

    if ( preset == "upgrades" )
    {
        steps = [];
        steps[0] = "open_map";
        steps[1] = "gramophone";
        steps[2] = "build_wind_staff";
        steps[3] = "build_lightning_staff";
        steps[4] = "build_ice_staff";
        steps[5] = "build_fire_staff";
        steps[6] = "upgrade_wind_staff";
        steps[7] = "upgrade_lightning_staff";
        steps[8] = "upgrade_ice_staff";
        steps[9] = "upgrade_fire_staff";
        return apply_preset_steps(player, "Preset Origins upgrades applicato.", "place_staffs", steps);
    }

    if ( preset == "endgame" || preset == "final" )
    {
        steps = [];
        steps[0] = "open_map";
        steps[1] = "gramophone";
        steps[2] = "build_wind_staff";
        steps[3] = "build_lightning_staff";
        steps[4] = "build_ice_staff";
        steps[5] = "build_fire_staff";
        steps[6] = "upgrade_wind_staff";
        steps[7] = "upgrade_lightning_staff";
        steps[8] = "upgrade_ice_staff";
        steps[9] = "upgrade_fire_staff";
        steps[10] = "place_staffs";
        steps[11] = "button_and_kills";
        steps[12] = "rain_fire";
        steps[13] = "thunder_fists";
        return apply_preset_steps(player, "Preset Origins endgame applicato.", "release_maxis", steps);
    }

    if ( preset == "complete" )
    {
        steps = [];
        steps[0] = "open_map";
        steps[1] = "gramophone";
        steps[2] = "build_wind_staff";
        steps[3] = "build_lightning_staff";
        steps[4] = "build_ice_staff";
        steps[5] = "build_fire_staff";
        steps[6] = "upgrade_wind_staff";
        steps[7] = "upgrade_lightning_staff";
        steps[8] = "upgrade_ice_staff";
        steps[9] = "upgrade_fire_staff";
        steps[10] = "place_staffs";
        steps[11] = "button_and_kills";
        steps[12] = "rain_fire";
        steps[13] = "thunder_fists";
        steps[14] = "release_maxis";
        return apply_preset_steps(player, "Preset Origins complete applicato.", "", steps);
    }

    player iprintln("^1[EE Debug] ^7Preset sconosciuto. Usa: prep, staffs, upgrades, endgame, complete");
    return false;
}

apply_preset_steps(player, success_msg, next_step, steps)
{
    for ( i = 0; i < steps.size; i++ )
        debug_complete_step_full(player, steps[i]);

    if ( next_step != "" )
        scripts\zm\ee\ee_progress::set_active_step(next_step);

    player iprintln("^3[EE Debug] ^7" + success_msg);
    return true;
}
