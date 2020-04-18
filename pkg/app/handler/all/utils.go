// miscellaneous utility functions used for the landing page of the application

package all

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderAllTemplate(w http.ResponseWriter, user *users.User, all []*models.Glsa) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/all/*.tmpl"))

	templates.ExecuteTemplate(w, "all.tmpl", createPageData("all", user, all))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, all []*models.Glsa) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		All         []*models.Glsa
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		All:         all,
	}
}
