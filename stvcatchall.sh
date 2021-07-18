#!/bin/bash
# https://github.com/einstweilen/stv-catchall/

SECONDS=0 
version_ist='20210718'  # Scriptversion

### Dateipfade & Konfiguration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # Pfad zum Skript
cd "$DIR"                           # ins Scriptverzeichnis wechseln

send_list="$DIR/stv_sender.txt"     # Liste aller Save.TV Sender
send_skip="$DIR/stv_skip.txt"       # Liste der zu überspringenden Sender
stv_log="$DIR/stv_ca_$(date '+%y%m%d_%H%M').log"  # Ausführungs- und Fehlerlog
stv_cred="$DIR/stv_autologin"       # gespeicherte Zugangsdaten
stv_cookie="$DIR/stv_cookie.txt"    # Session Cookie

log_max=6                           # Anzahl zubehaltender Logdateien i.d.R. eine Woche
err_flag=false                      # Flag für Bearbeitungsfehler (true|false)
err_max=9                           # maximal erlaubte Fehler bis Skriptabbruch
                                    # EXIT Codes:   1 kritischer Fehler, Abbruch
                                    #               2 einzelne Channels konnten nicht angelegt werden
vers_max=3                          # Anzahl erneuter Versuche für die Channelanlage
vers_sleep=600                      # Pause in Sekunden zwischen Wdh.Durchläufen

check_version=true                  # immer auf neue Skriptversion prüfen (true|false)

stv_ch_basis=5                      # Basispaket mit 5 Channeln, nur 50h Aufnahme!
stv_ch_xl=20                        # XL-Paket mit 20 Channeln
stv_ch_xxl=200                      # XXL-Paket mit 200 Channeln

anlege_modus=auto                   # auto  (löschen bei Basis & XL, behalten bei XXL)
                                    # immer (alle angelegten Channels werden nicht gelöscht)
                                    # nie   (angelegte Channels werden wieder gelöscht)
check_zombies=false                 # falsch sortierte Aufnahmen löschen (true|false)

tageszeit=('' 'Vormittag' 'Nachmittag' 'Abend' 'Nacht')
wochentag=(So Mo Di Mi Do Fr Sa So)

ca_ch_pre="zz "                     # Prefix-Kennung für vom Skript erstellte Channels
ca_ch_prexxl="_ "                   # alte Prefix-Kennung XXL Channels XXLTEMP
ca_in_pre="_  "                     # Prefix-Kennung für vom Skript erstellten Infotext
ca_in_preurl="_++"                  # dito URLencoded *zwei* Leerzeichen (alphabetisch vor den anderen Channels)


### Logging 
log() {
    echo "$*" | tr -d '"' >> "$stv_log"
}

### Logdatei anlegen, Link stv_ca.log zur aktuellesten 
log_init () {
    touch "$stv_log"
    rm -f "$DIR/stv_ca.log"
    ln -s $(ls stv_ca_*.log | tail -1) "$DIR/stv_ca.log"
}


### alte Logs löschen
log_delete() {
    log_keep="$1"
    log_keep=${log_keep:=$log_max}

    cd "$DIR"
    log_anz=$(ls stv_ca*.log 2>/dev/null | wc -l)
    log_del=$((log_anz - log_keep))
    if [[ $log_del -gt 0 ]]; then
        rm -f $(find * -prune -name 'stv_ca*.log' | head -$((log_del)))
    fi
    ls stv_ca*.log 2>/dev/null | wc -l | xargs 
}


### https://stackoverflow.com/a/10797966
urlencode() {
    local data
    data="$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
    if [[ $? != 3 ]]; then
        echo "[i] Fehler bei URLEncodierung von '$1'"
        log ": Fehler bei URLEncodierung von '$1'"
        exit 1
    fi
    echo "${data##/?}"
    return 0
}


### STV Webserver Login
stv_login() {

    stv_login_cred          # Accountdaten gespeichert?

    while ! $eingeloggt && [ $ausfuehrung == "manual" ] ; do
        stv_login_manual    # Accountdaten manuell eingeben
    done

    if ! $eingeloggt; then
        log ": keine gültige Loginoption für Cron Betrieb vorhanden"
        log ": das Skript im Terminal starten und Option auswählen"
    fi
}


### Login mit gespeicherten Zugangsdaten
stv_login_cred() {
    if [ -f "$stv_cred" ]; then
        IFS=' ' read -r stv_user stv_pass  < "$stv_cred" ; unset IFS
        if [[ $cmd == "-t" ]]; then
            echo "[✓] gespeicherte Logindaten in '$(basename "$stv_cred")' vorhanden"
        fi
        log "Logindaten aus $(basename "$stv_cred") für User $stv_user werden verwendet"

        userpass="sUsername=$stv_user&sPassword=$stv_pass"
        login_return=$(curl -s 'https://www.save.tv/STV/M/Index.cfm' --data "$userpass" --cookie-jar "$stv_cookie")
        grep -q Login_Succeed <<< "$login_return" && eingeloggt=true || eingeloggt=false
    
        if $eingeloggt; then
            log "gespeicherte Zugangsdaten sind gültig"
        else
            echo "[!] Gespeicherte Userdaten sind vorhanden, aber ungültig"
            echo "[i] Manuelles Login ist notwendig"
            log ': Userdaten in '$(basename "$stv_cred")' sind ungültig'
            log "$(basename "$stv_cred"): $(cat "$stv_cred")"
            log "Serverantwort"
            log "$login_return"
        fi
    else
        eingeloggt=false
        log "Keine Zugangsdatendatei '$(basename "$stv_cred")' vorhanden"
    fi
}

### Manuelles Login mit Eingabe der Zugangsdaten
stv_login_manual() {
    rm -f "$stv_cookie"
    rm -f "$stv_cred"
    echo    "[i] Keine gespeicherten Logindaten vorhanden, bitte manuell eingeben"
    read -p "    Save.TV Username: " stv_user
    read -p "    Save.TV Passwort: " stv_pass
    stv_pass=$(urlencode "$stv_pass")

    userpass="sUsername=$stv_user&sPassword=$stv_pass&bAutoLoginActivate=1"
    login_return=$(curl -s 'https://www.save.tv/STV/M/Index.cfm' --data "$userpass" --cookie-jar "$stv_cookie")
    grep -q Login_Succeed <<< "$login_return" && eingeloggt=true || eingeloggt=false
    
    if $eingeloggt; then
        echo    "[✓] Login bei SaveTV als User $stv_user war erfolgreich!"
        echo
        echo    "    Die Zugangsdaten können zum automatischen Login gespeichert werden"
        read -p '[?] Zugangsdaten speichern? (J/N)? : ' login_opt
        case $login_opt in
            [jJ]  )
                echo "$stv_user $stv_pass" >"$stv_cred"
                echo "[i] Zugangsdaten wurden in '$(basename "$stv_cred")' gespeichert"
                ;;
            *)
                echo "[i] Zugangsdaten werden bei jedem Login erneut abgefragt"
                ;;
        esac
    else
        if grep -q "Server Error" <<< "$login_return"; then
            echo "[!] Manuelles Login wegen Serverfehler nicht möglich"
            echo
            echo "[i] Skript wird abgebrochen"
            log ': Manuelles Login wegen Serverfehler nicht möglich, Skriptabbruch'
            log "Serverantwort"
            log "$login_return"
            
            exit 1
        fi
        echo "[!] Login mit diesen Userdaten nicht möglich"
        echo "    Username und Passwort prüfen und Eingabe wiederholen"
        echo
    fi    
}

### STV Webserver Logout
stv_logout() {
            if [ $ausfuehrung == "auto" ]; then
                if [ $check_zombies == true ]; then
                    log "automatischer Zombiecheck ist aktiv"
                    zombie_check
                fi
            fi

            curl -s 'https://www.save.tv/STV/M/obj/user/usLogout.cfm' --cookie "$stv_cookie"  >/dev/null 2>&1
            rm -f "$stv_cookie"
            log "Session Cookie gelöscht"
            eingeloggt=false
}


### Aktuelle Senderliste einlesen oder vom Server holen
senderliste_holen() {
    err_senderliste=false
    if [ ! -f "$send_list" ]; then
        sender_return=$(curl -s 'https://www.save.tv/STV/M/obj/JSON/TvStationGroupsApi.cfm?iFunction=2&loadTvStationsWithAllStationOption=true&bIsMemberarea=true' --cookie "$stv_cookie" )
        if grep -q "Server Error" <<< "$sender_return"; then
            err_senderliste=true
            log ': Senderliste konnte nicht geholt werden'
            log "$sender_return"
            return
        fi
        echo "$sender_return" | sed 's/.*)"},{//g ; s/"},{"ID":/;/g ; s/,"NAME":"/|/g ; s/"ID"://g ; s/"}]}//g' | tr ';' '\n' >"$send_list"
        log 'Aktualisierte Senderliste vom Server geholt'
    fi
    sender_alle=$(wc -l < "$send_list" | xargs)
    cp "$send_list" "$DIR/stv_skip_vorlage.txt"

    if [ ! -f "$send_skip" ]; then
        touch "$send_skip" # leere Datei anlegen
        log 'Liste der nicht aufzunehmenden Sender ist nicht vorhanden, leere Datei angelegt'
    fi
    
    skipindex=0
    while read line; do
        senderskip[skipindex]="$line"
        ((skipindex++))
    done < "$send_skip"

    sendindex=0
    while read line; do
        if [[ "${senderskip[@]}" != *"$line"* ]]; then 
            sender_name[sendindex]=${line#*|}
            sender_id[sendindex]=${line%|*}
            ((sendindex++))
        fi
    done < "$send_list"
    
    # Anzahl der anzulegenden Sender 
    sender_anz=${#sender_id[@]}           
}


### Anzahl der freien Channels prüfen
channelanz_check() {
    # Option anlege_modus 'auto' oder 'nie'
    if [[ ch_max -lt stv_ch_xxl || $anlege_modus = "nie" ]]; then
        channels_behalten=false
    else
        channels_behalten=true
    fi

    if [[ $channels_behalten = "false" ]]; then
        ch_nec=4   # 4 temporäre Channels für die vier Timeslots je Sender
    else    
        ch_nec=$(( sender_anz * 4 ))  # Sender mal die vier Timeslots je Sender
    fi

    # falls zu wenige Channels, prüfen ob anzulegnde Channels bereits vorhanden sind
    ch_dup=0        # doppelte Channels
    if [[ ch_fre -lt ch_nec ]]; then
        log ": benötigt $ch_nec freie Channels, bereits $ch_use von $ch_max Channels belegt"
        log ": Prüfe auf vorhandene Duplikate"
        ch_acc_all="${ch_nn[*]}"   # alle im Account vorhandenen Channelnamen
        for ((sender=0; sender<sender_anz; sender++)); do
            sendername=${sender_name[$sender]}
            ch_dup_sender=0
            for timeframe in 1 2 3 4; do
                if [[ $ch_acc_all == *"$ca_ch_pre$sendername - ${tageszeit[$timeframe]}"* ]]; then
                    log "OK Channel vorhanden: $sendername - ${tageszeit[$timeframe]}"
                    ((ch_dup++))        # Channel für Sender und Timeslot vorhanden 
                    ((ch_dup_sender++)) # Timeslot für diesen Sender vorhanden
                fi
            done
            if [[ ch_dup_sender -eq 4 ]]; then
                sender_id[$sender]=999  # alle Timeslots vorhanden, 999 = Sender skippen
            fi
        done
        log ": $ch_dup Duplikate gefunden"
    fi
}


### Infotext zu verfügbaren Channels ausgeben
channelanz_info() {
    echo "Aufnahme aller Sendungen der nächsten 7 Tage für folgende $sender_anz Sender einrichten:"
    sender_info         # Sendernamen anzeigen          
    echo

    if [[ ch_dup -eq ch_nec ]]; then
        echo "[✓] Es müssen keine zusätzlichen Channels angelegt werden,"
        echo "    alle $ch_nec anzulegenden Channels sind bereits vorhanden."
        channelinfo_set "OK nur Dups"
        log "OK alle $ch_nec anzulegenden Channels sind bereits vorhanden"
        stv_logout
        echo
        echo "Bearbeitungszeit $SECONDS Sekunden"
        log "Ende: $(date)"
        exit 0
    fi

    ch_nec=$((ch_nec-ch_dup))           # Duplikate rausrechnen
    if [[ ch_fre -lt ch_nec ]]; then
        echo "[!] Das Skript benötigt $ch_nec freie Channels zur Programmierung."
        echo "    Aktuell sind bereits $ch_use von $ch_max Channels des Pakets belegt"
        echo "    Manuell unter 'www.save.tv/Meine Channels' mindestens $((ch_nec - ch_fre)) Channels löschen"
        echo "    und das Skript anschließend erneut starten."
        echo "    Alle Channels lassen sich auch mit der Option -c des Skripts löschen."
        log ": benötigt $ch_nec freie Channels, bereits $ch_use von $ch_max Channels belegt"
        log ": mindestens $((ch_nec - ch_fre)) Channels löschen"
        if [[ ch_fre -ne 0 ]]; then
            channelinfo_set "zuwenige freie Channels"
        fi
        stv_logout
        echo "[i] Bearbeitungszeit $SECONDS Sekunden"
        log "Ende: $(date)"
        exit 1
    fi

    if [[ ch_use -gt 0 ]]; then
        echo "[i] Es sind $ch_use bereits angelegte Channels vorhanden, diese blieben erhalten."
    fi

    if [[ $channels_behalten = false ]]; then
        if [[ ch_max -eq stv_ch_basis ]]; then
            echo
            echo "[!] HINWEIS: Sie können mit Ihrem Basispaket nur 50 Stunden aufnehmen!"
            read -p '    Skript trotzdem ausführen (J/N)? : ' basis_check
            if [[ $basis_check == "N" || $basis_check == "n" ]]; then
                log "wg. Basis-Paket manuell beendet"
                stv_logout
                exit 0
            fi
        fi
    else
        echo "    Es werden $ch_nec zusätzliche Channels angelegt, die Channels bleiben erhalten."
    fi
    echo
}


### Sendernamen vierspaltig ausgeben   
sender_info() {
    for (( i=0; i<=${#sender_name[@]}-1; i=i+4)); do
        printf "%-19s %-19s %-19s %-19s\n" "${sender_name[i]}" "${sender_name[i+1]}" "${sender_name[i+2]}" "${sender_name[i+3]}"
    done
}


### Liste der ChannelIDs und Channelnamen
channel_liste() {     
    allchannels=$(curl -sL 'https://www.save.tv/STV/M/obj/channels/JSON/myChannelsApi.cfm?iFunction=1' --cookie "$stv_cookie")
    
    ch_max=$(grep -o "IMAXCHANNELS[^\.]*" <<< "$allchannels"| grep -o "[0-9]*$")
    if [[ -z $ch_max ]]; then
        server_prob=true
        log ": Channelliste konnte nicht geholt werden"
        log "$allchannels"
        return
    fi
    ch_use=$(grep -o "IUSEDCHANNELS[^,]*" <<< "$allchannels"| grep -o "[0-9]*$")
    ch_fre=$((ch_max - ch_use))

    if [[ ch_use -gt 0 ]]; then
        unset ch_rw ch_in ch_nn ch_sid
        # Rohdaten ChannelID und Channelname aus API Rückgabe
        IFS=$'\n' ch_rw=($(grep -o "CHANNELID[^}]*" <<< "$allchannels")) ; unset IFS
        
        # Rohdaten ins Format ChannelID|Channelname bringen
        for ((i=0;i<${#ch_rw[*]}; i++)); do        
            ch_in[i]=$(sed 's/CHANNELID..\([^\.]*\).*SNAME...\([^\"]*\).*/\1|\2/g' <<< "${ch_rw[i]}") # id|name
            ch_nn[i]=$(sed 's/[0-9\|]*//' <<< "${ch_in[i]}") # nur name
        done
        
        # sortieren ch_sid nach ChannelID
        IFS=$'\n' ch_sid=($(sort <<< "${ch_in[*]}" | sort -n )) ; unset IFS
    fi
}


### Channels anhand der Senderliste anlegen
channels_anlegen() {
    sender_bearbeitet=0
    ch_angelegt=0   # Counter für insgesamt angelegte Channel

    echo "Channels: + anlegen  - löschen  F_ehler&Anzahl   Sender: ✓ angelegt  D Duplikat"
    echo -ne "Sender  :"

    for ((sender=0; sender<sender_anz; sender++)); do	
        echo -ne "."
        sendername=${sender_name[$sender]}
        senderid=${sender_id[$sender]}
        err_cha=0   # Zähler für Fehler bei der Channelanlage
        if [[ senderid -gt 0 ]]; then
            ((sender_bearbeitet++))
            if (( (sender) % 5 == 0 )); then
                echo -ne "\b +"
            else
                echo -ne "\b+"
            fi
            if [[ senderid -ne 999 ]]; then
                senderchannel_anlegen "$senderid" "$sendername"
                if [[ $channels_behalten = false ]]; then
                    echo -ne "\b-"
                    channels_loeschen
                fi
                if [[ $err_cha -eq 0 ]]; then
                    echo -ne "\b✓ \b"       # keine Fehler aufgetreten
                else
                    echo -ne "\bF$err_cha"  # Fehler ist aufgetreten
                    err_flag=true           # Fehlerinfo bei Skriptende ausgeben
                fi
            else
                echo -ne "\bD \b"           # ID 999 Duplikat, nichts anzulegen
            fi
        else
            log ": Fehler: Sender $sender ohne ID in Senderliste gefunden!"
            err_flag=true
        fi
    done
    echo
}


### Senderchannels für alle Tageszeiten anlegen
senderchannel_anlegen() {
    senderid="$1"
    sendername="$2"
    ch_sender=0
    log ''
    log "Bearbeite Channels für Sender $sender_bearbeitet von $sender_anz '$sendername'"
    for timeframe in 1 2 3 4; do
        echo -en "$timeframe"
        channel_senderid_timeframe_anlegen "$senderid" "$timeframe" "$sendername"
        if [[ $ch_ok = true ]]; then
            ((ch_angelegt++))
            ((ch_sender++))
        else
            ((err_cha++))
            ((err_ges++))
            err_senderid[err_ges]=$senderid
            err_sendername[err_ges]=$sendername
            err_timeframe[err_ges]=$timeframe
            if [[ err_ges -gt err_max ]]; then
                abbrechen
            fi
        fi
        echo -en "\b"
    done
}


### einzelnen Channel für eine Tageszeit anlegen
channel_senderid_timeframe_anlegen() {

    senderid="$1"
    timeframe="$2"
    sendername="$3"

    ch_title=$(urlencode "$ca_ch_pre$sendername - ${tageszeit[$timeframe]}")

    channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' --cookie "$stv_cookie" --data "channelTypeId=1&sName=$ch_title&TvCategoryId=0&ChannelTimeFrameId=$timeframe&TvSubCategoryId=0&TvStationid=$senderid")  
    if grep -q "BISSUCCESSMSG..true" <<< "$channel_return"; then
        log "+ '${tageszeit[$timeframe]}' "
        ch_ok=true
    else
        log ''
        log ": *** Fehler *** bei $senderid $sendername ${tageszeit[$timeframe]}"

        if grep -q "mit gleichem Zeitraum und gleichen Kategoriebedingungen angelegt" <<< "$channel_return"; then 
            log ": Grund: Channel mit gleichem Zeitraum ist bereits vorhanden!"
            log ": Tip  : Channelliste mit -c prüfen und bereinigen"
        else
            fehlertext=$(grep -F "<title>" <<< "$channel_return" | sed 's/.*title>\(.[^<]*\)<.*/\1/g')
            log ": Grund: $fehlertext"
            # "
        fi
        ch_ok=false
    fi
}


### Fehlerhafte Channel erneut versuchen
iterum() {          #AnzahlVersuche #Pause 
    iter_max="$1"
    iter_sleep="$2"
    echo
    echo "Anlage der fehlerhaften Channels wird erneut versucht"
    log "Channelanlage Wdh: $iter_max Pause: $iter_sleep"
    err_fix=0       # behobene Fehler
    err_vorher=$err_ges

    for (( versuch=1; versuch<=iter_max; versuch++ )); do
        echo "[i] Versuch $versuch von $iter_max, noch $err_ges Channels anzulegen"
        for (( err_akt=1; err_akt<=err_ges; err_akt++ )); do
            if [[ ${err_senderid[err_akt]} -ne 0 ]]; then   # SenderID 0 'nicht mehr versuchen'
                senderid=${err_senderid[err_akt]}
                sendername=${err_sendername[err_akt]}
                timeframe=${err_timeframe[err_akt]}
                ch_title=$(urlencode "$ca_ch_pre$sendername - ${tageszeit[$timeframe]}")
                channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' --cookie "$stv_cookie" --data "channelTypeId=1&sName=$ch_title&TvCategoryId=0&ChannelTimeFrameId=$timeframe&TvSubCategoryId=0&TvStationid=$senderid")            
                if grep -q "BISSUCCESSMSG..true" <<< "$channel_return"; then
                    ((err_ges--)); ((err_fix++))
                    err_senderid[err_akt]=0         # Flag 'nicht mehr versuchen'
                    echo " ✓  Erfolgreich angelegt: '$sendername' '${tageszeit[$timeframe]}'"
                    log "Im $versuch. Versuch: + '$sendername' '${tageszeit[$timeframe]}'"
                else
                    if grep -q "mit gleichem Zeitraum und gleichen Kategoriebedingungen angelegt" <<< "$channel_return"; then
                        echo " ✓  Channel war doppelt : '$sendername' '${tageszeit[$timeframe]}'" 
                        err_senderid[err_akt]=0     # Flag 'nicht mehr versuchen'
                        ((err_fix++))
                    else
                        echo " !  Fehler bei          :'$sendername' '${tageszeit[$timeframe]}'" 
                    fi
                fi
            fi
        done
        if [[ $err_fix -eq $err_vorher ]]; then
            break   # alle Fehler gefixt, kein weiterer Durchlauf notwendig
        fi
        echo "    Warte $iter_sleep Sekunden bis zum nächsten Durchlauf"
        sleep "$iter_sleep"   # Pause zwischen Durchläufen
    done

    if [[ $err_fix -eq $err_vorher ]]; then
        echo "[✓] Alle $err_vorher Channels konnten erfolgreich angelegt werden."
        log "Alle $err_vorher Channels angelegt"
        err_flag=false
    else
        echo "[i] Es konnten $err_fix von $err_ges Channels angelegt werden."
        log "$err_fix von $err_ges Channels angelegt."
    fi
    echo
}


### Channel löschen: bestehende Programmierung und Aufnahmen bleiben erhalten
channels_loeschen() {        
    channel_liste  
    ch_loeschen=$((ch_use - ch_start))   # wieviele Channels sind vom Skript angelegt worden und zulöschen        
    if [[ ch_loeschen -gt 0 ]]; then
        log ''
        for ((i=ch_start;i<ch_use; i++)); do
            chid=$(grep -o "^[^\|]*" <<< "${ch_sid[i]}")           
            # channel_id
            # deleteProgrammedRecords 0=behalten 1=löschen
            # deleteReadyRecords 0=behalten 1=löschen
            delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$chid&deleteProgrammedRecords=0&deleteReadyRecords=0" --cookie "$stv_cookie")
            if grep -q "Channel gelöscht" <<< "$delete_return"; then
                log "- '$(sed 's/.* - //' <<< "${ch_sid[i]}")' "
            else
                ((err_cha++))
                ((err_ges++))
                fehlertext=$(grep -F "<title>" <<< "$delete_return" | sed 's/.*title>\(.[^<]*\)<.*/\1/g')
                log ''
                log ": *** Fehler *** beim Löschen $(sed 's/|/ /' <<< "${ch_sid[i]}")"
                log ": Grund: $fehlertext"
                if [[ err_ges -gt err_max ]]; then
                    abbrechen
                fi
            fi
        done
    log ''
    fi
}


### legt einen Stichwortchannel mit Status und Uhrzeit des Laufs an
channelinfo_set() {
    infotext=$(urlencode "$1")
    if [[ $check_version == "true" ]]; then
        versioncheck
        if [[ $version_aktuell == "true" ]]; then
            version_info=""
        else
            version_info=urlencode " Neue Version"
        fi
    else
        version_info=""
    fi
    
    ch_text="sTelecastTitle=$ca_in_preurl$infotext+${wochentag[$(date '+%w')]}+$(date '+%m%d+%H%M')$version_info&channelTypeId=3"
    channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' --cookie "$stv_cookie" --data "$ch_text")  
}


### löscht Pseudochannel mit letztem Status
channelinfo_del() {
    stvchinfo=$(grep -o "[0-9]*|$ca_in_pre" <<< "${ch_in[*]}" | head -1 | grep -o "[0-9]*") 
    if [[ stvchinfo -gt 0 ]]; then
        delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$stvchinfo&deleteProgrammedRecords=0&deleteReadyRecords=0" --cookie "$stv_cookie")
        channel_liste   # aktualisierte Channelliste holen und erneut Anzahl der Channels ermitteln
    fi
}


# löscht alle Channels eines Sendernamens
channel_name_del() {
    sendername="$1"
    unset ch_name_id
    IFS=$'\n' ch_name_id=($(grep -o "[0-9]*|$ca_ch_pre$sendername - [A-Za-z]*" <<< "${ch_in[*]}")); unset IFS
    if [[ ${#ch_name_id[*]} -gt 0 ]]; then
        ch_name_id_del=0
        for (( cni=0; cni<=${#ch_name_id[@]}; cni++)); do
            delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=${ch_name_id[cni]%|*}&deleteProgrammedRecords=1&deleteReadyRecords=1" --cookie "$stv_cookie")
            if [[ "$delete_return" == *"Channel und ausgewählte Aufnahmen gelöscht"* ]]; then
                log "Channel ${ch_name_id[cni]} gelöscht"
                ((ch_name_id_del++))
            else
                log "Channel ${ch_name_id[cni]} konnte nicht gelöscht werden"
            fi
        done
        printf "[✓] %-16s %-29s\n" "'$sendername'" "$ch_name_id_del Channels gelöscht"
    fi
    channel_liste   # aktualisierte Channelliste holen
}

### Vom Skript angelegte Channels löschen 
channel_cleanup() {
    if [[ $ch_use -gt 0 ]]; then
        err_flag=false      # Fehler beim Löschen
        ch_del=0            # Anzahl gelöschter Channels
        # ch_use_vor=$ch_use
        echo -n "    Lösche $ca_ch_anz Channels : "  
        for ch_test in "${ch_in[@]}"; do
            if [[ $ch_test == *[0-9]"|$ca_ch_pre"* ]] || [[ $ch_test == *[0-9]"|$ca_ch_prexxl"* ]]; then # XXLTEMP
                stvchinfo=$(grep -o "^[0-9]*" <<< "$ch_test")
                if [[ stvchinfo -gt 0 ]]; then
                    log "CA Channel löschen $ch_test"
                    delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$stvchinfo&deleteProgrammedRecords=0&deleteReadyRecords=0" --cookie "$stv_cookie")   
                    if [[ "$delete_return" == *"Channel gelöscht"* ]]; then 
                        echo -n "."
                        ((ch_del++))
                    else
                        err_flag=true
                        echo -n "F"
                        log ": Fehler beim Löschen von channelId=$stvchinfo"
                        log "$(sed 's/.*SMESSAGE...\(.*\)...BISSUCCESSMSG.*/\1/g ; s/\\//g' <<< "$delete_return")"
                    fi
                fi
            fi
        done
        echo -n '✓'
        echo
        echo "[✓] Es wurden $ch_del Channels gelöscht."
        if [[ $err_flag = true ]]; then
            echo "[!] Beim Löschen sind Fehler aufgetreten, Details siehe Logfile $(basename ''"$stv_log"'')!"
        fi   
    else
        echo "[i] Es sind keine Channels vorhanden."
    fi
}


### Skipliste, Channelliste, Videoarchiv aufräumen
inhalte_bereinigen() {
    cleanup_check=$1    # bei --cleanupauto 'J'
    echo "                Bereinigung von nicht mehr benötigten Inhalten"
    echo "    Skipliste   : Channels, Aufnahmen und Programmierungen"
    echo "    Channelliste: vom Skript angelegte Channels"
    echo "    Videoarchiv : Aufnahmen mit vordatiertem Timestamp"
    echo ; echo 
    sender_bereinigen

# bei manuellem Aufruf zusätzlich Channelaufräumen und Zombieslöschen anbieten
    if [[ $cleanup_modus == "manuell" ]]; then
        channelrestechecken
        zombie_check
    fi
}


### Skipliste Aufnahmen- und Programmierungsreste löschen
sender_bereinigen() {
    echo " 1/3  Programmierungen und Aufnahmen der Sender der Skipliste löschen"
    if [ ! -f "$send_skip" ]; then
        touch "$send_skip" # leere Datei anlegen
        log 'Liste der nicht aufzunehmenden Sender war nicht vorhanden, leere Datei wurde angelegt'
    fi

    skipindex=0
    while read line; do
        if [[ -n $line ]]; then
            skip_name[skipindex]=${line#*|}
            skip_id[skipindex]=${line%|*}      
            ((skipindex++))
        fi  
    done < "$send_skip"
    echo

    if [[ skipindex -gt 0 ]]; then
        unset skip_name_sorted
        IFS=$'\n' skip_name_sorted=($(sort <<<"${skip_name[*]}")); unset IFS
        echo "Die Liste der nicht aufzunehmenden Sender '$(basename "$send_skip")' beinhaltet zur Zeit:"
        for (( i=0; i<=${#skip_name_sorted[@]}; i=i+4)); do
            printf "%-19s %-19s %-19s %-19s\n" "${skip_name_sorted[i]}" "${skip_name_sorted[i+1]}" "${skip_name_sorted[i+2]}" "${skip_name_sorted[i+3]}"
        done

        if [[ $cleanup_check == "J" ]]; then
            echo "[i] Für diese ${#skip_name[@]} Sender werden die vorhandenen Channels, Programmierungen"
            echo "    und aufgenommenen Sendungen endgültig gelöscht"
            log 'Bereinigung im Batchmodus'
        else        
            echo
            echo "[i] Sollen für diese ${#skip_name[@]} Sender die vorhandenen Channels, Programmierungen"
            echo "    und die bereits aufgenommenen Sendungen *endgültig* gelöscht werden?"
            read -p '[?] Alles bereinigen (J/N)? : ' cleanup_check
        fi
        SECONDS=0 
        echo 
        if [[ $cleanup_check == "J" || $cleanup_check == "j" ]]; then
            echo "[i] Lösche die Channels, Programmierungen und Aufnahmen der Sender der Skipliste"
            channel_liste
            # Webinterface umschalten auf ungruppierte Darstellung wg. einzelner TelecastIds
            list_return=$(curl -s 'https://www.save.tv/STV/M/obj/user/submit/submitVideoArchiveOptions.cfm?bShowGroupedVideoArchive=false' --cookie "$stv_cookie" --data '')

            del_ids_tot=0       # Gesamtanzahl der TelecastIds
            del_ids_err=false   # Flag für mgl. Fehler

            for (( skip=0; skip<=${#skip_name[@]}; skip++)); do
                sendername=${skip_name[skip]}
                senderid=${skip_id[skip]}
                channel_name_del "$sendername"      # Channels für Sender löschen

                if [[ senderid -gt 0 ]]; then     
                    list_return=$(curl -s "https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm" --cookie "$stv_cookie" --data "iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=0&sSortOrder=StartDateDESC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=$senderid&bHighlightActivation=false&bVideoArchiveGroupOption=false&bShowRepeatitionActivation=false")
                    temp_te=$(grep -o "IENTRIESPERPAGE.*ITOTALPAGES"<<< "$list_return" | grep -o '"ITOTALENTRIES":[0-9]*'); totalentries=${temp_te#*:}
                    totalpages=$(grep -o '"ITOTALPAGES":[0-9]*' <<< "$list_return" | grep -o "[0-9]*$")
                    log "$sendername hat $totalentries zu löschende Einträge auf $totalpages Seiten" 
                
                    if [[ totalpages -gt 0 ]]; then
                        printf "[i] %-16s %-29s" "'$sendername'" "lösche $totalentries Einträge"
                        del_ids_tot=$((del_ids_tot + totalentries))  
                        for ((page=1; page<=totalpages; page++)); do
                            list_return=$(curl -s "https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm" --cookie "$stv_cookie" --data "iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=0&sSortOrder=StartDateDESC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=$senderid&bHighlightActivation=false&bVideoArchiveGroupOption=false&bShowRepeatitionActivation=false")
                            delete_ids=$(grep -o "TelecastId=[0-9]*" <<< "$list_return" | sed 's/TelecastId=\([0-9]*\)/\1%2C/g' | tr -d '\n')                        
                            if [ -n "$delete_ids" ]; then               
                                log "Lösche $senderid|$sendername : $delete_ids"
                                delete_return=$(curl -s "https://www.save.tv/STV/M/obj/cRecordOrder/croDelete.cfm" -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --cookie "$stv_cookie" --data "lTelecastID=$delete_ids")
                                if [[ "$delete_return" == *"ok"* ]]; then 
                                    echo -n "."
                                else
                                    echo -n "F"
                                    del_ids_err=true
                                fi
                                log "$(grep -oF '%2C' <<< "$delete_ids" | wc -l) von $sendername gelöscht : $delete_return"
                            fi
                        done
                        echo -n '✓'
                        echo
                    else
                        printf "    %-16s %-50s\n" "'$sendername'" "muß nicht gesäubert werden"  
                    fi
                fi
            done

            channel_liste   # aktualisierte Channelliste holen
            if [[ $del_ids_err = true ]]; then
                echo "[!] Beim Löschen sind Fehler aufgetreten, Details siehe Logfile $(basename ''"$stv_log"'')!"
                echo
            fi
            if [[ del_ids_tot -gt 0 ]]; then
                echo "[i] Es wurden insgesamt $del_ids_tot Aufnahmen und Programmierungen gelöscht."
            else
                echo "[i] Es sind keine Aufnahmen und Programmierungen vorhanden."
            fi
        else
            echo "[!] Bereinigung abgebrochen, es wurde nichts gelöscht."
        fi
    else
        echo "[i] Die Skipliste '$(basename "$send_skip")' ist leer, Bereinigung übersprungen."
    fi
}


### auf Channels beginnend mit 'zz ' prüfen und löschen
channelrestechecken() {
    echo
    echo
    echo ' 2/3    Prüfe die Channelliste auf von STV CatchAll angelegte Channels'
    echo
    channel_liste       # Liste vorhandener Channel
    channelinfo_del     # prüfen ob Pseudochannel gelöscht werden muß

    ca_ch_anz=$(grep -o "[0-9]*|${ca_ch_pre}[^ ]" <<< "${ch_in[*]}" | wc -l | xargs) # xarg entfernt whitespace
    ca_ch_anzxxl=$(grep -o "[0-9]*|${ca_ch_prexxl}[^ ]" <<< "${ch_in[*]}" | wc -l | xargs) # XXLTEMP
    ca_ch_anz=$((ca_ch_anz + ca_ch_anzxxl)) # XXLTEMP - aktuell noch alten Prefix _ mit berücksichtgen
    if [[ $ca_ch_anz -gt 0 ]]; then
        echo "[i] Es sind $ca_ch_anz vom STV CatchAll Skript angelegte Channels vorhanden,"
        echo "    beim Channellöschen bleiben bereits erfolgte Aufnahmen *erhalten*."
        echo
        echo "    Die Option 'L' zeigt eine Liste der gefundenen STV Channels an."
        read -p "[?] Diese $ca_ch_anz Channels und zugehörigen Programmierungen löschen (J/N/L)? : " ch_cleanup_check
        if [[ $ch_cleanup_check == "L" || $ch_cleanup_check == "l" ]]; then
            echo
            echo "[i] Die von STV CatchAll angelegten Channels beginnen immer mit '$ca_ch_pre' '$ca_ch_prexxl'" # XXLTEMP
            for ch_test in "${ch_in[@]}"; do
                grep -o "[0-9]*|${ca_ch_pre}[^|]*" <<< "$ch_test"
                grep -o "[0-9]*|${ca_ch_prexxl}[^|]*" <<< "$ch_test"   # XXLTEMP
            done
            read -p "[?] Diese $ca_ch_anz Channels und zugehörigen Programmierungen löschen (J/N)? : " ch_cleanup_check
        fi

        # Sicherheitsabfrage wg. XXL Upgradechanneln
        if [[ $ch_cleanup_check == "J" || $ch_cleanup_check == "j" ]]; then
            if [[ $ca_ch_anz -gt $ch_max ]]; then
                echo
                echo "[!] Achtung, von den $ca_ch_anz Channels sind nur $ch_max in ihrem STV Paket enthalten,"
                echo "    die übrigen $((ca_ch_anz - ch_max)) Channels können *nicht* neu angelegt werden."
                read -p "[?] Trotzdem die Channels und zugehörigen Programmierungen löschen (J/N)? : " ch_cleanup_check
            fi
        fi
        if [[ $ch_cleanup_check == "J" || $ch_cleanup_check == "j" ]]; then
            channel_cleanup
        else
            echo "[!] Bereinigung abgebrochen, es wurden keine Channels gelöscht."
        fi
    else
        echo '[i] Es sind keine von STV CatchAll angelegte Channels vorhanden.'
    fi
}

### chronologisch falsch einsortierte Aufnahmen löschen DSTARTDATE in der Zukunft
zombie_check() {
    if [ $ausfuehrung == "manual" ]; then
        echo
        echo
        echo ' 3/3    Prüfe das Videoarchiv auf falsch einsortierte Aufnahmen'
        echo
    fi
    log "Prüfe Videoarchiv auf Zombie Aufnahmen"
    # Umschalten auf ungruppierte Darstellung der Titel
    list_return=$(curl -s 'https://www.save.tv/STV/M/obj/user/submit/submitVideoArchiveOptions.cfm?bShowGroupedVideoArchive=false' --cookie "$stv_cookie" --data '')

    prog_return=$(curl -s 'https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm' --cookie "$stv_cookie" --data 'iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=0&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=1&sSortOrder=StartDateDESC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2020-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=0&iTvStationId=0&bHighlightActivation=false&bVideoArchiveGroupOption=0&bShowRepeatitionActivation=false')
    IFS=$'\n'
        prog_dstart=($(grep -o 'DSTARTDATE"[^ ]*' <<<"$prog_return" | grep -o '"20.*'))
        prog_id=($(grep -o 'TelecastId=[0-9]*' <<<"$prog_return" | grep -o '[0-9]*$'))
        prog_start=($(grep -o 'DSTARTDATEBUFFER[^,]*' <<<"$prog_return" | grep -o '20[^"]*'))
        prog_send=($(grep -o 'STVSTATIONNAME":"[^"][^"]*' <<<"$prog_return" | sed 's/STVSTATIONNAME":"//'))        
        prog_title=($(grep -o 'STITLE":"[^"][^"]*' <<<"$prog_return" | sed 's/STITLE":"//'))
    unset IFS

    # Sicherheitsüberprüfung, falls STV den Seitencode ändert
    if [[ ${#prog_dstart[*]} -eq 35 && ${#prog_id[*]} -eq 35 ]]; then
        heute=$(date '+"%Y-%m-%d') # das " soll die Erkennung als Zahl verhindern
        zom_ids=""
        zom_anz=0
        for (( i=0; i<${#prog_dstart[*]}; i++ )); do
            if [[ ${prog_dstart[i]} > $heute ]]; then # Aufnahme aus der Zukunft
                ((zom_anz++))
                zom_ids="$zom_ids${prog_id[i]} "
                if [[ zom_anz -eq 1 ]]; then
                    echo "    Aufzeichnungsbeginn Sender Sendung"
                    log "Telecast DSTARTDATE DSTARTDATEBUFFER    Sender Sendung"
                fi
                echo "    ${prog_start[i]} ${prog_send[i]} ${prog_title[i]}"
                log "${prog_id[i]} ${prog_dstart[i]} ${prog_start[i]} ${prog_send[i]} ${prog_title[i]}"
            fi
        done

        if [[ $zom_anz -gt 0 ]]; then
            log "$zom_anz Zombies gefunden"
            if [ $ausfuehrung == "manual" ]; then
                read -p "[?] Diese $zom_anz Aufnahmen löschen (J/N)? : " zom_check
            else
                zom_check="j"
            fi

            if [[ $zom_check == "J" || $zom_check == "j" ]]; then
                log "Gefundene Zombies: $zom_ids"
                zom_ids="${zom_ids// /%2C}" # Komma als Trenner
                delete_return=$(curl -s "https://www.save.tv/STV/M/obj/cRecordOrder/croDelete.cfm" -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --cookie "$stv_cookie" --data "lTelecastID=$zom_ids")
                if [[ "$delete_return" == *"ok"* ]]; then 
                    echo "[✓] alle $zom_anz Aufnahmen wurden gelöscht"
                    log "OK $zom_anz Zombies gelöscht"
                else
                    echo "[!] Fehler beim Löschen der $zom_anz Aufnahmen aufgetreten"
                    echo "    bei Bedarf das Skript nochmal mit der Option -c ausführen"
                    log "Fehler beim Löschen der Zombies"
                    log "Err: zu löschende IDs $zom_ids , Antwort"
                    log "$delete_return"
                fi
            else
                echo "[!] Zombiebereinigung abgebrochen, es wurde nichts gelöscht."
            fi
        else
            echo "[✓] keine falsch einsortierten Aufnahmen vorhanden"
            log "OK Keine Zombies vorhanden!"
        fi
    else
        echo "[!] Zombielöschen abgebrochen, es wurde nichts gelöscht. Details siehe Log" 
        log "Fehler im STV Datenformat, siehe prog_return.json"
        echo "$prog_return" >"prog_return.json"
    fi
}


### Abbruch wegen zuvieler Fehler
abbrechen() {
    echo
    echo "[!] Es sind $err_ges Fehler aufgetreten, das Skript wird vorzeitig beendet."
    log  ": Es sind $err_ges Fehler aufgetreten, das Skript wird vorzeitig beendet."
    echo "    Liste der aufgetretenen Fehler:"
    sed '/^: /,$!d ; s/^: /    /' stv_ca.log
    fkt_stoerung_info
    echo "[i] In der letzten Stunde wurden $stoer_as_std Störungen auf AlleStörungen.de gemeldet"
    echo "    Stand $stoer_as_akt <https://AlleStörungen.de/stoerung/save-tv/>"
    log  ": AlleStörungen.de meldet in der letzten Stunde $stoer_as_std Meldungen"
    channelinfo_set "ABGREBROCHEN FEHLER $err_ges"
    stv_logout
    exit 1
}


### Funktionstest Channelanlage prüfen
fkt_ch_anlegen() {
    ch_text="sTelecastTitle=$ca_in_preurl+$(date '+%m%d+%H%M')+Funktionstest&channelTypeId=3"
    channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' --cookie "$stv_cookie" --data "$ch_text")
    if grep -q "BISSUCCESSMSG..true" <<< "$channel_return"; then
        ch_ok=true
    else
        ch_ok=false
        log "Testchannel konnte nicht angelegt werden"
        log "REQUEST"
        log ": curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' --cookie \"$stv_cookie\" --data \"$ch_text\""
        log "ANSWER"
        log ": $channel_return"
    fi
}


### Funktionstest angelegten Channel löschen
fkt_ch_delete() {
    for ch_test in "${ch_in[@]}"; do
        if [[ $ch_test == *Funktionstest* ]]; then
            stvchinfo=$(grep -o "^[0-9]*" <<< "$ch_test")
            if [[ stvchinfo -gt 0 ]]; then
                delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$stvchinfo&deleteProgrammedRecords=0&deleteReadyRecords=0" --cookie "$stv_cookie")
                if [[ "$delete_return" == *"Channel gelöscht"* ]]; then 
                    ch_ok=true
                else
                    ch_ok=false
                fi
            fi
        fi
    done
}

### Störungen _as_ AlleStörungen.de 
fkt_stoerung_as() {
    stoer_as=$(curl -sm9 "https://xn--allestrungen-9ib.de/stoerung/save-tv/")
    if [ -n "$stoer_as" ]; then
        stoer_as_tag=$(grep -o "20[123][0-9]-[^}]*}," <<<"$stoer_as" | tail -96 | awk '{stoer += $3} END{print stoer}')
        stoer_as_std=$(grep -o "20[123][0-9]-[^}]*}," <<<"$stoer_as" | tail -4 | awk '{stoer += $3} END{print stoer}')
        stoer_as_let=$(grep -o "20[123][0-9]-[^}]*}," <<<"$stoer_as" | grep -v "y: 0" | tail -1 | grep -o "20[^.]*" | tr 'T' ' ' | head -1)
        stoer_as_akt=$(grep -o "20[123][0-9]-[^}]*}," <<<"$stoer_as" | tail -1 | grep -o "20[^']*" | tr 'T' ' ' | head -1)
        if [[ -z "$stoer_as_std" || $stoer_as_std -eq 0 ]]; then stoer_as_std="keine" ; fi
        if [[ -z "$stoer_as_tag" || $stoer_as_tag -eq 0 ]]; then stoer_as_tag="keine" ; fi
        if [[ -z "$stoer_as_akt" ]]; then stoer_as_akt="siehe" ; fi
    fi
}

fkt_stoerung_info() {
    fkt_stoerung_as     # AlleStörungen
    echo "    Auf AlleStörungen.de wurden in den letzten 24 Std. $stoer_as_tag Störungen gemeldet"
    if [[ $stoer_as_tag != "keine" ]]; then
        echo "    Letzte Meldung um $stoer_as_let. Letzte Stunde gab es $stoer_as_std Meldungen."
    fi
    echo "    Stand $stoer_as_akt <https://AlleStörungen.de/stoerung/save-tv/>" 
    echo
}

### Störungsinfo und Logausgabe im Fehlerfall
fkt_error_exit() {
    echo '[i] Prüfe auf von anderen Usern gemeldete Störungen'
    fkt_stoerung_info
    stv_logout
    echo "[i] Funktionstest wurde in $SECONDS Sekunden abgeschlossen"
    log "$(date) Funktionstest wurde in $SECONDS Sekunden abgeschlossen"
    exit 1
}

funktionstest() {
    clear ; banner

    cmd="-t"
    echo 'Funktionstest auf korrekte Logindaten und verfügbare Channels wird durchgeführt'
    echo

    # 01 Script testen
    log "$(date) Funktionstest begonnen"

    versioncheck
    if [[ $check_version == "true" ]]; then
        echo "[✓] Automatische Versionsüberprüfung ist AN"
    else
        echo "[!] Automatische Versionsüberprüfung ist AUS"
    fi

    if [[ $version_aktuell == "true" ]]; then
        echo "[✓] Skriptversion ist aktuell"
    else
        echo "[i] Neue Skriptversion vom '$version_onl' ist verfügbar, Update wird empfohlen"
    fi

    if [ ! -f "$stv_log" ]; then
        echo "[!] Keine Schreibrechte im Skriptverzeichnis vorhanden"
        echo "    Verzeichnis $DIR prüfen"
        exit 1
    else
        echo "[✓] Schreibrechte im Skriptverzeichnis OK"
    fi
    
    command -v curl >/dev/null 2>&1 || { echo >&2 "[!] 'curl' wird benötigt, ist aber nicht installiert"; exit 1; }

    # 02 login
    echo
    stv_login

    if $eingeloggt; then
        SECONDS=0 
        echo "[✓] Login mit UserID $stv_user erfolgreich"
    else
        echo "[!] Fehler beim Login mit UserID $stv_user!"
        echo "    Bitte in $(basename "$stv_cred") Username und Passwort prüfen,"
        echo '    und danach den Funktionstest mit --test erneut starten.'
        echo
        echo "    Aktueller Inhalt von $(basename "$stv_cred"):"
        cat "$stv_cred" 2>/dev/null
        echo
        echo '    Sind die Userdaten korrekt, kann auch eine allgemeine Störung vorliegen'
        fkt_stoerung_info 
        exit 1
    fi
        
    # 03 gebuchtes Paket, freie Channels, Senderliste, Aufnahmen
    paket_return=$(curl -s 'https://www.save.tv/STV/M/obj/user/JSON/userConfigApi.cfm?iFunction=2' --cookie "$stv_cookie")
    paket_art=$(sed 's/.*SCURRENTARTICLENAME":"\([^"]*\).*/\1/' <<<"$paket_return")
    paket_bis=$(sed 's/.*DCURRENTARTICLEENDDATE":"\([^ ]*\).*/\1/' <<<"$paket_return")
    stv_user=$(sed 's/.*SUSERNAME":\([^.]*\).*/\1/' <<<"$paket_return")

    rec_return=$(curl -s 'https://www.save.tv/STV/M/obj/user/JSON/userConfigApi.cfm?iFunction=1' --cookie "$stv_cookie")
    rec_vor=$(sed 's/.*ISTARTRECORDINGBUFFER":\([0-9]*\).*/\1/' <<<"$rec_return")
    rec_nach=$(sed 's/.*IENDRECORDINGBUFFER":\([0-9]*\).*/\1/' <<<"$rec_return")
    rec_auto=$(sed 's/.*BAUTOADCUTENABLED":\([0-9]*\).*/\1/' <<<"$rec_return")
    if [[ $rec_auto = "1" ]]; then rec_auto="AN" ; else rec_auto="AUS" ; fi
    
    if [[ $paket_art != *"Save"* ]]; then
        echo "[!] Gebuchtes Save.TV Paket konnte NICHT ermittelt werden."
        echo '    Es kann auch eine allgemeine Störung vorliegen'
        fkt_stoerung_info
        log "Fehler bei Paketname: '$paket_return'"
        exit 1
    fi

    channel_liste
    if [[ $server_prob = true ]]; then
        echo "[!] Anzahl verfügbarer Channels konnte NICHT ermittelt werden."
        echo "    Wahrscheinlichste Ursache ist ein Serverproblem"
        echo
        log "Fehler beim Holen der Channelliste, die wahrscheinlichste"
        log "Ursache ist ein Timeoutfehler"
        fkt_error_exit
    fi

    prog_return=$(curl -s 'https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm' --cookie "$stv_cookie" --data 'iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=2&sSortOrder=StartDateASC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=0&bHighlightActivation=false&bVideoArchiveGroupOption=0&bShowRepeatitionActivation=false')
    prog_zukunft=$(sed 's/.*ITOTALENTRIES\":\([0-9]*\).*/\1/'<<< "$prog_return")

    prog_return=$(curl -s 'https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm' --cookie "$stv_cookie" --data 'iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=1&sSortOrder=StartDateDESC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=0&bHighlightActivation=false&bVideoArchiveGroupOption=0&bShowRepeatitionActivation=false')
    prog_vorhanden=$(sed 's/.*ITOTALENTRIES\":\([0-9]*\).*/\1/'<<< "$prog_return")

    echo
    echo "[i] Paket '$paket_art' mit Laufzeit bis zum $paket_bis"
    echo "    $ch_max Channels enthalten, davon aktuell $ch_use benutzt"
    echo "    Channelanlegemodus '$anlege_modus' wird verwendet"
    echo "    Sendungen aufgenommen: $prog_vorhanden  Sendungen programmiert: $prog_zukunft"
    echo
    echo "[i] Eingestellte Pufferzeiten und Aufnahmeoptionen"
    printf "%-3s %-21s %-21s %-21s\n" "   " "Vorlaufzeit: $rec_vor Min." "Nachlaufzeit: $rec_nach Min." "Auto-Schnittlisten: $rec_auto"
    echo

    # alte Senderliste sichern, neue holen
    mv "$send_list" "$send_list.old" 2> /dev/null
    senderliste_holen
    if [ $err_senderliste = true ]; then
        mv "$send_list.old" "$send_list" 2> /dev/null
        echo "[!] Aktuelle Senderliste konnte NICHT geholt werden"
        echo
        fkt_error_exit
    else
        rm -f "$send_list.old"
    fi

    skipindex=0
    while read line; do
        if [[ -n $line ]]; then
            skip_name[skipindex]=${line#*|}
            skip_id[skipindex]=${line%|*}      
            ((skipindex++))
        fi  
    done < "$send_skip"
    unset skip_name_sorted
    IFS=$'\n' skip_name_sorted=($(sort <<<"${skip_name[*]}")); unset IFS

    
    if [[ skipindex -eq 0 ]]; then
        echo "[!] Keine ausgeschlossenen Sender in '$(basename "$send_skip")' vorhanden,"
        echo "    alle $sender_anz aktuell bei Save.TV verfügbaren Sender werden aufgenommen."
    else
        echo "[i] Aktuell sind $sender_alle Sender bei Save.TV verfügbar."
        echo "[i] Die Liste der ausgeschlossenen Sender '$(basename "$send_skip")' beinhaltet:"
        for (( i=0; i<=${#skip_name[@]}; i=i+3)); do
            printf "%-3s %-21s %-21s %-21s\n" "   " "${skip_name[i]}" "${skip_name[i+1]}" "${skip_name[i+2]}"
        done
    fi
    echo 

    # 04 channel anlegen
    if [[ ch_fre -eq 0 ]]; then
        echo '[!] Für den Test wird ein freier Channel benötigt.'
        echo '    Falls die Channelanlage getestet werden soll, mindestens einen Channel'
        echo '    manuell löschen und danach den Funktionstest mit --test erneut starten.'
    fi
    if [[ ch_fre -lt 0 ]]; then
        echo '[!] Es sind mehr Channels angelegt, als im gebuchten Paket verfügbar sind!'
        echo '    Diese können z.B. beim temporären XXL Upgrade 05/2020 angelegt worden sein,'
        echo '    sie sollten nur bei dringendem Bedarf gelöscht werden, da eine Neuanlage'
        echo '    nur im Rahmen des gebuchten Pakets möglich ist.'
        echo 
        echo '[i] Der Channeltest und der täglichen Infochannel werden übersprungen!'
    fi

    if [[ ch_fre -gt 0 ]]; then
        fkt_ch_anlegen
        if [[ $ch_ok = true ]]; then
            echo "[✓] Testchannel erfolgreich angelegt"
        else
            echo "[!] Testchannel konnte NICHT angelegt werden"
            echo "    Details siehe Logdatei $stv_log"
            echo
            fkt_error_exit
        fi

        # 05 channelliste lesen
        channel_liste
        echo "[✓] aktualisierte Channelliste eingelesen"
        
        # 06 channel löschen
        fkt_ch_delete
        if [[ $ch_ok = true ]]; then
            echo "[✓] Testchannel erfolgreich gelöscht"
        else
            echo "[!] Testchannel konnte NICHT gelöscht werden"
            echo "    Details siehe Logdatei $stv_log"
            echo
            fkt_error_exit
        fi
    fi

    # 07 ausloggen
    echo
    stv_logout
    echo "[✓] Logout durchgeführt"
    echo
    echo "[i] Prüfe auf von anderen Usern gemeldete Störungen"
    fkt_stoerung_info

    # Status ausgeben
    echo "[i] Funktionstest wurde in $SECONDS Sekunden abgeschlossen"
    log "$(date) Funktionstest wurde in $SECONDS Sekunden abgeschlossen"
    exit 0
}


### Test auf neuere Skriptversion
versioncheck() {
    version_onl=$(curl -s "https://raw.githubusercontent.com/einstweilen/stv-catchall/master/stv-version-check" |
                          grep -o "20[12][0-9][01][0-9][0-3][0-9]")
    if [[ $version_onl -gt $version_ist ]]; then
        version_aktuell=false
    else 
        version_aktuell=true
    fi
}


### Hilfetext anzeigen
hilfetext() {
    echo "CatchAll-Funktion für alle SaveTV Sender programmieren"
    echo
    echo "-t, --test     Skripteinstellungen und SaveTV Account überprüfen"
    echo
    echo "-c, --cleanup  'Reste aufräumen' Funktion aufrufen"
    echo
    echo "--cleanupauto  'Reste aufräumen' ohne Sicherheitsabfrage ausführen,"
    echo "               anschließend wird die Catchall Channel Einrichtung durchgeführt"
    echo "               ** Gelöschte Aufnahmen können nicht wiederhergestellt werden **"
    echo
    echo "-?, --help     Hilfetext anzeigen"
    echo 
    echo "Optional: '$(basename "$send_skip")' anpassen, um Sender von der Programmierung auszunehmen"
    echo
    echo "Vollständige Anleitung unter https://github.com/einstweilen/stv-catchall"
}


### Headergrafik
banner() {
    echo '                _______ _______ _    _ _______  _______ _    _'
    echo '                |______ |_____|  \  /  |______     |     \  /'
    echo '                ______| |     |   \/   |______     |      \/ ' 
    echo '                =============================================='
    echo '                _____C_a_t_c_h_a_l_l__e_i_n_r_i_c_h_t_e_n_____'
    echo
}


### Hauptroutine

    cmd=$1
    log_anz=$(log_delete "$log_max")
    log_init

    if [ -t 1 ]; then
        ausfuehrung="manual"    # Skript wurde direkt im Terminal aufgerufen
    else
        ausfuehrung="auto"      # im Cron aufgerufen
    fi


    if [ $ausfuehrung == "manual" ]; then
        if [[ $cmd == "--test" ||  $cmd == "-t" ]]; then
            funktionstest
        fi

        if [[ log_anz -eq 0 ]]; then
            clear; banner
            read -p '[?] Soll zuerst ein Funktionstest durchgeführt werden (J/N)? : ' fkt_check
            if [[ $fkt_check == "J" || $fkt_check == "j" ]]; then
                funktionstest
            fi
        fi
    fi

    log "Beginn: $(date)"

    if [[ $cmd == "-?" || $cmd == "--help" ]]; then
        log "Hilfetext mit $cmd aufgerufen"
        hilfetext
        exit 0
    fi

    clear; banner

    # Einloggen und Sessioncookie holen
    stv_login
    
    # Login erfolgreich?
    if $eingeloggt; then
        if [[ $cmd == "--cleanup" ||  $cmd == "-c" ]]; then # Bereinigen mit Sicherheitsabfrage
            cleanup_modus=manuell
            inhalte_bereinigen
        else
            err_ges=0
            if [[ $cmd == "--cleanupauto" ]]; then          # Bereinigen ohne Sicherheitsabfrage
                cleanup_modus=auto
                inhalte_bereinigen "J"  
                echo
                echo
            fi
            senderliste_holen   # Liste der vorhanden und zu aufzunehmenden Sender
            channel_liste       # Liste vorhandener Channels
            channelinfo_del     # prüfen ob Pseudochannel gelöscht werden muß
            ch_start=$ch_use    # Anzahl der belegten Channels bei Skriptstart
            channelanz_check    # prüfen ob freie Channels ausreichen
            channelanz_info     # Infotext zu verfügbaren Channels ausgeben
            channels_anlegen

            if [[ err_cha -gt 0 ]]; then
                echo "[!] Bei der Channelanlage sind $err_cha Fehler aufgetreten"
                if [[ $vers_max -ne 0 ]]; then
                    iterum $vers_max $vers_sleep    #    Fehlerhafte Channels erneut versuchen
                else
                    echo "[i] Wiederholung der Channelanlage ist deaktiviert"
                fi
            fi

            if [[ $ch_angelegt -ne 0 ]]; then
                echo
                if [[ $channels_behalten = false ]]; then
                    echo "[✓] Alle temporär angelegte Channels wurden wieder gelöscht."
                else    
                    echo "[✓] Es wurden $ch_angelegt Channels dauerhaft angelegt."
                fi
            else
                echo "[i] Es wurden keine neuen Channels angelegt."	
            fi

            prog_return=$(curl -s 'https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm' --cookie "$stv_cookie" --data 'iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=2&sSortOrder=StartDateASC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=0&bHighlightActivation=false&bVideoArchiveGroupOption=0&bShowRepeatitionActivation=false')
            prog_zukunft=$(sed 's/.*ITOTALENTRIES\":\([0-9]*\).*/\1/'<<< "$prog_return")
            echo "[i] Aktuell sind $prog_zukunft Sendungen zur Aufnahme programmiert"
            log "Programmierte Sendungen Stand $(date '+%m%d %H%M'): $prog_zukunft"

            if [[ $err_flag = true ]]; then
                echo "[!] Es sind nicht behebbare Fehler bei der Channelanlage aufgetreten."
                echo "    Details siehe Logdatei $stv_log"
                echo
                echo "   --- $(basename "$stv_log") ---"
                echo
                grep "^:" "$stv_log"   # nur schwerwiegende Fehler anzeigen
                echo "    ------"
                channelinfo_set "FEHLER $err_ges"
            else 
                channelinfo_set "OK"
            fi
        fi
        stv_logout
    else
        echo "[!] Fehler beim Login mit UserID $stv_user!"
        echo "    Bitte in '$(basename "$stv_cred")' Username und Passwort prüfen"
        echo
        echo "    Aktueller Inhalt von $(basename "$stv_cred"):"
        cat "$stv_cred" 2>/dev/null
        echo
        log ": Fehler beim Login - Username und Passwort prüfen!"
        exit 1 
    fi
    echo
    echo "[i] Bearbeitungszeit $SECONDS Sekunden"
    log "Ende: $(date)"
    exit 0

    if ! $eingeloggt; then
        if [[ $err_flag = true ]]; then
            stv_logout
            exit 2
        else 
            stv_logout
            exit 0
        fi
    fi
