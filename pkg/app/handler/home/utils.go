// miscellaneous utility functions used for the landing page of the application

package home

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderHomeTemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/home/*.tmpl"))

	templates.ExecuteTemplate(w, "home.tmpl", createPageData("home", user))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
	}
}
