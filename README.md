# Gabbibo ZM Server - BO2 Plutonium GSC Script

Benvenuto nello script server GSC per Call of Duty: Black Ops II Zombies (Plutonium T6). Questo script implementa una vasta gamma di comandi in chat, funzionalità di Quality of Life (QoL), controlli amministrativi e un HUD personalizzato per migliorare l'esperienza di gioco.

## 🌟 Caratteristiche Principali

- **Comandi Chat Integrati:** Un sistema completo di comandi divisi per categorie (Pubblici, Admin, Server, Armi).
- **Gestione Permessi:** Opzione per limitare comandi di amministrazione soltanto all'host (`level.host_only_commands`).
- **HUD Personalizzato:** Contatori moderni e barre informative per monitorare le statistiche in tempo reale (Zombie Rimanenti, Timer a Terra, ecc.).
- **Miglioramenti QoL Automatizzati:**
  - Hitmarker globali per tutti i giocatori.
  - Ricarica automatica dell'intero arsenale al raccoglimento di un Max Ammo.
  - Limite di rianimazioni sul Quick Revive in solo rimosso (Vite illimitate).
  - Annunci in chat quando un giocatore va a terra, con invio di un timer visibile per la rianimazione.
- **Fix e Aiuti Esclusivi per Origins:**
  - Drop istantaneo dei Bastoni potenziati con weapon-swap fix per evitare crash delle animazioni.
  - Comando `.snow` per forzare la tempesta di neve per le buche del bastone di ghiaccio.

## 📥 Installazione

Il file `_bo2_server.gsc` deve risiedere all'interno della directory corretta degli script in locale sul server o nel client del giocatore che hosta:
`%localappdata%\Plutonium\storage\t6\raw\scripts\zm`

## 📜 Lista dei Comandi Chat

I comandi possono essere digitati liberamente nella macro di chat in game.

### 👥 Comandi Giocatore (Pubblici)

- `.help` / `.cmds`: Mostra la sintesi dei comandi direttamente a schermo.
- `.pay <nome> <punti>`: Invia un ammontare di punti a un compagno in base al nome.
- `.deposit <valore>` / `.withdraw <valore>`: Usa la banca personale persistente per depositare o prelevare punti (accetta anche "all").
- `.dropweapon`: Riponi a terra sotto forma di entità fluttuante l'arma in tuo possesso per i tuoi compagni.
- `.save`: Salva le proprie coordinate correnti.
- `.load`: Si teletrasporta sulle coordinate precedentemente salvate.
- `.parts` / `.esp`: Mostra un testo verde fluttuante in 3D sopra tutti i pezzi raccoglibili della mappa.
- `.tp <nome>`: Teletrasporta il personaggio dal compagno.
- `.third`: Abilita / disabilita la visuale in Terza Persona.
- `.fog`: Rimuove o reintegra la nebbia nella mappa.
- `.run`: Ricevi la Corsa Infinita disabilitando la fatica.
- `.join`: Permette di rientrare dalla modalità spettatore.

### 🛡️ Comandi Admin

_I comandi Admin sono ristretti all'host del server se la variabile Host-Only è impostata su "true"_

- `.god`: Modalità Invincibilità.
- `.fly` / `.noclip`: Vola e attraversa le pareti direzionandoti liberamente. (Spara = Avanti, Mira = Indietro).
- `.ignore` / `.afk`: Diventa invisibile ai nemici.
- `.ammo`: Ripristina istantaneamente tutte le munizioni del tuo intero arsenale.
- `.perks`: Ricevi un classico pacchetto essenziale dei 4 Perk base.
- `.allperks`: Forza e assimila l'intero set globale di tutti i Perk del gioco, senza limite.
- `.points <valore>`: Assegnazione gratuita di punti desiderati (il default senza valore dona 50000).
- `.speed <valore>`: Genera o incrementa la velocità di movimento moltiplicatore (Es. .speed 2.5). Usare .speed pulito accende un boost fisso x1.5!
- `.kick <nome>` / `.ban`: Manda in Spectator forzato e blocca un utente troll.
- `.unkick <nome>` / `.unban`: Ripristina un membro bannato prima, restituendogli comandi e armi in game.
- `.opendoors`: Sblocca forzatamente tutte le porte e ostacoli presenti nella mappa in modo automatico.

### ⚙️ Comandi Server e Mappe

- `.map <nome_mappa>`: Forza tramite rotazione un caricamento verso un'altra mappa o survival mode. (Es: `origins`, `mob`, `town`, `tranzit`, `dierise`, `nuketown`, ecc).
- `.reset`: Riavvia istantaneamente la mappa e la sessione in corso.
- `.round <numero>`: Trancia il round attuale ed effettua uno skip brutale ed immediato al nuovo round indicato.
- `.killall`: Trucida in blocco tutti gli zombie presenti sulla mappa (passando automaticamente round).
- `.bring`: Risucchia l'intera lobby sulle tue coordinate originarie.
- `.drop <tipo>`: Forza lo spawn sul tuo mirino di poweup custom (`ammo`, `nuke`, `insta`, `fire`, `blood`).
- `.snow`: Origin-Only, innesca a comando la nevicata necessaria per gli scavi.

### 🔫 Comandi Arsenale Veloce

- `.pap`: Esegue il Pack-a-Punch diretto all'arma corrente in mano (se possibile).
- `.shield` / `.escudo`: Imbraccia ed equipaggia fin da subito lo Scudo Zombie rispettivo per la mappa in corso.
- `.mk2` / `.mark2`: Ottieni Ray Gun Mark II (ove disponibile nel pool).
- `.raygun`: Ottieni la Ray Gun base.
- `.galil`: Ricevi istantaneamente il Galil Assault Rifle.
- `.an94`: Ricevi l'AN-94.
- `.ms` / `.mustang`: Riceve sul momento le Mustang & Sally già potenziate allo scoppio.
- `.monkeys`: Confeziona subitamente il drop tattico delle Scimmiette Esplosive.
- `.staff <tipo>`: Origin-Only, rimpiazza ed ottiene i bastoni in forma potenziata suprema (`fire`, `ice`, `lightning`, `wind`).

## 🛠️ Configurazione Script Interne

Puoi modificare questi valori all'interno del blocco superiore `init()` in `_bo2_server.gsc`:

```gsc
level.perk_purchase_limit = 999; // Limite perk disattivato forzatamente a 999
level.host_only_commands = false; // "true" restringe tutti i comandi forti di manipolazione esclusivamente agli host
```
