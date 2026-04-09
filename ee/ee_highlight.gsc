#include ee\ee_progress;

toggle_active_step_pois(player)
{
    if ( !isDefined( player.ee_poi_visible ) || !player.ee_poi_visible )
    {
        player.ee_poi_visible = true;
        show_active_step_pois(player);
        player iprintln("^3[EE] ^7POI attivi per 10 secondi.");
    }
    else
    {
        player.ee_poi_visible = false;
        player notify("ee_stop_pois");
        player iprintln("^3[EE] ^7POI disattivati.");
    }
}

show_active_step_pois(player)
{
    step = ee\ee_progress::get_active_step();
    if ( !isDefined( step ) )
        return;

    player thread poi_lifecycle(step);
}

poi_lifecycle(step)
{
    self endon("disconnect");
    self endon("ee_stop_pois");

    for ( i = 0; i < step.pois.size; i++ )
    {
        poi = step.pois[i];
        if ( isDefined( poi.origin ) )
            Print3d(poi.origin, poi.text, (0, 1, 0), 1, 1.5, 10);
    }

    wait 10;
    self.ee_poi_visible = false;
}
