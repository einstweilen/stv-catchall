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
  * 2020-05-29 [zusätzliche Loginoption 'Cookie'](README-ext.md#wechsel-zwischen-den-loginoptionen), [Funktionstest](README-ext.md#beispielausgabe-des-funktionstests) Vertragslaufzeit und Aufnahmestatus, [7-Tage-Log](README-ext.md#fehler-w%C3%A4hrend-der-skriptausf%C3%BChrung)
  * 2020-05-25 [Logindaten werden nicht mehr im Skript](README-ext.md#username-und-passwort),
[Auslauf des XXL Upgrades](https://github.com/einstweilen/stv-catchall/issues/3),
[Channeltitel](README-ext.md#aufbau-der-channeltitel),
[Fehlerbehandlung](README-ext.md#wiederholung-der-channelanlage)
  * 2020-03-27 Zusatzüberprüfung auf kostenloses XXL Upgrade bis 26.05.
  * 2020-03-15 [Fehlerauswertung mittels EXIT Codes](README-ext.md#im-batchmodus) dokumentiert
  * 2020-01-30 [Funktionstest](README-ext.md#funktionstest) Störungsausgabe Textausgabe korrigiert

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
      + [Erstes Login und manuelles Login](README-ext.md#erstes-login-und-manuelles-login)
      + [Automatisches Login](README-ext.md#automatisches-login)
      + [Wechsel zwischen den Loginoptionen](README-ext.md#wechsel-zwischen-den-loginoptionen)
    + [Sender von der automatischen Aufnahme ausschließen](README-ext.md#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen)
    + [Angelegte Channels behalten `auto`, `immer`, `nie`](README-ext.md#angelegte-channels-behalten-auto-immer-nie)
    + [Hinweis zum Ende das kostenlosen XXL Upgrades](README-ext.md#hinweis-zum-ende-des-kostenlosen-xxl-upgrades-zum-2605)   
    + [Tip: Channels "korrigieren"](README-ext.md#tip-channels-korrigieren)
    + [Besonderheit beim Basis Paket](README-ext.md#besonderheit-beim-basis-paket)
    + [Versionsüberprüfung](README-ext.md#Versions%C3%BCberpr%C3%BCfung)
    + [Funktionstest](README-ext.md#funktionstest)
        + [Funktionstest aufrufen](README-ext.md#funktionstest-aufrufen)
    	+ [Beispielausgabe des Funktionstests](README-ext.md#beispielausgabe-des-funktionstests)
    + [Ausführungsstatus kontrollieren](README-ext.md#ausf%C3%BChrungsstatus-kontrollieren)
    + [Fehlerausgabe](README-ext.md#fehler-w%C3%A4hrend-der-skriptausf%C3%BChrung)
        + [im Direktmodus](README-ext.md#im-direktmodus)
    	+ [im Batchmodus](README-ext.md#im-batchmodus)
        + [Wiederholung der Channelanlage](#wiederholung-der-channelanlage)
    + [Servicehinweis: Save.TV Aufnahme-Optionen prüfen](README-ext.md#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen)
    + [Tip für Mac-User](README-ext.md#tip-f%C3%BCr-mac-user)
    + [Hinweis zur Verwendung unter Termux](README-ext.md#hinweis-zur-verwendung-unter-termux)
    + [Beispielausgabe CatchAll Programmierung](README-ext.md#beispielausgabe-catchall-programmierung)
  * [Zusatzfunktion Reste aufräumen](README-ext.md#zusatzfunktion-reste-aufr%C3%A4umen)
    + [Reste aufräumen Hintergrund](README-ext.md#reste-aufr%C3%A4umen-hintergrund)
    + [Reste aufräumen Funktionsweise](README-ext.md#reste-aufr%C3%A4umen-funktionsweise)
    + [Reste aufräumen einmalig starten](README-ext.md#reste-aufr%C3%A4umen-einmalig-starten)
    + [Reste aufräumen starten und anschließend Catchall Channel anlegen](README-ext.md#reste-aufr%C3%A4umen-starten-und-anschlie%C3%9Fend-catchall-channel-anlegen)
    + [Beispielausgabe Reste aufräumen](README-ext.md#beispielausgabe-reste-aufr%C3%A4umen)
  * [Zusatzfunktion Channels aufräumen](README-ext.md#zusatzfunktion-channels-aufr%C3%A4umen)
    + [Channels aufräumen Hintergrund](README-ext.md#channels-aufr%C3%A4umen-hintergrund)
    + [Channels aufräumen Funktionsweise und Aufruf](README-ext.md#channels-aufr%C3%A4umen-funktionsweise-und-aufruf)
    + [Beispielausgabe der Zusatzfunktion Channels aufräumen](README-ext.md#beispielausgabe-der-zusatzfunktion-channels-aufr%C3%A4umen)
  * [Installation auf einem Raspberry Pi mit täglicher Ausführung](README-ext.md#installation-auf-einem-raspberry-pi-mit-t%C3%A4glicher-ausf%C3%BChrung)
    + [Einmaliger Download](README-ext.md#einmaliger-download)
    + [Per Git installieren](README-ext.md#per-git-installieren)
    + [Dateirechte setzen](README-ext.md#dateirechte-setzen)
    + [Tägliche Ausführung einrichten](README-ext.md#t%C3%A4gliche-ausf%C3%BChrung-einrichten)
  * [Hilfefunktion](README-ext.md#hilfefunktion)
