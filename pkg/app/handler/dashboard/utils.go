// miscellaneous utility functions used for the landing page of the application

package dashboard

import (
	"glsamaker/pkg/app/handler/statistics"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/cve"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderDashboardTemplate(w http.ResponseWriter, user *users.User, glsas []*models.Glsa, cves []*cve.DefCveItem, comments []*cve.Comment, statisticsData *statistics.StatisticsData) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/dashboard/*.tmpl"))

	templates.ExecuteTemplate(w, "dashboard.tmpl", createPageData("dashboard", user, glsas, cves, comments, statisticsData))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, glsas []*models.Glsa, cves []*cve.DefCveItem, comments []*cve.Comment, statisticsData *statistics.StatisticsData) interface{} {
	return struct {
		Page           string
		Application    *models.GlobalSettings
		User           *users.User
		GLSAs          []*models.Glsa
		CVEs           []*cve.DefCveItem
		Comments       []*cve.Comment
		StatisticsData *statistics.StatisticsData
	}{
		Page:           page,
		Application:    models.GetDefaultGlobalSettings(),
		User:           user,
		GLSAs:          glsas,
		CVEs:           cves,
		Comments:       comments,
		StatisticsData: statisticsData,
	}
}
