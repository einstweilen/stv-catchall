    _______ _______ _    _ _______   _______ _    _
    |______ |_____|  \  /  |______      |     \  /
    ______| |     |   \/   |______ .    |      \/  
    ===============================================
    ____ C_a_t_c_h_A_l_l___e_i_n_r_i_c_h_t_e_n ____

Nachbildung der [2016 aus juristischen Gründen eingestellten CatchAll Funktion](https://tv-forum.info/viewtopic.php?f=33&t=619) bei der alle Sendungen aller bei Save.TV [verfügbaren Sender](https://hilfe.save.tv/Knowledgebase/50080/Senderliste) 24/7 aufgenommen werden. Dadurch erhält das Save.TV XL Paket die gleiche Funktionalität wie das XXL Paket. Beim XXL Paket spart man sich das manuelle Channelanlegen.

Das Skript ist unverändert auf Raspbian/DietPi, MacOS sowie mit Termux unter Android lauffähig.

## Schnelleinstieg
Das Skript läuft defaultmäßig im Automatikmodus und nimmt alle verfügbaren Sender auf. Es fragt Username und Passwort ab, bietet eine Speicherung an, erkennt das gebuchte Save.TV Paket und wählt die dafür passenden Einstellungen. Beim ersten Start wird ein Funktionstest angeboten, der die wichtigsten Einstellungen und den Zugriff auf den Save.TV Account überprüft.
1. [stvcatchall.sh](https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stvcatchall.sh) runterladen oder Git verwenden, benötigte Hilfsdateien werden automatisch erstellt ([mehr …](README-ext.md#einmaliger-download))
2. das Skript manuell oder regelmäßig per Cron ausführen ([mehr …](README-ext.md#t%C3%A4gliche-ausf%C3%BChrung-einrichten))
3. *Optional* Bei Save.TV die Einstellung der [Aufnahmeoptionen prüfen](README-ext.md#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen)
4. *Optional* Die Datei `stv_skip.txt` anpassen, um einzelne Sender von der Programmierung auszunehmen ([mehr …](README-ext.md#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen))

[Weiter zur vollständigen Anleitung ...](README-ext.md#table-of-contents)

**Neueste Änderungen**
  * 2020-12-16 Fix Zombiebereinigung, Bereinigungen zusammengefaßt
  * 2020-12-10 Fix Logdatei, verbessertes Channelhandling, Login per Cookie entfernt, ReadMe angepaßt
  * 2020-12-09 Bereinigungsfunktion um Zombiebereinigung erweitert
  * 2020-06-17 XL Paket wurde von SaveTV wieder auf 20 Channels reduziert [siehe Issue #3](https://github.com/einstweilen/stv-catchall/issues/3)
  
#### 2020-12-16
  * für die Zombiebereinigung auf ungruppierte Sortierung der Übersichtsseite umgestellt
  * Dokumentation und Ausgabe der Bereinigungsfunktionen überarbeitet
  * Hinweis und Sicherheitsabfrage vor dem Channellöschen bei temporären XXL Upgrades ergänzt

#### 2020-12-10
  * der Link `stv_ca.log` auf die aktuellste Logdatei wurde bei der Ausführung per Cron im Homeverzeichnis statt im Scriptverzeichnis angelegt, das ist korrigiert
  * der Logout wurde zweimal durchgeführt, das ist korrigiert
  * die verwirrenden negativen Channel-Verfügbarkeitsanzeigen bei Usern mit temporärem XXL Upgrade wurden entfernt. Im Funktionstest wurde hierzu zusätzlich eine Erklärung ergänzt
  * die Zombieaufnahmen löschen Funktion schreibt gefundene Dateien ins Log
  * die bereits im Juni 'versteckte' Option das Login per Cookie durchführen zu können, wurde komplett entfernt, da es nicht stabil funktionierte 

#### 2020-12-09
Die [Bereinigungsfunktion](README-ext.md#modul-zombieaufnahmen-l%C3%B6schen) `./stvcatchall.sh -c` löscht jetzt auch Zombies (falsch einsortierte Aufnahmen) optional kann das auch automatisch erfolgen.

#### 2020-06-17
Seitens SaveTV wurde bei den XL Paketen heute Nacht die Anzahl der nutzbaren Channels **von 200 wieder auf 20 reduziert**. Aktuell sind bereits angelegte Channels **weiterhin vorhanden** und wurden nicht bis auf 20 gelöscht.
Die Anleitung/Empfehlung hierzu ist ausgelagert: [siehe Issue #3](https://github.com/einstweilen/stv-catchall/issues/3)

### Beispielausgabe CatchAll Programmierung
                _______ _______ _    _ _______   _______ _    _
                |______ |_____|  \  /  |______      |     \  /
                ______| |     |   \/   |______ .    |      \/ 
                ===============================================
                ____ C_a_t_c_h_a_l_l___e_i_n_r_i_c_h_t_e_n ____
		
	Aufnahme aller Sendungen der nächsten 7 Tage für folgende 36 Sender einrichten:
	3sat                ANIXE HD            ARD alpha HD        arte               
	BR                  Comedy Central      Das Erste           DELUXE MUSIC       
	eoTV                hr                  Kabel 1             mdr                
	N24 Doku            NDR                 Nickelodeon         n-tv               
	ONE HD              phoenix             ProSieben           ProSieben MAXX     
	RBB                 RTL II              SAT.1               SAT.1 Gold         
	ServusTV            sixx                SUPER RTL           SWR                
	tagesschau24        Tele 5              VOX                 WDR                
	WELT                ZDF                 zdf_neo             zdfinfo            
                                                                               
	Es werden jeweils 4 temporäre Channels angelegt und wieder gelöscht.
    
    Channels + anlegen  - löschen  ✓ Sender programmiert  F_ehler&Anzahl
    Sender : ✓✓✓✓✓ ✓✓✓✓✓ ✓✓✓✓✓ ✓✓✓✓✓ ✓✓✓✓✓ ✓✓✓✓✓ ✓✓✓✓✓ ✓ 

    144 Channels wurden angelegt und wieder gelöscht.
    Aktuell sind 10243 Sendungen zur Aufnahme programmiert.

    Bearbeitungszeit 474 Sekunden
## Table of contents
  * [Hintergrund](README-ext.md#hintergrund)
  * [Funktionsweise](README-ext.md#funktionsweise)
  * [Einrichten und Starten](README-ext.md#einrichten-und-starten)
    + [Username und Passwort](#username-und-passwort)
    + [Sender von der automatischen Aufnahme ausschließen](README-ext.md#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen)
    + [Angelegte Channels behalten `auto`, `immer`, `nie`](README-ext.md#angelegte-channels-behalten-auto-immer-nie)
    + [Hinweis zum Ende das kostenlosen XXL Upgrades](README-ext.md#hinweis-zum-ende-des-kostenlosen-xxl-upgrades-zum-2605)   
    + [Tip: Channels "korrigieren"](README-ext.md#tip-channels-korrigieren)
    + [Besonderheit beim Basis Paket](README-ext.md#besonderheit-beim-basis-paket)
    + [Versionsüberprüfung](README-ext.md#Versions%C3%BCberpr%C3%BCfung)
    + [Funktionstest](README-ext.md#funktionstest)
    + [Ausführungsstatus kontrollieren](README-ext.md#ausf%C3%BChrungsstatus-kontrollieren)
    + [Fehlerausgabe](README-ext.md#fehler-w%C3%A4hrend-der-skriptausf%C3%BChrung)
    + [Servicehinweis: Save.TV Aufnahme-Optionen prüfen](README-ext.md#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen)
    + [Tip für Mac-User](README-ext.md#tip-f%C3%BCr-mac-user)
    + [Hinweis zur Verwendung unter Termux](README-ext.md#hinweis-zur-verwendung-unter-termux)
    + [Beispielausgabe CatchAll Programmierung](README-ext.md#beispielausgabe-catchall-programmierung)
  * [Bereinigungsfunktionen](README-ext.md#bereinigungsfunktionen)
    + [Modul Reste aufräumen](README-ext.md#modul-reste-aufr%C3%A4umen)
    + [Modul Channels aufräumen](README-ext.md#modul-channels-aufr%C3%A4umen)
    + [Modul Zombieaufnahmen löschen](README-ext.md#modul-zombieaufnahmen-l%C3%B6schen)
  * [Installation auf einem Raspberry Pi mit täglicher Ausführung](README-ext.md#installation-auf-einem-raspberry-pi-mit-t%C3%A4glicher-ausf%C3%BChrung)
    + [Einmaliger Download](README-ext.md#einmaliger-download)
    + [Per Git installieren](README-ext.md#per-git-installieren)
    + [Dateirechte setzen](README-ext.md#dateirechte-setzen)
    + [Tägliche Ausführung einrichten](README-ext.md#t%C3%A4gliche-ausf%C3%BChrung-einrichten)
  * [Hilfefunktion](README-ext.md#hilfefunktion)
