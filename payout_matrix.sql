-- ============================================================================
-- Database: payout_mandate_db (SQLite Dialect)
-- Description: Payout mandate matrix storing auto-approval limits, threshold rules,
--              and routing guidelines per claim scenario.
-- Generated: 2026-08-11
-- ============================================================================

PRAGMA foreign_keys = ON;

-- Drop existing objects if re-running
DROP VIEW IF EXISTS v_evaluate_payout_mandate;
DROP TABLE IF EXISTS claim_scenario_rules;
DROP TABLE IF EXISTS approval_authority_levels;

-- ----------------------------------------------------------------------------
-- Table 1: approval_authority_levels
-- Defines authority tiers for manual review routing when STP threshold is exceeded
-- ----------------------------------------------------------------------------
CREATE TABLE approval_authority_levels (
    tier_id INTEGER PRIMARY KEY AUTOINCREMENT,
    authority_role TEXT NOT NULL UNIQUE, -- e.g., 'STP_Automated', 'Junior_Adjuster', 'Senior_Claims_Manager', 'Chief_Risk_Officer'
    max_payout_limit REAL NOT NULL,
    description TEXT NOT NULL
);

-- ----------------------------------------------------------------------------
-- Table 2: claim_scenario_rules
-- Auto-approval limits, maximum discrepancy tolerances, and risk constraints
-- ----------------------------------------------------------------------------
CREATE TABLE claim_scenario_rules (
    rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_type TEXT NOT NULL,            -- e.g., 'Individual Health Insurance', 'Private Car Motor Insurance', etc.
    claim_scenario TEXT NOT NULL,         -- e.g., 'Standard Inpatient / Daycare Procedures', etc.
    auto_approval_limit REAL NOT NULL,    -- Maximum calculated net payout allowed for STP
    max_discrepancy_tolerance REAL DEFAULT 0.00, -- Maximum allowed difference between claimed amount and verified evidence total
    max_allowed_risk_score REAL DEFAULT 0.20,     -- Max fraud/risk score (0.00 to 1.00) allowed for STP
    min_verifier_trust_score REAL DEFAULT 0.90,  -- Minimum acceptable trust score of 3rd party verifier
    requires_zero_dep_addon INTEGER DEFAULT 0,    -- 0 = FALSE, 1 = TRUE
    mandatory_human_review_flag INTEGER DEFAULT 0, -- 0 = FALSE, 1 = TRUE
    routing_tier_id_on_breach INTEGER NOT NULL,   -- Which tier handles review if STP rules are breached
    rule_status TEXT DEFAULT 'Active',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (routing_tier_id_on_breach) REFERENCES approval_authority_levels(tier_id)
);

-- ============================================================================
-- SEED DATA INSERTION
-- ============================================================================

-- Authority Tiers
INSERT INTO approval_authority_levels (tier_id, authority_role, max_payout_limit, description) VALUES
(1, 'STP_Automated_Engine', 200000.00, 'Straight-through automated approval without human intervention'),
(2, 'Junior_Claims_Adjuster', 500000.00, 'Requires human review by a Level-1 Claims Adjuster'),
(3, 'Senior_Claims_Manager', 2500000.00, 'Requires review & approval by Senior Claims Manager'),
(4, 'Chief_Risk_Officer_Panel', 100000000.00, 'Requires executive committee / CRO level sign-off');

-- Mandate Matrix Rules per Claim Scenario
INSERT INTO claim_scenario_rules (
    policy_type, claim_scenario, auto_approval_limit, max_discrepancy_tolerance, 
    max_allowed_risk_score, min_verifier_trust_score, requires_zero_dep_addon, 
    mandatory_human_review_flag, routing_tier_id_on_breach
) VALUES
-- 1. Health Claims: Standard hospitalization / Daycare
(
    'Individual Health Insurance',
    'Standard Inpatient / Daycare Procedures',
    150000.00,
    10000.00,
    0.15,
    0.95,
    0,
    0,
    2
),

-- 2. Motor Claims: Collision / Partial Own Damage
(
    'Private Car Motor Insurance',
    'Partial Loss Accidental Collision',
    100000.00,
    15000.00,
    0.20,
    0.90,
    1,
    0,
    2
),

-- 3. Motor Claims: Total Loss / Theft (Mandatory Human Review)
(
    'Private Car Motor Insurance',
    'Total Loss / Vehicle Theft',
    0.00,
    0.00,
    0.05,
    0.95,
    0,
    1,
    3
),

-- 4. Cyber Insurance: SME Breach / Ransomware
(
    'Cyber & Data Privacy Insurance',
    'Extortion & Incident Response Recovery',
    500000.00,
    50000.00,
    0.10,
    0.98,
    0,
    0,
    3
),

-- 5. Commercial Fire Insurance: Material Damage (Requires Senior Approval)
(
    'Commercial Property & Fire Insurance',
    'Industrial Fire & Material Damage',
    0.00,
    0.00,
    0.10,
    0.95,
    0,
    1,
    4
);

-- ============================================================================
-- VIEW: Replaces Stored Procedure `sp_evaluate_payout_mandate`
-- Exposes the scenario evaluation rules and breach routing targets.
-- ============================================================================

CREATE VIEW v_evaluate_payout_mandate AS
SELECT 
    r.rule_id,
    r.policy_type,
    r.claim_scenario,
    r.auto_approval_limit,
    r.max_discrepancy_tolerance,
    r.max_allowed_risk_score,
    r.min_verifier_trust_score,
    r.mandatory_human_review_flag,
    r.requires_zero_dep_addon,
    a.authority_role AS designated_breach_authority,
    a.description AS breach_authority_description
FROM claim_scenario_rules r
JOIN approval_authority_levels a ON r.routing_tier_id_on_breach = a.tier_id
WHERE r.rule_status = 'Active';
