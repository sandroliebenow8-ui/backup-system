#!/bin/bash
# backup.sh - laeuft auf backup-liebenow als root
# Sichert /etc, /home und /DATA der Quellserver per rsync ueber SSH nach /BACKUP.
# Jede Sicherung landet in einem eigenen Ordner (version.0 = neueste).
# Unveraenderte Dateien werden nur als Hardlink abgelegt und brauchen keinen
# zusaetzlichen Platz. Es bleiben immer 4 Versionen erhalten.

ZIEL="/BACKUP"                  # Zielverzeichnis auf dem Backup-Server (RAID 1)
VERSIONEN=4                     # Anzahl der Versionen, die aufbewahrt werden
QUELLEN="/etc /home /DATA"      # Verzeichnisse, die gesichert werden
SERVER="fs-liebenow"            # Quellserver; weitere mit Leerzeichen anhaengen
LOG="/var/log/backup.log"       # Protokolldatei

for HOST in $SERVER; do
    KEY="/root/.ssh/backup_$HOST"   # genau ein eigener Schluessel je Server
    BASIS="$ZIEL/$HOST"
    mkdir -p "$BASIS"
    echo "$(date '+%F %T') Start Sicherung $HOST" >> "$LOG"

    # Neue Sicherung zuerst in einen Arbeitsordner schreiben.
    # --link-dest: unveraenderte Dateien als Hardlink auf die letzte Version
    # -a: Rechte, Besitzer und Zeiten erhalten   --delete: Geloeschtes entfernen
    # -R: Pfade vollstaendig uebernehmen (etc, home, DATA als Unterordner)
    # BatchMode: nie nach einem Passwort fragen (Anmeldung nur per Schluessel)
    LISTE=""
    for Q in $QUELLEN; do LISTE="$LISTE root@$HOST:$Q"; done
    rm -rf "$BASIS/neu"
    rsync -aR --delete -e "ssh -i $KEY -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
          --link-dest="$BASIS/version.0" $LISTE "$BASIS/neu/" >> "$LOG" 2>&1
    STATUS=$?

    # Nur bei Erfolg rotieren, damit ein Fehlschlag keine gute Version verdraengt
    if [ $STATUS -eq 0 ]; then
        rm -rf "$BASIS/version.$((VERSIONEN-1))"            # aelteste loeschen
        for ((i=VERSIONEN-2; i>=0; i--)); do                # Rest weiterschieben
            [ -d "$BASIS/version.$i" ] && mv "$BASIS/version.$i" "$BASIS/version.$((i+1))"
        done
        mv "$BASIS/neu" "$BASIS/version.0"
        touch "$BASIS/version.0"                            # Zeitpunkt der Sicherung
        echo "$(date '+%F %T') Sicherung $HOST erfolgreich" >> "$LOG"
    else
        rm -rf "$BASIS/neu"
        echo "$(date '+%F %T') FEHLER bei $HOST (rsync-Code $STATUS)" >> "$LOG"
    fi
done
