// miscellaneous utility functions used for the landing page of the application

package cvetool

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderIndexTemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/index/*.tmpl"))

	templates.ExecuteTemplate(w, "show.tmpl", createPageData("cvetool", user))
}

// renderIndexTemplate renders all templates used for the landing page
func renderIndexFullscreenTemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/index/*.tmpl"))

	templates.ExecuteTemplate(w, "showFullscreen.tmpl", createPageData("cvetool", user))
}

// renderIndexTemplate renders all templates used for the landing page
func renderNewCVETemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/index/new.tmpl"))

	templates.ExecuteTemplate(w, "new.tmpl", createPageData("cvetool", user))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		CanEdit     bool
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		CanEdit:     user.CanEditCVEs(),
	}
}
