// Contains the model of the application data

package models

import (
	"glsamaker/pkg/config"
	"glsamaker/pkg/database/connection"
	"time"
)

type ApplicationSetting struct {
	Key        string `pg:",pk"`
	Value      string
	LastUpdate time.Time
	//LastBugUpdate time.Time
	//LastCVEUpdate time.Time
}

type GlobalSettings struct {
	LastBugUpdate       time.Time
	LastCVEUpdate       time.Time
	Version             string
	Force2FALogin       bool
	Force2FAGLSARelease bool
}

func GetApplicationKey(key string) *ApplicationSetting {
	applicationData := &ApplicationSetting{Key: key}
	connection.DB.Model(applicationData).WherePK().Select()
	return applicationData
}

func SetApplicationValue(key string, value string) {
	applicationData := &ApplicationSetting{
		Key:        key,
		Value:      value,
		LastUpdate: time.Now(),
	}

	connection.DB.Model(applicationData).WherePK().OnConflict("(key) DO Update").Insert()
}

func SeedApplicationValue(key string, value string) {
	applicationData := &ApplicationSetting{
		Key:        key,
		Value:      value,
		LastUpdate: time.Now(),
	}

	connection.DB.Model(applicationData).WherePK().OnConflict("(key) DO Nothing").Insert()
}

func GetDefaultGlobalSettings() *GlobalSettings {
	return &GlobalSettings{
		LastBugUpdate:       GetApplicationKey("LastBugUpdate").LastUpdate,
		LastCVEUpdate:       GetApplicationKey("LastCVEUpdate").LastUpdate,
		Version:             GetApplicationKey("Version").Value,
		Force2FALogin:       GetApplicationKey("Force2FALogin").Value == "1",
		Force2FAGLSARelease: GetApplicationKey("Force2FAGLSARelease").Value == "1",
	}
}

func SeedInitialApplicationData() {
	SeedApplicationValue("LastBugUpdate", "")
	SeedApplicationValue("LastCVEUpdate", "")
	SeedApplicationValue("Version", config.Version())
	SeedApplicationValue("Force2FALogin", "0")
	SeedApplicationValue("Force2FAGLSARelease", "0")
}
