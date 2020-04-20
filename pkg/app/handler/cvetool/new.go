package cvetool

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/cve"
	"net/http"
	"strconv"
	"time"
)

// Show renders a template to show the landing page of the application
func New(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.AddCVE {
		authentication.AccessDenied(w, r)
		return
	}

	id, baseScore, summary, err := getNewCVEParams(r)
	parsedBaseScore, baseScorErr := strconv.ParseFloat(baseScore, 64)


	if r.Method == "GET" || err != nil || baseScorErr != nil || id == "" {
		renderNewCVETemplate(w, user)
		return
	}
	
	newCVE := &cve.DefCveItem{
		Id:               id,
		State:            "New",
		Configurations:   nil,
		Cve:              cve.CVE{
			Affects:     nil,
			CVEDataMeta: nil,
			DataFormat:  "",
			DataType:    "",
			DataVersion: "",
			Description: nil,
			Problemtype: nil,
			References:  &cve.References{ReferenceData: []*cve.Reference{}},
		},
		Description:      summary,
		Impact:           &cve.DefImpact{
			BaseMetricV3: cve.BaseMetricV3{
				CvssV3:              cve.CvssV3{
					BaseScore:       parsedBaseScore,
				},
			},
		},
		LastModifiedDate: time.Now().String(),
		PublishedDate:    time.Now().String(),
		ManuallyCreated:  true,
		Comments:         nil,
		Packages:         nil,
		Bugs:             nil,
	}

	_, err = connection.DB.Model(newCVE).OnConflict("(id) DO UPDATE").Insert()
	if err != nil {
		logger.Error.Println("Err during CVE insert")
		logger.Error.Println(err)
	}

	http.Redirect(w, r, "/cve/tool", 301)
}



func getNewCVEParams(r *http.Request) (string, string, string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", "", err
	}
	id := r.Form.Get("id")
	basescore := r.Form.Get("basescore")
	summary := r.Form.Get("summary")
	return id, basescore, summary, err
}
