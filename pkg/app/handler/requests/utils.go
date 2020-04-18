// miscellaneous utility functions used for the landing page of the application

package requests

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderRequestsTemplate(w http.ResponseWriter, user *users.User, requests []*models.Glsa) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/requests/*.tmpl"))

	templates.ExecuteTemplate(w, "requests.tmpl", createPageData("requests", user, requests))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, requests []*models.Glsa) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		Requests    []*models.Glsa
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		Requests:    requests,
	}
}
