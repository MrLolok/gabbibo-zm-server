#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

get_spawn_origin()
{
    return (0, 0, 0);
}

get_excavation_origin()
{
    return (1150, 150, 50);
}

get_church_origin()
{
    return (5500, -300, 200);
}

get_fire_tunnel_origin()
{
    return (4200, -1200, 60);
}

get_ice_tunnel_origin()
{
    return (-1550, 1950, 40);
}

get_wind_tunnel_origin()
{
    return (-3500, 2600, 120);
}

get_lightning_tunnel_origin()
{
    return (2850, 2350, 100);
}

get_generator5_origin()
{
    return (3300, 2000, 100);
}

get_generator6_origin()
{
    return (5200, 250, 180);
}

get_church_build_origin()
{
    return (5050, -850, 70);
}

check_landmark(player, origin, radius, step_id, substep_id)
{
    if ( distance(player.origin, origin) < radius )
        scripts\zm\ee\ee_progress::complete_substep(step_id, substep_id, "area_detect");
}

complete_step_bundle(step_id, source, substeps)
{
    for ( i = 0; i < substeps.size; i++ )
        scripts\zm\ee\ee_progress::complete_substep(step_id, substeps[i], source);
}

handle_staff_weapon_completion(player, base_weapon, upgraded_weapon, step_id, substeps)
{
    if ( !(player HasWeapon(base_weapon)) && !(player HasWeapon(upgraded_weapon)) )
        return;

    complete_step_bundle(step_id, "weapon_detect", substeps);
}

handle_upgraded_staff_completion(player, upgraded_weapon, step_id, puzzle_substep, done_substep)
{
    if ( !(player HasWeapon(upgraded_weapon)) )
        return;

    scripts\zm\ee\ee_progress::complete_substep(step_id, puzzle_substep, "weapon_detect");
    scripts\zm\ee\ee_progress::complete_substep(step_id, done_substep, "weapon_detect");
}

register()
{
    level.ee.quest_id = "origins_little_lost_girl";
    level.ee.progress_mode = "hybrid";

    register_step_open_map();
    register_step_gramophone();
    register_step_build_wind_staff();
    register_step_build_lightning_staff();
    register_step_build_ice_staff();
    register_step_build_fire_staff();
    register_step_upgrade_wind_staff();
    register_step_upgrade_lightning_staff();
    register_step_upgrade_ice_staff();
    register_step_upgrade_fire_staff();
    register_step_place_staffs();
    register_step_press_button_and_kills();
    register_step_rain_fire();
    register_step_thunder_fists();
    register_step_release_maxis();

    scripts\zm\ee\ee_progress::set_active_step("open_map");
    scripts\zm\ee\ee_progress::register_watcher(::watch_landmark_progression);
    scripts\zm\ee\ee_progress::register_watcher(::watch_staff_ownership);
    scripts\zm\ee\ee_progress::register_watcher(::watch_upgraded_staff_ownership);
}

register_step_open_map()
{
    step = scripts\zm\ee\ee_data::make_step(
        "open_map",
        "Apri la mappa",
        "Raggiungi i punti chiave",
        "Avanza fino alla Excavation Site, sblocca i percorsi principali e preparati a costruire gli staff."
    );

    step = scripts\zm\ee\ee_data::add_substep(step, "reach_excavation", "Raggiungi Excavation Site");
    step = scripts\zm\ee\ee_data::add_substep(step, "reach_church", "Raggiungi Church");
    step = scripts\zm\ee\ee_data::add_substep(step, "reach_gen5", "Raggiungi Generator 5");
    step = scripts\zm\ee\ee_data::add_substep(step, "reach_gen6", "Raggiungi Generator 6");

    step = scripts\zm\ee\ee_data::add_hint(step, "Apri prima il centro mappa: Excavation è il nodo comune di quasi tutto l'EE.", "reach_excavation");
    step = scripts\zm\ee\ee_data::add_hint(step, "Church e Generator 6 ti servono presto per Fire Staff e accesso avanzato.", "reach_church");

    step = scripts\zm\ee\ee_data::add_note(step, "Questo step è intentionally broad: serve a evitare che il framework spinga staff/puzzle troppo presto.");
    step = scripts\zm\ee\ee_data::add_poi(step, get_excavation_origin(), "Excavation Site");
    step = scripts\zm\ee\ee_data::add_poi(step, get_church_origin(), "Church");
    step = scripts\zm\ee\ee_data::add_poi(step, get_generator5_origin(), "Generator 5");
    step = scripts\zm\ee\ee_data::add_poi(step, get_generator6_origin(), "Generator 6");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_gramophone()
{
    step = scripts\zm\ee\ee_data::make_step(
        "gramophone",
        "Prendi Gramophone",
        "Sblocca Crazy Place",
        "Prendi Gramophone e il record corretto per iniziare l'accesso ai tunnel elementali e alle camere dei cristalli."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("gramophone_ready", "Gramophone disponibile");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("wind_record_ready", "Record Wind trovato");
    step.substeps[2] = scripts\zm\ee\ee_data::make_substep("lightning_record_ready", "Record Lightning trovato");
    step.substeps[3] = scripts\zm\ee\ee_data::make_substep("ice_record_ready", "Record Ice trovato");
    step.substeps[4] = scripts\zm\ee\ee_data::make_substep("fire_record_ready", "Record Fire trovato");

    step.hints[0] = scripts\zm\ee\ee_data::make_hint("Senza Gramophone non puoi entrare nella Crazy Place per i cristalli degli staff.", "gramophone_ready");
    step.hints[1] = scripts\zm\ee\ee_data::make_hint("Ogni staff ha il proprio record: usa questo step come gate comune.", "");

    step = scripts\zm\ee\ee_data::add_note(step, "Il framework non prova a sniffare ogni pickup record nativo: usa detect best-effort o debug `.ee sub` se necessario.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_excavation_origin(), "Excavation / Gramophone zone");
    step.pois[1] = scripts\zm\ee\ee_data::make_poi(get_church_origin(), "Church / Fire record zone");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_build_wind_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "build_wind_staff",
        "Costruisci Wind Staff",
        "Parti, record e cristallo",
        "Ottieni le tre parti dai robot, il record Wind, il cristallo Wind e assembla lo staff."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("wind_record", "Recupera il record Wind");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("wind_crystal", "Recupera il cristallo Wind");
    step.substeps[2] = scripts\zm\ee\ee_data::make_substep("wind_part_robot_1", "Parte robot 1");
    step.substeps[3] = scripts\zm\ee\ee_data::make_substep("wind_part_robot_2", "Parte robot 2");
    step.substeps[4] = scripts\zm\ee\ee_data::make_substep("wind_part_robot_3", "Parte robot 3");
    step.substeps[5] = scripts\zm\ee\ee_data::make_substep("wind_built", "Assembla il Wind Staff");

    step.hints[0] = scripts\zm\ee\ee_data::make_hint("Le parti Wind arrivano tutte dai robot, non dal tank o dagli scavi.", "wind_part_robot_1");
    step.hints[1] = scripts\zm\ee\ee_data::make_hint("Il cristallo richiede accesso al tunnel Wind e alla Crazy Place.", "wind_crystal");

    step = scripts\zm\ee\ee_data::add_note(step, "Quando il framework rileva il possesso del Wind Staff, considera questo step completo a posteriori.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_wind_tunnel_origin(), "Ingresso tunnel Wind");
    step.pois[1] = scripts\zm\ee\ee_data::make_poi(get_excavation_origin(), "Excavation / robot lanes");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_build_lightning_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "build_lightning_staff",
        "Costruisci Lightning Staff",
        "Tank, record e cristallo",
        "Ottieni le tre parti legate al percorso del tank, il record Lightning, il cristallo e assembla lo staff."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("lightning_record", "Recupera il record Lightning");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("lightning_crystal", "Recupera il cristallo Lightning");
    step.substeps[2] = scripts\zm\ee\ee_data::make_substep("lightning_part_1", "Parte tank 1");
    step.substeps[3] = scripts\zm\ee\ee_data::make_substep("lightning_part_2", "Parte tank 2");
    step.substeps[4] = scripts\zm\ee\ee_data::make_substep("lightning_part_3", "Parte tank 3");
    step.substeps[5] = scripts\zm\ee\ee_data::make_substep("lightning_built", "Assembla il Lightning Staff");

    step.hints[0] = scripts\zm\ee\ee_data::make_hint("Le tre parti Lightning si prendono saltando dal tank in punti precisi.", "lightning_part_1");
    step.hints[1] = scripts\zm\ee\ee_data::make_hint("Il record Lightning è vicino al tank path / area Generator 4-5.", "lightning_record");

    step = scripts\zm\ee\ee_data::add_note(step, "Se vuoi usare il framework come assistant e non come soluzione totale, lascia i jump del tank solo suggeriti, non auto-risolti.");
    step = scripts\zm\ee\ee_data::add_note(step, "Puzzle upgrade Lightning: sequence tipica 1-3-6, 3-5-7, 2-4-6 nel tunnel; verificare con la tua versione della guida prima di hardcodare UI definitiva.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_lightning_tunnel_origin(), "Ingresso tunnel Lightning");
    step.pois[1] = scripts\zm\ee\ee_data::make_poi(get_generator5_origin(), "Generator 5 / tank route");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_build_ice_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "build_ice_staff",
        "Costruisci Ice Staff",
        "Parti dagli scavi",
        "Ottieni il record Ice, il cristallo Ice, le tre parti dagli scavi durante la neve e assembla lo staff."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("ice_record", "Recupera il record Ice");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("ice_crystal", "Recupera il cristallo Ice");
    step.substeps[2] = scripts\zm\ee\ee_data::make_substep("ice_part_1", "Parte scavo 1");
    step.substeps[3] = scripts\zm\ee\ee_data::make_substep("ice_part_2", "Parte scavo 2");
    step.substeps[4] = scripts\zm\ee\ee_data::make_substep("ice_part_3", "Parte scavo 3");
    step.substeps[5] = scripts\zm\ee\ee_data::make_substep("ice_built", "Assembla l'Ice Staff");

    step.hints[0] = scripts\zm\ee\ee_data::make_hint("Le parti Ice compaiono solo durante la neve e tramite dig spots.", "ice_part_1");
    step.hints[1] = scripts\zm\ee\ee_data::make_hint("Se stai hostando puoi usare il tuo comando `.snow` per testing del framework.", "");

    step = scripts\zm\ee\ee_data::add_note(step, "Lo script server esistente ha gia' il comando `.snow`: ottimo per testare il tracking Ice senza aspettare il weather cycle.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_ice_tunnel_origin(), "Ingresso tunnel Ice");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_build_fire_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "build_fire_staff",
        "Costruisci Fire Staff",
        "Disco, cristallo e parti",
        "Ottieni disco rosso, cristallo Fire, tre parti del bastone e assembla tutto al tavolo di costruzione."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("fire_record", "Recupera il record Fire");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("fire_crystal", "Recupera il cristallo Fire");
    step.substeps[2] = scripts\zm\ee\ee_data::make_substep("fire_part_robot", "Recupera la parte dal robot");
    step.substeps[3] = scripts\zm\ee\ee_data::make_substep("fire_part_church", "Recupera la parte area Church");
    step.substeps[4] = scripts\zm\ee\ee_data::make_substep("fire_part_tank", "Recupera la parte del tank");
    step.substeps[5] = scripts\zm\ee\ee_data::make_substep("fire_built", "Assembla il Fire Staff");

    step.hints[0] = scripts\zm\ee\ee_data::make_hint("Il record Fire e una parte Fire gravitano attorno alla Church / Gen 6.", "fire_record");
    step.hints[1] = scripts\zm\ee\ee_data::make_hint("L'ultima parte mancante dipende da robot, Church o tank.", "");

    step = scripts\zm\ee\ee_data::add_note(step, "Questo e' il build path che attualmente ha il tracking best-effort piu' forte.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_church_origin(), "Church / Fire record");
    step.pois[1] = scripts\zm\ee\ee_data::make_poi(get_fire_tunnel_origin(), "Ingresso tunnel Fire");
    step.pois[2] = scripts\zm\ee\ee_data::make_poi(get_church_build_origin(), "Tavolo di costruzione");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_upgrade_wind_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "upgrade_wind_staff",
        "Upgrade Wind Staff",
        "Risolvi puzzle Wind",
        "Risolvi il puzzle delle piattaforme / simboli Wind, poi ricarica e completa il rituale di upgrade."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("wind_puzzle", "Risolvi il puzzle Wind");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("wind_upgrade_done", "Ottieni il Wind Staff potenziato");

    step = scripts\zm\ee\ee_data::add_note(step, "Il helper puzzle Wind dovrebbe mostrare la corrispondenza simboli -> piattaforme corrette.");
    step = scripts\zm\ee\ee_data::add_note(step, "Per ora il framework fornisce note/hints, non una texture puzzle dedicata.");
    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_upgrade_lightning_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "upgrade_lightning_staff",
        "Upgrade Lightning Staff",
        "Risolvi sequenza",
        "Attiva i pannelli nel tunnel Lightning con la sequenza corretta e completa il rituale di upgrade."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("lightning_puzzle", "Risolvi la sequenza Lightning");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("lightning_upgrade_done", "Ottieni il Lightning Staff potenziato");

    step = scripts\zm\ee\ee_data::add_note(step, "Sequence reference da verificare con la tua guida finale: 1-3-6 / 3-5-7 / 2-4-6.");
    step = scripts\zm\ee\ee_data::add_note(step, "Non hardcodare output sbagliati nel build finale senza una verifica in partita.");
    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_upgrade_ice_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "upgrade_ice_staff",
        "Upgrade Ice Staff",
        "Risolvi puzzle Ice",
        "Identifica i simboli corretti, spara alle lapidi nell'ordine giusto e completa il rituale di upgrade."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("ice_puzzle", "Risolvi il puzzle Ice");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("ice_upgrade_done", "Ottieni l'Ice Staff potenziato");

    step = scripts\zm\ee\ee_data::add_note(step, "Ottimo candidato per un puzzle helper HUD futuro: simbolo, conversione numerica, bersaglio lapide.");
    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_upgrade_fire_staff()
{
    step = scripts\zm\ee\ee_data::make_step(
        "upgrade_fire_staff",
        "Upgrade Fire Staff",
        "Risolvi codice Fire",
        "Accendi i bracieri corretti secondo il codice Fire e completa il rituale di upgrade."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("fire_puzzle", "Risolvi il codice Fire");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("fire_upgrade_done", "Ottieni il Fire Staff potenziato");

    step = scripts\zm\ee\ee_data::add_note(step, "Reference comune del puzzle Fire: bracieri 11, 5, 9, 7.");
    step = scripts\zm\ee\ee_data::add_note(step, "Mantieni questo come nota UX, non come auto-completamento.");
    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_place_staffs()
{
    step = scripts\zm\ee\ee_data::make_step(
        "place_staffs",
        "Posiziona gli staff",
        "Metti gli staff nei robot",
        "Inserisci gli staff potenziati nei robot corretti e nel centro Excavation per avanzare la main quest."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("wind_placed", "Wind Staff posizionato");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("lightning_placed", "Lightning Staff posizionato");
    step.substeps[2] = scripts\zm\ee\ee_data::make_substep("ice_placed", "Ice Staff posizionato");
    step.substeps[3] = scripts\zm\ee\ee_data::make_substep("fire_placed", "Fire Staff posizionato");

    step = scripts\zm\ee\ee_data::add_note(step, "Step difficilmente auto-rilevabile in modo robusto senza hook map-specific approfonditi.");
    step = scripts\zm\ee\ee_data::add_note(step, "Per adesso trattalo come guided/manual assisted con `.ee sub` in fase di authoring.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_excavation_origin(), "Excavation / center pedestal");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_press_button_and_kills()
{
    step = scripts\zm\ee\ee_data::make_step(
        "button_and_kills",
        "Pulsante e kill",
        "Attiva la fase centrale",
        "Premi il pulsante rosso a Excavation e completa la fase di kill nella Crazy Place / beacon centrale."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("button_pressed", "Pulsante rosso premuto");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("crazy_place_kills", "Kill richieste completate");

    step = scripts\zm\ee\ee_data::add_note(step, "Questa fase cambia spesso nel ricordo dei player: il framework deve chiarire il next action, non sostituire la coordinazione del team.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_excavation_origin(), "Pulsante / beacon centrale");

    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_rain_fire()
{
    step = scripts\zm\ee\ee_data::make_step(
        "rain_fire",
        "Rain Fire",
        "Lancia il beacon",
        "Ottieni e usa il G-Strike per aprire il passaggio nel robot corretto durante la fase Rain Fire."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("gstrike_ready", "G-Strike disponibile");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("rain_fire_done", "Rain Fire completato");

    step = scripts\zm\ee\ee_data::add_note(step, "Questo è uno degli step dove l'assistente UX dà più valore: chiarire timing, robot e destinazione del beacon.");
    step = scripts\zm\ee\ee_data::add_note(step, "Auto detect completo complesso; mantieni helper forte e completion manuale/debug finché non hai hook certi.");
    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_thunder_fists()
{
    step = scripts\zm\ee\ee_data::make_step(
        "thunder_fists",
        "Thunder Fists",
        "Completa il melee path",
        "Sblocca e ottieni le Thunder Fists / One Inch Punch richieste per il finale della quest."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("fists_ready", "Thunder Fists ottenute");

    step = scripts\zm\ee\ee_data::add_note(step, "Il nome arma/esatto hook puo' variare: meglio non affidarsi ancora a un HasWeapon hardcoded senza test in-engine.");
    scripts\zm\ee\ee_progress::register_step(step);
}

register_step_release_maxis()
{
    step = scripts\zm\ee\ee_data::make_step(
        "release_maxis",
        "Rilascia Maxis",
        "Chiudi l'EE",
        "Dopo aver aperto il passaggio finale, libera Maxis Drone nel punto corretto e chiudi la quest."
    );

    step.substeps[0] = scripts\zm\ee\ee_data::make_substep("maxis_ready", "Maxis Drone disponibile");
    step.substeps[1] = scripts\zm\ee\ee_data::make_substep("ee_complete", "Easter Egg completato");

    step = scripts\zm\ee\ee_data::add_note(step, "Lo step finale va mantenuto molto esplicito perché i player casual si perdono qui anche se hanno fatto tutto il resto.");
    step.pois[0] = scripts\zm\ee\ee_data::make_poi(get_excavation_origin(), "Final release / Excavation");

    scripts\zm\ee\ee_progress::register_step(step);
}

watch_landmark_progression()
{
    level endon("end_game");

    excavation_origin = get_excavation_origin();
    church_origin = get_church_origin();
    gen5_origin = get_generator5_origin();
    gen6_origin = get_generator6_origin();
    fire_tunnel_origin = get_fire_tunnel_origin();
    wind_tunnel_origin = get_wind_tunnel_origin();
    ice_tunnel_origin = get_ice_tunnel_origin();
    lightning_tunnel_origin = get_lightning_tunnel_origin();

    for ( ;; )
    {
        players = get_players();
        foreach ( player in players )
        {
            check_landmark(player, excavation_origin, 275, "open_map", "reach_excavation");
            check_landmark(player, gen5_origin, 250, "open_map", "reach_gen5");
            check_landmark(player, gen6_origin, 250, "open_map", "reach_gen6");
            check_landmark(player, excavation_origin, 250, "gramophone", "gramophone_ready");

            if ( distance(player.origin, church_origin) < 275 )
            {
                scripts\zm\ee\ee_progress::complete_substep("open_map", "reach_church", "area_detect");
                scripts\zm\ee\ee_progress::complete_substep("build_fire_staff", "fire_record", "area_detect");
            }

            if ( distance(player.origin, fire_tunnel_origin) < 220 )
            {
                scripts\zm\ee\ee_progress::complete_substep("build_fire_staff", "fire_crystal", "area_detect");
                scripts\zm\ee\ee_progress::complete_substep("gramophone", "fire_record_ready", "area_detect");
            }

            if ( distance(player.origin, wind_tunnel_origin) < 220 )
            {
                scripts\zm\ee\ee_progress::complete_substep("build_wind_staff", "wind_crystal", "area_detect");
                scripts\zm\ee\ee_progress::complete_substep("gramophone", "wind_record_ready", "area_detect");
            }

            if ( distance(player.origin, ice_tunnel_origin) < 220 )
            {
                scripts\zm\ee\ee_progress::complete_substep("build_ice_staff", "ice_crystal", "area_detect");
                scripts\zm\ee\ee_progress::complete_substep("gramophone", "ice_record_ready", "area_detect");
            }

            if ( distance(player.origin, lightning_tunnel_origin) < 220 )
            {
                scripts\zm\ee\ee_progress::complete_substep("build_lightning_staff", "lightning_crystal", "area_detect");
                scripts\zm\ee\ee_progress::complete_substep("gramophone", "lightning_record_ready", "area_detect");
            }
        }

        wait 0.25;
    }
}

watch_staff_ownership()
{
    level endon("end_game");

    wind_substeps = [];
    wind_substeps[0] = "wind_record";
    wind_substeps[1] = "wind_crystal";
    wind_substeps[2] = "wind_part_robot_1";
    wind_substeps[3] = "wind_part_robot_2";
    wind_substeps[4] = "wind_part_robot_3";
    wind_substeps[5] = "wind_built";

    lightning_substeps = [];
    lightning_substeps[0] = "lightning_record";
    lightning_substeps[1] = "lightning_crystal";
    lightning_substeps[2] = "lightning_part_1";
    lightning_substeps[3] = "lightning_part_2";
    lightning_substeps[4] = "lightning_part_3";
    lightning_substeps[5] = "lightning_built";

    ice_substeps = [];
    ice_substeps[0] = "ice_record";
    ice_substeps[1] = "ice_crystal";
    ice_substeps[2] = "ice_part_1";
    ice_substeps[3] = "ice_part_2";
    ice_substeps[4] = "ice_part_3";
    ice_substeps[5] = "ice_built";

    fire_substeps = [];
    fire_substeps[0] = "fire_record";
    fire_substeps[1] = "fire_crystal";
    fire_substeps[2] = "fire_part_robot";
    fire_substeps[3] = "fire_part_church";
    fire_substeps[4] = "fire_part_tank";
    fire_substeps[5] = "fire_built";

    for ( ;; )
    {
        players = get_players();
        foreach ( player in players )
        {
            handle_staff_weapon_completion(player, "staff_air_zm", "staff_air_upgraded_zm", "build_wind_staff", wind_substeps);
            handle_staff_weapon_completion(player, "staff_lightning_zm", "staff_lightning_upgraded_zm", "build_lightning_staff", lightning_substeps);
            handle_staff_weapon_completion(player, "staff_water_zm", "staff_water_upgraded_zm", "build_ice_staff", ice_substeps);
            handle_staff_weapon_completion(player, "staff_fire_zm", "staff_fire_upgraded_zm", "build_fire_staff", fire_substeps);
        }

        wait 0.35;
    }
}

watch_upgraded_staff_ownership()
{
    level endon("end_game");

    for ( ;; )
    {
        players = get_players();
        foreach ( player in players )
        {
            handle_upgraded_staff_completion(player, "staff_air_upgraded_zm", "upgrade_wind_staff", "wind_puzzle", "wind_upgrade_done");
            handle_upgraded_staff_completion(player, "staff_lightning_upgraded_zm", "upgrade_lightning_staff", "lightning_puzzle", "lightning_upgrade_done");
            handle_upgraded_staff_completion(player, "staff_water_upgraded_zm", "upgrade_ice_staff", "ice_puzzle", "ice_upgrade_done");
            handle_upgraded_staff_completion(player, "staff_fire_upgraded_zm", "upgrade_fire_staff", "fire_puzzle", "fire_upgrade_done");
        }

        wait 0.35;
    }
}
