make_step(id, title, short_desc, long_desc)
{
    step = SpawnStruct();
    step.id = id;
    step.title = title;
    step.short_desc = short_desc;
    step.long_desc = long_desc;
    step.state = "future";
    step.substeps = [];
    step.hints = [];
    step.pois = [];
    step.notes = [];
    step.category = "main";
    return step;
}

add_substep(step, id, title)
{
    step.substeps[step.substeps.size] = make_substep(id, title);
    return step;
}

add_hint(step, text, flag_required)
{
    step.hints[step.hints.size] = make_hint(text, flag_required);
    return step;
}

add_poi(step, origin, text)
{
    step.pois[step.pois.size] = make_poi(origin, text);
    return step;
}

make_substep(id, title)
{
    sub = SpawnStruct();
    sub.id = id;
    sub.title = title;
    sub.done = false;
    return sub;
}

make_hint(text, flag_required)
{
    hint = SpawnStruct();
    hint.text = text;
    hint.flag_required = flag_required;
    return hint;
}

make_poi(origin, text)
{
    poi = SpawnStruct();
    poi.origin = origin;
    poi.text = text;
    return poi;
}

add_note(step, text)
{
    step.notes[step.notes.size] = text;
    return step;
}
