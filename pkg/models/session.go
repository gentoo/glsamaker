package models

import (
	"glsamaker/pkg/models/users"
	"time"
)

type Session struct {
	Id                  string `pg:",pk"`
	UserId              int64
	User                *users.User
	SecondFactorMissing bool
	IP                  string
	Expires             time.Time
}
