// Contains utility functions around the database

package database

import (
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/database/schema"
	"glsamaker/pkg/logger"
	"log"
)

// Connect is used to connect to the database
// and turn on logging if desired
func Connect() {
	connection.Connect()
	err := schema.CreateSchema(connection.DB)
	if err != nil {
		logger.Error.Println("ERROR: Could not create database schema")
		logger.Error.Println(err)
		log.Fatalln(err)
	}

}
