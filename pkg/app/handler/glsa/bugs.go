package glsa

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/bugzilla"
	"net/http"
	"strconv"
)

// Show renders a template to show the landing page of the application
func UpdateBugs(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.UpdateBugs {
		authentication.AccessDenied(w, r)
		return
	}

	go bugUpdate()

	http.Redirect(w, r, "/", 301)
}

func bugUpdate() {

	var allBugs []*bugzilla.Bug
	connection.DB.Model(&allBugs).Select()

	var bugIdsLists [][]string
	bugIdsLists = append(bugIdsLists, []string{})
	for _, bug := range allBugs {
		lastElem := bugIdsLists[len(bugIdsLists)-1]

		if len(lastElem) < 100 {
			bugIdsLists[len(bugIdsLists)-1] = append(lastElem, strconv.FormatInt(bug.Id, 10))
		} else {
			bugIdsLists = append(bugIdsLists, []string{strconv.FormatInt(bug.Id, 10)})
		}
	}

	for _, bugIdsList := range bugIdsLists {
		updatedBugs := bugzilla.GetBugsByIds(bugIdsList)

		for _, updatedBug := range updatedBugs {
			_, err := connection.DB.Model(&updatedBug).WherePK().Update()
			if err != nil {
				logger.Error.Println("Error during bug data update")
				logger.Error.Println(err)
			}
		}
	}

	// Possibly delete deleted bugs
	// Do we even delete bugs?

	// update the time of the last bug update
	models.SetApplicationValue("LastBugUpdate", "")
}
