// Contains utility functions around the database

package connection

import (
	"glsamaker/pkg/config"
	"glsamaker/pkg/logger"
	"context"
	"github.com/go-pg/pg/v9"
)

// DBCon is the connection handle
// for the database
var (
	DB *pg.DB
)

type dbLogger struct{}

func (d dbLogger) BeforeQuery(c context.Context, q *pg.QueryEvent) (context.Context, error) {
	return c, nil
}

// AfterQuery is used to log SQL queries
func (d dbLogger) AfterQuery(c context.Context, q *pg.QueryEvent) error {
	logger.Debug.Println(q.FormattedQuery())
	return nil
}

// Connect is used to connect to the database
// and turn on logging if desired
func Connect() {
	DB = pg.Connect(&pg.Options{
		User:     config.PostgresUser(),
		Password: config.PostgresPass(),
		Database: config.PostgresDb(),
		Addr:     config.PostgresHost() + ":" + config.PostgresPort(),
	})

	DB.AddQueryHook(dbLogger{})

}
