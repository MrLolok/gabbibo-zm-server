#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;

ee_init()
{
    if ( isDefined( level.ee_initialized ) && level.ee_initialized )
        return;

    level.ee_initialized = true;
    level.ee_enabled = true;

    scripts\zm\ee\ee_progress::init_state();

    if ( !scripts\zm\ee\ee_registry::resolve_map() )
        return;

    scripts\zm\ee\ee_registry::register_map_module();

    level thread on_player_connect();
    level thread ee_command_listener();
    level thread scripts\zm\ee\ee_progress::run_watchers();
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
            scripts\zm\ee\ee_ui::create_hud(self);
            self.ee_ui_initialized = true;
        }

        scripts\zm\ee\ee_ui::refresh_all(self);
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
        scripts\zm\ee\ee_ui::refresh_all(player);
        player iprintln("^3[EE] ^7Checklist aggiornata.");
        return;
    }

    if ( subcmd == "detail" )
    {
        scripts\zm\ee\ee_ui::toggle_detail(player);
        return;
    }

    if ( subcmd == "hints" )
    {
        scripts\zm\ee\ee_hint::show_step_hint(player, scripts\zm\ee\ee_progress::get_active_step_id());
        return;
    }

    if ( subcmd == "next" )
    {
        scripts\zm\ee\ee_debug::debug_complete_active_step(player);
        return;
    }

    if ( subcmd == "dump" )
    {
        scripts\zm\ee\ee_debug::debug_dump_status(player);
        return;
    }

    if ( subcmd == "stepfull" )
    {
        if ( args.size > 2 )
        {
            scripts\zm\ee\ee_debug::debug_complete_step_full(player, args[2]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee stepfull <step_id>");
        return;
    }

    if ( subcmd == "sub" )
    {
        if ( args.size > 3 )
        {
            scripts\zm\ee\ee_debug::debug_complete_substep(player, args[2], args[3]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee sub <step_id> <substep_id>");
        return;
    }

    if ( subcmd == "preset" )
    {
        if ( args.size > 2 )
        {
            scripts\zm\ee\ee_debug::debug_apply_origins_preset(player, args[2]);
            return;
        }

        player iprintln("^3[EE] ^7Uso: .ee preset <prep/staffs/upgrades/endgame/complete>");
        return;
    }

    if ( subcmd == "off" )
    {
        player.ee_hidden = true;
        scripts\zm\ee\ee_ui::set_visibility(player, false);
        player iprintln("^3[EE] ^7HUD nascosta.");
        return;
    }

    if ( subcmd == "on" )
    {
        player.ee_hidden = false;
        scripts\zm\ee\ee_ui::set_visibility(player, true);
        scripts\zm\ee\ee_ui::refresh_all(player);
        player iprintln("^3[EE] ^7HUD visibile.");
        return;
    }

    if ( subcmd == "toggle" )
    {
        if ( !isDefined( player.ee_hidden ) )
            player.ee_hidden = false;

        player.ee_hidden = !player.ee_hidden;

        if ( player.ee_hidden )
        {
            scripts\zm\ee\ee_ui::set_visibility(player, false);
            player iprintln("^3[EE] ^7HUD nascosta.");
        }
        else
        {
            scripts\zm\ee\ee_ui::set_visibility(player, true);
            scripts\zm\ee\ee_ui::refresh_all(player);
            player iprintln("^3[EE] ^7HUD visibile.");
        }
        return;
    }

    print_usage(player);
}

ensure_player_ui(player)
{
    if ( isDefined( player.ee_ui_initialized ) && player.ee_ui_initialized )
        return;

    scripts\zm\ee\ee_ui::create_hud(player);
    player.ee_ui_initialized = true;
}

print_usage(player)
{
    player iprintln("^3[EE] ^7Uso: .ee, .ee detail, .ee hints, .ee toggle, .ee dump");
}
