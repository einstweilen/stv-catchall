    _______ _______ _    _ _______   _______ _    _
    |______ |_____|  \  /  |______      |     \  /
    ______| |     |   \/   |______ .    |      \/  
    ===============================================
    ____ C_a_t_c_h_A_l_l___e_i_n_r_i_c_h_t_e_n ____

Nachbildung der [2016 aus juristischen Gründen eingestellten CatchAll Funktion](https://tv-forum.info/viewtopic.php?f=33&t=619) bei der alle bei Save.TV [verfügbaren Sender](https://hilfe.save.tv/Knowledgebase/50080/Senderliste) 24/7 aufgenommen werden. Dadurch erhält das Save.TV XL Paket die gleiche Funktionalität wie das XXL Paket. Beim XXL Paket spart man sich das manuelle Channelanlegen.

Für die regelmäßige Ausführung kann das Skript auf einem Raspberry Pi (ein Zero ist ausreichend) installiert werden. Als reines BASH Skript läuft es unverändert unter Raspbian/DietPi, MacOS, Termux (Android).

Fehler und Anregungen bitte unter [Issues](https://github.com/einstweilen/stv-catchall/issues) posten.

## Schnelleinstieg
Das Skript läuft defaultmäßig im Automatikmodus und nimmt alle verfügbaren Sender auf. Es fragt Username und Passwort ab, bietet deren Speicherung an, erkennt das gebuchte Save.TV Paket und wählt die dafür passenden Einstellungen. Beim ersten Start wird ein Funktionstest angeboten, der die wichtigsten Einstellungen und den Zugriff auf den Save.TV Account überprüft.
1. [stvcatchall.sh](https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stvcatchall.sh) runterladen oder Git verwenden ([wie macht man das?](README-ext.md#einmaliger-download))
2. das Skript manuell oder regelmäßig per Cron ausführen ([wie macht man das?](README-ext.md#t%C3%A4gliche-ausf%C3%BChrung-einrichten))
3. *Optional Bei Save.TV die Einstellung der Aufnahmeoptionen prüfen* ([wie macht man das?](README-ext.md#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen))
4. *Optional `stv_skip.txt` anpassen, um einzelne Sender von der Programmierung auszunehmen* ([wie macht man das?](README-ext.md#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen))

[Weiter zur vollständigen Anleitung ...](README-ext.md#table-of-contents)

### Servicehinweis - das Projekt lebt
Wenn es keine Updates gibt, heißt das nicht, dass das Projekt nicht mehr betreut wird. Mein Save.TV Abo läuft aktuell bis August 2025, d.h. falls technische Anpassungen notwendig werden, werden die -wenn möglich- gemacht.

**Neueste Änderungen**
#### 2023-04-11
  * FIXED cURL wieder per secure ohne Ignorierung von Zertifikatsfehlern
#### 2022-08-24
  * QUICKFIX für cURL Login Problem
#### 2022-04-25
  * Abfrage von AlleStörungen aus Aufwand/Nutzen-Gründen entfernt
#### 2022-03-13
  * FIXED unter Linux wurden manuelle Eingaben zum Teil ignoriert
  
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
