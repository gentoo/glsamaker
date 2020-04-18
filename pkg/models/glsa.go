package models

import (
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/cve"
	"glsamaker/pkg/models/gpackage"
	"glsamaker/pkg/models/users"
	"time"
)

type Glsa struct {
	//	Id                string
	Id          int64 `pg:",pk,unique"`
	Alias       string
	Type        string
	Title       string
	Synopsis    string
	Packages    []gpackage.Package
	Description string
	Impact      string
	Workaround  string
	Resolution  string
	References  []Reference
	Permission  string
	Access      string
	Severity    string
	Keyword     string
	Background  string
	Bugs        []bugzilla.Bug `pg:"many2many:glsa_to_bugs,joinFK:bug_id"`
	Comments    []cve.Comment  `pg:",fk:glsa_id"`
	Revision    string
	ApprovedBy  []int64
	DeclinedBy  []int64
	CreatorId   int64
	Creator     *users.User
	Created     time.Time
	Updated     time.Time
	Status      Status `pg:"-"`
}

type GlsaToBug struct {
	GlsaId int64 `pg:",unique:glsa_to_bug"`
	BugId  int64 `pg:",unique:glsa_to_bug"`
}

type Reference struct {
	Title string
	URL   string
}

type Status struct {
	BugReady       bool
	Approval       string
	WorkflowStatus string
	Permission     string
}

func (glsa *Glsa) IsBugReady() bool {
	bugReady := true
	for _, bug := range glsa.Bugs {
		bugReady = bugReady && bug.IsReady()
	}
	return bugReady
}

func (glsa *Glsa) ComputeStatus(user *users.User) {
	status := Status{
		BugReady:       glsa.IsBugReady(),
		Approval:       "none",
		WorkflowStatus: "todo",
		Permission:     glsa.Permission,
	}

	if glsa.DeclinedBy != nil && len(glsa.DeclinedBy) > 0 {
		status.Approval = "declined"
	} else if glsa.ApprovedBy != nil && len(glsa.ApprovedBy) > 0 {
		status.Approval = "approved"
	} else if glsa.Comments != nil && len(glsa.Comments) > 0 {
		status.Approval = "comments"
	}

	if glsa.CreatorId == user.Id {
		status.WorkflowStatus = "own"
	} else if contains(glsa.ApprovedBy, user.Id) {
		status.WorkflowStatus = "approved"
	} else {
		for _, comment := range glsa.Comments {
			if comment.User == user.Id {
				status.WorkflowStatus = "commented"
				break
			}
		}
	}

	glsa.Status = status
}

func (glsa *Glsa) ComputeCommentBadges() {
	for _, comment := range glsa.Comments {
		user := new(users.User)
		connection.DB.Model(user).Where("id = ?", comment.User).Select()

		comment.UserBadge = user.Badge
	}
}

func contains(arr []int64, element int64) bool {
	for _, a := range arr {
		if a == element {
			return true
		}
	}
	return false
}
