package cvetool

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/cve"
	"net/http"
)

// Show renders a template to show the landing page of the application
func AssignBug(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.AssignBug {
		authentication.AccessDenied(w, r)
		return
	}

	cveId, bugId, err := getBugAssignParams(r)

	// TODO validate bug using bugzilla api before continue

	cveItem := &cve.DefCveItem{Id: cveId}
	err = connection.DB.Select(cveItem)

	if err != nil {
		w.Write([]byte("err"))
		return
	}

	cveItem.State = "Assigned"

	logger.Info.Println("bugId")
	logger.Info.Println(bugId)

	//assign bug
	newBugs := bugzilla.GetBugsByIds([]string{bugId})

	for _, newBug := range newBugs {
		_, err = connection.DB.Model(&newBug).OnConflict("(id) DO UPDATE").Insert()

		if err != nil {
			logger.Info.Println("Error creating bug")
			logger.Info.Println(err)
		}

		cveToBug := &cve.DefCveItemToBug{
			DefCveItemId: cveId,
			BugId:        newBug.Id,
		}

		connection.DB.Model(cveToBug).Insert()

	}

	// TODO MIGRATION
	//cveItem.Bugs = append(cveItem.Bugs, bugId)

	_, err = connection.DB.Model(cveItem).Column("bugs").WherePK().Update()
	_, err = connection.DB.Model(cveItem).Column("state").WherePK().Update()

	if err != nil {
		logger.Info.Println("Err")
		logger.Info.Println(err)
		w.Write([]byte("err"))
		return
	}

	w.Write([]byte("ok"))

}

func getBugAssignParams(r *http.Request) (string, string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", err
	}
	cveid := r.Form.Get("cveid")
	bugid := r.Form.Get("bugid")
	return cveid, bugid, err
}
