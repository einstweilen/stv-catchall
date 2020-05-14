    _______ _______ _    _ _______   _______ _    _
    |______ |_____|  \  /  |______      |     \  /
    ______| |     |   \/   |______ .    |      \/  
    ===============================================
    ____ C_a_t_c_h_A_l_l___e_i_n_r_i_c_h_t_e_n ____


## 14.05. Save.TV Fehler bei der Channelanlage per Skript und Website
Nachdem heute Abend der Server wieder halbwegs performant läuft, habe ich ein paar Tests durchgeführt. Während letzte Nacht 140 Channels zwar sehr langsam aber korrekt angelegt wurden, erhält das Skript aktuell laut Logdatei immer die Fehlermeldung "Dein Suchbegriff muss mindestens 1 Zeichen enthalten. Bitte wähle einen längeren Suchbegriff.".

Ich habe das auch im Web genau nach Vorschrift auf der Seite https://www.save.tv/STV/M/obj/channels/MeineChannels.cfm ausprobiert: _Tippe TATORT in das untenstehende Suchfeld und wähle die Option "Serienchannel"_ und erhalte auch dort die gleiche Fehlermeldung:
Weder als Serien- noch als Stichwortchannel läßt sich 'TATORT' anlegen.

![STV Aufnahme Optionen Screenshot](img-fuer-readme/stv-channel-stoerung-sc.jpg)

![STV Aufnahme Optionen Screenshot](img-fuer-readme/stv-channel-stoerung.jpg)

## 14.05. Save.TV Timeouts bei der Channelanlage
Wer nicht unbedingt muß, sollte aktuell nur zusätzliche Sender programmieren, aber nicht die Funktion zum Bereinigen/Löschen der alten Channels verwenden, da nicht garantiert werden kann, daß die Channelanlage komplett und korrekt durchläuft.

Falls man doch die kompletten Catchall Channels anlegen lassen will oder muß:

1. [Funktionstest](README-ext.md#funktionstest) `-t` durchführen, wenn der bereits Fehler zeigt, später nochmal wiederholen
2. [Zusatzfunktion Channels aufräumen](README-ext.md#zusatzfunktion-channels-aufr%C3%A4umen) `-c` starten,
`Alles bereinigen (J/N)? : N` NEIN,
`Channels und zugehörige Programmierungen löschen (J/N/L)? : J` JA
3. OPTIONAL in Zeile 5 bei `err_max=5` einen sehr hohen Wert z.B. `999` wählen, damit das Skript trotz verienzelter Timeouts möglichst viele Channels anlegt
4. Skript ohne Zusatzparamter starten, um alle Channels neu anzulegen

Es besteht das **Risiko**, daß der Save.TV Server bei der Neuanlage gestört ist und man beim Test nur "Glück hatte", also wirklich nur machen, wenn erfroderlich oder alles wieder stabil läuft.


## 14.05. Save.TV Schnittlisten fehlen
Zur Zeit werden keine Schnittlisten erstellt. Bei allen Senders steht bei den aktuellen Aufnahmen "Für Aufnahmen dieses Senders ist kein Werbeschnitt verfügbar", wenn man sich ältere Aufnahmen vor dem 24.04. des gleichen Sender ansieht, sind dort Schnittlisten erstellt worden, sowohl ÖR als auch Privat.

Es wird wohl noch eine Weile dauern, bis alles wieder wie vorher funktioniert. Da mindestens bis zum 26.05. noch das XXL-Upgrade gilt, müssen bis dahin keine neuen Channel angelegt werden. 

## 14.05. Tip für fehleden Serienaufnahmen
Windowsuser sollten sich den [SERIEN! TV Serien Organizer](https://tv-forum.info/viewtopic.php?f=37&t=1123) ansehen, der Aufnahmen aus  zwei Quellen nutzen kann: Save.TV und MediathekViewWeb, der Web-Service zum Programm MediathekView, welches die Mediatheken aller Öffentlich-Rechtlichen bereitstellt.


## 13.05 Save.TV ist wieder online, keine Skriptanpassungen notwendig
Seit dem 12.05. ist Save.TV wieder online ([Zusammenfassung zum Hack auf netzwelt.de](https://www.netzwelt.de/news/178330-savetv-online-videorekorder-hackerangriff-neustart.html)). Wenn man sich ein [neues Passwort](https://reset.save.tv/) gegeben und das auch im Skript eingetragen hat ([Username und Passwort hinterlegen …](README-ext.md#username-und-passwort-hinterlegen)) funktioniert alles ohne weitere Anpassungen wieder.

Die Server sind noch überlastet, es kann zu langen Skriptlaufzeiten und Timeouts kommen. Der Funktionstest dauert aktuell dreimal solange wie sonst `Funktionstest wurde in 31 Sekunden abgeschlossen`.
