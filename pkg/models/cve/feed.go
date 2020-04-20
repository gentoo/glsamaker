package cve

import (
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/gpackage"
	"glsamaker/pkg/models/users"
	"time"
)

// NVDFeed
type NVDFeed struct {
	CVEDataFormat string `json:"CVE_data_format"`

	// NVD adds number of CVE in this feed
	CVEDataNumberOfCVEs string `json:"CVE_data_numberOfCVEs,omitempty"`

	// NVD adds feed date timestamp
	CVEDataTimestamp string `json:"CVE_data_timestamp,omitempty"`
	CVEDataType      string `json:"CVE_data_type"`
	CVEDataVersion   string `json:"CVE_data_version"`

	// NVD feed array of CVE
	CVEItems []*DefCveItem `json:"CVE_Items"`
}

// DefConfigurations Defines the set of product configurations for a NVD applicability statement.
type DefConfigurations struct {
	CVEDataVersion string     `json:"CVE_data_version"`
	Nodes          []*DefNode `json:"nodes,omitempty"`
}

// DefCpeMatch CPE match string or range
type DefCpeMatch struct {
	Cpe22Uri              string        `json:"cpe22Uri,omitempty"`
	Cpe23Uri              string        `json:"cpe23Uri"`
	CpeName               []*DefCpeName `json:"cpe_name,omitempty"`
	VersionEndExcluding   string        `json:"versionEndExcluding,omitempty"`
	VersionEndIncluding   string        `json:"versionEndIncluding,omitempty"`
	VersionStartExcluding string        `json:"versionStartExcluding,omitempty"`
	VersionStartIncluding string        `json:"versionStartIncluding,omitempty"`
	Vulnerable            bool          `json:"vulnerable"`
}

// DefCpeName CPE name
type DefCpeName struct {
	Cpe22Uri         string `json:"cpe22Uri,omitempty"`
	Cpe23Uri         string `json:"cpe23Uri"`
	LastModifiedDate string `json:"lastModifiedDate,omitempty"`
}

// DefCveItem Defines a vulnerability in the NVD data feed.
type DefCveItem struct {
	Id               string             `pg:",pk"`
	State            string             `pg:"state"`
	Configurations   *DefConfigurations `json:"configurations,omitempty"`
	Cve              CVE                `json:"cve"`
	Description      string
	Impact           *DefImpact `json:"impact,omitempty"`
	LastModifiedDate string     `json:"lastModifiedDate,omitempty"`
	PublishedDate    string     `json:"publishedDate,omitempty"`

	Comments []Comment `pg:",fk:cve_id"`
	Packages []gpackage.Package
	Bugs     []bugzilla.Bug `pg:"many2many:def_cve_item_to_bugs,joinFK:bug_id"`
}

type DefCveItemToBug struct {
	DefCveItemId string `pg:",unique:cve_to_bug"`
	BugId        int64  `pg:",unique:cve_to_bug"`
}

type Comment struct {
	Id        int64 `pg:",pk,unique"`
	GlsaId    int64
	CVEId     string
	UserId    int64
	User      *users.User
	UserBadge users.Badge
	Type      string
	Message   string
	//	Date      time.Time `pg:"-"`
	Date time.Time
}

// DefNode Defines a node or sub-node in an NVD applicability statement.
type DefNode struct {
	Children []*DefNode     `json:"children,omitempty"`
	CpeMatch []*DefCpeMatch `json:"cpe_match,omitempty"`
	Negate   bool           `json:"negate,omitempty"`
	Operator string         `json:"operator,omitempty"`
}

// DefImpact Impact scores for a vulnerability as found on NVD.
type DefImpact struct {
	BaseMetricV3 BaseMetricV3 `json:"baseMetricV3"`
	BaseMetricV2 BaseMetricV2 `json:"baseMetricV2"`
}

// BaseMetricV2 CVSS V2.0 score.
type BaseMetricV2 struct {
	CvssV2                  CvssV2  `json:"cvssV2"`
	Severity                string  `json:"severity"`
	ExploitabilityScore     float32 `json:"exploitabilityScore"`
	ImpactScore             float32 `json:"impactScore"`
	AcInsufInfo             bool    `json:"acInsufInfo"`
	ObtainAllPrivilege      bool    `json:"obtainAllPrivilege"`
	ObtainUserPrivilege     bool    `json:"obtainUserPrivilege"`
	ObtainOtherPrivilege    bool    `json:"obtainOtherPrivilege"`
	UserInteractionRequired bool    `json:"userInteractionRequired"`
}

// BaseMetricV3 CVSS V3.x score.
type BaseMetricV3 struct {
	CvssV3              CvssV3  `json:"cvssV3"`
	ExploitabilityScore float32 `json:"exploitabilityScore"`
	ImpactScore         float32 `json:"impactScore"`
}
