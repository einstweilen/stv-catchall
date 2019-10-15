    _______ _______ _    _ _______   _______ _    _
    |______ |_____|  \  /  |______      |     \  /
    ______| |     |   \/   |______ .    |      \/  
    ===============================================
    ____ C_a_t_c_h_A_l_l___e_i_n_r_i_c_h_t_e_n ____

Nachbildung der CatchAll Funktion durch automatische Anlage der dafür notwendigen Channels.

Getestet auf Raspbian/DietPi (Stretch und Buster) und MacOS 10.13 High Sierra. 

**Keine Zeit?** Das Skript läuft defaultmäßig im Automatikmodus, erkennt das gebuchte SaveTV Paket und wählt die dafür passenden Einstellungen. Beim ersten Start wird ein Funktionstest angeboten, der die wichtigsten Einstellungen und den Zugriff auf den SaveTV Account überprüft.

Die vollständige Dokumentation wird nur als Einrichtungshilfe und für Sonderfälle oder Probleme benötigt.   
Direkt zu [TL;DR](#tldr) am Seitenende springen.

**Neuste Änderung**

2019-10-15 [Funktionstest](#funktionstest) ergänzt

## Table of contents
  * [Hintergrund](#hintergrund)
  * [Funktionsweise](#funktionsweise)
  * [Einrichten und Starten](#einrichten-und-starten)
    + [Username und Passwort hinterlegen](#username-und-passwort-hinterlegen)
    + [Sender von der automatischen Aufnahme ausschließen](#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen)
    + [Angelegte Channels behalten `auto`, `immer`, `nie`](#angelegte-channels-behalten-auto-immer-nie)
    + [Tip: Channels "korrigieren"](#tip-channels-korrigieren)
    + [Besonderheit beim Basis Paket](#besonderheit-beim-basis-paket)
    + [Funktionstest](#funktionstest)
        + [Funktionstest aufrufen](#funktionstest-aufrufen)
    	+ [Beispielausgabe des Funktionstests](#beispielausgabe-des-funktionstests)
    + [Ausführungsstatus kontrollieren](#ausf%C3%BChrungsstatus-kontrollieren)
    + [Fehler während der Skriptausführung](#fehler-w%C3%A4hrend-der-skriptausf%C3%BChrung)
    + [Servicehinweis: Save.TV Aufnahme-Optionen prüfen](#servicehinweis-savetv-aufnahme-optionen-pr%C3%BCfen)
    + [Tip für Mac-User](#tip-f%C3%BCr-mac-user)    
    + [Beispielausgabe CatchAll Programmierung](#beispielausgabe-catchall-programmierung)
  * [Zusatzfunktion Reste aufräumen](#zusatzfunktion-reste-aufr%C3%A4umen)
    + [Reste aufräumen Hintergrund](#reste-aufr%C3%A4umen-hintergrund)
    + [Reste aufräumen Funktionsweise](#reste-aufr%C3%A4umen-funktionsweise)
    + [Reste aufräumen einmalig starten](#reste-aufr%C3%A4umen-einmalig-starten)
    + [Reste aufräumen starten und anschließend Catchall Channel anlegen](#reste-aufr%C3%A4umen-starten-und-anschlie%C3%9Fend-catchall-channel-anlegen)
    + [Beispielausgabe Reste aufräumen](#beispielausgabe-reste-aufr%C3%A4umen)
  * [Zusatzfunktion Channels aufräumen](#zusatzfunktion-channels-aufr%C3%A4umen)
    + [Channels aufräumen Hintergrund](#channels-aufr%C3%A4umen-hintergrund)
    + [Channels aufräumen Funktionsweise und Aufruf](#channels-aufr%C3%A4umen-funktionsweise-und-aufruf)
    + [Beispielausgabe der Zusatzfunktion Channels aufräumen](#beispielausgabe-der-zusatzfunktion-channels-aufr%C3%A4umen)
  * [Installation auf einem Raspberry Pi mit täglicher Ausführung](#installation-auf-einem-raspberry-pi-mit-t%C3%A4glicher-ausf%C3%BChrung)
    + [Einmaliger Download](#einmaliger-download)
    + [Per Git installieren](#per-git-installieren)
    + [Dateirechte setzen](#dateirechte-setzen)
    + [Tägliche Ausführung einrichten](#t%C3%A4gliche-ausf%C3%BChrung-einrichten)
  * [Hilfefunktion](#hilfefunktion)
  * [Ausblick auf geplante Funktionen](#geplante-funktionen)
  * [TL;DR](#tldr)
 
## Hintergrund
[SaveTV](https://www.save.tv/) bietet keine CatchAll Funktion bei der automatisch alle Sendungen aller verfügbaren Sender aufgenommen werden.

Zur Aufnahmeprogrammierung können [je nach gebuchtem Paket](https://www.save.tv/stv/s/misc/paketauswahl.cfm) eine unterschiedliche Anzahl an Channels (5 Basis, 20 XL, 200 XXL) verwendet werden.

Über die [Erweiterten Einstellungen](https://www.save.tv/STV/M/obj/channels/ChannelAnlegen.cfm) kann ein Channel für einen Sender und einen Zeitslot (0-6 Uhr, 6-12 Uhr, 12-18 Uhr, 18-24 Uhr) programmiert werden.

Während sich mit den 200 Channels des XXL-Pakets die Catchall Funktion durch Programmierung von vier Zeitslots für die 47 SaveTV Sender (4 x 47 = 188 Channels) mit etwas Anlegefleiß nachbilden läßt, bieten das Basis-Paket mit 5 Channels und des XL Paket mit 20 Channels nicht genug Channels um alle Slots für alle Sender zu programmieren.

Die Grundidee von SaveTV Catchall basiert auf den unterschiedlichen Optionen, die beim Channellöschen angeboten werden 

* Nur Channel löschen (Programmierungen der kommenden 4 Wochen bleiben erhalten)
* Diesen Channel und alle darin enthaltenen Programmierungen löschen
* Diesen Channel und alle darin enthaltenen abgeschlossenen Aufnahmen aus dem Videoarchiv löschen
* Alles löschen – löscht alle Programmierungen und die im Channel enthaltenen Aufnahmen aus dem Archiv

Da bei der ersten Option die Programmierungen erhalten bleiben, kann man nach der Anlage der Programmierung den Channel wieder löschen und einen anderen Zeitslot / Sender mit dem gleichen Channel programmieren.

## Funktionsweise
STV CatchAll benötigt vier Channels (für die vier Zeitslots eines Senders) um darüber für alle Sender eine Programmierung anzulegen.

Eventuell im Account bereits enthaltene manuell vorgenommene Channelprogrammierungen bleiben erhalten. Sollten weniger als vier freie Channels vorhanden sein, wird das Skript mit einem entsprechenden Hinweis abgebrochen.

Direkt nach Anlage der vier Zeitslotchannels eines Sender werden diese wieder gelöscht, wobei die Programmierungen erhalten bleiben (s.o.). Dadurch können die gleichen Channels für den nächsten Sender wiederverwendet werden.

Je Sender erfolgen 9 save.tv Zugriffe, wodurch das Skript relativ langsam läuft
* 4 x Senderzeitslotchannel anlegen (0-6 Uhr, 6-12 Uhr, 12-18 Uhr, 18-24 Uhr)
* 1 x Aufruf Channelübersicht, um die zu löschenden ChannelIDs abzufragen (die IDs werden bei der Anlage nicht zurückgegeben)
* 4 x Senderzeitslotchannel löschen

Der Nachteil dieses Verfahren besteht allerdings darin, daß die Programmierung der Aufnahmen nur ca. sieben Tage in die Zukunft reicht, so daß das Skript regelmäßig ausgeführt werden muß, um die neu hinzugekommenen Sendungen und eventuelle Programmänderungen zu programmieren.
SaveTV aktualisert sein Angebot einmal täglich gegen 4:30 Uhr, so daß das Skript kurz danach laufen sollte, um alle Änderungen zeitnah zu berücksichtigen.

Siehe auch [Installation auf einem Raspberry Pi mit täglicher Ausführung](#installation-auf-einem-raspberry-pi-mit-t%C3%A4glicher-ausf%C3%BChrung)

Auf einem Raspberry Pi Zero W benötigt das Skript je nach der aktuellen Auslastung des SaveTV Servers etwa 18 Sekunden für die vier Channels eines Senders, bei mir um die 10 bis 11 Minuten für 36 aufzunehmende Sender. 
	
## Einrichten und Starten
### Username und Passwort hinterlegen
Die notwendigen Accountdaten, der SaveTV Username und das Passwort, können entweder direkt im Skript in den `Zeilen 8 und 9` hinterlegt werden oder beim Aufruf an das Skript übergeben werden.

    ./stvcatchall.sh
bzw.

    ./stvcatchall.sh username passwort
    
Sind die Accountdaten weder gespeichert noch wurden sie beim Aufruf übergeben, werden diese durch das Skript abgefragt.

### Sender von der automatischen Aufnahme ausschließen
Standardmäßig wird die Aufnahme aller Sendungen aller Sender programmiert. 
Im Skriptverzeichnis befindet sich die Datei `stv_sender.txt` in der alle bei SaveTV verfügbaren Sender hinterlegt sind. Wird diese Datei gelöscht, holt das Skript beim nächsten Start automatisch eine aktualisierte Senderliste vom SaveTV Server und legt die Datei neu an. Eventuell neu hinzugekommene Sender werden automatisch zur Aufnahme programmiert.

Über die Datei `stv_skip.txt` können einzelne Sender von der Aufnahme ausgeschlossen werden. Wird diese Datei gelöscht, legt das Skript beim Start eine neue Datei mit "17|RTL" als Defaulteintrag an.

Da `stv_sender.txt` und `stv_skip.txt` das gleiche Format benutzen ("SenderID|Sendername" "17|RTL") kann man seine persönliche Skipliste am einfachsten erstellen, indem man die `stv_sender.txt` nach `stv_skip.txt` kopiert

	cp stv_sender.txt stv_skip.txt
und dann mit einem Texteditor diejenigen Sender/Zeilen entfernt, die weiterhin aufgenommen werden sollen, sodaß nur noch die nicht aufzunehmenden Sender übrigleiben:

	> cat senderskip.txt
	92|Disney Channel
	60|DMAX
	7|Eurosport
	96|Fix und Foxi
	59|Folx TV
	40|Health TV
	10|KiKA
	11|MTV
	93|RiC
	17|RTL
	6|SPORT 1
	95|TLC

### Angelegte Channels behalten `auto`, `immer`, `nie`
Durch den Parameter `anlege_modus` in `Zeile 10` wird gesteuert, wie mit den durch das Skript angelegten Channels verfahren wird. Normalerweise wird man die voreingestellte Option `auto` verwenden, kann sie aber auch überschreiben.

***Defaulteinstellung `anlege_modus=auto`***  
Bei dem **Basis** und **XL** Paket werden die Channels nach dem Anlegen **wieder gelöscht**,  
beim **XXL** Paket bleiben die Channels **erhalten**.  
Sollten beim Start nicht genügend ungenutzte Channels vorhanden sein, bricht das Skript mit einem Hinweistext ab.

***`anlege_modus=immer`***  
Vom Skript angelegte Channels bleiben immer erhalten. Das Skript prüft vor dem Start, ob noch genügend ungenutzte Channels vorhanden sind und wechselt bei Bedarf zurück in den `auto` Modus. Ein Hinweistext wird ausgeben.

***`anlege_modus=nie`***  
Vom Skript angelegte Channels werden nach dem Anlegen wieder gelöscht, auch wenn mehr ungenutzte Channels verfügbar sind als benötigt werden. Der Pseudostichwortchannel mit dem Ausführungsstatus wird nicht angelegt.

#### Tip: Channels "korrigieren"
Hat man aus Versehen zu viele Channels angelegt oder möchte nur alle Channels löschen lassen, kann man die [Zusatzfunktion Reste aufräumen](#zusatzfunktion-reste-aufr%C3%A4umen) verwenden.

### Besonderheit beim Basis Paket
STV Catchall kann zwar mit dem Basis Paket verwendet werden, aber das Einrichten von CatchAll Channels ist nicht sinnvoll, da das Basis Paket nur einen begrenzten Aufnahmespeicher von 50 Stunden bietet.

### Funktionstest
Der Funktionstest überprüft neben den Skripteinstellungen den korrekten Zugriff auf den SaveTV Account.

#### Funktionstest aufrufen
Bei der ersten Skriptausführung wird der Funktionstest `Soll ein Funktionstest durchgeführt werden (J/N)? :` automatisch angeboten. 

Zusätzlich zum automatischen Aufruf beim ersten Skriptstart kann der Funktionstest mit den Optionen `-t` `--test` direkt aufgerufen werden.

Hinweis: der erste Aufruf des Skripts wird anhand des Fehlens der Logdatei `stv_ca.log` erkannt.

#### Beispielausgabe des Funktionstests
    Funktionstest auf korrekte Logindaten und verfügbare Channels wird durchgeführt.
    
    [✓] Schreibrechte im Skriptverzeichnis
    [✓] Login mit UserID 0815 erfolgreich
    [✓] Paket 'Save.TV XL 24 Monate' mit 20 Channels, 0 benutzt
        Channelanlegemodus 'auto' wird verwendet
    
    [✓] Die Liste der nicht aufzunehmenden Sender 'stv_skip.txt' beinhaltet:
        KiKA                MTV                 Health TV          
        Folx TV             SPORT 1             DMAX               
        Eurosport           Disney Channel      RiC                
        TLC                 Fix und Foxi        RTL                
                                                                   
    [✓] Testchannel erfolgreich angelegt
    [✓] Channelliste einlesen
    [✓] Testchannel erfolgreich gelöscht
    [✓] Logout durchgeführt
  
    Funktionstest wurde in 6 Sekunden abgeschlossen

### Ausführungsstatus kontrollieren
Der aktuelle Skriptfortschritt wird während der Ausführung auf dem Bildschirm (siehe unten "Beispielausgabe") ausgegeben, zusätzlich wird zur späteren genaueren Kontrolle im Skriptverzeichnis die Logdatei `stv_ca.log` geschrieben, die sämtliche vom Skript angelegte Channels und eventuelle Fehlermeldungen enthält.

Um den Status des letzten Skriptlaufs von jedem Gerät aus prüfen zu können z.B. der SaveTV Webseite oder der SaveTV App wird am Ende der Skriptausführung eine Kurzzusammenfassung als "Pseudostichwortchannel", dessen Titel den Status enthält, angelegt. Der Channeltitel hat dabei folgenden Aufbau:


	_  OK 0731 2258 Delta 49	bedeutet
	_				Underscore am Anfang = von CatchAll angelegt
	OK / FEHLER			fehlerfrei bzw. Fehler sind aufgetreten
	0728				Datum Monat Tag
	2257				Uhrzeit Stunde Minute
	Delta 49			49 Sendungen wurden zusätzlich programmiert
	
Das Delta für die Anzahl der programmierten Sendungen wird gegenüber dem letzten Skriptlauf ermittelt und kann auch negativ sein, da mal mehr und mal weniger Sendungen in den nächsten 7 Tagen gesendet werden.

Für diese Statusinformation wird kein Channel "verschwendet", da dieser Channel bei der nächsten Skriptausführung als erstes gelöscht wird, bevor weitere Channels angelegt werden. Und da der "Pseudochannel" erst ganz am Ende neu angelegt wird, nachdem alle zur Skriptausführung benötigten temporären Channels bereits wieder gelöscht wurden, belegt er quasi nur den Platz eines der temporären Channels während das Skript nicht läuft.

### Fehler während der Skriptausführung
Sollten bei der Verarbeitung Fehler auftreten, so wird im Fortschrittsbalken statt des "✓" für Okay ein "F" ausgegeben und am Ende zeigt das Skript die Logdatei `stv_ca.log` an.

Meistens treten Fehler auf, wenn der SaveTV Server im Moment überlastet ist. Bei einem erneuten Skriptlauf werden diese Channels wieder ohne Fehler eingerichtet. Daher können Fehler i.d.R. ignoriert werden, solange das Skript zeitnah, maximal jedoch innerhalb von 7 Tagen erneut gestartet wird und fehlerfrei durchläuft.

Die komplette Serverfehlermeldung ist in der Logdatei `stv_ca.log` enthalten.

### Servicehinweis: Save.TV Aufnahme-Optionen prüfen
Bitte vor dem ersten Skriptlauf prüfen, ob die Save.TV Einstellungen zu Vorlauf-, Nachlaufzeit und Auto-Schnittlisten den eigenen Wünschen entsprechen.

[Save.TV > Account-Einstellungen > Aufnahme-Optionen](https://www.save.tv/STV/M/obj/user/config/AccountEinstellungen.cfm?iActiveMenu=0)
![STV Aufnahme Optionen Screenshot](img-fuer-readme/stv-account-optionen.png)

### Tip für Mac-User
Durch Ändern der Fileextension von `stvcatchall.sh` in `stvcatchall.console` kann das Skript direkt im Finder per Doppelklick gestartet werden; es wird ein neues Terminalfenster geöffnet, in dem das Skript dann abläuft.

Diese Datei kann man auch als Autostartobjekt verwenden, dann wird es bei jedem Systemstart automatisch ausgeführt.
[Externe Anleitung: Autostart-Programme über die Systemeinstellungen festlegen](https://www.heise.de/tipps-tricks/Mac-Autostart-Programme-festlegen-4025523.html#anchor_2)

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
    Programmierte Sendungen beim letzten Lauf: 10182 aktuell: 10231 Delta: 49

    Bearbeitungszeit 474 Sekunden

## Zusatzfunktion Reste aufräumen
### Reste aufräumen Hintergrund
Wenn man einen Sender nicht mehr aufnehmen möchte oder man die Anleitung bezüglich der Senderskipliste nicht sorgfältig genug gelesen hat ([mehr …](#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen)), befinden sich die vorgenommenen Programmierungen und alten Aufnahmen weiterhin im SaveTV System bis die Vorhaltezeit des SaveTV Pakets abgelaufen ist.

Wer seinen Account bereits vorher säubern will, kann die entsprechenden Sender und Sendungen manuell löschen oder die *Reste aufräumen* Funktion von stv-catchall verwenden.

### Reste aufräumen Funktionsweise
Die Funktion prüft, ob für die Sender der Skipliste, die bei der Aufnahme übersprungen werden, (siehe auch [Sender von der automatischen Aufnahme ausschließen](#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen)) aufgenommene Sendungen oder vorgenommene Programmierungen vorliegen und löscht diese.

Beim Start der Aufräumenfunktion werden alle Sender der Skipliste aufgelistet und das Aufräumen muß mit "j" oder "J" bestätigt werden.

**Hinweis**: Die Löschung der aufgenommenen Sendungen kann **nicht rückgängig** gemacht werden. 

### Reste aufräumen einmalig starten
Um die *Reste aufräumen* Funktion auszuführen, muß das Skript mit dem Parameter `--cleanup` oder `-c` aufgerufen werden

	./stvcatchall.sh --cleanup
	
### Reste aufräumen starten und anschließend Catchall Channel anlegen
Die Sicherheitsabfrage der *Reste aufräumen* Funktion 'Alles bereinigen (J/N)?' wird durch Aufruf des Skripts mit dem Parameter `--cleanupauto` übersprungen. Nach dem Aufräumen wird mit der Anlage der Catchall Channels fortgefahren

	./stvcatchall.sh --cleanupauto
Dadurch ist es möglich nicht nur die Catchall Programmierung sondern auch das Reste aufräumen im Cron durchzuführen. Siehe auch [Tägliche Ausführung einrichten](#t%C3%A4gliche-ausf%C3%BChrung-einrichten)

### Beispielausgabe Reste aufräumen
                _______ _______ _    _ _______   _______ _    _
                |______ |_____|  \  /  |______      |     \  /
                ______| |     |   \/   |______ .    |      \/ 
                ===============================================
                ____ C_a_t_c_h_a_l_l___e_i_n_r_i_c_h_t_e_n ____
        Programmierungen und Aufnahmen der Sender der Skipliste löschen

	Die Liste der nicht aufzunehmenden Sender 'senderskip.txt' beinhaltet zur Zeit:
	KiKA                MTV                 Health TV           Folx TV            
	SPORT 1             DMAX                Eurosport           Disney Channel     
	RiC                 TLC                 Fix und Foxi        RTL                
                                                                               
	Sollen für diese 12 Sender die vorhandenen Programmierungen und
	aufgenommenen Sendungen endgültig gelöscht werden?

	Alles bereinigen (J/N)? : j

	Lösche alle Programmierungen und Aufnahmen der Sender der Skipliste
	'KiKA' hat 415 Einträge, beginne Löschung : ............✓
	'MTV' hat 114 Einträge, beginne Löschung : ....✓
	'Health TV' hat 383 Einträge, beginne Löschung : ...........✓
	'Folx TV' hat 146 Einträge, beginne Löschung : .....✓
	'SPORT 1' hat 281 Einträge, beginne Löschung : .........✓
	'DMAX' hat 237 Einträge, beginne Löschung : .......✓
	'Eurosport' hat 127 Einträge, beginne Löschung : ....✓
	'Disney Channel' hat 316 Einträge, beginne Löschung : ..........✓
	'RiC' hat 159 Einträge, beginne Löschung : .....✓
	'TLC' hat 274 Einträge, beginne Löschung : ........✓
	'Fix und Foxi' hat 387 Einträge, beginne Löschung : ............✓
	'RTL' muß nicht gesäubert werden
	Alle Aufnahmen und Programmierungen wurden gelöscht.

	Bearbeitungszeit 178 Sekunden
	
## Zusatzfunktion Channels aufräumen
### Channels aufräumen Hintergrund
Wenn man im XXL Paket 188 Channel angelegt hat und CatchAll nicht mehr verwenden möchte oder wenn die Ausführung des Skripts beim Channelanlegen abgebrochen wurde (Ctrl C, Stromausfall ...) bleiben vom Skript angelegte Channels übrig, die von Hand gelöscht werden müssen.

### Channels aufräumen Funktionsweise und Aufruf
Wird die *Reste aufräumen* Funktion im manuellen Modus mit `./stvcatchall.sh --cleanup` aufgerufen, wird anschließend an das Aufräumen der Sender der Skipliste geprüft, ob noch 'alte' vom Skript angelegte Channels vorhanden sind. Das Skript erkennt dabei seine eigenen Channels anhand des `_ ` am Anfang des Channelnamens und fragt, ob diese Channels gelöscht werden sollen.
Es sind 4 vom STV CatchAll Skript angelegte Channels '`_ `' vorhanden, diese Channels löschen (J/N)?  

Um einen ungewollten Datenverlust zu vemeiden, löscht das Skript **nur** die Channels und die zukünftigen Programmierungen, die vorhandenen Aufnahmen bleiben erhalten.

Sollen die Aufnahmen auch gelöscht werden, muß man die zu den Channels gehörenden Sender in die Skipliste `stv_skip.txt` eintragen und die *Reste aufräumen* Funktion`./stvcatchall.sh --cleanup` erneut aufrufen.

### Beispielausgabe der Zusatzfunktion Channels aufräumen
Der erster Teil ist identisch zu [Beispielausgabe Reste aufräumen](#beispielausgabe-reste-aufr%C3%A4umen) denn folgt:

	         Prüfe die Channelliste auf von STV CatchAll angelegte Channels
	
	Es sind 5 vom STV CatchAll Skript angelegte Channels vorhanden,
	beim Channellöschen bleiben bereits erfolgte Aufnahmen erhalten.
	
	Hinweis: Die Option 'L' zeigt eine Liste der gefundenen STV Channels an
	
	Diese 5 Channels und zugehörigen Programmierungen löschen (J/N/L)? : j
	Lösche 5 Channels : .....✓
	Es wurden 5 Channels gelöscht.

	Bearbeitungszeit 208 Sekunden
	
## Installation auf einem Raspberry Pi mit täglicher Ausführung

### Einmaliger Download
Die Datei [stvcatchall.sh](https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stvcatchall.sh) direkt auf dem Raspberry runterladen.

	wget https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stvcatchall.sh
Die Dateien für die Senderliste und die Skipliste der zu überspringenden Sender müssen nicht runtergeladen werden, diese legt das Skript automatisch an.

### Per Git installieren
Statt des einmaligen Downloads kann man auch das komplette stv-catchall Repository auf den Raspberry clonen

	git clone https://github.com/einstweilen/stv-catchall.git
Falls Git noch nicht installiert ist, zuerst Git mit `sudo apt-get install git` installieren.

### Dateirechte setzen
Danach entweder in das durch Git anlegte Verzeichnis `stv-catchall` wechseln `cd stv-catchall` oder in des Verzeichnis in dem der manuelle Download des Skripts `stvcatchall.sh` erfolgt ist. Dort die Datei mit

	chmod +x stvcatchall.sh
auf ausführbar setzen. 

### Tägliche Ausführung einrichten
Damit das Skript automatisch täglich ausgeführt wird, muß es in die Liste der regelmäßigen Jobs, der Cron Tabelle, eingetragen werden.
Um das Skript z.B. täglich um 5 Uhr ausführen zu lassen, zuerst die Cron Tabelle mit `crontab -e ` öffnen, nach ganz unten scrollen und am Ende 

	0 5 * * * /home/dietpi/stv-catchall/stvcatchall.sh
	
eintragen.
Dabei steht `0 5` für 5:00 Uhr, `* * *` für jeden Tag, jeden Monat, an jedem Wochentag und `/home/dietpi/stv-catchall/stvcatchall.sh` für den kompletten Pfad zum Skript.
Für weitere Details siehe [Externe Seite: Crontab editing made simple](http://corntab.com/?c=0_5_*_*_*).

Wird kein DietPi verwendet, den Pfad zum `stvcatchall.sh` Skript entsprechend anpassen. Wenn man sich nicht sicher ist, in das Skriptverzeichnis wechseln und dort `pwd` eingeben, dann bekommt man den Pfad `/home/dietpi/stv-catchall` angezeigt und muß nur noch den Skriptnamen `stvcatchall.sh` ergänzen.

Es ist auch möglich, dem Skriptaufruf Parameter mitzugeben, so daß täglich ein `stvcatchall.sh --cleanupauto` ausgeführt wird

	0 5 * * * /home/dietpi/stv-catchall/stvcatchall.sh --cleanupauto

## Hilfefunktion
Wenn das SaveTV Catchall Skript mit `stvcatchall.sh -?` oder `stvcatchall.sh --help` aufgerufen wird, wird ein kurzer Hilfetext angezeigt.

## Geplante Funktionen
  * Aufnahmeprogrammierung splitten, um Sondersendungen o.ä. aufzunehmen

## TL;DR
1. [stvcatchall.sh](https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stvcatchall.sh) runterladen oder Git verwenden, benötigte Hilfsdateien werden automatisch erstellt ([mehr …](#einmaliger-download))
2. In `Zeile 8 und 9` den SaveTV Username und das Passwort eintragen oder beim manuellen Aufruf mit `./stvcatchall.sh username passwort` übergeben ([mehr …](#username-und-passwort-hinterlegen))
3. Optional Die Datei `senderskip.txt` anpassen, um einzelne Sender von der Programmierung auszunehmen ([mehr …](#sender-von-der-automatischen-aufnahme-ausschlie%C3%9Fen))
4. das Skript manuell oder regelmäßig per Cron ausführen ([mehr …](#t%C3%A4gliche-ausf%C3%BChrung-einrichten))
