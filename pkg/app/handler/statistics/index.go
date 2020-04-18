// Used to show the landing page of the application

package statistics

import (
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/cve"
	"net/http"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	requests, _ := connection.DB.Model((*models.Glsa)(nil)).Where("type = ?", "request").Count()
	drafts, _ := connection.DB.Model((*models.Glsa)(nil)).Where("type = ?", "draft").Count()
	glsas, _ := connection.DB.Model((*models.Glsa)(nil)).Where("type = ?", "glsa").Count()
	allGlsas, _ := connection.DB.Model((*models.Glsa)(nil)).Count()

	new, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "New").Count()
	assigned, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "Assigned").Count()
	nfu, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "NFU").Count()
	later, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "Later").Count()
	invalid, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "Invalid").Count()
	allCVEs, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Count()

	statisticsData := StatisticsData{
		Requests: float64(requests) / float64(allGlsas),
		Drafts:   float64(drafts) / float64(allGlsas),
		Glsas:    float64(glsas) / float64(allGlsas),
		New:      float64(new) / float64(allCVEs),
		Assigned: float64(assigned) / float64(allCVEs),
		NFU:      float64(nfu) / float64(allCVEs),
		Later:    float64(later) / float64(allCVEs),
		Invalid:  float64(invalid) / float64(allCVEs),
	}

	renderStatisticsTemplate(w, user, &statisticsData)
}
