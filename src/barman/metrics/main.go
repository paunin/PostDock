package main

import (
    "fmt"
    "net/http"
    "os/exec"
    "encoding/json"
    // "github.com/davecgh/go-spew/spew"
    "syscall"
    "time"
    "strings"
    "sort"
)

func main() {
    http.HandleFunc("/metrics", handler)
    http.ListenAndServe(":8080", nil)
    fmt.Printf("Server is listeinging on :8080. Metrics URL — /metrics")
}

func handler(w http.ResponseWriter, r *http.Request) {
    for k, v := range collectMetrics() {
        fmt.Fprintf(w, "%s %d\n", k, v)
    }
}

func collectMetrics() map[string]int64 {
    metrics := make(map[string]int64)

    diagnose := barmanDiagnose()
    backups := diagnose.Servers.Pg_cluster.Backups
    backups = FilterBackups(backups, func(b BarmanBackup) bool {
        return b.Status == "DONE"
    })

    metrics["barman_check_is_ok"] = int64(barmanCheck())
    metrics["barman_backups_amount"] = int64(len(backups))
    if (len(backups) > 0) {
        var keys []string
        for k := range backups {
            keys = append(keys, k)
        }
        sort.Strings(keys)
        latestBackup := backups[keys[len(keys)-1]]
        oldestBackup := backups[keys[0]]
        metrics["barman_last_backup_start_time_seconds"] = latestBackup.Begin_time.Unix()
        metrics["barman_last_backup_end_time_seconds"] = latestBackup.End_time.Unix()
        metrics["barman_last_backup_size_bytes"] = latestBackup.Size
        metrics["barman_last_backup_duration_total_seconds"] = int64(latestBackup.Copy_stats["total_time"])
        metrics["barman_last_backup_duration_copy_seconds"] = int64(latestBackup.Copy_stats["copy_time"])
        metrics["barman_oldest_backup_end_time_seconds"] = oldestBackup.End_time.Unix()
    }

    var diskUsage syscall.Statfs_t
    syscall.Statfs("/var/backups", &diskUsage)
    metrics["barman_disk_free_bytes"] = int64(diskUsage.Bavail * uint64(diskUsage.Bsize))
    metrics["barman_disk_used_bytes"] = int64((diskUsage.Blocks - diskUsage.Bfree) * uint64(diskUsage.Bsize))

    return metrics
}

func FilterBackups(backups map[string]BarmanBackup, filter func(BarmanBackup) bool) map[string]BarmanBackup {
    result := make(map[string]BarmanBackup, len(backups))
    for key, backup := range backups {
        if filter(backup) {
            result[key] = backup
        }
    }
    return result
}

var execCommand = exec.Command
func barmanCheck() int {
    checkCmd := execCommand("barman", "check", "all")
    checkErr := checkCmd.Run()

    barman_check_ok := 1
    if checkErr != nil {
        barman_check_ok = 0
    }

    return barman_check_ok
}

type BarmanDiagnose struct {
    Servers struct {
        Pg_cluster struct {
            Backups map[string]BarmanBackup
        }
    }
}

type BarmanBackup struct {
    Backup_id string
    Begin_time CustomTime
    End_time CustomTime
    Copy_stats map[string]float64
    Size int64
    Status string
}

func barmanDiagnose() BarmanDiagnose {
    cmd := execCommand("barman", "diagnose")
    result, err := cmd.Output()
    if err != nil {
        panic(string(result))
    }

    var diag BarmanDiagnose
    jsonErr := json.Unmarshal(result, &diag)
    if jsonErr != nil {
        panic(jsonErr)
    }

    return diag
}

type CustomTime struct {
    time.Time
}

const ctLayout = "Mon Jan 2 15:04:05 2006"

func (ct *CustomTime) UnmarshalJSON(b []byte) (err error) {
    s := strings.Trim(string(b), "\"")
    if s == "null" {
        ct.Time = time.Time{}
        return
    }
    ct.Time, err = time.Parse(ctLayout, s)
    return
}

func (ct *CustomTime) MarshalJSON() ([]byte, error) {
    if ct.Time.UnixNano() == nilTime {
        return []byte("null"), nil
    }
    return []byte(fmt.Sprintf("\"%s\"", ct.Time.Format(ctLayout))), nil
}

var nilTime = (time.Time{}).UnixNano()
func (ct *CustomTime) IsSet() bool {
    return ct.UnixNano() != nilTime
}

