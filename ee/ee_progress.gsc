init_state()
{
    level.ee = SpawnStruct();
    level.ee.quest_id = "";
    level.ee.progress_mode = "hybrid";
    level.ee.steps = [];
    level.ee.step_state = [];
    level.ee.step_lookup = [];
    level.ee.active_step_index = 0;
    level.ee.watchers = [];
    level.ee.flags = [];
}

run_watchers()
{
    level endon("end_game");

    for ( i = 0; i < level.ee.watchers.size; i++ )
    {
        watcher = level.ee.watchers[i];
        if ( isDefined( watcher ) )
            level thread [[watcher]]();
    }
}

register_step(step)
{
    index = level.ee.steps.size;
    step.index = index;

    if ( !isDefined( step.state ) )
        step.state = "future";

    level.ee.steps[index] = step;
    level.ee.step_lookup[step.id] = index;
    level.ee.step_state[step.id] = step.state;
}

register_watcher(func_ref)
{
    level.ee.watchers[level.ee.watchers.size] = func_ref;
}

find_substep_index(step, substep_id)
{
    for ( i = 0; i < step.substeps.size; i++ )
    {
        if ( step.substeps[i].id == substep_id )
            return i;
    }

    return -1;
}

get_step(step_id)
{
    if ( !isDefined( level.ee.step_lookup[step_id] ) )
        return undefined;

    return level.ee.steps[level.ee.step_lookup[step_id]];
}

has_step(step_id)
{
    return isDefined( level.ee.step_lookup[step_id] );
}

get_step_state(step_id)
{
    if ( !isDefined( level.ee.step_state[step_id] ) )
        return "future";

    return level.ee.step_state[step_id];
}

get_step_by_index(index)
{
    if ( index < 0 || index >= level.ee.steps.size )
        return undefined;

    return level.ee.steps[index];
}

get_active_step()
{
    if ( level.ee.steps.size <= 0 )
        return undefined;

    return level.ee.steps[level.ee.active_step_index];
}

get_active_step_id()
{
    step = get_active_step();
    if ( !isDefined( step ) )
        return "";

    return step.id;
}

get_step_count()
{
    return level.ee.steps.size;
}

get_active_step_number()
{
    return level.ee.active_step_index + 1;
}

set_active_step(step_id)
{
    if ( !isDefined( level.ee.step_lookup[step_id] ) )
        return false;

    for ( i = 0; i < level.ee.steps.size; i++ )
    {
        step = level.ee.steps[i];
        if ( level.ee.step_state[step.id] != "done" )
            level.ee.step_state[step.id] = "future";
    }

    level.ee.active_step_index = level.ee.step_lookup[step_id];
    level.ee.step_state[step_id] = "active";
    notify_refresh_all_players();
    return true;
}

set_flag(flag_id, value)
{
    level.ee.flags[flag_id] = value;
}

get_flag(flag_id)
{
    if ( !isDefined( level.ee.flags[flag_id] ) )
        return false;

    return level.ee.flags[flag_id];
}

is_substep_done(step_id, substep_id)
{
    step = get_step(step_id);
    if ( !isDefined( step ) )
        return false;

    index = find_substep_index(step, substep_id);
    if ( index < 0 )
        return false;

    return isDefined( step.substeps[index].done ) && step.substeps[index].done;
}

get_step_substep_total(step_id)
{
    step = get_step(step_id);
    if ( !isDefined( step ) )
        return 0;

    return step.substeps.size;
}

get_step_substep_done_count(step_id)
{
    step = get_step(step_id);
    if ( !isDefined( step ) )
        return 0;

    count = 0;
    for ( i = 0; i < step.substeps.size; i++ )
    {
        if ( isDefined( step.substeps[i].done ) && step.substeps[i].done )
            count++;
    }

    return count;
}

complete_substep(step_id, substep_id, source)
{
    step = get_step(step_id);
    if ( !isDefined( step ) )
        return false;

    index = find_substep_index(step, substep_id);
    if ( index < 0 )
        return false;

    if ( isDefined( step.substeps[index].done ) && step.substeps[index].done )
        return false;

    step.substeps[index].done = true;
    step.substeps[index].source = source;
    level.ee.steps[level.ee.step_lookup[step_id]] = step;
    level.ee.flags[substep_id] = true;
    level.ee.flags[step_id + "_" + substep_id] = true;

    notify_refresh_all_players();

    if ( are_all_substeps_done(step) )
        complete_step(step_id, source);

    return true;
}

complete_step_substeps(step_id, source)
{
    step = get_step(step_id);
    if ( !isDefined( step ) )
        return false;

    for ( i = 0; i < step.substeps.size; i++ )
        complete_substep(step_id, step.substeps[i].id, source);

    if ( get_step_state(step_id) != "done" )
        complete_step(step_id, source);

    return true;
}

are_all_substeps_done(step)
{
    for ( i = 0; i < step.substeps.size; i++ )
    {
        if ( !isDefined( step.substeps[i].done ) || !step.substeps[i].done )
            return false;
    }

    return true;
}

complete_step(step_id, source)
{
    if ( !isDefined( level.ee.step_lookup[step_id] ) )
        return false;

    if ( level.ee.step_state[step_id] == "done" )
        return false;

    level.ee.step_state[step_id] = "done";
    level.ee.flags[step_id] = true;
    level.ee.flags["step_" + step_id + "_source"] = source;

    next_index = find_next_incomplete_index();
    if ( next_index >= 0 )
    {
        level.ee.active_step_index = next_index;
        level.ee.step_state[level.ee.steps[next_index].id] = "active";
    }

    level notify("ee_step_completed", step_id, source);
    notify_refresh_all_players();
    return true;
}

find_next_incomplete_index()
{
    for ( i = 0; i < level.ee.steps.size; i++ )
    {
        if ( level.ee.step_state[level.ee.steps[i].id] != "done" )
            return i;
    }

    return -1;
}

notify_refresh_all_players()
{
    players = get_players();
    foreach ( p in players )
    {
        if ( isDefined( p.ee_ui_initialized ) && p.ee_ui_initialized )
            p notify("ee_refresh_ui");
    }
}
