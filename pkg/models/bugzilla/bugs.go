package bugzilla

import (
	"encoding/json"
	"glsamaker/pkg/database/connection"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
)

type Bugs struct {
	Bugs []Bug
}

// missing flags
type Bug struct {
	Id                  int64         `json:"id" pg:",pk"`
	Alias               []string      `json:"alias"`
	AssignedTo          string        `json:"assigned_to"`
	AssignedToDetail    Contributor   `json:"assigned_to"`
	Blocks              []int64       `json:"blocks"`
	CC                  []string      `json:"cc"`
	CCDetail            []Contributor `json:"cc_detail"`
	Classification      string        `json:"classification"`
	Component           string        `json:"component"`
	CreationTime        string        `json:"creation_time"`
	Creator             string        `json:"creator"`
	CreatorDetail       Contributor   `json:"creator_detail"`
	DependsOn           []int64       `json:"depends_on"`
	DupeOf              int64         `json:"dupe_of"`
	Groups              []string      `json:"groups"`
	IsCCAccessible      bool          `json:"is_cc_accessible"`
	IsConfirmed         bool          `json:"is_confirmed"`
	IsCreatorAccessible bool          `json:"is_creator_accessible"`
	IsOpen              bool          `json:"is_open"`
	Keywords            []string      `json:"keywords"`
	LastChangeTime      string        `json:"last_change_time"`
	OpSys               string        `json:"op_sys"`
	Platform            string        `json:"platform"`
	Priority            string        `json:"priority"`
	Product             string        `json:"product"`
	QAContact           string        `json:"qa_contact"`
	Resolution          string        `json:"resolution"`
	SeeAlso             []string      `json:"see_also"`
	Severity            string        `json:"severity"`
	Status              string        `json:"status"`
	Summary             string        `json:"summary"`
	TargetMilestone     string        `json:"target_milestone"`
	Url                 string        `json:"url"`
	Version             string        `json:"version"`
	Whiteboard          string        `json:"whiteboard"`
}

type Contributor struct {
	Email    string `json:"email"`
	Id       int64  `json:"id"`
	Name     string `json:"name"`
	RealName string `json:"real_name"`
}

func (bug *Bug) IsReady() bool {
	return strings.Contains(bug.Whiteboard, "[glsa")
}

func GetBugById(id string) Bug {

	parsedId, err := strconv.ParseInt(id, 10, 64)
	if err != nil {
		return Bug{}
	}

	bug := &Bug{Id: parsedId}
	err = connection.DB.Model(bug).WherePK().Select()

	if err == nil && bug != nil {
		return *bug
	}

	resp, err := http.Get("https://bugs.gentoo.org/rest/bug?id=" + id)
	if err != nil {
		return Bug{}
	}

	// Read body
	b, err := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	if err != nil {
		return Bug{}
	}

	// Unmarshal
	var bugs Bugs
	err = json.Unmarshal(b, &bugs)
	if err != nil || bugs.Bugs == nil || len(bugs.Bugs) == 0 {
		return Bug{}
	}

	return bugs.Bugs[0]
}

func GetBugsByIds(ids []string) []Bug {

	var result []Bug

	if len(ids) < 1 {
		return result
	}

	// get existing bugs from database
	var newBugIds []string
	for _, id := range ids {

		parsedId, err := strconv.ParseInt(id, 10, 64)
		if err != nil {
			continue
		}

		bug := &Bug{Id: parsedId}
		err = connection.DB.Model(bug).WherePK().Select()

		if err == nil && bug != nil {
			result = append(result, *bug)
		} else {
			newBugIds = append(newBugIds, id)
		}

	}

	// if there are new bugs, import them
	if len(newBugIds) > 0 {
		var bugs Bugs
		resp, err := http.Get("https://bugs.gentoo.org/rest/bug?id=" + strings.Join(newBugIds, ","))

		if err != nil {
			return bugs.Bugs
		}

		// Read body
		b, err := ioutil.ReadAll(resp.Body)
		defer resp.Body.Close()
		if err != nil {
			return bugs.Bugs
		}

		// Unmarshal
		err = json.Unmarshal(b, &bugs)
		if err != nil || bugs.Bugs == nil || len(bugs.Bugs) == 0 {
			return result
		}

		result = append(result, bugs.Bugs...)
	}

	return result
}
