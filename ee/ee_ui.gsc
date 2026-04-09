#include maps\mp\gametypes_zm\_hud_util;
#include ee\ee_progress;

create_hud(player)
{
    player.ee_ui = SpawnStruct();

    player.ee_ui.bg = newClientHudElem(player);
    player.ee_ui.bg.alignX = "left";
    player.ee_ui.bg.alignY = "top";
    player.ee_ui.bg.horzAlign = "user_left";
    player.ee_ui.bg.vertAlign = "user_top";
    player.ee_ui.bg.x = 108;
    player.ee_ui.bg.y = 6;
    player.ee_ui.bg setShader("white", 242, 74);
    player.ee_ui.bg.color = (0, 0, 0);
    player.ee_ui.bg.alpha = 0.45;
    player.ee_ui.bg.sort = 18;

    player.ee_ui.accent = newClientHudElem(player);
    player.ee_ui.accent.alignX = "left";
    player.ee_ui.accent.alignY = "top";
    player.ee_ui.accent.horzAlign = "user_left";
    player.ee_ui.accent.vertAlign = "user_top";
    player.ee_ui.accent.x = 108;
    player.ee_ui.accent.y = 6;
    player.ee_ui.accent setShader("white", 4, 74);
    player.ee_ui.accent.color = (1, 0.65, 0.1);
    player.ee_ui.accent.alpha = 1;
    player.ee_ui.accent.sort = 19;

    player.ee_ui.title = newClientHudElem(player);
    player.ee_ui.title.alignX = "left";
    player.ee_ui.title.alignY = "top";
    player.ee_ui.title.horzAlign = "user_left";
    player.ee_ui.title.vertAlign = "user_top";
    player.ee_ui.title.x = 112;
    player.ee_ui.title.y = 8;
    player.ee_ui.title.fontscale = 1.2;
    player.ee_ui.title.sort = 20;
    player.ee_ui.title.alpha = 1;

    player.ee_ui.meta = newClientHudElem(player);
    player.ee_ui.meta.alignX = "left";
    player.ee_ui.meta.alignY = "top";
    player.ee_ui.meta.horzAlign = "user_left";
    player.ee_ui.meta.vertAlign = "user_top";
    player.ee_ui.meta.x = 112;
    player.ee_ui.meta.y = 22;
    player.ee_ui.meta.fontscale = 0.9;
    player.ee_ui.meta.sort = 20;
    player.ee_ui.meta.alpha = 1;

    player.ee_ui.body = newClientHudElem(player);
    player.ee_ui.body.alignX = "left";
    player.ee_ui.body.alignY = "top";
    player.ee_ui.body.horzAlign = "user_left";
    player.ee_ui.body.vertAlign = "user_top";
    player.ee_ui.body.x = 112;
    player.ee_ui.body.y = 36;
    player.ee_ui.body.fontscale = 0.95;
    player.ee_ui.body.sort = 20;
    player.ee_ui.body.alpha = 1;

    player.ee_ui.objective = newClientHudElem(player);
    player.ee_ui.objective.alignX = "left";
    player.ee_ui.objective.alignY = "top";
    player.ee_ui.objective.horzAlign = "user_left";
    player.ee_ui.objective.vertAlign = "user_top";
    player.ee_ui.objective.x = 112;
    player.ee_ui.objective.y = 72;
    player.ee_ui.objective.fontscale = 0.9;
    player.ee_ui.objective.sort = 20;
    player.ee_ui.objective.alpha = 1;

    player.ee_ui.detail = newClientHudElem(player);
    player.ee_ui.detail.alignX = "left";
    player.ee_ui.detail.alignY = "top";
    player.ee_ui.detail.horzAlign = "user_left";
    player.ee_ui.detail.vertAlign = "user_top";
    player.ee_ui.detail.x = 112;
    player.ee_ui.detail.y = 104;
    player.ee_ui.detail.fontscale = 0.9;
    player.ee_ui.detail.sort = 20;
    player.ee_ui.detail.alpha = 0;

    player.ee_ui.detail_open = false;
    player.ee_ui.selected_step_id = "";
    player.ee_hidden = false;

    player thread ui_refresh_listener();
}

ui_refresh_listener()
{
    self endon("disconnect");

    for ( ;; )
    {
        self waittill("ee_refresh_ui");
        refresh_all(self);
    }
}

refresh_all(player)
{
    if ( !isDefined( player.ee_ui ) || player.ee_hidden )
        return;

    refresh_checklist(player);

    if ( isDefined( player.ee_ui.detail_open ) && player.ee_ui.detail_open )
        show_step_detail(player, get_display_step_id(player));
}

refresh_checklist(player)
{
    active = ee\ee_progress::get_active_step();
    if ( !isDefined( active ) )
        return;

    player.ee_ui.title setText("^3Easter Egg Assistant");
    player.ee_ui.meta setText("^7Quest: ^3" + level.ee.quest_id + " ^7| Step ^3" + ee\ee_progress::get_active_step_number() + "^7/^3" + ee\ee_progress::get_step_count());

    lines = [];
    start = active.index - 1;
    if ( start < 0 )
        start = 0;

    end = active.index + 2;
    if ( end >= level.ee.steps.size )
        end = level.ee.steps.size - 1;

    for ( i = start; i <= end; i++ )
    {
        step = level.ee.steps[i];
        state = ee\ee_progress::get_step_state(step.id);

        if ( state == "done" )
            lines[lines.size] = "^2[OK]^7 " + step.title;
        else if ( state == "active" )
            lines[lines.size] = "^3[>]^7 " + step.title;
        else
            lines[lines.size] = "^8[ ]^7 " + step.title;
    }

    player.ee_ui.body setText(join_lines(lines));
    player.ee_ui.objective setText("^7Obiettivo: ^3" + active.short_desc + " ^7(" + ee\ee_progress::get_step_substep_done_count(active.id) + "/" + ee\ee_progress::get_step_substep_total(active.id) + ")");
}

toggle_detail(player)
{
    if ( !isDefined( player.ee_ui ) )
        return;

    player.ee_ui.detail_open = !player.ee_ui.detail_open;

    if ( player.ee_ui.detail_open )
    {
        if ( player.ee_ui.selected_step_id == "" )
            player.ee_ui.selected_step_id = ee\ee_progress::get_active_step_id();

        show_step_detail(player, get_display_step_id(player));
        player iprintln("^3[EE] ^7Dettaglio step aperto.");
    }
    else
    {
        hide_step_detail(player);
        player iprintln("^3[EE] ^7Dettaglio step chiuso.");
    }
}

show_step_detail(player, step_id)
{
    step = ee\ee_progress::get_step(step_id);
    if ( !isDefined( step ) )
        return;

    lines = [];
    lines[lines.size] = "^5" + step.title;
    lines[lines.size] = step.long_desc;
    lines[lines.size] = "^7Progresso: ^3" + ee\ee_progress::get_step_substep_done_count(step.id) + "^7/^3" + ee\ee_progress::get_step_substep_total(step.id);

    for ( i = 0; i < step.substeps.size; i++ )
    {
        sub = step.substeps[i];
        prefix = "^8[ ]^7 ";
        if ( isDefined( sub.done ) && sub.done )
            prefix = "^2[OK]^7 ";

        lines[lines.size] = prefix + sub.title;
    }

    if ( step.notes.size > 0 )
    {
        lines[lines.size] = "^6Note:";
        for ( i = 0; i < step.notes.size; i++ )
            lines[lines.size] = "^6- ^7" + step.notes[i];
    }

    player.ee_ui.detail.alpha = 1;
    player.ee_ui.detail setText(join_lines(lines));
}

hide_step_detail(player)
{
    if ( !isDefined( player.ee_ui ) )
        return;

    player.ee_ui.detail.alpha = 0;
    player.ee_ui.detail setText("");
}

set_visibility(player, visible)
{
    alpha = 0;
    if ( visible )
        alpha = 1;

    if ( isDefined( player.ee_ui.title ) )
        player.ee_ui.title.alpha = alpha;

    if ( isDefined( player.ee_ui.bg ) )
        player.ee_ui.bg.alpha = alpha * 0.45;

    if ( isDefined( player.ee_ui.accent ) )
        player.ee_ui.accent.alpha = alpha;

    if ( isDefined( player.ee_ui.meta ) )
        player.ee_ui.meta.alpha = alpha;

    if ( isDefined( player.ee_ui.body ) )
        player.ee_ui.body.alpha = alpha;

    if ( isDefined( player.ee_ui.objective ) )
        player.ee_ui.objective.alpha = alpha;

    if ( isDefined( player.ee_ui.detail ) )
    {
        if ( visible && player.ee_ui.detail_open )
            player.ee_ui.detail.alpha = 1;
        else
            player.ee_ui.detail.alpha = 0;
    }
}

join_lines(lines)
{
    out = "";

    for ( i = 0; i < lines.size; i++ )
    {
        out += lines[i];
        if ( i < lines.size - 1 )
            out += "\n";
    }

    return out;
}

set_selected_step(player, step_id)
{
    if ( !ee\ee_progress::has_step(step_id) )
        return false;

    player.ee_ui.selected_step_id = step_id;

    if ( player.ee_ui.detail_open )
        show_step_detail(player, step_id);

    return true;
}

clear_selected_step(player)
{
    player.ee_ui.selected_step_id = "";
}

get_display_step_id(player)
{
    if ( isDefined( player.ee_ui.selected_step_id ) && player.ee_ui.selected_step_id != "" && ee\ee_progress::has_step(player.ee_ui.selected_step_id) )
        return player.ee_ui.selected_step_id;

    return ee\ee_progress::get_active_step_id();
}

print_step_list(player)
{
    for ( i = 0; i < level.ee.steps.size; i++ )
    {
        step = level.ee.steps[i];
        state = ee\ee_progress::get_step_state(step.id);
        player iprintln("^3[EE] ^7" + step.id + " ^8(" + state + "^8)");
    }
}
