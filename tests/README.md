# Test PostDock

## Requirements to run the tests

* Docker
* Docker-compose

## How to run tests

From the root of the project simply run command `./tests/run.sh` and see results on the screen
You can pass only one argument - string with names of the tests you want to run(e.g `./tests/run.sh "test1 test2"`), basically it should be names of directories under `./tests`

Some binary ENV variables for tests runner(By default everything is `0`, you can set it to `1` or any non-zero value):

* `TEST_COMBINATIONS` - array of combinations to run (e.g. `postgres-9.6_pgpool-3.3_barman-2.3 postgres-10.1_pgpool-3.6_barman-2.3`) should be one or set of filenames from directory [docker-compose](../docker-compose) (without extension `.yml`)
* `NO_COLOURS` - disable fancy coloured output
* `DEBUG` - will output everything from tests scripts
* `NO_CLEANUP` - will not destroy `docker-compose` environment after each test
* `SKIP_BUILD` - allow to avoid rebuilding of all images for tests on start (required images would be built on test run anyways )

## How to create a new test

Create a new file `./tests/MY_AWESOME_TEST/run.sh` and return code from it:

* `0` - test passed
* `*` - test failed - STDOUT might contain description

Context of the test will be **root** folder of the repository.