// Copyright 2016 Attic Labs, Inc. All rights reserved.
// Licensed under the Apache License, version 2.0:
// http://www.apache.org/licenses/LICENSE-2.0

package main

import (
	"context"
	"fmt"

	flag "github.com/juju/gnuflag"
	"github.com/liquidata-inc/ld/dolt/go/store/cmd/noms/util"
	"github.com/liquidata-inc/ld/dolt/go/store/config"
	"github.com/liquidata-inc/ld/dolt/go/store/types"
	"github.com/liquidata-inc/ld/dolt/go/store/util/verbose"
)

var toDelete string

var nomsDs = &util.Command{
	Run:       runDs,
	UsageLine: "ds [<database> | -d <dataset>]",
	Short:     "Noms dataset management",
	Long:      "See Spelling Objects at https://github.com/attic-labs/noms/blob/master/doc/spelling.md for details on the database and dataset arguments.",
	Flags:     setupDsFlags,
	Nargs:     0,
}

func setupDsFlags() *flag.FlagSet {
	dsFlagSet := flag.NewFlagSet("ds", flag.ExitOnError)
	dsFlagSet.StringVar(&toDelete, "d", "", "dataset to delete")
	verbose.RegisterVerboseFlags(dsFlagSet)
	return dsFlagSet
}

func runDs(ctx context.Context, args []string) int {
	cfg := config.NewResolver()
	if toDelete != "" {
		db, set, err := cfg.GetDataset(ctx, toDelete)
		util.CheckError(err)
		defer db.Close()

		oldCommitRef, errBool := set.MaybeHeadRef()
		if !errBool {
			util.CheckError(fmt.Errorf("Dataset %v not found", set.ID()))
		}

		_, err = set.Database().Delete(ctx, set)
		util.CheckError(err)

		fmt.Printf("Deleted %v (was #%v)\n", toDelete, oldCommitRef.TargetHash().String())
	} else {
		dbSpec := ""
		if len(args) >= 1 {
			dbSpec = args[0]
		}
		store, err := cfg.GetDatabase(ctx, dbSpec)
		util.CheckError(err)
		defer store.Close()

		store.Datasets(ctx).IterAll(ctx, func(k, v types.Value) {
			fmt.Println(k)
		})
	}
	return 0
}