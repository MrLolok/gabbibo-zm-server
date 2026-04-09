#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include ee\ee_registry;
#include ee\ee_progress;
#include ee\ee_ui;
#include ee\ee_hint;
#include ee\ee_highlight;
#include ee\ee_debug;
#include ee\maps\origins_ee;

init()
{
    if ( isDefined( level.ee_initialized ) && level.ee_initialized )
        return;

    level.ee_initialized = true;
    level.ee_enabled = true;

    ee\ee_progress::init_state();

    if ( !ee\ee_registry::resolve_map() )
        return;

    ee\ee_registry::register_map_module();

    level thread on_player_connect();
    level thread ee_command_listener();
    level thread ee\ee_progress::run_watchers();
}

on_player_connect()
{
    level endon("end_game");

    for ( ;; )
    {
        level waittill("connecting", player);
        player thread init_player();
    }
}

init_player()
{
    self endon("disconnect");

    for ( ;; )
    {
        self waittill("spawned_player");

        if ( !level.ee_enabled )
            continue;

        if ( !isDefined( self.ee_ui_initialized ) || !self.ee_ui_initialized )
        {
            ee\ee_ui::create_hud(self);
            self.ee_ui_initialized = true;
        }

        ee\ee_ui::refresh_all(self);
    }
}

ee_command_listener()
{
    level endon("end_game");

    for ( ;; )
    {
        level waittill("say", message, player);

        if ( !level.ee_enabled )
            continue;

        message = tolower(message);
        args = strtok(message, " ");

        if ( args.size == 0 )
            continue;

        if ( args[0] != ".ee" )
            continue;

        handle_ee_command(player, args);
    }
}

handle_ee_command(player, args)
{
    ensure_player_ui(player);

    subcmd = "status";
    if ( args.size > 1 )
        subcmd = args[1];

    if ( subcmd == "status" )
    {
        ee\ee_ui::refresh_all(player);
        player iprintln("^3[EE] ^7Checklist aggiornata.");
        return;
    }

    if ( subcmd == "detail" )
    {
        ee\ee_ui::toggle_detail(player);
        return;
    }

    if ( subcmd == "list" )
    {
        ee\ee_ui::print_step_list(player);
        return;
    }

    if ( subcmd == "show" )
    {
        if ( args.size > 2 )
        {
            if ( ee\ee_ui::set_selected_step(player, args[2]) )
            {
                if ( !player.ee_ui.detail_open )
                    ee\ee_ui::toggle_detail(player);
                else
                    ee\ee_ui::refresh_all(player);

                player iprintln("^3[EE] ^7Visualizzazione step: " + args[2]);
            }
            else
            {
                player iprintln("^1[EE] ^7Step non trovato.");
            }
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee show <step_id>");
        return;
    }

    if ( subcmd == "active" )
    {
        ee\ee_ui::clear_selected_step(player);
        ee\ee_ui::refresh_all(player);
        player iprintln("^3[EE] ^7Dettaglio riportato allo step attivo.");
        return;
    }

    if ( subcmd == "hints" )
    {
        ee\ee_hint::show_step_hint(player, ee\ee_ui::get_display_step_id(player));
        return;
    }

    if ( subcmd == "notes" || subcmd == "puzzle" )
    {
        ee\ee_hint::show_step_notes(player, ee\ee_ui::get_display_step_id(player));
        return;
    }

    if ( subcmd == "poi" )
    {
        ee\ee_highlight::toggle_active_step_pois(player);
        return;
    }

    if ( subcmd == "next" )
    {
        ee\ee_debug::debug_complete_active_step(player);
        return;
    }

    if ( subcmd == "dump" )
    {
        ee\ee_debug::debug_dump_status(player);
        return;
    }

    if ( subcmd == "step" )
    {
        if ( args.size > 2 )
        {
            ee\ee_debug::debug_set_active_step(player, args[2]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee step <step_id>");
        return;
    }

    if ( subcmd == "stepfull" )
    {
        if ( args.size > 2 )
        {
            ee\ee_debug::debug_complete_step_full(player, args[2]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee stepfull <step_id>");
        return;
    }

    if ( subcmd == "sub" )
    {
        if ( args.size > 3 )
        {
            ee\ee_debug::debug_complete_substep(player, args[2], args[3]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee sub <step_id> <substep_id>");
        return;
    }

    if ( subcmd == "preset" )
    {
        if ( args.size > 2 )
        {
            ee\ee_debug::debug_apply_origins_preset(player, args[2]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee preset <prep/staffs/upgrades/endgame/complete>");
        return;
    }

    if ( subcmd == "off" )
    {
        player.ee_hidden = true;
        ee\ee_ui::set_visibility(player, false);
        player iprintln("^3[EE] ^7HUD nascosta.");
        return;
    }

    if ( subcmd == "on" )
    {
        player.ee_hidden = false;
        ee\ee_ui::set_visibility(player, true);
        ee\ee_ui::refresh_all(player);
        player iprintln("^3[EE] ^7HUD visibile.");
        return;
    }

    print_usage(player);
}

ensure_player_ui(player)
{
    if ( isDefined( player.ee_ui_initialized ) && player.ee_ui_initialized )
        return;

    ee\ee_ui::create_hud(player);
    player.ee_ui_initialized = true;
}

print_usage(player)
{
    player iprintln("^3[EE] ^7Uso: .ee, .ee detail, .ee list, .ee show <id>, .ee hints, .ee notes, .ee poi, .ee dump");
}
