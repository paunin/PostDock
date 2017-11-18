package main

import "testing"
import "fmt"
import "os"
import "github.com/stretchr/testify/assert"
import "github.com/stretchr/testify/suite"
import "net/http"
import "net/http/httptest"
import "os/exec"
import "io/ioutil"
import "strconv"

var fakeExitCode = 0

type MainTestSuite struct {
    suite.Suite
    testHandler http.HandlerFunc
    rr *httptest.ResponseRecorder
    req *http.Request
}

func TestAll(t *testing.T) {
    execCommand = fakeExecCommand
    suite.Run(t, new(MainTestSuite))
}

func (suite *MainTestSuite) SetupTest() {
    fakeExitCode = 0
    var err error
    suite.req, err = http.NewRequest("GET", "http://localhost:8080/metrics", nil)
    if err != nil {
        panic(err.Error())
    }

    suite.rr = httptest.NewRecorder()
    suite.testHandler = http.HandlerFunc(handler)
}

func (suite *MainTestSuite) TestBarmanCheckFailed() {
    fakeExitCode = 1
    suite.testHandler.ServeHTTP(suite.rr, suite.req)

    if status := suite.rr.Code; status != http.StatusOK {
        suite.T().Errorf("handler returned wrong status code: got %v want %v",
        status, http.StatusOK)
    }

    resp := suite.rr.Body.String();
    assert.Contains(suite.T(), resp, "barman_check_is_ok 0")
}

func (suite *MainTestSuite) TestHandler() {
    suite.testHandler.ServeHTTP(suite.rr, suite.req)

    if status := suite.rr.Code; status != http.StatusOK {
        suite.T().Errorf("handler returned wrong status code: got %v want %v",
        status, http.StatusOK)
    }

    resp := suite.rr.Body.String();
    assert.Contains(suite.T(), resp, "barman_check_is_ok 1")
    assert.Contains(suite.T(), resp, "barman_backups_amount 2")
    assert.Contains(suite.T(), resp, "barman_last_backup_start_time_seconds 1503656945")
    assert.Contains(suite.T(), resp, "barman_last_backup_end_time_seconds 1503656955")
    assert.Contains(suite.T(), resp, "barman_last_backup_size_bytes 36304273")
    assert.Contains(suite.T(), resp, "barman_last_backup_duration_copy_seconds 5")
    assert.Contains(suite.T(), resp, "barman_last_backup_duration_total_seconds 10")
    assert.Contains(suite.T(), resp, "barman_oldest_backup_end_time_seconds 1503570545")
    assert.Contains(suite.T(), resp, "barman_disk_free_bytes ")
    assert.Contains(suite.T(), resp, "barman_disk_used_bytes ")
}

func fakeExecCommand(command string, args...string) *exec.Cmd {
    cs := []string{"-test.run=TestHelperProcess", "--", command}
    cs = append(cs, args...)
    cmd := exec.Command(os.Args[0], cs...)
    cmd.Env = []string{"GO_WANT_HELPER_PROCESS=1", "GO_FAKE_EXIT_CODE=" + strconv.Itoa(fakeExitCode)}
    return cmd
}

func TestHelperProcess(t *testing.T){
    if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
        return
    }
    command := os.Args[3]
    arguments := os.Args[4:]

    switch command {
        case "barman":
            switch arguments[0] {
            case "diagnose":
                testfile, err := ioutil.ReadFile("test.json")
                if err != nil {
                    panic(err.Error())
                }
                fmt.Fprintf(os.Stdout, string(testfile))
            case "check":
                if arguments[1] != "all" {
                    os.Exit(2)
                }
                code, err := strconv.Atoi(os.Getenv("GO_FAKE_EXIT_CODE"))
                if err != nil {
                    panic(err.Error())
                }
                os.Exit(code)
            default:
                fmt.Fprintf(os.Stderr, "Unknown barman command call")
                os.Exit(1)
            }
        default:
            fmt.Fprintf(os.Stderr, "Unknown command call")
            os.Exit(2)
    }

    os.Exit(0)
}
