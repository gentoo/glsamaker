package cve

// CvssV2 Common Vulnerability Scoring System version 2.0
type CvssV2 struct {
	AccessComplexity           string  `json:"accessComplexity,omitempty"`
	AccessVector               string  `json:"accessVector,omitempty"`
	Authentication             string  `json:"authentication,omitempty"`
	AvailabilityImpact         string  `json:"availabilityImpact,omitempty"`
	AvailabilityRequirement    string  `json:"availabilityRequirement,omitempty"`
	BaseScore                  float64 `json:"baseScore"`
	CollateralDamagePotential  string  `json:"collateralDamagePotential,omitempty"`
	ConfidentialityImpact      string  `json:"confidentialityImpact,omitempty"`
	ConfidentialityRequirement string  `json:"confidentialityRequirement,omitempty"`
	EnvironmentalScore         float64 `json:"environmentalScore,omitempty"`
	Exploitability             string  `json:"exploitability,omitempty"`
	IntegrityImpact            string  `json:"integrityImpact,omitempty"`
	IntegrityRequirement       string  `json:"integrityRequirement,omitempty"`
	RemediationLevel           string  `json:"remediationLevel,omitempty"`
	ReportConfidence           string  `json:"reportConfidence,omitempty"`
	TargetDistribution         string  `json:"targetDistribution,omitempty"`
	TemporalScore              float64 `json:"temporalScore,omitempty"`
	VectorString               string  `json:"vectorString"`

	// CVSS Version
	Version string `json:"version"`
}

// CvssV3 Common Vulnerability Scoring System version 3.x (BETA)
type CvssV3 struct {
	AttackComplexity              string  `json:"attackComplexity,omitempty"`
	AttackVector                  string  `json:"attackVector,omitempty"`
	AvailabilityImpact            string  `json:"availabilityImpact,omitempty"`
	AvailabilityRequirement       string  `json:"availabilityRequirement,omitempty"`
	BaseScore                     float64 `json:"baseScore"`
	BaseSeverity                  string  `json:"baseSeverity"`
	ConfidentialityImpact         string  `json:"confidentialityImpact,omitempty"`
	ConfidentialityRequirement    string  `json:"confidentialityRequirement,omitempty"`
	EnvironmentalScore            float64 `json:"environmentalScore,omitempty"`
	EnvironmentalSeverity         string  `json:"environmentalSeverity,omitempty"`
	ExploitCodeMaturity           string  `json:"exploitCodeMaturity,omitempty"`
	IntegrityImpact               string  `json:"integrityImpact,omitempty"`
	IntegrityRequirement          string  `json:"integrityRequirement,omitempty"`
	ModifiedAttackComplexity      string  `json:"modifiedAttackComplexity,omitempty"`
	ModifiedAttackVector          string  `json:"modifiedAttackVector,omitempty"`
	ModifiedAvailabilityImpact    string  `json:"modifiedAvailabilityImpact,omitempty"`
	ModifiedConfidentialityImpact string  `json:"modifiedConfidentialityImpact,omitempty"`
	ModifiedIntegrityImpact       string  `json:"modifiedIntegrityImpact,omitempty"`
	ModifiedPrivilegesRequired    string  `json:"modifiedPrivilegesRequired,omitempty"`
	ModifiedScope                 string  `json:"modifiedScope,omitempty"`
	ModifiedUserInteraction       string  `json:"modifiedUserInteraction,omitempty"`
	PrivilegesRequired            string  `json:"privilegesRequired,omitempty"`
	RemediationLevel              string  `json:"remediationLevel,omitempty"`
	ReportConfidence              string  `json:"reportConfidence,omitempty"`
	Scope                         string  `json:"scope,omitempty"`
	TemporalScore                 float64 `json:"temporalScore,omitempty"`
	TemporalSeverity              string  `json:"temporalSeverity,omitempty"`
	UserInteraction               string  `json:"userInteraction,omitempty"`
	VectorString                  string  `json:"vectorString"`

	// CVSS Version
	Version string `json:"version"`
}
