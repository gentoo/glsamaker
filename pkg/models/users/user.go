// Contains the model of the application data

package users

import (
	"crypto/rand"
	"errors"
	"github.com/duo-labs/webauthn/protocol"
	"github.com/duo-labs/webauthn/webauthn"
	"github.com/go-pg/pg/v9/orm"
	"golang.org/x/crypto/argon2"
	"strconv"
	"strings"
)

type User struct {
	Id int64 `pg:",pk,unique"`

	Email                   string `pg:",unique"`
	Nick                    string
	Name                    string
	Password                Argon2Parameters
	ForcePasswordChange     bool
	Role                    string
	TOTPSecret              string
	TOTPQRCode              string
	IsUsingTOTP             bool
	WebauthnCredentials     []webauthn.Credential
	WebauthnCredentialNames []*WebauthnCredentialName
	IsUsingWebAuthn         bool
	Show2FANotice           bool

	Permissions Permissions

	Badge Badge

	ForcePasswordRotation bool
	Force2FA              bool

	Disabled bool
}

type Argon2Parameters struct {
	Type    string
	Salt    []byte
	Time    uint32
	Memory  uint32
	Threads uint8
	KeyLen  uint32
	Hash    []byte
}

func (a *Argon2Parameters) GenerateSalt(n uint32) error {
	b := make([]byte, n)
	_, err := rand.Read(b)
	if err != nil {
		return err
	}
	a.Salt = b

	return nil
}

func (a *Argon2Parameters) GeneratePassword(password string) error {
	if a.Salt == nil || a.Time == 0 || a.Memory == 0 || a.Threads == 0 || a.KeyLen == 0 {
		return errors.New("Invalid parameters")
	}
	a.Hash = argon2.IDKey([]byte(password), a.Salt, a.Time, a.Memory, a.Threads, a.KeyLen)
	return nil
}

func (u *User) UpdatePassword(password string) error {
	err := u.Password.GeneratePassword(password)
	if err != nil {
		return err
	}
	return nil
}

func (u *User) CheckPassword(password string) bool {
	return string(u.Password.Hash) == string(argon2.IDKey(
		[]byte(password),
		u.Password.Salt,
		u.Password.Time,
		u.Password.Memory,
		u.Password.Threads,
		u.Password.KeyLen))
}

type Permissions struct {
	Glsa    GlsaPermissions
	CVETool CVEToolPermissions
	Admin   AdminPermissions
}

type GlsaPermissions struct {
	View           bool
	UpdateBugs     bool
	Comment        bool
	Create         bool
	Edit           bool
	Approve        bool
	ApproveOwnGlsa bool
	Decline        bool
	Delete         bool
	Release        bool
	Confidential   bool
}

type CVEToolPermissions struct {
	View        bool
	UpdateCVEs  bool
	Comment     bool
	AddPackage  bool
	ChangeState bool
	AssignBug   bool
	CreateBug   bool
}

type AdminPermissions struct {
	View            bool
	CreateTemplates bool
	ManageUsers     bool
	GlobalSettings  bool
}

type WebauthnCredentialName struct {
	Id   []byte
	Name string
}

type Badge struct {
	Name        string `pg:",pk"`
	Description string
	Color       string
}

func (u User) IsUsing2FA() bool {
	return u.IsUsingTOTP || u.IsUsingWebAuthn
}

// WebAuthnID returns the user's ID
func (u User) WebAuthnID() []byte {
	return []byte(strconv.FormatInt(u.Id, 10))
}

// WebAuthnName returns the user's username
func (u User) WebAuthnName() string {
	return strings.TrimRight(u.Nick, "@")
}

// WebAuthnDisplayName returns the user's display name
func (u User) WebAuthnDisplayName() string {
	return strings.TrimRight(u.Nick, "@")
}

// WebAuthnIcon is not (yet) implemented
func (u User) WebAuthnIcon() string {
	return ""
}

// WebAuthnCredentials returns credentials owned by the user
func (u User) WebAuthnCredentials() []webauthn.Credential {
	return u.WebauthnCredentials
}

// CredentialExcludeList returns a CredentialDescriptor array filled
// with all the user's credentials
func (u User) CredentialExcludeList() []protocol.CredentialDescriptor {

	credentialExcludeList := []protocol.CredentialDescriptor{}
	for _, cred := range u.WebauthnCredentials {
		descriptor := protocol.CredentialDescriptor{
			Type:         protocol.PublicKeyCredentialType,
			CredentialID: cred.ID,
		}
		credentialExcludeList = append(credentialExcludeList, descriptor)
	}

	return credentialExcludeList
}

// AddCredential associates the credential to the user
func (u *User) AddCredential(cred webauthn.Credential, credentialName string) {
	u.WebauthnCredentials = append(u.WebauthnCredentials, cred)

	webauthnCredentialName := &WebauthnCredentialName{
		Id:   cred.ID,
		Name: credentialName,
	}

	u.WebauthnCredentialNames = append(u.WebauthnCredentialNames, webauthnCredentialName)

}

func (u *User) CanEditCVEs() bool {
	return u.Role == "admin" || u.Role == "editor"
}

func (u *User) Confidential() string {
	confidential := "public"
	if u.Permissions.Glsa.Confidential {
		confidential = "confidential"
	}
	return confidential
}

func (u *User) CanAccess(query *orm.Query) *orm.Query {
	return query.WhereGroup(func(q *orm.Query) (*orm.Query, error) {
		q = q.WhereOr("permission = ?", "public").
			WhereOr("permission = ?", u.Confidential())
		return q, nil
	})
}
