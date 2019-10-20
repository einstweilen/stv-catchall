#! /bin/bash
# 2019-10-16
# https://github.com/einstweilen/stv-catchall/

SECONDS=0 

#### Userdaten & Löschmodus
stv_user=''     	      # für Autologin Username ausfüllen z.B. 612612
stv_pass=''     	      # für Autologin Passwort ausfüllen z.B. R2D2C3PO
anlege_modus=auto       # auto  (löschen bei Basis & XL, behalten bei XXL)
                        # immer (alle angelegte Channels werden nicht gelöscht)
                        # nie   (angelegte Channels werden wieder gelöscht)
#### Dateipfade
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # Pfad zum Skript
send_list="$DIR/stv_sender.txt"     # Liste alle Sender
send_skip="$DIR/stv_skip.txt"       # Liste der zu überspringenden Sender
stvlog="$DIR/stv_ca.log"            # Ausführungs- und Fehlerlog
stvsend="$DIR/stv_sendungen.txt"    # Programmierte Sendungen
stvcookie="$DIR/stv_cookie.txt"     # Session Cookie

err_flag=false                      # Flag für Bearbeitungsfehler

stv_ch_basis=5                      # Basispaket mit 5 Channeln, nur 50h Aufnahme!
stv_ch_xl=20                        # XL-Paket mit 20 Channeln
stv_ch_xxl=200                      # XXL-Paket mit 200 Channeln

tageszeit=('' 'Vormittag' 'Nachmittag' 'Abend' 'Nacht')

ca_ch_pre='_ '                      # Prefix-Kennung für vom Skript erstelle Channel
ca_ch_preurl='_+'                   # dito URLencoded *ein* Leerzeichen
ca_in_pre="$ca_ch_pre "             # Prefix-Kennung für vom Skript erstellen Infotext
ca_in_preurl="$ca_ch_preurl+"       # dito URLencoded *zwei* Leerzeichen (alphabetisch vor den anderen Channels)

#### Username und Passwort setzen und ggf abfragen
userpass_set() {
    # Username und Passwort manuell abfragen falls nicht im Skript gesetzt
    if [[ -z $stv_user ]] ; then
        read -p "Save.TV Username: " stv_user
    fi

    if [[ -z $stv_pass ]] ; then
        read -p "Save.TV Passwort: " stv_pass
    fi
    userpass="sUsername=$stv_user&sPassword=$stv_pass"
}


#### Login
login() {
            login_return=$(curl -s 'https://www.save.tv/STV/M/Index.cfm' -H 'Host: www.save.tv' -H 'User-Agent: Mozilla/5.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/stv/s/obj/user/usShowlogin.cfm' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' --data "$userpass" --cookie-jar "$stvcookie" | grep -c -F Login_Failed)     
}


#### Logout
logout () {
            curl -s 'https://www.save.tv/STV/M/obj/user/usLogout.cfm' -H 'DNT: 1' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://www.save.tv/STV/M/obj/user/config/AccountEinstellungen.cfm' --cookie "$stvcookie" -H 'Connection: keep-alive' --compressed >/dev/null 2>&1
            rm "$stvcookie"
}


#### Aktuelle Senderliste einlesen oder von Server holen
senderliste_holen() {
    if [ ! -e "$send_skip" ]; then
        echo '17|RTL' >"$send_skip" # keine Liste vorhanden? => Minimalliste mit RTL
        echo 'Liste der nicht aufzunehmenden Sender ist nicht vorhanden, Defaultliste angelegt' >> "$stvlog"
    fi
    
    index=0
    while read line; do
        senderskip[index]="$line"
        ((index++))
    done < "$send_skip"
    
    if [ ! -e "$send_list" ]; then
        sender_return=$(curl -s 'https://www.save.tv/STV/M/obj/JSON/TvStationGroupsApi.cfm?iFunction=2&loadTvStationsWithAllStationOption=true&bIsMemberarea=true'  -H 'Host: www.save.tv' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/ChannelAnlegen.cfm' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' --cookie "$stvcookie" -H 'DNT: 1' -H 'Connection: keep-alive')
        echo "$sender_return" | sed 's/.*)"},{//g ; s/"},{"ID":/;/g ; s/,"NAME":"/|/g ; s/"ID"://g ; s/"}]}//g' | tr ';' '\n' >"$send_list"
        echo 'Aktualisierte Senderliste vom Server geholt' >> "$stvlog"
    fi

    index=0
    while read line; do
        if [[ "${senderskip[@]}" != *"$line"* ]]; then 
            sender_name[index]=${line#*|}
            sender_id[index]=${line%|*}
            ((index++))
        fi
    done < "$send_list"
    
    # Anzahl der anzulegenden Sender 
    sender_anz=${#sender_id[@]}           
}

#### Sendernamen vierspaltig ausgeben   
sender_info() {
    for (( i=0; i<=${#sender_name[@]}-1; i=i+4)); do
        printf "%-19s %-19s %-19s %-19s\n" "${sender_name[i]}" "${sender_name[i+1]}" "${sender_name[i+2]}" "${sender_name[i+3]}"
    done
}


#### Liste der ChannelIDs und Channelnamen ####
channel_liste() {     
        allchannels=$(curl -sL 'https://www.save.tv/STV/M/obj/channels/JSON/myChannelsApi.cfm?iFunction=1' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/MeineChannels.cfm' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie" -H 'Cache-Control: max-age=0')
        
        ch_max=$(grep -o "IMAXCHANNELS[^\.]*" <<< "$allchannels"| grep -o "[0-9]*$")
        ch_use=$(grep -o "IUSEDCHANNELS[^,]*" <<< "$allchannels"| grep -o "[0-9]*$")
        ch_fre=$((ch_max - ch_use))

        if [[ ch_use -gt 0 ]]; then
            # Rohdaten ChannelID und Channelname aus API Rückgabe
            IFS=$'\n' ch_rw=($(grep -o "CHANNELID[^}]*" <<< "$allchannels")) ; unset IFS
            
            # Rohdaten ins Format ChannelID|Channelname bringen
            for ((i=0;i<${#ch_rw[*]}; i++)); do        
                 ch_in[i]=$(sed 's/CHANNELID..\([^\.]*\).*SNAME...\([^\"]*\).*/\1|\2/g' <<< "${ch_rw[i]}")
            done
            
            # sortieren ch_sid nach ChannelID
            IFS=$'\n' ch_sid=($(sort <<< "${ch_in[*]}" | sort -n )) ; unset IFS
        fi
}


#### Channels anhand der Senderliste anlegen
channels_anlegen () {
    sender_bearbeitet=0
    ch_angelegt=0   # Counter für insgesamt angelegte Channel

    echo "Channels + anlegen  - löschen  ✓ Sender programmiert  F_ehler&Anzahl"
    echo -ne "Sender :"

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
            echo "Fehler: Sender $sender ohne ID gefunden!" >> "$stvlog"
        fi
    done
    echo
}


#### Senderchannel für alle Tageszeiten anlegen
senderchannel_anlegen () {
        senderid="$1"
        sendername="$2"
        ch_sender=0
        echo '' >> "$stvlog"
        echo "Bearbeite Channel für Sender $sender_bearbeitet von $sender_anz '$sendername'" >> "$stvlog"
        for timeframe in 1 2 3 4; do
            echo -en "$timeframe"
            channel_senderid_timeframe_anlegen "$senderid" "$timeframe" "$sendername"
            if [[ $ch_ok = true ]]; then
                ((ch_angelegt++))
                ((ch_sender++))
            else
                ((err_cha++))
                err_send_id[err_cha]="$senderid"
                err_send_time[err_cha]="$timeframe"
                err_send_name[err_cha]="$sendername"
                err_send_text[err_cha]="$fehlertext"
            fi
            echo -en "\b"
        done
}


#### reicht die Anzahl der freien Channels aus
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

    if [[ ch_fre -lt ch_nec ]]; then
        echo "Das Skript benötigt $ch_nec freie Channels zur Programmierung."
        echo "Aktuell sind bereits $ch_use von $ch_max Channels des Pakets belegt"
        echo "Bitte manuell unter 'www.save.tv/Meine Channels' mindestens $((ch_nec - ch_fre)) Channels löschen"
        echo "und das Skript anschließend erneut starten."
        exit 0
    fi

    echo "Aufnahme aller Sendungen der nächsten 7 Tage für folgende $sender_anz Sender einrichten:"
    sender_info         # Sendernamen anzeigen          
    echo ''                
    if [[ ch_use -gt 0 ]]; then
        echo "Es sind $ch_use manuell angelegte Channels vorhanden, diese blieben erhalten."
    fi

    if [[ $channels_behalten = false ]]; then
        echo "Es werden $ch_nec temporäre Channels angelegt und wieder gelöscht."
        if [[ ch_max -eq stv_ch_basis ]]; then
            echo ''
            echo "HINWEIS: Sie können mit Ihrem Basispaket nur 50 Stunden aufnehmen!"
            read -p 'Skript trotzdem ausführen (J/N)? : ' basis_check
            if [[ $basis_check == "N" || $basis_check == "n" ]]; then
                exit 0
            fi
        fi
    else
        echo "Es werden $ch_nec zusätzliche Channels angelegt, die Channels bleiben erhalten."
    fi
    echo '' 
}


#### einzelenen Channel für eine Tageszeit anlegen
channel_senderid_timeframe_anlegen () {
    senderid="$1"
    timeframe="$2"
    sendername="$3"

    ch_title=$(tr ' ' '+' <<<"$ca_ch_pre$sendername - ${tageszeit[$timeframe]}") # minimal URLencoding

    channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' -H 'Host: www.save.tv' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/ChannelAnlegen.cfm' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' --cookie "$stvcookie" -H 'DNT: 1' -H 'Connection: keep-alive' --data "channelTypeId=1&sName=$ch_title&TvCategoryId=0&ChannelTimeFrameId=$timeframe&TvSubCategoryId=0&TvStationid=$senderid")            
    if [[ $(grep -c "BISSUCCESSMSG..true" <<< "$channel_return") -eq 1 ]]; then
        echo -n "+ '${tageszeit[$timeframe]}' " >> "$stvlog"
        ch_ok=true
    else
        echo '' >> "$stvlog"
        echo "*** Fehler *** bei $senderid $sendername ${tageszeit[$timeframe]}" >> "$stvlog"
        # echo "Fehlermeldung: $channel_return" >> "$stvlog"

        fehlertext=$(sed 's/.*SMESSAGE...\(.*\)...BISSUCCESSMSG.*/\1/g ; s/\\//g' <<< "$channel_return")
        echo "$fehlertext" >> "$stvlog"
        # "
        ch_ok=false
    fi
}


#### Anlage wiederholen bei Channelfehlern wegen Serverproblemen
channel_fehlerfix () {
    echo ''
    echo "Erneuter Versuch die fehlerhaften $err_cha Channels anzulegen."
    err_i=$((err_cha+1))
    for ((i=1;i<err_i; i++)); do
        echo -n "Versuche Channel ${err_send_name[i]} - ${tageszeit[${err_send_time[i]}]} "
        channel_senderid_timeframe_anlegen "${err_send_id[i]}" "${err_send_time[i]}" "${err_send_name[i]}"
        if [[ $ch_ok = true ]]; then
            ((ch_angelegt++))
            ((ch_sender++))
            ((err_cha--))
            echo "✓ gefixt"
        else
            echo "X nicht gefixt"
        fi
        channels_loeschen
    done

    # Du hast bereits einen Sender-Channel für den Sender "3sat" mit gleichem Zeitraum und gleichen Kategoriebedingungen angelegt.
    # Die Aufnahmen wurden erfolgreich für diesen Channel angelegt.


    if [[ $err_cha -eq 0 ]]; then
        err_flag=false
        echo ''
        echo "Alle Fehler konnten behoben werden!"
    fi

}


#### Channel löschen: bestehende Programmierung und Aufnahmen bleiben erhalten
channels_loeschen () {        
        channel_liste  
        ch_loeschen=$((ch_use - ch_start))   # wieviele Channel sind vom Skript angelegt worden und zulöschen        
        if [[ ch_loeschen -gt 0 ]]; then
            echo '' >> "$stvlog"
            for ((i=ch_start;i<ch_use; i++)); do
                chid=$(grep -o "^[^\|]*" <<< "${ch_sid[i]}")           
                # channel_id
                # deleteProgrammedRecords 0=behalten 1=löschen
                # deleteReadyRecords 0=behalten 1=löschen
                delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$chid&deleteProgrammedRecords=0&deleteReadyRecords=0" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/MeineChannels.cfm' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie")           
                # delete_return OK {"SMESSAGE":"Channel gelöscht"}
                if [[ $(grep -c "Channel gelöscht" <<< "$delete_return") -eq 1 ]]; then
                    echo -n "- '$(sed 's/.* - //' <<< "${ch_sid[i]}")' " >> "$stvlog"
                else
                    ((err_cha++))
                    echo '' >> "$stvlog"
                    echo "*** Fehler *** bei $(sed 's/|/ /' <<< "${ch_sid[i]}") $delete_return" >> "$stvlog"
                fi
            done
        echo '' >> "$stvlog"
        fi
}


#### legt einen Stichwortchannel mit Status und Uhrzeit des Laufs an
channelinfo_set() {  
    ch_text="sTelecastTitle=$ca_in_preurl$1+$(date '+%m%d+%H%M')+Delta+$pro_delta&channelTypeId=3"
    channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' -H 'Host: www.save.tv' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/ChannelAnlegen.cfm' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' --cookie "$stvcookie" -H 'DNT: 1' -H 'Connection: keep-alive' --data "$ch_text")  
}

#### Pseudochannel mit letztem Status als Text löschen
channelinfo_del() {
    stvchinfo=$(grep -o "[0-9]*|$ca_in_pre" <<< "${ch_in[*]}" | head -1 | grep -o "[0-9]*") 
    if [[ stvchinfo -gt 0 ]]; then
        delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$stvchinfo&deleteProgrammedRecords=0&deleteReadyRecords=0" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/MeineChannels.cfm' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie")
        channel_liste   # aktualisierte Channelliste holen und erneut Anzahl der Channels ermitteln
    fi
}


#### Vom Skript angelegte Channels löschen 
channel_cleanup() {
    if [[ $ch_use -gt 0 ]]; then
        ch_use_vor=$ch_use
        echo -n "Lösche $ca_ch_anz Channels : "  
        for ch_test in "${ch_in[@]}"; do
            if [[ $ch_test == *[0-9]"|$ca_ch_pre"* ]]; then
                stvchinfo=$(grep -o "^[0-9]*" <<< "$ch_test")
                if [[ stvchinfo -gt 0 ]]; then
                    echo "CA Channel löschen $ch_test" >> "$stvlog"
                    delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$stvchinfo&deleteProgrammedRecords=0&deleteReadyRecords=0" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/MeineChannels.cfm' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie")   
                    if [[ "$delete_return" == *"Channel gelöscht"* ]]; then 
                        echo -n "."
                    else
                        echo -n "F"
                        sed 's/.*SMESSAGE...\(.*\)...BISSUCCESSMSG.*/\1/g ; s/\\//g' <<< "$delete_return" >> "$stvlog"
                    fi
                fi
            fi
        done
        echo -n '✓'
        echo ''
        channel_liste   # aktualisierte Channelliste holen und erneut Anzahl der Channels ermitteln
        echo "Es wurden $((ch_use_vor - ch_use)) Channels gelöscht."
    else
        echo "Es sind keine Channels vorhanden."
    fi
}


#### Aufnahme- und Programmierungsreste löschen
sender_bereinigen() {
    cleanup_check=$1
    echo "        Programmierungen und Aufnahmen der Sender der Skipliste löschen"
    if [ ! -e "$send_skip" ]; then
        echo '17|RTL' >"$send_skip" # keine Liste vorhanden? => Minimalliste mit RTL
        echo 'Liste der nicht aufzunehmenden Sender war nicht vorhanden, Defaultliste wurde angelegt' >> "$stvlog"
    fi

    index=0
    while read line; do
        if [[ -n $line ]]; then
            skip_name[index]=${line#*|}
            skip_id[index]=${line%|*}      
            ((index++))
        fi
    done < "$send_skip"
        
    echo ''
    echo "Die Liste der nicht aufzunehmenden Sender '$(basename "$send_skip")' beinhaltet zur Zeit:"
    for (( i=0; i<=${#skip_name[@]}; i=i+4)); do
        printf "%-19s %-19s %-19s %-19s\n" "${skip_name[i]}" "${skip_name[i+1]}" "${skip_name[i+2]}" "${skip_name[i+3]}"
    done
    
    if [[ $cleanup_check == "J" ]]; then
        echo "Für diese ${#skip_name[@]} Sender werden die vorhandenen Programmierungen und"
        echo "aufgenommenen Sendungen endgültig gelöscht"
        
        echo 'Bereinigung im Batchmodus' >> "$stvlog"
    else        
        echo "Sollen für diese ${#skip_name[@]} Sender die vorhandenen Programmierungen und"
        echo "aufgenommenen Sendungen endgültig gelöscht werden?"
        echo 
        read -p 'Alles bereinigen (J/N)? : ' cleanup_check
    fi
    SECONDS=0 
    echo
    
    if [[ $cleanup_check == "J" || $cleanup_check == "j" ]]; then
        echo "Lösche alle Programmierungen und Aufnahmen der Sender der Skipliste"
        # Webinterface umschalten auf ungruppierte Darstellung wg. EinzelsTelecastIds
        list_return=$(curl -s 'https://www.save.tv/STV/M/obj/user/submit/submitVideoArchiveOptions.cfm?bShowGroupedVideoArchive=false' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/archive/VideoArchive.cfm?bLoadLast=true' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie" --data '')
        
        del_ids_tot=0       # Gesamtsumme der TelecastIds
        del_ids_err=false   # Flag für mgl. Fehler
        for (( i=0; i<=${#skip_name[@]}; i++)); do
            sendername=${skip_name[i]}
            senderid=${skip_id[i]}
            if [[ senderid -gt 0 ]]; then     
                list_return=$(curl -s "https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/archive/VideoArchive.cfm?bLoadLast=true' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie" --data "iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=0&sSortOrder=StartDateDESC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=$senderid&bHighlightActivation=false&bVideoArchiveGroupOption=false&bShowRepeatitionActivation=false")
                temp_te=$(grep -o "IENTRIESPERPAGE.*ITOTALPAGES"<<< "$list_return" | grep -o '"ITOTALENTRIES":[0-9]*'); totalentries=${temp_te#*:}
                totalpages=$(grep -o '"ITOTALPAGES":[0-9]*' <<< "$list_return" | grep -o "[0-9]*$")
                echo "$sendername hat $totalentries zu löschende Einträge auf $totalpages Seiten" >> "$stvlog" 
            
                if [[ totalpages -gt 0 ]]; then
                    echo -n "'$sendername' hat $totalentries Einträge, beginne Löschung : "
                    del_ids_tot=$((del_ids_tot + totalentries))  
                    for ((page=1; page<=totalpages; page++)); do
                        list_return=$(curl -s "https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/archive/VideoArchive.cfm?bLoadLast=true' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie" --data "iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=0&sSortOrder=StartDateDESC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=$senderid&bHighlightActivation=false&bVideoArchiveGroupOption=false&bShowRepeatitionActivation=false")
                        delete_ids=$(grep -o "TelecastId=[0-9]*" <<< "$list_return" | sed 's/TelecastId=\([0-9]*\)/\1%2C/g' | tr -d '\n')                        
                        if [ -n "$delete_ids" ]; then               
                            echo "Lösche $senderid|$sendername : $delete_ids" >> "$stvlog"
                            delete_return=$(curl -s "https://www.save.tv/STV/M/obj/cRecordOrder/croDelete.cfm" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/archive/VideoArchive.cfm?bLoadLast=true' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie" --data "lTelecastID=$delete_ids")
                            if [[ "$delete_return" == *"ok"* ]]; then 
                                echo -n "."
                            else
                                echo -n "F"
                                del_ids_err=true
                            fi
                            echo "$(grep -oF '%2C' <<< "$delete_ids" | wc -l) von $sendername gelöscht : $delete_return" >> "$stvlog"
                        fi
                    done
                    echo -n '✓'
                    echo ''
                else
                    echo "'$sendername' muß nicht gesäubert werden"   
                fi
            fi
        done
        if [[ $del_ids_err = true ]]; then
            echo "Hinweis: Beim Löschen sind Fehler aufgetreten, Details siehe Logfile $(basename ''"$stvlog"'')!"
            echo
        fi
        if [[ del_ids_tot -gt 0 ]]; then
            echo "Es wurden insgesamt $del_ids_tot Aufnahmen und Programmierungen gelöscht."
        else
            echo "Es sind keine Aufnahmen und Programmierungen vorhanden."
        fi
        # nur bei manuellem Aufruf Channelaufräumen zusätzlich anbieten
        if [[ $cleanup_modus == "manuell" ]]; then
            channelrestechecken
        fi
    else
        echo "Bereinigung abgebrochen, es wurde nichts gelöscht."
        if [[ $cleanup_modus == "manuell" ]]; then
            channelrestechecken
        fi
    fi
}


#### auf Channels beginnend mit '_ ' prüfen und löschen
channelrestechecken () {
    echo ''
    echo ''
    echo '         Prüfe die Channelliste auf von STV CatchAll angelegte Channels'
    echo ''
    channel_liste       # Liste vorhandener Channel
    channelinfo_del     # prüfen ob Pseudochannel gelöscht werden muß

    ca_ch_anz=$(grep -o "[0-9]*|$ca_ch_pre[^ ]" <<< "${ch_in[*]}" | wc -l | xargs) # xarg entfernt whitespace
    if [[ $ca_ch_anz -gt 0 ]]; then
        echo "Es sind $ca_ch_anz vom STV CatchAll Skript angelegte Channels vorhanden,"
        echo "beim Channellöschen bleiben bereits erfolgte Aufnahmen erhalten."
        echo
        echo "Hinweis: Die Option 'L' zeigt eine Liste der gefundenen STV Channels an."
        read -p "Diese $ca_ch_anz Channels und zugehörigen Programmierungen löschen (J/N/L)? : " ch_cleanup_check
        if [[ $ch_cleanup_check == "L" || $ch_cleanup_check == "l" ]]; then
        echo ''
            echo "Hinweis: Die von STV CatchAll angelegten Channels beginnen immer mit '$ca_ch_pre'"
            for ch_test in "${ch_in[@]}"; do
                grep -o "[0-9]*|$ca_ch_pre[^|]*" <<< "$ch_test"
            done
            read -p "Diese $ca_ch_anz Channels und zugehörigen Programmierungen löschen (J/N)? : " ch_cleanup_check
        fi
        if [[ $ch_cleanup_check == "J" || $ch_cleanup_check == "j" ]]; then
            channel_cleanup
        else
            echo "Bereinigung abgebrochen, es wurden keine Channels gelöscht."
        fi
    else
        echo 'Es sind keine von STV CatchAll angelegte Channels vorhanden.'
    fi
}

#### Funktionstest Channelanlage prüfen
fkt_ch_anlegen() {
    ch_text="sTelecastTitle=$ca_ch_preurl+$(date '+%m%d+%H%M')+Funktionstest&channelTypeId=3"
    channel_return=$(curl -s 'https://www.save.tv/STV/M/obj/channels/createChannel.cfm' -H 'Host: www.save.tv' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/ChannelAnlegen.cfm' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' --cookie "$stvcookie" -H 'DNT: 1' -H 'Connection: keep-alive' --data "$ch_text")
    if [[ $(grep -c "BISSUCCESSMSG..true" <<< "$channel_return") -eq 1 ]]; then
        ch_ok=true
    else
        ch_ok=false
    fi
}

#### Funktionstest angelegten Channel löschen
fkt_ch_delete() {
    for ch_test in "${ch_in[@]}"; do
        if [[ $ch_test == *Funktionstest* ]]; then
            stvchinfo=$(grep -o "^[0-9]*" <<< "$ch_test")
            if [[ stvchinfo -gt 0 ]]; then
                delete_return=$(curl -s "https://www.save.tv/STV/M/obj/channels/deleteChannel.cfm?channelId=$stvchinfo&deleteProgrammedRecords=0&deleteReadyRecords=0" -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/channels/MeineChannels.cfm' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie")   
                if [[ "$delete_return" == *"Channel gelöscht"* ]]; then 
                    ch_ok=true
                else
                    ch_ok=false
                fi
            fi
        fi
    done
}

funktionstest() {
    clear ; banner
    echo 'Funktionstest auf korrekte Logindaten und verfügbare Channels wird durchgeführt.'
    echo

    # 01 Scriptverzeichnis R/W
    echo "$(date) Funktionstest begonnen" > "$stvlog"
    if [ ! -e "$stvlog" ]; then
        echo "[-] Keine Schreibrechte im Skriptverzeichnis vorhanden"
        echo "    Verzeichnis $DIR prüfen"
        exit 1
    else
        echo "[✓] Schreibrechte im Skriptverzeichnis"
    fi


    # 02 login
    login
    if [[ $login_return -eq 0 ]]; then
        echo "[✓] Login mit UserID $stv_user erfolgreich"
    else
        echo "[-] Fehler beim Login mit UserID $stv_user!"
        echo '    Bitte in den Zeilen 8 und 9 Username und Passwort prüfen,'
        echo '    und danach den Funktionstest mit --test erneut starten.'
        exit 1
    fi
        
    # 03 gebuchtes Paket, freie Channels, Senderliste
    paket_return=$(curl -s 'https://www.save.tv/STV/M/obj/user/JSON/userConfigApi.cfm?iFunction=7' -H 'Host: www.save.tv' -H 'User-Agent: Mozilla/5.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: de' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' --cookie "$stvcookie" -H 'Cache-Control: max-age=0' -H 'TE: Trailers')
    paket=$(sed 's/.*SNAME":"\([^"]*\).*/\1/' <<<$paket_return )
    channel_liste
    echo "[✓] Paket '$paket' mit $ch_max Channels, $ch_use benutzt"
    echo "    Channelanlegemodus '$anlege_modus' wird verwendet"
    echo
    if [[ ch_fre -eq 0 ]]; then
        echo '    Für den Test wird ein freier Channel benötigt.'
        echo '    Mindestens einen Channel manuell löschen'
        echo '    und danach den Funktionstest mit --test erneut starten.'
        exit 1
    fi

    senderliste_holen
    index=0
    while read line; do
        if [[ -n $line ]]; then
            skip_name[index]=${line#*|}
            skip_id[index]=${line%|*}      
            ((index++))
        fi  
    done < "$send_skip"

    if [ ! -e "$send_skip" ]; then
        echo "[-] Liste der nicht aufzunehmenden Sender '$(basename "$send_skip")' ist nicht vorhanden,"
        echo "    alle $sender_anz bei Save.TV verfügbaren Sender werden aufgenommen."
    else
        echo "[✓] Die Liste der nicht aufzunehmenden Sender '$(basename "$send_skip")' beinhaltet:"
        for (( i=0; i<=${#skip_name[@]}; i=i+3)); do
            printf "%-3s %-19s %-19s %-19s\n" "   " "${skip_name[i]}" "${skip_name[i+1]}" "${skip_name[i+2]}"
        done
    fi

    # 04 channel anlegen
    fkt_ch_anlegen
    if [[ $ch_ok = true ]]; then
        echo "[✓] Testchannel erfolgreich angelegt"
    else
        echo "[-] Testchannel konnte nicht angelegt werden"
        exit 1
    fi

    # 054 channelliste lesen
    channel_liste
    echo "[✓] Channelliste einlesen"
    
    # 06 channel löschen
    fkt_ch_delete
    if [[ $ch_ok = true ]]; then
        echo "[✓] Testchannel erfolgreich gelöscht"
    else
        echo "[-] Testchannel konnte nicht gelöscht werden"
        exit 1
    fi

    # 07 ausloggen
    logout
    echo "[✓] Logout durchgeführt"

    # Status ausgeben
    echo
    echo "Funktionstest wurde in $SECONDS Sekunden abgeschlossen"
    echo
    echo "$(date) Funktionstest wurde in $SECONDS Sekunden abgeschlossen" > "$stvlog"
    exit 0
}

# foo="$(time ( ls ) 2>&1 1>/dev/null)"
# echo "$foo" | grep real | sed -E 's/[^0-9\.]+//g' | tr -d '\n' | (cat && echo " * 1000") | bc | sed 's/.000//'

hilfetext() {
    banner
    echo "SaveTV Catchall Aufnahme aller Sendungen für alle SaveTV Sender programmieren"
    echo
    echo "-t, --test      Skripteinstellungen und SaveTV Account überprüfen"
    echo 
    echo "-c, --cleanup  'Reste aufräumen' Funktion aufrufen"
    echo
    echo "--cleanupauto  'Reste aufräumen' ohne Sicherheitsabfrage ausführen,"
    echo "                anschließend wird die Catchall Channel Einrichtung durchgeführt"
    echo "                !Gelöschte Aufnahmen können nicht wiederhergestellt werden!"
    echo
    echo "-?, --help      Hilfetext anzeigen"
    echo 
    echo "In den Zeilen 8 und 9 den SaveTV Username und das Passwort eintragen oder"
    echo "beim manuellen Aufruf mit './stvcatchall.sh username passwort' übergeben"
    echo "Optional die Datei '$(basename "$send_skip")' anpassen, um einzelne Sender von der"
    echo "Programmierung auszunehmen"
    echo
    echo "Vollständige Anleitung unter https://github.com/einstweilen/stv-catchall"
}


#### Headergrafik
banner () {
    echo '                _______ _______ _    _ _______   _______ _    _'
    echo '                |______ |_____|  \  /  |______      |     \  /'
    echo '                ______| |     |   \/   |______ .    |      \/ ' 
    echo '                ==============================================='
    echo '                ____ C_a_t_c_h_a_l_l___e_i_n_r_i_c_h_t_e_n ____'
    echo ''
}


#### Hauptroutine ####

    cmd=$1
    if [ ! -e "$stvlog" ] && [ -z $cmd ]; then
        # Annahme keine Logdatei vorhanden bedeutet erster Lauf
        read -p 'Soll ein Funktionstest durchgeführt werden (J/N)? : ' fkt_check
        if [[ $fkt_check == "J" || $fkt_check == "j" ]]; then
            funktionstest
        fi
    fi

    echo "Beginn: $(date)" > "$stvlog"

    if [[ $cmd == "-?" || $cmd == "--help" ]]; then
        echo "Hilfetext mit $cmd aufgerufen" >> "$stvlog"
        hilfetext
        exit 0
    fi

    clear
    banner
    # wurden dem Skript beim Aufruf Username und Passwort übergeben? 
    if [[ -z $1 ]] ; then
        userpass_set
        else
        if [[ -z $2 ]] ; then
            userpass_set
        else
            userpass="sUsername=$1&sPassword=$2"
        fi    
    fi

    if [[ $cmd == "--test" ||  $cmd == "-t" ]]; then
        funktionstest
    fi

    # Einloggen und Sessioncookie holen
    login
    
    # Login erfolgreich?
    if [[ $login_return -eq 0 ]]; then
        if [[ $cmd == "--cleanup" ||  $cmd == "-c" ]]; then # Bereinigen mit Sicherheitsabfrage
            cleanup_modus=manuell
            sender_bereinigen
        else
            if [[ $cmd == "--cleanupauto" ]]; then          # Bereinigen ohne Sicherheitsabfrage
                cleanup_modus=auto
                sender_bereinigen "J"  
                echo
                echo
            fi
            senderliste_holen   # Liste der vorhanden und zu aufzunehmenden Sender
            channel_liste       # Liste vorhandener Channels
            channelinfo_del     # prüfen ob Pseudochannel gelöscht werden muß
            ch_start=$ch_use    # Anzahl der belegten Channels bei Skriptstart
                
            channelanz_check    # prüfen ob freie Channels ausreichen
            channels_anlegen

            if [[ err_cha -gt 0 ]]; then
                echo "Bei der Channelanlage sind $err_cha Fehler aufgetreten"
                # channel_fehlerfix
            fi


            if [[ $ch_angelegt -ne 0 ]] ; then
                echo ''
                if [[ $channels_behalten = false ]]; then
                    echo "$ch_angelegt Channels wurden angelegt und wieder gelöscht."
                else    
                    echo "Es wurden $ch_angelegt Channels dauerhaft angelegt."
                fi
                
                if [ ! -e "$stvsend" ]; then
                    echo '0' >"$stvsend" # keine Liste vorhanden?
                fi
                pro_vor=$( grep -o "[0-9][0-9]*" "$stvsend" )
                
                prog_return=$(curl -s 'https://www.save.tv/STV/M/obj/archive/JSON/VideoArchiveApi.cfm' -H 'User-Agent: Mozilla/5.0' -H 'Accept: */*' -H 'Accept-Language: de' --compressed -H 'Referer: https://www.save.tv/STV/M/obj/archive/VideoArchive.cfm?bLoadLast=true' -H 'X-Requested-With: XMLHttpRequest' -H 'DNT: 1' -H 'Connection: keep-alive' --cookie "$stvcookie" --data 'iEntriesPerPage=35&iCurrentPage=1&iFilterType=1&sSearchString=&iTextSearchType=2&iChannelIds=0&iTvCategoryId=0&iTvSubCategoryId=0&bShowNoFollower=false&iRecordingState=2&sSortOrder=StartDateASC&iTvStationGroupId=0&iRecordAge=0&iDaytime=0&manualRecords=false&dStartdate=2019-01-01&dEnddate=2038-01-01&iTvCategoryWithSubCategoriesId=Category%3A0&iTvStationId=0&bHighlightActivation=false&bVideoArchiveGroupOption=0&bShowRepeatitionActivation=false')
                temp_te=$(grep -o "IENTRIESPERPAGE.*ITOTALPAGES"<<< "$prog_return" | grep -o '"ITOTALENTRIES":[0-9]*') ; pro_nach=${temp_te#*:}
                echo "$pro_nach" >"$stvsend"
                
                pro_delta=$((pro_nach-pro_vor))
                echo "Programmierte Sendungen beim letzten Lauf: $pro_vor aktuell: $pro_nach Delta: $pro_delta"
                echo "Programmierte Sendungen beim letzten Lauf: $pro_vor aktuell: $pro_nach Delta: $pro_delta" >> "$stvlog"
            else
                echo "Es wurden keine neuen Channel angelegt."	
            fi

            if [[ $err_flag = true ]]; then
                echo "Achtung! Es sind nicht behebbare Fehler bei der Channelanlage aufgetreten."
                echo "Details siehe Logdatei $stvlog"
                echo ''
                echo "------"
                echo ''
                cat "$stvlog"
                channelinfo_set FEHLER
            else 
                channelinfo_set OK
            fi
        fi
        logout
    else
        echo "Fehler beim Login - bitte Username und Passwort prüfen!"
    fi
    echo ''
    echo "Bearbeitungszeit $SECONDS Sekunden"
    echo "Ende: $(date)" >> "$stvlog"
exit 0
