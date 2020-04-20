// Used to show the landing page of the application

package dashboard

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/app/handler/statistics"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/cve"
	"net/http"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !(user.Permissions.Glsa.View && user.Permissions.CVETool.View) {
		authentication.AccessDenied(w, r)
		return
	}

	var glsas []*models.Glsa
	user.CanAccess(connection.DB.Model(&glsas).Relation("Creator").Order("updated DESC").Limit(5)).Select()

	var cves []*cve.DefCveItem
	connection.DB.Model(&cves).Order("last_modified_date DESC").Limit(5).Select()

	var comments []*cve.Comment
	connection.DB.Model(&comments).Relation("User").Order("date DESC").Limit(5).Select()

	requests, _ := connection.DB.Model((*models.Glsa)(nil)).Where("type = ?", "request").Count()
	drafts, _ := connection.DB.Model((*models.Glsa)(nil)).Where("type = ?", "draft").Count()
	glsasCount, _ := connection.DB.Model((*models.Glsa)(nil)).Where("type = ?", "glsa").Count()
	allGlsas, _ := connection.DB.Model((*models.Glsa)(nil)).Count()

	new, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "New").Count()
	assigned, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "Assigned").Count()
	nfu, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "NFU").Count()
	later, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "Later").Count()
	invalid, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state = ?", "Invalid").Count()
	allCVEs, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Count()

	statisticsData := statistics.StatisticsData{
		Requests: float64(requests) / float64(allGlsas),
		Drafts:   float64(drafts) / float64(allGlsas),
		Glsas:    float64(glsasCount) / float64(allGlsas),
		New:      float64(new) / float64(allCVEs),
		Assigned: float64(assigned) / float64(allCVEs),
		NFU:      float64(nfu) / float64(allCVEs),
		Later:    float64(later) / float64(allCVEs),
		Invalid:  float64(invalid) / float64(allCVEs),
	}

	renderDashboardTemplate(w, user, glsas, cves, comments, &statisticsData)
}
