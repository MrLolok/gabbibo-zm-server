#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;

create_hud(player)
{
    player endon("disconnect");
    flag_wait("initial_blackscreen_passed");

    if ( isDefined( player.ee_ui ) )
    {
        if ( isDefined( player.ee_ui.bg ) ) player.ee_ui.bg destroy();
        if ( isDefined( player.ee_ui.accent ) ) player.ee_ui.accent destroy();
        if ( isDefined( player.ee_ui.title ) ) player.ee_ui.title destroy();
        if ( isDefined( player.ee_ui.meta ) ) player.ee_ui.meta destroy();
        if ( isDefined( player.ee_ui.body ) ) player.ee_ui.body destroy();
        if ( isDefined( player.ee_ui.objective ) ) player.ee_ui.objective destroy();
        if ( isDefined( player.ee_ui.detail_bg ) ) player.ee_ui.detail_bg destroy();
        if ( isDefined( player.ee_ui.detail ) ) player.ee_ui.detail destroy();
    }

    player.ee_ui = SpawnStruct();

    player.ee_ui.bg = newClientHudElem(player);
    player.ee_ui.bg.alignX = "left";
    player.ee_ui.bg.alignY = "top";
    player.ee_ui.bg.horzAlign = "user_left";
    player.ee_ui.bg.vertAlign = "user_top";
    player.ee_ui.bg.x = 5;
    player.ee_ui.bg.y = 62;
    player.ee_ui.bg setShader("white", 190, 54);
    player.ee_ui.bg.color = (0, 0, 0);
    player.ee_ui.bg.alpha = 0.5;
    player.ee_ui.bg.sort = 18;

    player.ee_ui.accent = newClientHudElem(player);
    player.ee_ui.accent.alignX = "left";
    player.ee_ui.accent.alignY = "top";
    player.ee_ui.accent.horzAlign = "user_left";
    player.ee_ui.accent.vertAlign = "user_top";
    player.ee_ui.accent.x = 5;
    player.ee_ui.accent.y = 62;
    player.ee_ui.accent setShader("white", 2, 54);
    player.ee_ui.accent.color = (0, 0.6, 1);
    player.ee_ui.accent.alpha = 1;
    player.ee_ui.accent.sort = 19;

    // NOTA: NON usare .font = "objective" — è il font gigante delle missioni
    // e crea rendering sovrapposto. Usiamo il font default (piccolo).
    player.ee_ui.title = newClientHudElem(player);
    player.ee_ui.title.alignX = "left";
    player.ee_ui.title.alignY = "top";
    player.ee_ui.title.horzAlign = "user_left";
    player.ee_ui.title.vertAlign = "user_top";
    player.ee_ui.title.x = 12;
    player.ee_ui.title.y = 64;
    player.ee_ui.title.fontscale = 1.1;
    player.ee_ui.title.sort = 20;
    player.ee_ui.title.alpha = 1;

    player.ee_ui.meta = newClientHudElem(player);
    player.ee_ui.meta.alignX = "left";
    player.ee_ui.meta.alignY = "top";
    player.ee_ui.meta.horzAlign = "user_left";
    player.ee_ui.meta.vertAlign = "user_top";
    player.ee_ui.meta.x = 12;
    player.ee_ui.meta.y = 76;
    player.ee_ui.meta.fontscale = 1.0;
    player.ee_ui.meta.sort = 20;
    player.ee_ui.meta.alpha = 1;

    player.ee_ui.body = newClientHudElem(player);
    player.ee_ui.body.alignX = "left";
    player.ee_ui.body.alignY = "top";
    player.ee_ui.body.horzAlign = "user_left";
    player.ee_ui.body.vertAlign = "user_top";
    player.ee_ui.body.x = 12;
    player.ee_ui.body.y = 88;
    player.ee_ui.body.fontscale = 1.0;
    player.ee_ui.body.sort = 20;
    player.ee_ui.body.alpha = 1;

    player.ee_ui.objective = newClientHudElem(player);
    player.ee_ui.objective.alignX = "left";
    player.ee_ui.objective.alignY = "top";
    player.ee_ui.objective.horzAlign = "user_left";
    player.ee_ui.objective.vertAlign = "user_top";
    player.ee_ui.objective.x = 12;
    player.ee_ui.objective.y = 100;
    player.ee_ui.objective.fontscale = 1.0;
    player.ee_ui.objective.sort = 20;
    player.ee_ui.objective.alpha = 1;

    player.ee_ui.detail_bg = newClientHudElem(player);
    player.ee_ui.detail_bg.alignX = "left";
    player.ee_ui.detail_bg.alignY = "top";
    player.ee_ui.detail_bg.horzAlign = "user_left";
    player.ee_ui.detail_bg.vertAlign = "user_top";
    player.ee_ui.detail_bg.x = 5;
    player.ee_ui.detail_bg.y = 120;
    player.ee_ui.detail_bg setShader("white", 220, 100);
    player.ee_ui.detail_bg.color = (0, 0, 0);
    player.ee_ui.detail_bg.alpha = 0;
    player.ee_ui.detail_bg.sort = 18;

    player.ee_ui.detail = newClientHudElem(player);
    player.ee_ui.detail.alignX = "left";
    player.ee_ui.detail.alignY = "top";
    player.ee_ui.detail.horzAlign = "user_left";
    player.ee_ui.detail.vertAlign = "user_top";
    player.ee_ui.detail.x = 12;
    player.ee_ui.detail.y = 123;
    player.ee_ui.detail.fontscale = 0.9;
    player.ee_ui.detail.sort = 20;
    player.ee_ui.detail.alpha = 0;

    player.ee_ui.detail_open = false;
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
        show_step_detail(player, scripts\zm\ee\ee_progress::get_active_step_id());
}

refresh_checklist(player)
{
    active = scripts\zm\ee\ee_progress::get_active_step();
    if ( !isDefined( active ) )
        return;

    player.ee_ui.title setText("^7EE: ^3" + scripts\zm\ee\ee_progress::get_active_step_number() + "^7/^3" + scripts\zm\ee\ee_progress::get_step_count());
    player.ee_ui.meta setText("^3" + truncate_text(active.title, 28));

    lines = [];
    lines[0] = format_step_line(active.id, "^3[>]^7 ", 18);

    player.ee_ui.body setText(join_lines(lines));
    player.ee_ui.objective setText("^7Prog: ^3" + scripts\zm\ee\ee_progress::get_step_substep_done_count(active.id) + "^7/^3" + scripts\zm\ee\ee_progress::get_step_substep_total(active.id));
}

toggle_detail(player)
{
    if ( !isDefined( player.ee_ui ) )
        return;

    player.ee_ui.detail_open = !player.ee_ui.detail_open;

    if ( player.ee_ui.detail_open )
    {
        show_step_detail(player, scripts\zm\ee\ee_progress::get_active_step_id());
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
    step = scripts\zm\ee\ee_progress::get_step(step_id);
    if ( !isDefined( step ) )
        return;

    lines = [];
    lines[lines.size] = "^5" + step.title;
    lines[lines.size] = step.long_desc;
    lines[lines.size] = "^7Progresso: ^3" + scripts\zm\ee\ee_progress::get_step_substep_done_count(step.id) + "^7/^3" + scripts\zm\ee\ee_progress::get_step_substep_total(step.id);

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

    player.ee_ui.detail_bg.alpha = 0.6;
    player.ee_ui.detail.alpha = 1;
    player.ee_ui.detail setText(join_lines(lines));
}

hide_step_detail(player)
{
    if ( !isDefined( player.ee_ui ) )
        return;

    player.ee_ui.detail_bg.alpha = 0;
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

    if ( isDefined( player.ee_ui.detail_bg ) )
    {
        if ( visible && player.ee_ui.detail_open )
            player.ee_ui.detail_bg.alpha = 0.6;
        else
            player.ee_ui.detail_bg.alpha = 0;
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

format_step_line(step_id, prefix, max_len)
{
    step = level.ee.steps[level.ee.step_lookup[step_id]];
    return prefix + truncate_text(step.title, max_len);
}

truncate_text(text, max_len)
{
    if ( !isDefined(text) )
        return "";

    if ( text.size <= max_len )
        return text;

    return getsubstr(text, 0, max_len - 3) + "...";
}
