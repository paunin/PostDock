## Free space requirements:
1. For base backup itself, you can check size with `barman show-backup`

2. Space for WALs
	* Take into account that barman stores WALs in compress form. You can calcuate required space by checking once again `barman show-backup`. There you will find disk usage and compression rate.
	* During recovery barman put `restore_command = cp...` which means that you have to have at least double of WAL size.
Upod recovery completion duplicates wil be removed.

## Recovery steps:

1. Stop pg cluster, but retain containers. **IMPORTANT start with slaves**
    ```
    touch /var/run/recovery.lock
    killall repmgrd
    gosu postgres pg_ctl stop
    ```    
1. Check sshd is running on master, if not start it:
    ```
    SSH_ENABLE=1 sshd_start
    ```
1. Connect to barman container and select appropriate base backup
    ```
    barman list-backup all
    ```
1. Recover to required point, for example:
    ```
    barman recover pg_cluster 20170815T041301 /var/lib/postgresql/data/ --target-time "2017-08-15 04:11:26.5" --remote-ssh-command="ssh pgmaster" -j$(nproc)
    ```
1. Connect to master node, start recovery and check DB consistency, then finish recovery
    ```
    gosu postgres pg_ctl start -o "-c listen_addresses='localhost'"
    psql -U monkey_user monkey_db -c "SELECT * from t"
    psql -U postgres -c "SELECT pg_xlog_replay_resume()"
    ```
1. Restart master container
    ```
    rm /var/run/recovery.lock
    ```
1. Wait until master will become fully functional and restart every standby node
    ```
    rm /var/run/recovery.lock
    ```
1. Recreate replication slot for barman
    ```
    barman receive-wal --create-slot $UPSTREAM_NAME
    ```

## Caveat

You need manually rewind 2nd-tier replicas to master
```
gosu postgres pg_rewind --target-pgdata /var/lib/postgresql/data/ --source-server 'host=pgmaster user=replication_user password=replication_pass dbname=replication_db'
```

