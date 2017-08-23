## Recovery steps:

1. Stop pg cluster, but retain containers. **IMPORTANT start with slaves**
    ```
    touch /var/run/recovery.lock
    killall repmgrd
    gosu postgres pg_ctl stop
    ```    
1. Check sshd is running on master, if not start it:
    ```
    /home/postgres/.ssh/entrypoint.sh
    ```
1. Connect to barman container and select appropriate base backup
    ```
    barman list-backup all
    ```
1. Recover to required point, for example:
    ```
    barman recover pg_cluster 20170815T041301 /var/lib/postgresql/data/ --target-time "2017-08-15 04:11:26.5" --remote-ssh-command="ssh pgmaster"
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
1. Wait until master will fully functional and restart each standby node one by one
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

