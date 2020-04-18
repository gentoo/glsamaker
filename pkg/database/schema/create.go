package schema

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/cve"
	"glsamaker/pkg/models/users"
	"github.com/go-pg/pg/v9"
	"github.com/go-pg/pg/v9/orm"
)

// CreateSchema creates the tables in the database
// in case they don't alreay exist
func CreateSchema(dbCon *pg.DB) error {
	for _, model := range []interface{}{
		(*models.GlobalSettings)(nil),
		(*models.ApplicationSetting)(nil),
		(*users.User)(nil),
		(*models.Session)(nil),
		(*bugzilla.Bug)(nil),
		(*models.Glsa)(nil),
		(*models.GlsaToBug)(nil),
		(*cve.Comment)(nil),
		(*cve.DefCveItem)(nil),
		(*cve.DefCveItemToBug)(nil)} {

		err := dbCon.CreateTable(model, &orm.CreateTableOptions{
			IfNotExists: true,
		})
		if err != nil {
			return err
		}

	}
	return nil
}
