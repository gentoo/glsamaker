// Used to show the landing page of the application

package cvetool

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/cve"
	"encoding/json"
	"fmt"
	"github.com/go-pg/pg/v9/orm"
	"glsamaker/pkg/models/users"
	"html"
	"net/http"
	"strconv"
	"strings"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.View {
		authentication.AccessDenied(w, r)
		return
	}

	renderIndexTemplate(w, user)
}

// Show renders a template to show the landing page of the application
func ShowFullscreen(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.View {
		authentication.AccessDenied(w, r)
		return
	}

	renderIndexFullscreenTemplate(w, user)
}

// Show renders a template to show the landing page of the application
func Add(w http.ResponseWriter, r *http.Request) {
	//renderIndexTemplate(w)
}

// Show renders a template to show the landing page of the application
func CveData(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.View {
		authentication.AccessDenied(w, r)
		return
	}

	type DataTableData struct {
		Draw            int        `json:"draw"`
		RecordsTotal    int        `json:"recordsTotal"`
		RecordsFiltered int        `json:"recordsFiltered"`
		Data            [][]string `json:"data"`
	}

	draw, _ := strconv.Atoi(getParam(r, "draw"))
	start, _ := strconv.Atoi(getParam(r, "start"))
	length, _ := strconv.Atoi(getParam(r, "length"))
	order_column := getParam(r, "order[0][column]")
	order_dir := strings.ToUpper(getParam(r, "order[0][dir]"))
	search_value := strings.ToUpper(getParam(r, "search[value]"))

	state_value := getParam(r, "columns[10][search][value]")
	logger.Info.Println("state_value")
	logger.Info.Println(state_value)

	count_overall, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Count()
	count, _ := connection.DB.Model((*cve.DefCveItem)(nil)).Where("state LIKE " + "'%" + state_value + "%'").WhereGroup(func(q *orm.Query) (*orm.Query, error) {
		q = q.WhereOr("description LIKE " + "'%" + search_value + "%'").
			WhereOr("id LIKE " + "'%" + search_value + "%'")
		return q, nil
	}).Count()

	order := "id"
	if order_column == "0" {
		order = "id"
	} else if order_column == "8" {
		order = "last_modified_date"
	} else if order_column == "9" {
		order = "published_date"
	} else if order_column == "10" {
		order = "state"
	}

	var dataTableEntries [][]string
	var cves []*cve.DefCveItem
	err := connection.DB.Model(&cves).Order(order + " " + order_dir).Offset(start).Limit(length).Where("state LIKE " + "'%" + state_value + "%'").WhereGroup(func(q *orm.Query) (*orm.Query, error) {
		q = q.WhereOr("description LIKE " + "'%" + search_value + "%'").
			WhereOr("id LIKE " + "'%" + search_value + "%'")
		return q, nil
	}).Relation("Bugs").Relation("Comments").Relation("Comments.User").Select()

	if err != nil || len(cves) == 0 {
		logger.Info.Println("Error finding cves:")
		logger.Info.Println(err)
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"draw":` + strconv.Itoa(draw) + `,"recordsTotal":` + strconv.Itoa(count_overall) + `,"recordsFiltered":0,"data":[]}`))
		return
	} else {
		for _, cve := range cves {

			// TODO handle empty

			baseScore := ""
			impact := ""
			if cve.Impact != nil {
				baseScore = fmt.Sprintf("%.2f", cve.Impact.BaseMetricV3.CvssV3.BaseScore)
				impact = cve.Impact.BaseMetricV3.CvssV3.VectorString
			}

			var referenceList []string
			for _, reference := range cve.Cve.References.ReferenceData {
				referenceList = append(referenceList, "<a href=\""+reference.Url+"\">source</a>")
				//referenceList = append(referenceList, "<a href=\"" + reference.Url + "\">" + strings.ToLower(reference.Refsource) + "</a>")
			}
			references := strings.Join(referenceList, ", ")

			for k,_ := range cve.Comments {
				cve.Comments[k].Message = html.EscapeString(cve.Comments[k].Message)
				cve.Comments[k].User = &users.User{
					Id:                      cve.Comments[k].User.Id,
					Email:                   cve.Comments[k].User.Email,
					Nick:                    cve.Comments[k].User.Nick,
					Name:                    cve.Comments[k].User.Name,
					Password:                users.Argon2Parameters{},
					Badge:                   cve.Comments[k].User.Badge,
				}
			}

			comments, _ := json.Marshal(cve.Comments)

			packages, _ := json.Marshal(cve.Packages)
			bugs, _ := json.Marshal(cve.Bugs)

			dataTableEntries = append(dataTableEntries, []string{
				cve.Id,
				cve.Description,
				string(packages), // TODO MIGRATION strings.Join(cve.Packages, ","),
				string(bugs),     // TODO MIGRATION strings.Join(cve.Bugs, ","),
				baseScore,
				impact,
				references,
				string(comments),
				cve.LastModifiedDate,
				cve.PublishedDate,
				cve.State,
				"changelog"})
		}
	}

	dataTableData := DataTableData{
		Draw:            draw,
		RecordsTotal:    count_overall,
		RecordsFiltered: count,
		Data:            dataTableEntries,
	}

	res, _ := json.Marshal(dataTableData)

	w.Header().Set("Content-Type", "application/json")
	w.Write(res)
}

func getParam(r *http.Request, keyname string) string {
	keys, ok := r.URL.Query()[keyname]
	if !ok || len(keys[0]) < 1 {
		return ""
	}
	result := keys[0]
	return result
}
