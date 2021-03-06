package main

import (
	"glsamaker/pkg/app"
	"glsamaker/pkg/config"
	"glsamaker/pkg/cveimport"
	"glsamaker/pkg/logger"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"time"
)

func printHelp() {
	fmt.Println("Please specific one of the following options:")
	fmt.Println("  glsamaker --update       -- incrementally import cve's and update the database")
	fmt.Println("  glsamaker --full-update  -- import all cve's and update the database")
	fmt.Println("  glsamaker --serve        -- serve the application")
}

func isCommand(command string) bool {
	return len(os.Args) > 1 && os.Args[1] == command
}

func main() {

	errorLogFile := logger.CreateLogFile(config.LogFile())
	defer errorLogFile.Close()
	initLoggers(os.Stdout, errorLogFile)

	if isCommand("--serve") {
		waitForPostgres(10)
		app.Serve()
	} else if isCommand("--full-update") {
		waitForPostgres(5)
		cveimport.FullUpdate()
	} else if isCommand("--update") {
		waitForPostgres(7)
		cveimport.Update()
	} else {
		printHelp()
	}

}

// initialize the loggers depending on whether
// config.debug is set to true
func initLoggers(infoHandler io.Writer, errorHandler io.Writer) {
	if config.Debug() == "true" {
		logger.Init(os.Stdout, infoHandler, errorHandler)
	} else {
		logger.Init(ioutil.Discard, infoHandler, errorHandler)
	}
}

// TODO this has to be solved differently
// wait for postgres to come up
func waitForPostgres(seconds int) {
	time.Sleep(time.Duration(seconds) * time.Second)
}
