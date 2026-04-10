#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_score;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_powerups;
#include scripts\zm\ee\ee_assistant;

init()
{
    // ==========================================
    // GLOBAL SETTINGS
    // ==========================================
    level.player_out_of_playable_area_monitor = false;

    // ==========================================
    // PRECACHE TEXTURES (Prevents crashing)
    // ==========================================
    PrecacheShader("white");
    PrecacheShader("damage_feedback"); 

    // ==========================================
    // SERVER CONFIGURATION
    // ==========================================
    level.perk_purchase_limit = 999; 
    level.host_only_commands = false; // true = Host Only, false = Everyone

    level thread onPlayerConnect();
    level thread chat_command_listener();
    level thread remove_quick_revive_limit(); 
    level thread global_hitmarker_manager(); 
    level thread scripts\zm\ee\ee_assistant::ee_init();

    // Precachiamo gli shader per la nuova help HUD
    PrecacheShader("black");
}

onPlayerConnect()
{
    for (;;)
    {
        level waittill("connecting", player);
        player notifyOnPlayerCommand("toggle_parts_key", "+smoke");
        player thread onplayerspawned();
        player thread parts_toggle_key_monitor();
    }
}

onplayerspawned()
{
    self endon("disconnect");
    
    // Initialize HUD and monitors only on the first spawn
    if(!isDefined(self.hud_initiated))
    {
        self thread modern_counters_hud();
        self thread ezz_bars_hud();
        self thread auto_reload_monitor();
        self thread down_timer_monitor();
        self.hud_initiated = true;
    }
    
    for (;;)
    {
        self waittill("spawned_player");
        
        self iprintln("^6[Gabbibo Server] ^7Benvenuto, ^2" + self.name);
        self iprintln("Scrivi ^3.help ^7in chat per vedere i comandi.");

        if(!isDefined(self.speed_buff_active) || self.speed_buff_active == false)
        {
            self setMoveSpeedScale(1.0); 
        }
    }
}

// ==========================================
// CHAT COMMAND SYSTEM
// ==========================================
chat_command_listener()
{
    level endon("end_game");

    for(;;)
    {
        level waittill("say", message, player);
        message = tolower(message);
        args = strtok(message, " ");
        if (args.size == 0) continue;
        command = args[0];

        // ------------------------------------------
        // PUBLIC COMMANDS
        // ------------------------------------------
        if(command == ".help" || command == ".cmds")
        {
            player thread toggle_help_hud();
            continue;
        }

        if(command == ".pay")
        {
            if(args.size >= 3)
            {
                target_name = args[1];
                amount = int(args[2]);
                if(amount > 0 && player.score >= amount)
                {
                    target = get_player_by_name(target_name);
                    if(isDefined(target) && target != player)
                    {
                        player maps\mp\zombies\_zm_score::minus_to_player_score(amount);
                        target maps\mp\zombies\_zm_score::add_to_player_score(amount);
                        player iprintln("^2Hai inviato " + amount + " punti a " + target.name);
                        target iprintln("^2Hai ricevuto " + amount + " punti da " + player.name + "!");
                    }
                    else { player iprintln("^1Errore: Giocatore non trovato."); }
                }
                else { player iprintln("^1Errore: Punti insufficienti."); }
            }
            continue;
        }

        if(command == ".join")
        {
            player.sessionstate = "playing";
            player iprintlnbold("^2[Join] ^7Sei entrato in gioco, " + player.name + "!");
            continue;
        }

        if(command == ".dropweapon")
        {
            current_weapon = player GetCurrentWeapon();
            if(current_weapon != "none" && current_weapon != "knife_zm")
            {
                player DropItem(current_weapon);
                player iprintln("^2Hai lanciato la tua arma a terra.");
            }
            else { player iprintln("^1Errore: Non puoi lanciare questa arma."); }
            continue;
        }

        if(command == ".deposit")
        {
            if(!isDefined(level.player_bank)) { level.player_bank = []; }
            if(!isDefined(level.player_bank[player.name])) { level.player_bank[player.name] = 0; }
            
            if(args.size > 1)
            {
                amount = 0;
                if(args[1] == "all") { amount = player.score; }
                else { amount = int(args[1]); }
                
                if(amount > 0 && player.score >= amount)
                {
                    player maps\mp\zombies\_zm_score::minus_to_player_score(amount);
                    level.player_bank[player.name] += amount;
                    player iprintln("^2Hai depositato " + amount + " pt. Saldo: " + level.player_bank[player.name]);
                }
                else { player iprintln("^1Errore: Punti insufficienti."); }
            }
            else { player iprintln("^3Banca: ^7Saldo attuale: ^2" + level.player_bank[player.name] + " pt."); }
            continue;
        }

        if(command == ".withdraw")
        {
            if(!isDefined(level.player_bank)) { level.player_bank = []; }
            if(!isDefined(level.player_bank[player.name])) { level.player_bank[player.name] = 0; }
            
            if(args.size > 1)
            {
                amount = 0;
                if(args[1] == "all") { amount = level.player_bank[player.name]; }
                else { amount = int(args[1]); }
                
                if(amount > 0 && level.player_bank[player.name] >= amount)
                {
                    level.player_bank[player.name] -= amount;
                    player maps\mp\zombies\_zm_score::add_to_player_score(amount);
                    player iprintln("^2Hai prelevato " + amount + " pt. Saldo: " + level.player_bank[player.name]);
                }
                else { player iprintln("^1Errore: Saldo insufficiente."); }
            }
            continue;
        }

        // ------------------------------------------
        // HOST PERMISSION CHECK
        // ------------------------------------------
        if ( level.host_only_commands && !player isHost() )
        {
            player iprintln("^1Errore: Solo l'Host del server può usare questi comandi.");
            continue;
        }

        if(command == ".snow")
        {
            if ( level.script == "zm_tomb" )
            {
                if(!isDefined(level.force_snow_enabled) || level.force_snow_enabled == false)
                {
                    level.force_snow_enabled = true;
                    level.weather_snow = 1;
                    level.weather_rain = 0;
                    level setclientfield( "snowing", 1 );
                    level setclientfield( "raining", 0 );
                    level notify( "weather_cycle" );
                    player iprintln("^2Tempesta di Neve FORZATA! (Ora puoi scavare il Ghiaccio).");
                }
                else
                {
                    level.force_snow_enabled = false;
                    level.weather_snow = 0;
                    level setclientfield( "snowing", 0 );
                    level notify( "weather_cycle" );
                    player iprintln("^1Meteo Origins riportato al ciclo naturale.");
                }
            } else { player iprintln("^1Errore: Questo comando funziona solo su Origins."); }
            continue;
        }

        // ------------------------------------------
        // ORIGINS STAFFS FIX
        // ------------------------------------------
        if(command == ".staff")
        {
            if ( level.script != "zm_tomb" )
            {
                player iprintln("^1Errore: I bastoni sono disponibili solo su Origins.");
                continue;
            }

            if(args.size < 2)
            {
                player iprintln("^3Uso: ^7.staff <fire/ice/lightning/wind>");
                continue;
            }

            staff_type = tolower(args[1]);
            weapon_to_give = "none";

            // Treyarch internal names mapped
            if(staff_type == "fire" || staff_type == "fuego") weapon_to_give = "staff_fire_upgraded_zm";
            else if(staff_type == "ice" || staff_type == "water" || staff_type == "hielo") weapon_to_give = "staff_water_upgraded_zm";
            else if(staff_type == "lightning" || staff_type == "rayo") weapon_to_give = "staff_lightning_upgraded_zm";
            else if(staff_type == "wind" || staff_type == "air" || staff_type == "viento") weapon_to_give = "staff_air_upgraded_zm";

            if(weapon_to_give != "none")
            {
                // SECRET FIX: Give the revive weapon to prevent animation crash
                if ( !player HasWeapon("staff_revive_zm") )
                {
                    player GiveWeapon("staff_revive_zm");
                }
                
                // Safe native method for weapon swap
                player maps\mp\zombies\_zm_weapons::weapon_give(weapon_to_give);
                player SwitchToWeapon(weapon_to_give);
                
                player iprintln("^2Bastone potenziato equipaggiato all'istante!");
            }
            else
            {
                player iprintln("^1Errore: Tipo non valido. Usa: fire, ice, lightning, oppure wind.");
            }
        }

        // ------------------------------------------
        // OTHER COMMANDS
        // ------------------------------------------
        else if(command == ".mk2" || command == ".mark2")
        {
            if ( isDefined( level.zombie_weapons["raygun_mark2_zm"] ) || isDefined( level.zombie_weapons["raygun_mark2_upgraded_zm"] ) || level.script == "zm_tomb" )
            {
                player maps\mp\zombies\_zm_weapons::weapon_give("raygun_mark2_zm");
                player SwitchToWeapon("raygun_mark2_zm");
                player iprintln("^2Ray Gun Mark II equipaggiata!");
            } else { player iprintln("^1Errore: La Mark II non è disponibile in questa mappa."); }
        }
        else if(command == ".bring")
        {
            players = get_players();
            foreach(p in players)
            {
                if(p != player)
                {
                    p SetOrigin(player.origin);
                    p SetPlayerAngles(player.angles);
                }
            }
            player iprintln("^2Tutti i giocatori teletrasportati alla tua posizione!");
        }
        else if(command == ".reset" || command == ".restart")
        {
            player iprintln("^2Riavvio della mappa in corso...");
            map_restart(false);
        }
        else if(command == ".killall")
        {
            zombies = GetAiSpeciesArray( "axis", "all" );
            if(isDefined(zombies))
            {
                foreach(z in zombies) { z DoDamage(z.health + 666, z.origin, player); }
            }
            player iprintln("^2Tutti gli zombie eliminati!");
        }
        else if(command == ".opendoors")
        {
            zombie_doors = GetEntArray( "zombie_door", "targetname" );
            if(isDefined(zombie_doors)) {
                foreach(door in zombie_doors) { door notify("trigger", player, 1); }
            }
            zombie_debris = GetEntArray( "zombie_debris", "targetname" );
            if(isDefined(zombie_debris)) {
                foreach(debris in zombie_debris) { debris notify("trigger", player, 1); }
            }
            player iprintln("^2Tutte le porte e ostacoli sono stati aperti!");
        }
        else if(command == ".kick" || command == ".ban")
        {
            if(args.size > 1)
            {
                target_name = args[1];
                target = get_player_by_name(target_name);
                if(isDefined(target) && target != player)
                {
                    target iprintlnbold("^1SEI STATO ESPULSO DAL SERVER.");
                    target DisableWeapons();
                    target freezeControls(true);
                    target.sessionstate = "spectator";
                    target.ignoreme = true;
                    player iprintln("^2Giocatore " + target.name + " espulso e congelato.");
                }
                else { player iprintln("^1Errore: Giocatore non trovato."); }
            }
            else { player iprintln("^3Uso: ^7.kick <nome>"); }
        }
        else if(command == ".unkick" || command == ".unban")
        {
            if(args.size > 1)
            {
                target_name = args[1];
                target = get_player_by_name(target_name);
                if(isDefined(target) && target != player)
                {
                    target freezeControls(false);
                    target.sessionstate = "playing";
                    target.ignoreme = false;
                    target EnableWeapons();
                    target iprintlnbold("^2SEI STATO PARDONATO DALL'ADMIN.");
                    player iprintln("^2L'espulsione di " + target.name + " è stata revocata.");
                }
                else { player iprintln("^1Errore: Giocatore non trovato."); }
            }
            else { player iprintln("^3Uso: ^7.unban <nome>"); }
        }
        else if(command == ".map")
        {
            if(args.size > 1)
            {
                map_req = tolower(args[1]);
                map_id = "";
                
                if(map_req == "origins" || map_req == "tomb") { map_id = "zm_tomb"; setdvar("ui_zm_mapstartlocation", "tomb"); setdvar("ui_zm_gamemodegroup", "zclassic"); }
                else if(map_req == "mob" || map_req == "motd" || map_req == "prison") { map_id = "zm_prison"; setdvar("ui_zm_mapstartlocation", "prison"); setdvar("ui_zm_gamemodegroup", "zclassic"); }
                else if(map_req == "buried" || map_req == "resolution") { map_id = "zm_buried"; setdvar("ui_zm_mapstartlocation", "resolution"); setdvar("ui_zm_gamemodegroup", "zclassic"); }
                else if(map_req == "dierise" || map_req == "highrise") { map_id = "zm_highrise"; setdvar("ui_zm_mapstartlocation", "roof"); setdvar("ui_zm_gamemodegroup", "zclassic"); }
                else if(map_req == "nuketown" || map_req == "nuked") { map_id = "zm_nuked"; setdvar("ui_zm_mapstartlocation", "nuked"); setdvar("ui_zm_gamemodegroup", "zclassic"); }
                else if(map_req == "tranzit" || map_req == "transit") { map_id = "zm_transit"; setdvar("ui_zm_mapstartlocation", "transit"); setdvar("ui_zm_gamemodegroup", "zclassic"); }
                else if(map_req == "town") { map_id = "zm_transit"; setdvar("ui_zm_mapstartlocation", "town"); setdvar("ui_zm_gamemodegroup", "zsurvival"); }
                else if(map_req == "farm") { map_id = "zm_transit"; setdvar("ui_zm_mapstartlocation", "farm"); setdvar("ui_zm_gamemodegroup", "zsurvival"); }

                if (map_id != "")
                {
                    player iprintln("^2Caricamento mappa: " + map_req + "...");
                    setdvar("sv_maprotation", "map " + map_id);
                    ExitLevel(false);
                }
                else 
                {
                    player iprintln("^2Caricamento mappa custom: " + map_req + "...");
                    setdvar("sv_maprotation", "map " + map_req);
                    ExitLevel(false);
                }
            }
            else
            {
                player iprintln("^3Uso: ^7.map <origins/mob/buried/dierise/nuketown/tranzit/town/farm>");
            }
        }
        else if(command == ".round")
        {
            if(args.size > 1)
            {
                new_round = int(args[1]);
                if(new_round > 0)
                {
                    level.zombie_total = 0;
                    level.round_number = new_round - 1; 
                    zombies = GetAiSpeciesArray( "axis", "all" );
                    if(isDefined(zombies))
                    {
                        foreach(z in zombies) { z DoDamage(z.health + 666, z.origin, player); }
                    }
                    player iprintln("^2Salto forzato al round " + new_round + "!");
                }
            }
        }
        else if(command == ".shield" || command == ".escudo")
        {
            shield_name = "none";
            if ( level.script == "zm_tomb" ) shield_name = "tomb_shield_zm";           
            else if ( level.script == "zm_prison" ) shield_name = "alcatraz_shield_zm"; 
            else if ( level.script == "zm_transit" ) shield_name = "riotshield_zm";     

            if(shield_name != "none")
            {
                player GiveWeapon( shield_name );
                player SetActionSlot( 3, "weapon", shield_name ); 
                player iprintln("^2Scudo equipaggiato all'istante!");
            }
            else { player iprintln("^1Errore: Nessuno scudo disponibile in questa mappa."); }
        }
        else if(command == ".galil")
        {
            player maps\mp\zombies\_zm_weapons::weapon_give("galil_zm");
            player SwitchToWeapon("galil_zm");
            player iprintln("^2Galil equipaggiato!");
        }
        else if(command == ".an94")
        {
            player maps\mp\zombies\_zm_weapons::weapon_give("an94_zm");
            player SwitchToWeapon("an94_zm");
            player iprintln("^2AN-94 equipaggiato!");
        }
        else if(command == ".ms" || command == ".mustang")
        {
            player maps\mp\zombies\_zm_weapons::weapon_give("m1911_upgraded_zm");
            player SwitchToWeapon("m1911_upgraded_zm");
            player iprintln("^2Mustang & Sally pronte!");
        }
        else if(command == ".monkeys")
        {
            player maps\mp\zombies\_zm_weapons::weapon_give("cymbal_monkey_zm");
            player iprintln("^2Scimmiette Spaziali ricevute!");
        }
        else if(command == ".raygun")
        {
            player maps\mp\zombies\_zm_weapons::weapon_give("ray_gun_zm");
            player SwitchToWeapon("ray_gun_zm");
            player iprintln("^2Ray Gun equipaggiata!");
        }
        else if(command == ".pap")
        {
            current_weapon = player GetCurrentWeapon();
            if(current_weapon != "none" && current_weapon != "knife_zm")
            {
                upgraded_weapon = player maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon );
                if(isDefined(upgraded_weapon))
                {
                    player TakeWeapon(current_weapon);
                    player maps\mp\zombies\_zm_weapons::weapon_give(upgraded_weapon);
                    player iprintln("^2Arma potenziata all'istante!");
                } else { player iprintln("^1Questa arma non può essere potenziata."); }
            }
        }
        else if(command == ".drop")
        {
            drop_type = "full_ammo"; 
            if (args.size > 1)
            {
                if(args[1] == "ammo") drop_type = "full_ammo";
                else if(args[1] == "nuke") drop_type = "nuke";
                else if(args[1] == "insta") drop_type = "insta_kill";
                else if(args[1] == "fire") drop_type = "fire_sale";
                else if(args[1] == "blood") drop_type = "zombie_blood";
            }
            if ( isDefined( level.zombie_powerups ) && isDefined( level.zombie_powerups[drop_type] ) )
            {
                maps\mp\zombies\_zm_powerups::specific_powerup_drop( drop_type, player.origin );
                player iprintln("^2Drop generato: " + drop_type);
            } else { player iprintln("^1Drop non supportato in questa mappa."); }
        }
        else if(command == ".parts" || command == ".esp")
        {
            toggle_parts_esp(player);
        }
        else if(command == ".fog")
        {
            if(!isDefined(player.fog_disabled) || player.fog_disabled == false)
            {
                player.fog_disabled = true;
                player setClientDvar("r_fog", "0");
                player iprintln("^2Nebbia DISATTIVATA!");
            } else {
                player.fog_disabled = false;
                player setClientDvar("r_fog", "1");
                player iprintln("^1Nebbia ATTIVATA.");
            }
        }
        else if(command == ".run")
        {
            if(!isDefined(player.infiniterun_enabled) || player.infiniterun_enabled == false)
            {
                player.infiniterun_enabled = true;
                player setPerk("specialty_unlimitedsprint");
                player iprintln("^2Corsa Infinita ATTIVATA!");
            } else {
                player.infiniterun_enabled = false;
                player unsetPerk("specialty_unlimitedsprint");
                player iprintln("^1Corsa Infinita DISATTIVATA.");
            }
        }
        else if(command == ".mud" || command == ".nomud" || command == ".trenches")
        {
            if ( level.script != "zm_tomb" )
            {
                player iprintln("^1Errore: Questo comando funziona solo su Origins.");
                continue;
            }

            if(!isDefined(player.origins_no_mud) || player.origins_no_mud == false)
            {
                player.origins_no_mud = true;
                player thread maintain_origins_no_mud();
                player iprintln("^2No-Mud ATTIVATO! Le trincee di Origins non ti rallentano.");
            }
            else
            {
                player.origins_no_mud = false;
                player notify("stop_origins_no_mud");

                if(!isDefined(player.speed_buff_active) || player.speed_buff_active == false)
                {
                    player.custom_speed = 1.0;
                    player setMoveSpeedScale(1.0);
                }

                player iprintln("^1No-Mud DISATTIVATO.");
            }
        }
        else if(command == ".fly" || command == ".noclip")
        {
            if(!isDefined(player.is_flying) || player.is_flying == false)
            {
                player.is_flying = true;
                player thread do_noclip_logic();
                player iprintln("^2Volo (Noclip) ATTIVATO! Usa MIRARE e SPARARE per muoverti.");
            } else {
                player.is_flying = false;
                player notify("stop_noclip_logic");
                player iprintln("^1Volo DISATTIVATO.");
            }
        }
        else if(command == ".tp")
        {
            if(args.size > 1)
            {
                target_name = args[1];
                target = get_player_by_name(target_name);
                if(isDefined(target) && target != player)
                {
                    player SetOrigin(target.origin);
                    player iprintln("^2Sei stato teletrasportato da " + target.name);
                }
                else { player iprintln("^1Errore: Giocatore non trovato."); }
            }
            else { player iprintln("^3Uso: ^7.tp <nome>"); }
        }
        else if(command == ".third")
        {
            if(!isDefined(player.thirdperson) || player.thirdperson == false)
            {
                player.thirdperson = true;
                player setClientThirdPerson(1);
                player iprintln("^2Terza Persona ATTIVATA!");
            } else {
                player.thirdperson = false;
                player setClientThirdPerson(0);
                player iprintln("^1Terza Persona DISATTIVATA.");
            }
        }
        else if(command == ".save")
        {
            player.saved_origin = player.origin;
            player.saved_angles = player.angles;
            player iprintln("^2Posizione salvata con successo!");
        }
        else if(command == ".load")
        {
            if (isDefined(player.saved_origin))
            {
                player SetOrigin(player.saved_origin);
                player SetPlayerAngles(player.saved_angles);
                player iprintln("^2Teletrasportato alla posizione salvata!");
            } else {
                player iprintln("^1Errore: Nessuna posizione salvata. Usa .save prima.");
            }
        }
        else if(command == ".ignore" || command == ".afk")
        {
            if(!isDefined(player.ignoreme) || player.ignoreme == false) {
                player.ignoreme = true;
                player iprintln("^2Invisibilità ATTIVATA.");
            } else {
                player.ignoreme = false;
                player iprintln("^1Invisibilità DISATTIVATA.");
            }
        }
        else if(command == ".speed")
        {
            if(args.size > 1)
            {
                target_speed = float(args[1]);
                if(target_speed >= 0.1 && target_speed <= 10.0)
                {
                    player notify("stop_speed_buff"); 
                    player.speed_buff_active = true;
                    player.custom_speed = target_speed;
                    player thread maintain_speed();
                    player iprintln("^2Velocità impostata a " + target_speed + "x!");
                }
                else { player iprintln("^1Errore: Inserisci un valore da 0.1 a 10.0"); }
            }
            else
            {
                if(!isDefined(player.speed_buff_active) || player.speed_buff_active == false)
                {
                    player.speed_buff_active = true;
                    player.custom_speed = 1.5;
                    player thread maintain_speed(); 
                    player iprintln("^2Velocità Extra ATTIVATA (1.5x)!");
                } else {
                    player notify("stop_speed_buff"); 
                    player.speed_buff_active = false;
                    player.custom_speed = 1.0;
                    player setMoveSpeedScale(1.0);
                    player iprintln("^1Velocità Extra DISATTIVATA.");
                }
            }
        }
        else if(command == ".god")
        {
            if(!isDefined(player.godmode_active) || player.godmode_active == false) 
            {
                player.godmode_active = true;
                player EnableInvulnerability(); 
                player thread brute_force_godmode(); 
                player iprintln("^2Godmode ATTIVATA!");
            } else {
                player notify("stop_godmode"); 
                player.godmode_active = false;
                player DisableInvulnerability();
                player iprintln("^1Godmode DISATTIVATA.");
            }
        }
        else if(command == ".points")
        {
            points_to_give = 50000; 
            if (args.size > 1) { points_to_give = int(args[1]); }
            player maps\mp\zombies\_zm_score::add_to_player_score( points_to_give );
            player iprintln("^2Hai ricevuto " + points_to_give + " punti!");
        }
        else if(command == ".ammo")
        {
            weapons = player GetWeaponsList( true );
            foreach ( weapon in weapons )
            {
                player GiveMaxAmmo( weapon );
                player SetWeaponAmmoClip( weapon, WeaponClipSize( weapon ) );
            }
            player iprintln("^2Munizioni massime ricevute!");
        }
        else if(command == ".perks")
        {
            player maps\mp\zombies\_zm_perks::give_perk( "specialty_armorvest", false );   
            player maps\mp\zombies\_zm_perks::give_perk( "specialty_longersprint", false ); 
            player maps\mp\zombies\_zm_perks::give_perk( "specialty_fastreload", false );   
            player maps\mp\zombies\_zm_perks::give_perk( "specialty_quickrevive", false );  
            player iprintln("^24 Perk Base ricevuti!");
        }
        else if(command == ".allperks")
        {
            lista_perks = [];
            lista_perks[0] = "specialty_armorvest";               
            lista_perks[1] = "specialty_quickrevive";             
            lista_perks[2] = "specialty_fastreload";              
            lista_perks[3] = "specialty_rof";                     
            lista_perks[4] = "specialty_longersprint";            
            lista_perks[5] = "specialty_flakjacket";              
            lista_perks[6] = "specialty_deadshot";                
            lista_perks[7] = "specialty_additionalprimaryweapon"; 
            lista_perks[8] = "specialty_grenadepulldeath";        
            
            for ( i = 0; i < lista_perks.size; i++ )
            {
                if ( !player hasPerk( lista_perks[i] ) )
                {
                    player maps\mp\zombies\_zm_perks::give_perk( lista_perks[i], false );
                    wait 0.1; 
                }
            }
            player iprintln("^2Arsenale completo di Perk ricevuto!");
        }
    }
}

// ==========================================
// QoL FEATURES & UTILITIES
// ==========================================

// Get player by name (For !pay command)
get_player_by_name(name)
{
    players = get_players();
    foreach(p in players)
    {
        if(issubstr(tolower(p.name), tolower(name))) return p;
    }
    return undefined;
}

// Auto-Reload on Max Ammo pickup
auto_reload_monitor()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill( "zmb_max_ammo" ); 
        weapons = self GetWeaponsList(true);
        foreach(weapon in weapons)
        {
            self SetWeaponAmmoClip(weapon, WeaponClipSize(weapon));
        }
    }
}

// Global Hitmarker Manager
global_hitmarker_manager()
{
    level endon("end_game");
    for(;;)
    {
        zombies = GetAiSpeciesArray("axis", "all");
        foreach(z in zombies)
        {
            if(!isDefined(z.has_hitmarker_monitor))
            {
                z.has_hitmarker_monitor = true;
                z thread monitor_zombie_damage();
            }
        }
        wait 1; 
    }
}

// Monitor damage for each zombie
monitor_zombie_damage()
{
    self endon("death");
    for(;;)
    {
        self waittill("damage", amount, attacker, dir, point, type);
        if(isDefined(attacker) && isPlayer(attacker))
        {
            attacker thread show_hitmarker();
        }
    }
}

// Display hitmarker and play sound
show_hitmarker()
{
    if(!isDefined(self.hitmarker_hud))
    {
        self.hitmarker_hud = newClientHudElem(self);
        self.hitmarker_hud.alignX = "center";
        self.hitmarker_hud.alignY = "middle";
        self.hitmarker_hud.horzAlign = "center";
        self.hitmarker_hud.vertAlign = "middle";
        self.hitmarker_hud.alpha = 0;
        self.hitmarker_hud setShader("damage_feedback", 24, 48);
    }
    
    self.hitmarker_hud.alpha = 1;
    self playlocalsound("mpl_hit_alert"); 
    self.hitmarker_hud fadeOverTime(0.5);
    self.hitmarker_hud.alpha = 0;
}

broadcast_all(msg)
{
    players = get_players();
    foreach(p in players) { p iprintln(msg); }
}

down_timer_monitor()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("downed");
        self notify("stop_down_timer");
        self thread down_revive_timer();
        self thread on_revived_broadcast();
    }
}

on_revived_broadcast()
{
    self endon("disconnect");
    self endon("stop_down_timer");
    self waittill_any("player_revived", "revived");
    self notify("stop_down_timer");
    broadcast_all("^2[Revive] ^7" + self.name + " ^2è stato rianimato!");
}

down_revive_timer()
{
    self endon("disconnect");
    self endon("stop_down_timer");

    player_name = self.name;
    remaining = 60;

    broadcast_all("^1[Down] ^7" + player_name + " ^1è a terra! 60 sec per rianimarlo.");
    while(remaining > 0)
    {
        wait 15;
        remaining -= 15;
        if(remaining > 0)
            broadcast_all("^3[Down] ^7Mancano ^3" + remaining + " ^7sec per rianimare ^3" + player_name + "^7.");
        else
            broadcast_all("^1[Down] ^7Tempo scaduto! ^3" + player_name + " ^1non è stato rianimato!");
    }
}

// ==========================================
// BACKGROUND FUNCTIONS
// ==========================================
brute_force_godmode()
{
    self endon("disconnect");
    self endon("stop_godmode");
    level endon("end_game");

    for(;;)
    {
        self.health = self.maxhealth;
        wait 0.05; 
    }
}

remove_quick_revive_limit()
{
    level endon("end_game");
    for(;;)
    {
        if ( isDefined( level.solo_lives_given ) ) { level.solo_lives_given = 0; }
        level.perk_purchase_limit = 999;
        wait 1; 
    }
}

maintain_speed()
{
    self endon("disconnect");
    self endon("stop_speed_buff"); 
    level endon("end_game");

    for(;;)
    {
        if(isDefined(self.custom_speed))
        {
            if(self getMoveSpeedScale() != self.custom_speed) { self setMoveSpeedScale(self.custom_speed); }
        }
        else
        {
            if(self getMoveSpeedScale() != 1.5) { self setMoveSpeedScale(1.5); }
        }
        wait 0.1; 
    }
}

maintain_origins_no_mud()
{
    self endon("disconnect");
    self endon("death");
    self endon("stop_origins_no_mud");
    level endon("end_game");

    for(;;)
    {
        if(level.script != "zm_tomb")
            return;

        if(!isDefined(self.origins_no_mud) || self.origins_no_mud == false)
            return;

        if(!isDefined(self.speed_buff_active) || self.speed_buff_active == false)
        {
            if(self getMoveSpeedScale() < 1.0)
            {
                self setMoveSpeedScale(1.0);
            }
        }

        wait 0.05;
    }
}

do_noclip_logic()
{
    self endon("disconnect");
    self endon("stop_noclip_logic");
    
    fly_speed = 60;

    // Max altitude above the point where fly was enabled. Most zombies maps
    // (Origins in particular) have a height killbrush that bypasses
    // EnableInvulnerability, so we clamp the linker Z to stay below it.
    max_fly_height = 2500;

    self EnableInvulnerability();
    self.ignoreme = true;

    fly_start_z = self.origin[2];
    fly_ceiling = fly_start_z + max_fly_height;

    linker = spawn("script_origin", self.origin);
    self PlayerLinkTo(linker, undefined, 0, 180, 180, 180, 180);
    self DisableWeapons();

    self thread cleanup_noclip(linker);

    for(;;)
    {
        forward = anglesToForward(self getPlayerAngles());
        
        vec_x = forward[0] * fly_speed;
        vec_y = forward[1] * fly_speed;
        vec_z = forward[2] * fly_speed;
        scaled = (vec_x, vec_y, vec_z);

        if (self AttackButtonPressed())
        {
            linker.origin = linker.origin + scaled;
        }
        else if (self AdsButtonPressed())
        {
            linker.origin = linker.origin - scaled;
        }

        // Clamp altitude to keep the player below the map height killbrush.
        if (linker.origin[2] > fly_ceiling)
        {
            linker.origin = (linker.origin[0], linker.origin[1], fly_ceiling);
        }

        // Melee = safe exit: teleport the player to the current fly position
        // and terminate the noclip loop. cleanup_noclip will handle unlink +
        // invulnerability grace period.
        if (self MeleeButtonPressed())
        {
            self.fly_exit_origin = linker.origin;
            self.is_flying = false;
            self notify("stop_noclip_logic");
            return;
        }

        self.health = self.maxhealth;
        wait 0.05;
    }
}

cleanup_noclip(linker)
{
    self waittill_any("disconnect", "death", "stop_noclip_logic");
    
    // Capture the last fly position BEFORE deleting the linker, so we can
    // re-snap the player there after unlinking. This prevents the engine from
    // dropping them at a stale origin (which is what causes fall / crush deaths).
    exit_origin = undefined;
    if (isDefined(self) && isDefined(self.fly_exit_origin))
    {
        exit_origin = self.fly_exit_origin;
        self.fly_exit_origin = undefined;
    }
    else if (isDefined(linker))
    {
        exit_origin = linker.origin;
    }

    if (isDefined(self))
    {
        self EnableWeapons();
        self unlink();

        if (isDefined(exit_origin))
        {
            self SetOrigin(exit_origin);
        }
    }

    if (isDefined(linker)) { linker delete(); }

    // Keep the player invulnerable for a short grace period after unlinking so
    // that fall damage / being stuck in geometry cannot kill them while the
    // physics settles them back on the ground.
    if (isDefined(self))
    {
        self endon("disconnect");
        grace = 0.0;
        while (grace < 1.5)
        {
            self.health = self.maxhealth;
            wait 0.05;
            grace += 0.05;
        }

        if (!isDefined(self.godmode_active) || self.godmode_active == false)
        {
            self DisableInvulnerability();
        }

        self.ignoreme = false;
    }
}

// ==========================================
// UNIFIED MODERN HUD
// ==========================================

modern_counters_hud()
{
    self endon("disconnect");
    flag_wait("initial_blackscreen_passed");

    self.panel_bg = newClientHudElem(self);
    self.panel_bg.alignX = "left";
    self.panel_bg.alignY = "top";
    self.panel_bg.horzAlign = "user_left";
    self.panel_bg.vertAlign = "user_top";
    self.panel_bg.x = 5;
    self.panel_bg.y = 5;
    self.panel_bg setShader("white", 100, 52); 
    self.panel_bg.color = (0, 0, 0);
    self.panel_bg.alpha = 0.6;
    self.panel_bg.sort = 1;

    self.panel_line = newClientHudElem(self);
    self.panel_line.alignX = "left";
    self.panel_line.alignY = "top";
    self.panel_line.horzAlign = "user_left";
    self.panel_line.vertAlign = "user_top";
    self.panel_line.x = 5;
    self.panel_line.y = 5;
    self.panel_line setShader("white", 3, 52); 
    self.panel_line.color = (0, 0.6, 1);
    self.panel_line.alpha = 1;
    self.panel_line.sort = 2;

    self.zombie_text = newClientHudElem(self);
    self.zombie_text.alignX = "left";
    self.zombie_text.alignY = "top";
    self.zombie_text.horzAlign = "user_left";
    self.zombie_text.vertAlign = "user_top";
    self.zombie_text.x = 12;
    self.zombie_text.y = 8;
    self.zombie_text.fontscale = 1.2;
    self.zombie_text.color = (1, 1, 1);
    self.zombie_text.label = &"Zombie: ^5"; 
    self.zombie_text.sort = 3;

    self.round_time_text = newClientHudElem(self);
    self.round_time_text.alignX = "left";
    self.round_time_text.alignY = "top";
    self.round_time_text.horzAlign = "user_left";
    self.round_time_text.vertAlign = "user_top";
    self.round_time_text.x = 12;
    self.round_time_text.y = 23;
    self.round_time_text.fontscale = 1.2;
    self.round_time_text.color = (1, 1, 1);
    self.round_time_text.label = &"Round: ^5";
    self.round_time_text.sort = 3;

    self.game_time_text = newClientHudElem(self);
    self.game_time_text.alignX = "left";
    self.game_time_text.alignY = "top";
    self.game_time_text.horzAlign = "user_left";
    self.game_time_text.vertAlign = "user_top";
    self.game_time_text.x = 12;
    self.game_time_text.y = 38;
    self.game_time_text.fontscale = 1.2;
    self.game_time_text.color = (1, 1, 1);
    self.game_time_text.label = &"Partita: ^5";
    self.game_time_text.sort = 3;

    self.game_time_text setTimerUp(0);
    self thread update_zombie_counter_modern();
    self thread update_round_timer_modern();
}

update_zombie_counter_modern()
{
    self endon("disconnect");
    for (;;)
    {
        self.zombie_text setvalue(level.zombie_total + get_current_zombie_count());
        wait 0.05;
    }
}

update_round_timer_modern()
{
    self endon("disconnect");
    for (;;)
    {
        self.round_time_text setTimerUp(0);
        start_time = GetTime() / 1000;
        level waittill("end_of_round");

        end_time = GetTime() / 1000;
        time_elapsed = end_time - start_time;

        self.round_time_text setTimer(time_elapsed);
    }
}

ezz_bars_hud()
{
    self endon("disconnect");
    flag_wait("initial_blackscreen_passed");

    bar_width = 130;
    hp_height = 8;
    shield_height = 3;  
    bg_padding = 4;
    y_bottom_anchor = -40; 

    self.hp_text = newClientHudElem(self);
    self.hp_text.alignX = "center";
    self.hp_text.alignY = "bottom";
    self.hp_text.horzAlign = "center";
    self.hp_text.vertAlign = "bottom";
    self.hp_text.x = 0;
    self.hp_text.y = y_bottom_anchor - hp_height - shield_height - bg_padding - 2; 
    self.hp_text.fontscale = 0.8;
    self.hp_text.sort = 2;
    self.hp_text.last_text = "";

    self.hp_bg = newClientHudElem(self);
    self.hp_bg.alignX = "center";
    self.hp_bg.alignY = "bottom";
    self.hp_bg.horzAlign = "center";
    self.hp_bg.vertAlign = "bottom";
    self.hp_bg.x = 0;
    self.hp_bg.y = y_bottom_anchor;
    self.hp_bg setShader("white", bar_width + bg_padding, hp_height + shield_height + bg_padding);
    self.hp_bg.color = (0, 0, 0);
    self.hp_bg.alpha = 0.6;
    self.hp_bg.sort = 1;

    self.hp_bar = newClientHudElem(self);
    self.hp_bar.alignX = "left";
    self.hp_bar.alignY = "bottom";
    self.hp_bar.horzAlign = "center";
    self.hp_bar.vertAlign = "bottom";
    self.hp_bar.x = -(bar_width/2);
    self.hp_bar.y = y_bottom_anchor - (bg_padding/2); 
    self.hp_bar setShader("white", bar_width, hp_height);
    self.hp_bar.sort = 3;

    self.shield_bar = newClientHudElem(self);
    self.shield_bar.alignX = "left";
    self.shield_bar.alignY = "bottom";
    self.shield_bar.horzAlign = "center";
    self.shield_bar.vertAlign = "bottom";
    self.shield_bar.x = -(bar_width/2);
    self.shield_bar.y = y_bottom_anchor - (bg_padding/2) - hp_height; 
    self.shield_bar setShader("white", bar_width, shield_height);
    self.shield_bar.color = (0, 0.6, 1); 
    self.shield_bar.sort = 4;

    for(;;)
    {
        current_health = self.health;
        max_health = self.maxhealth;
        
        if(max_health <= 0) max_health = 100;
        health_percent = current_health / max_health;
        
        hp_visual_width = int(bar_width * health_percent);
        if(hp_visual_width < 1) hp_visual_width = 1; 

        if (health_percent >= 1.0) {
            self.hp_bar.color = (0, 1, 0); 
            self.hp_bar.alpha = 1;
        } else if (health_percent > 0.4) {
            self.hp_bar.color = (1, 1, 0); 
            self.hp_bar.alpha = 1;
        } else {
            self.hp_bar.color = (1, 0, 0); 
            self.hp_bar.alpha = (int(GetTime() / 250) % 2) ? 0.3 : 1; 
        }

        self.hp_bar setShader("white", hp_visual_width, hp_height);

        if ( self HasWeapon("riotshield_zm") || self HasWeapon("alcatraz_shield_zm") || self HasWeapon("tomb_shield_zm") )
        {
            self.shield_bar.alpha = 1;
        }
        else
        {
            self.shield_bar.alpha = 0;
        }

        update_hp_label();

        wait 0.05; 
    }
}

parts_esp_monitor()
{
    self endon("disconnect");
    self endon("stop_parts_esp");
    level endon("end_game");

    keywords = [];
    keywords[0] = "part";
    keywords[1] = "buildable";
    keywords[2] = "piece";
    keywords[3] = "craftable";
    keywords[4] = "staff";
    keywords[5] = "record";
    keywords[6] = "crystal";
    keywords[7] = "plane";
    keywords[8] = "key";
    keywords[9] = "turbine";
    keywords[10] = "shield";
    keywords[11] = "engine";
    keywords[12] = "rotor";
    keywords[13] = "battery";
    keywords[14] = "tank";
    keywords[15] = "wire";

    for(;;)
    {
        models = GetEntArray("script_model", "classname");
        closest_origin = undefined;
        closest_name = "";

        foreach(m in models)
        {
            if(isDefined(m.model))
            {
                name = tolower(m.model);
                found = false;
                for(i = 0; i < keywords.size; i++)
                {
                    if(issubstr(name, keywords[i]))
                    {
                        found = true;
                        break;
                    }
                }
                
                if(found)
                {
                    dist = int(distance(self.origin, m.origin));
                    if(!isDefined(closest_origin) || dist < int(distance(self.origin, closest_origin)))
                    {
                        closest_origin = m.origin;
                        closest_name = classify_part_name(name);
                    }

                    Print3d(m.origin + (0, 0, 15), "[ PEZZO ]", (0, 1, 0), 1, 1.5, 2);
                }
            }
        }

        update_parts_focus_state(closest_origin, closest_name);
        wait 0.1; 
    }
}

update_hp_label()
{
    text = "^5HP / SCUDO";

    if(isDefined(self.parts_focus_text) && self.parts_focus_text != "")
    {
        text += "\n" + self.parts_focus_text;
    }

    if(!isDefined(self.hp_text))
        return;

    if(!isDefined(self.hp_text.last_text) || self.hp_text.last_text != text)
    {
        self.hp_text.last_text = text;
        self.hp_text setText(text);
    }
}

update_parts_focus_state(target_origin, part_name)
{
    if(!isDefined(target_origin))
    {
        self.parts_focus_text = "";
        return;
    }

    self.parts_focus_text = "^2PART:^7 " + part_name;
}

parts_toggle_key_monitor()
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("toggle_parts_key");

        if(!isAlive(self))
            continue;

        toggle_parts_esp(self);
        wait 0.2;
    }
}

classify_part_name(name)
{
    if(!isDefined(name) || name == "")
        return "piece";

    if(issubstr(name, "shield"))
        return "shield";
    if(issubstr(name, "staff"))
        return "staff";
    if(issubstr(name, "record"))
        return "record";
    if(issubstr(name, "crystal"))
        return "crystal";
    if(issubstr(name, "engine"))
        return "engine";
    if(issubstr(name, "rotor"))
        return "rotor";
    if(issubstr(name, "battery"))
        return "battery";
    if(issubstr(name, "wire"))
        return "wire";
    if(issubstr(name, "key"))
        return "key";
    if(issubstr(name, "plane"))
        return "plane";
    if(issubstr(name, "turbine"))
        return "turbine";

    return "part";
}

toggle_parts_esp(player)
{
    if(!isDefined(player.parts_esp) || player.parts_esp == false)
    {
        player.parts_esp = true;
        player thread parts_esp_monitor();
        player iprintln("^2Ricerca Pezzi ATTIVATA! ^7(bind 4 / tactical)");
    }
    else
    {
        player.parts_esp = false;
        player notify("stop_parts_esp");
        player.parts_focus_text = "";
        player update_hp_label();
        player iprintln("^1Ricerca Pezzi DISATTIVATA.");
    }
}

toggle_help_hud()
{
    self endon("disconnect");
    
    if(!isDefined(self.help_hud_active)) self.help_hud_active = false;
    
    self.help_hud_active = !self.help_hud_active;
    
    if(self.help_hud_active)
    {
        self create_help_ui();
        self iprintln("^3[Help] ^7Guida comandi aperta.");
    }
    else
    {
        self destroy_help_ui();
        self iprintln("^3[Help] ^7Guida comandi chiusa.");
    }
}

create_help_ui()
{
    self endon("disconnect");
    flag_wait("initial_blackscreen_passed");
    
    self destroy_help_ui(); // Sicurezza
    
    self.help_ui = SpawnStruct();
    
    // Sfondo (Top Right)
    self.help_ui.bg = newClientHudElem(self);
    self.help_ui.bg.alignX = "right";
    self.help_ui.bg.alignY = "top";
    self.help_ui.bg.horzAlign = "user_right";
    self.help_ui.bg.vertAlign = "user_top";
    self.help_ui.bg.x = -10;
    self.help_ui.bg.y = 10;
    self.help_ui.bg setShader("white", 210, 100);
    self.help_ui.bg.color = (0, 0, 0);
    self.help_ui.bg.alpha = 0.6;
    self.help_ui.bg.sort = 10;

    self.help_ui.accent = newClientHudElem(self);
    self.help_ui.accent.alignX = "right";
    self.help_ui.accent.alignY = "top";
    self.help_ui.accent.horzAlign = "user_right";
    self.help_ui.accent.vertAlign = "user_top";
    self.help_ui.accent.x = -10;
    self.help_ui.accent.y = 10;
    self.help_ui.accent setShader("white", 2, 100);
    self.help_ui.accent.color = (0, 0.6, 1);
    self.help_ui.accent.alpha = 1;
    self.help_ui.accent.sort = 11;

    self.help_ui.line1 = self create_help_line(16, &"^3Player: ^7.pay .save .load .third .fog .run .mud .join");
    self.help_ui.line2 = self create_help_line(30, &"^3Admin: ^7.god .fly .ignore .ammo .perks .speed .kick .unban");
    self.help_ui.line3 = self create_help_line(44, &"^3Server: ^7.map .round .killall .bring .drop .snow");
    self.help_ui.line4 = self create_help_line(58, &"^3Armi: ^7.pap .shield .mk2 .galil .ms .monkeys .staff");
    self.help_ui.line5 = self create_help_line(72, &"^3EE: ^7.ee .ee detail .ee hints .ee toggle");
    self.help_ui.line6 = self create_help_line(86, &"^8(Scrivi .help per chiudere)");
}

create_help_line(y_offset, label_ref)
{
    line = newClientHudElem(self);
    line.alignX = "right";
    line.alignY = "top";
    line.horzAlign = "user_right";
    line.vertAlign = "user_top";
    line.x = -15;
    line.y = y_offset;
    line.fontscale = 1.0;
    line.color = (1, 1, 1);
    line.alpha = 1;
    line.sort = 12;
    line.label = label_ref;
    return line;
}

destroy_help_ui()
{
    if(isDefined(self.help_ui))
    {
        if(isDefined(self.help_ui.bg)) self.help_ui.bg destroy();
        if(isDefined(self.help_ui.accent)) self.help_ui.accent destroy();
        if(isDefined(self.help_ui.line1)) self.help_ui.line1 destroy();
        if(isDefined(self.help_ui.line2)) self.help_ui.line2 destroy();
        if(isDefined(self.help_ui.line3)) self.help_ui.line3 destroy();
        if(isDefined(self.help_ui.line4)) self.help_ui.line4 destroy();
        if(isDefined(self.help_ui.line5)) self.help_ui.line5 destroy();
        self.help_ui = undefined;
    }
}
