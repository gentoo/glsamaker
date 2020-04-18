// Used to show the landing page of the application

package search

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"github.com/go-pg/pg/v9/orm"
	"net/http"
	"strconv"
)

// Show renders a template to show the landing page of the application
func Search(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	keys, ok := r.URL.Query()["q"]

	if !ok || len(keys[0]) < 1 {
		http.NotFound(w, r)
		return
	}

	// Query()["key"] will return an array of items,
	// we only want the single item.
	key := keys[0]

	// redirect to glsa if isNumeric
	if _, err := strconv.Atoi(key); err == nil {
		http.Redirect(w, r, "/glsa/"+key, 301)
	}

	if key == "#home" {
		http.Redirect(w, r, "/", 301)
		return
	} else if key == "#dashboard" {
		http.Redirect(w, r, "/dashboard", 301)
		return
	} else if key == "#new" {
		http.Redirect(w, r, "/new", 301)
		return
	} else if key == "#cvetool" {
		http.Redirect(w, r, "/cve/tool", 301)
		return
	} else if key == "#requests" {
		http.Redirect(w, r, "/requests", 301)
		return
	} else if key == "#drafts" {
		http.Redirect(w, r, "/drafts", 301)
		return
	} else if key == "#all" {
		http.Redirect(w, r, "/all", 301)
		return
	} else if key == "#archive" {
		http.Redirect(w, r, "/archive", 301)
		return
	} else if key == "#about" {
		http.Redirect(w, r, "/about", 301)
		return
	} else if key == "#bugzilla" {
		http.Redirect(w, r, "https://bugs.gentoo.org/", 301)
		return
	} else if key == "#admin" {
		http.Redirect(w, r, "/admin", 301)
		return
	} else if key == "#password" {
		http.Redirect(w, r, "/account/password", 301)
		return
	} else if key == "#2fa" {
		http.Redirect(w, r, "/account/2fa", 301)
		return
	} else if key == "#statistics" {
		http.Redirect(w, r, "/statistics", 301)
		return
	}

	if key == "#logout" {
		http.Redirect(w, r, "/logout", 301)
		return
	}

	if !user.Permissions.Glsa.View {
		authentication.AccessDenied(w, r)
		return
	}

	var glsas []*models.Glsa
	err := user.CanAccess(connection.DB.Model(&glsas).
		Relation("Bugs").
		Relation("Comments").
		Relation("Creator").
		WhereGroup(func(q *orm.Query) (*orm.Query, error) {
			q = q.WhereOr("title LIKE " + "'%" + key + "%'").
				WhereOr("type LIKE " + "'%" + key + "%'").
				WhereOr("synopsis LIKE " + "'%" + key + "%'").
				WhereOr("description LIKE " + "'%" + key + "%'").
				WhereOr("workaround LIKE " + "'%" + key + "%'").
				WhereOr("resolution LIKE " + "'%" + key + "%'").
				WhereOr("keyword LIKE " + "'%" + key + "%'").
				WhereOr("background LIKE " + "'%" + key + "%'")
				//WhereOr("creator LIKE " + "'%" + key + "%'")
			return q, nil
		})).
		Select()

	// TODO search in comments
	// TODO search in bugs

	if err != nil {
		logger.Info.Println("Error during searching")
		logger.Info.Println(err)
		http.NotFound(w, r)
		return
	}

	for _, glsa := range glsas {
		glsa.ComputeStatus(user)
	}

	renderSearchTemplate(w, user, key, glsas)

}
