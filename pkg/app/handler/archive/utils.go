// miscellaneous utility functions used for the landing page of the application

package archive

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderArchiveTemplate(w http.ResponseWriter, user *users.User, glsas []*models.Glsa) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/archive/*.tmpl"))

	templates.ExecuteTemplate(w, "archive.tmpl", createPageData("archive", user, glsas))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, glsas []*models.Glsa) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		GLSAs       []*models.Glsa
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		GLSAs:       glsas,
	}
}
