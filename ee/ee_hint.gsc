show_step_hint(player, step_id)
{
    step = scripts\zm\ee\ee_progress::get_step(step_id);
    if ( !isDefined( step ) )
        return;

    hint = get_best_hint(step);
    if ( !isDefined( hint ) )
    {
        player iprintln("^3[EE] ^7Nessun hint disponibile per questo step.");
        return;
    }

    player iprintln("^3[EE Hint] ^7" + hint.text);
}

get_best_hint(step)
{
    for ( i = 0; i < step.hints.size; i++ )
    {
        hint = step.hints[i];
        if ( !isDefined( hint.flag_required ) || hint.flag_required == "" )
            return hint;

        if ( !scripts\zm\ee\ee_progress::get_flag(hint.flag_required) )
            return hint;
    }

    return undefined;
}
