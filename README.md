    _______ _______ _    _ _______   _______ _    _
    |______ |_____|  \  /  |______      |     \  /
    ______| |     |   \/   |______ .    |      \/  
    ===============================================
    ____ C_a_t_c_h_A_l_l___e_i_n_r_i_c_h_t_e_n ____

Nachbildung der [2016 aus juristischen Gründen eingestellten CatchAll Funktion](https://tv-forum.info/viewtopic.php?f=33&t=619) bei der alle bei Save.TV [verfügbaren Sender](https://hilfe.save.tv/Knowledgebase/50080/Senderliste) 24/7 aufgenommen werden. Dadurch erhält das Save.TV XL Paket die gleiche Funktionalität wie das XXL Paket. Beim XXL Paket spart man sich das manuelle Channelanlegen.

Für die regelmäßige Ausführung kann das Skript auf einem Raspberry Pi (ein Zero ist ausreichend) installiert werden. Als reines BASH Skript läuft es unverändert unter Raspbian/DietPi, MacOS, Termux (Android).

Fehler und Anregungen bitte unter [Issues](https://github.com/einstweilen/stv-catchall/issues) posten.

**2022-02-02 Olympiaupdate** Aktuelle Sondersendungen aus dem Sportbereich erhalten häufig falsche, d.h. in der Zukunft liegende, interne Zeitcodes wodurch ältere Sendungen vor neuere sortiert werden. Details siehe unter [Modul Zombieaufnahmen löschen](README-ext.md#modul-zombieaufnahmen-l%C3%B6schen).

Im Rahmen der Olympiaberichterstattung ist durch die Sondersendungen mit vermehrten 'Sortierungsfehlern' zu rechnen. Das Einrichten der automatischen Löschung ([wie macht man das?](README-ext.md#zombieaufnahmen-l%C3%B6schen-funktionsweise-und-aktivierung)) solcher Aufnahmen hat für Sportinterssierte den Nachteil, dass die Aufnahmen bei der täglichen Skriptausführung u.U. bereits vor dem Anschauen gelöscht werden.

Die Löschmodule in den [Bereinigungsfunktionen](README-ext.md#bereinigungsfunktionen) lassen sich nun zusätzlich auch gezielt einzeln aufrufen.

                Bereinigung von nicht mehr benötigten Inhalten

        1  Skipliste   : Channels, Aufnahmen und Programmierungen
        2  Channelliste: vom Skript angelegte Channels löschen
        3  Videoarchiv : Aufnahmen mit vordatiertem Timestamp löschen

     [?] Bereinigungsmodul wählen (1 / 2 / 3 / A_lle 1-3 / Q_uit)? :

## Schnelleinstieg
Das Skript läuft defaultmäßig im Automatikmodus und nimmt alle verfügbaren Sender auf. Es fragt Username und Passwort ab, bietet deren Speicherung an, erkennt das gebuchte Save.TV Paket und wählt die dafür passenden Einstellungen. Beim ersten Start wird ein Funktionstest angeboten, der die wichtigsten Einstellungen und den Zugriff auf den Save.TV Account überprüft.
1. [stvcatchall.sh](https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stvcatchall.sh) runterladen oder Git verwenden ([wie macht man das?](README-ext.md#einmaliger-download))
2. das Skript manuell oder regelmäßig per Cron ausführen ([wie macht man das?](README-ext.md#t%C3%A4gliche-ausf%C3%BChrung-einrichten))
3. *Optional Bei Save.TV die Einstellung der Aufnahmeoptionen prüfen* ([wie macht man das?](README-ext.md#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen))
4. *Optional `stv_skip.txt` anpassen, um einzelne Sender von der Programmierung auszunehmen* ([wie macht man das?](README-ext.md#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen))

[Weiter zur vollständigen Anleitung ...](README-ext.md#table-of-contents)

**Neueste Änderungen**
#### 2022-02-02
  * Direktanwahl einzelner Module der [Bereinigungsfunktionen](README-ext.md#bereinigungsfunktionen)
#### 2021-10-25
  * Bedienung der [Bereinigungsfunktionen](README-ext.md#bereinigungsfunktionen) vereinfacht, Abbruchfunktion ergänzt
  * Dokumentation der Bereinigungsfunktionen überarbeitet
#### 2021-07-22
  * FIXED Ermittlung der Anzahl der Usermeldungen bei AlleStörungen.de
  
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
    + [Username und Passwort](README-ext.md#username-und-passwort)
    + [Sender von der automatischen Aufnahme ausschließen](README-ext.md#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen)
    + [Funktionstest](README-ext.md#funktionstest)
    + [Ausführungsstatus kontrollieren](README-ext.md#ausf%C3%BChrungsstatus-kontrollieren)
    + [Fehlerausgabe](README-ext.md#fehler-w%C3%A4hrend-der-skriptausf%C3%BChrung)
    + [Servicehinweis: Save.TV Aufnahme-Optionen prüfen](README-ext.md#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen)
    + [Beispielausgabe CatchAll Programmierung](README-ext.md#beispielausgabe-catchall-programmierung)
  * [Bereinigungsfunktionen](README-ext.md#bereinigungsfunktionen)
    + [Modul Reste aufräumen](README-ext.md#modul-reste-aufr%C3%A4umen)
    + [Modul Channels aufräumen](README-ext.md#modul-channels-aufr%C3%A4umen)
    + [Modul Zombieaufnahmen löschen](README-ext.md#modul-zombieaufnahmen-l%C3%B6schen)
  * [Installation auf einem Raspberry Pi mit täglicher Ausführung](README-ext.md#installation-auf-einem-raspberry-pi-mit-t%C3%A4glicher-ausf%C3%BChrung)
  * [Hilfefunktion](README-ext.md#hilfefunktion)
