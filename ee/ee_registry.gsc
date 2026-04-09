#include ee\maps\origins_ee;

resolve_map()
{
    level.ee_map_id = undefined;

    switch ( level.script )
    {
        case "zm_tomb":
            level.ee_map_id = "origins";
            break;

        case "zm_prison":
            level.ee_map_id = "mob";
            break;

        case "zm_buried":
            level.ee_map_id = "buried";
            break;

        case "zm_highrise":
            level.ee_map_id = "dierise";
            break;

        case "zm_transit":
            level.ee_map_id = "tranzit";
            break;
    }

    return isDefined( level.ee_map_id );
}

register_map_module()
{
    if ( !isDefined( level.ee_map_id ) )
        return false;

    switch ( level.ee_map_id )
    {
        case "origins":
            ee\maps\origins_ee::register();
            return true;
    }

    return false;
}
