## Metrics

Metrics are exposed in prometheus format on `:8080/metrics` via small go deamon which collects data from `fs`, `barman diagnose` and `barman check` commands.

Type of all metrics is GAUGE.
Available metrics are:
 * `barman_check_is_ok` 0 or 1. 1 means ok and returned when exit code of `barman check` is 0
 * `barman_backups_amount`
 * `barman_last_backup_start_time_seconds`
 * `barman_last_backup_end_time_seconds`
 * `barman_last_backup_size_bytes`
 * `barman_last_backup_duration_total_seconds`
 * `barman_last_backup_duration_copy_seconds`
 * `barman_oldest_backup_end_time_seconds`
 * `barman_backup_disk_free_bytes`
 * `barman_backup_disk_used_bytes`
