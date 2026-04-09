#include ee\ee_progress;

show_step_hint(player, step_id)
{
    step = ee\ee_progress::get_step(step_id);
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

show_step_notes(player, step_id)
{
    step = ee\ee_progress::get_step(step_id);
    if ( !isDefined( step ) )
        return;

    if ( step.notes.size <= 0 )
    {
        player iprintln("^3[EE] ^7Nessuna nota puzzle per questo step.");
        return;
    }

    for ( i = 0; i < step.notes.size; i++ )
        player iprintln("^6[EE Note] ^7" + step.notes[i]);
}

get_best_hint(step)
{
    for ( i = 0; i < step.hints.size; i++ )
    {
        hint = step.hints[i];
        if ( !isDefined( hint.flag_required ) || hint.flag_required == "" )
            return hint;

        if ( !ee\ee_progress::get_flag(hint.flag_required) )
            return hint;
    }

    return undefined;
}
