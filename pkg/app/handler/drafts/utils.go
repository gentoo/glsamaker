// miscellaneous utility functions used for the landing page of the application

package drafts

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderDraftsTemplate(w http.ResponseWriter, user *users.User, drafts []*models.Glsa) {

	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/drafts/*.tmpl"))

	templates.ExecuteTemplate(w, "drafts.tmpl", createPageData("drafts", user, drafts))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, drafts []*models.Glsa) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		Drafts      []*models.Glsa
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		Drafts:      drafts,
	}
}
