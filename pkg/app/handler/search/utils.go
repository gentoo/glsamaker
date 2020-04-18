// miscellaneous utility functions used for the landing page of the application

package search

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderSearchTemplate(w http.ResponseWriter, user *users.User, searchQuery string, searchResults []*models.Glsa) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/search/*.tmpl"))

	templates.ExecuteTemplate(w, "search.tmpl", createPageData("search", user, searchQuery, searchResults))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, searchQuery string, searchResults []*models.Glsa) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		GLSAs       []*models.Glsa
		SearchQuery string
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		GLSAs:       searchResults,
		SearchQuery: searchQuery,
	}
}
