#!/usr/bin/env bats

setup() {
    export PATH=$PATH:~/go/bin
    export NOMS_VERSION_NEXT=1
    cd $BATS_TMPDIR
    mkdir dolt-repo
    cd dolt-repo
    dolt init
}

teardown() {
    rm -rf $BATS_TMPDIR/dolt-repo
}

@test "create a single primary key table" {
    run dolt table create -s=$BATS_TEST_DIRNAME/helper/1pk5col.schema test
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "create a two primary key table" {
    run dolt table create -s=$BATS_TEST_DIRNAME/helper/2pk5col.schema test
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "create a repo with two tables" {
    dolt table create -s=$BATS_TEST_DIRNAME/helper/1pk5col.schema test1
    dolt table create -s=$BATS_TEST_DIRNAME/helper/2pk5col.schema test2
    run dolt ls
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test1" ]]
    [[ "$output" =~ "test2" ]]
    [ "${#lines[@]}" -eq 3 ]
}

@test "create a table with json import" {
    run dolt table import -c -s $BATS_TEST_DIRNAME/helper/employees-sch.json employees $BATS_TEST_DIRNAME/helper/employees-tbl.json
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    run dolt table select employees
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tim" ]]
    [ "${#lines[@]}" -eq 4 ]
}

@test "create a table with json import. no schema" {
    run dolt table import -c employees $BATS_TEST_DIRNAME/helper/employees-tbl.json
    [ "$status" -ne 0 ]
    [ "$output" = "Please specify schema file for .json tables." ] 
}

@test "import data from csv and create the table" {
    run dolt table import -c --pk=pk test $BATS_TEST_DIRNAME/helper/1pk5col.csv
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    run dolt table select test
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "import data from psv and create the table" {
    run dolt table import -c --pk=pk test $BATS_TEST_DIRNAME/helper/1pk5col.psv
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    run dolt table select test
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "create two table with the same name" {
    dolt table create -s=$BATS_TEST_DIRNAME/helper/1pk5col.schema test
    run dolt table create -s=$BATS_TEST_DIRNAME/helper/1pk5col.schema test
    [ "$status" -ne 0 ]
    [[ "$output" =~ "already exists." ]]
}

@test "reproduce the nutrition dataset bug" {
    run dolt table import -c --pk=NDB_Number test $BATS_TEST_DIRNAME/helper/nutrition-bug.csv
    skip "This throws an Error determining the output schema error. Should work"
    [ "$status" -eq 0 ]
}