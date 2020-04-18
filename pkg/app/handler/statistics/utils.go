// miscellaneous utility functions used for the landing page of the application

package statistics

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderStatisticsTemplate(w http.ResponseWriter, user *users.User, statisticsData *StatisticsData) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/statistics/*.tmpl"))

	templates.ExecuteTemplate(w, "statistics.tmpl", createPageData("statistics", user, statisticsData))
}

type StatisticsData struct {
	Requests float64
	Drafts   float64
	Glsas    float64
	// CVEs
	New      float64
	Assigned float64
	NFU      float64
	Later    float64
	Invalid  float64
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, statisticsData *StatisticsData) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		Data        *StatisticsData
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		Data:        statisticsData,
	}
}
