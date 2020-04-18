// miscellaneous utility functions used for the landing page of the application

package newRequest

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderNewTemplate(w http.ResponseWriter, user *users.User, newID string) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/new/*.tmpl"))

	templates.ExecuteTemplate(w, "new.tmpl", createPageData("new", user, newID))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, newID string) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		NewID       string
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		NewID:       newID,
	}
}
