// miscellaneous utility functions used for the about pages of the application

package about

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderAboutTemplate renders all templates used for the main about page
func renderAboutTemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/about/*.tmpl"))

	templates.ExecuteTemplate(w, "about.tmpl", createPageData("about", user))
}

// renderAboutSearchTemplate renders all templates used for
// the about page about the search functionality
func renderAboutSearchTemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/about/*.tmpl"))

	templates.ExecuteTemplate(w, "aboutSearch.tmpl", createPageData("about", user))
}

// renderAboutCLITemplate renders all templates used for
// the about page about the command line tool
func renderAboutCLITemplate(w http.ResponseWriter, user *users.User) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/about/*.tmpl"))

	templates.ExecuteTemplate(w, "aboutCLI.tmpl", createPageData("about", user))
}

// createPageData creates the data used in the templates of the about pages
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
