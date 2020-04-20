package app

import (
	"glsamaker/pkg/app/handler/authentication/totp"
	"glsamaker/pkg/config"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/users"
)

func defaultAdminPermissions() users.Permissions {
	return users.Permissions{
		Glsa:    users.GlsaPermissions{
			View:           true,
			UpdateBugs:     true,
			Comment:        true,
			Create:         true,
			Edit:           true,
			Approve:        true,
			ApproveOwnGlsa: true,
			Decline:        true,
			Delete:         true,
			Release:        true,
			Confidential:   true,
		},
		CVETool: users.CVEToolPermissions{
			View:        true,
			UpdateCVEs:  true,
			Comment:     true,
			AddCVE:      true,
			AddPackage:  true,
			ChangeState: true,
			AssignBug:   true,
			CreateBug:   true,
		},
		Admin:   users.AdminPermissions{
			View:            true,
			CreateTemplates: true,
			ManageUsers:     true,
			GlobalSettings:  true,
		},
	}
}

func CreateDefaultAdmin() {

	token, qrcode := totp.Generate(config.AdminEmail())

	badge := users.Badge{
		Name:        "admin",
		Description: "Admin Account",
		Color:       "orange",
	}

	passwordParameters := users.Argon2Parameters{
		Type:    "argon2id",
		Time:    1,
		Memory:  64 * 1024,
		Threads: 4,
		KeyLen:  32,
	}
	passwordParameters.GenerateSalt(32)
	passwordParameters.GeneratePassword(config.AdminInitialPassword())

	defaultUser := &users.User{
		Email:                 config.AdminEmail(),
		Password:              passwordParameters,
		Nick:                  "admin",
		Name:                  "Admin Account",
		Role:                  "admin",
		ForcePasswordChange:   false,
		TOTPSecret:            token,
		TOTPQRCode:            qrcode,
		IsUsingTOTP:           false,
		WebauthnCredentials:   nil,
		IsUsingWebAuthn:       false,
		Show2FANotice:         true,
		Badge:                 badge,
		Disabled:              false,
		ForcePasswordRotation: false,
		Force2FA:              false,
		Permissions:           defaultAdminPermissions(),
	}

	_, err := connection.DB.Model(defaultUser).OnConflict("(email) DO Nothing").Insert()
	if err != nil {
		logger.Error.Println("Err during creating default admin user")
		logger.Error.Println(err)
	}
}
