# backup-system

Datensicherung im Team-Netzwerk (Linux WPF, OSZ IMT).

Das Skript `backup.sh` laeuft auf dem Backup-Server und holt die Daten per rsync
ueber SSH vom File-Server.

| Punkt | Wert |
|---|---|
| Quelle | fs-liebenow: /etc, /home, /DATA |
| Ziel | backup-liebenow: /BACKUP/<server>/version.N |
| Versionen | 4 (version.0 ist die neueste) |
| Zeitsteuerung | taeglich 02:00 Uhr ueber /etc/cron.d/backup |
| Anmeldung | ein eigener SSH-Schluessel je Quellserver, ohne Passwort |

## Installation

    install -m 755 backup.sh /usr/local/bin/backup.sh
    echo "0 2 * * * root /usr/local/bin/backup.sh" > /etc/cron.d/backup
