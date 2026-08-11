-- ============================================================================
-- Database: payout_mandate_db
-- Description: Payout mandate matrix storing auto-approval limits, threshold rules,
--              and routing guidelines per claim scenario. The LLM queries this DB
--              to evaluate calculated payouts (post deductibles & depreciation)
--              against rules to decide Straight-Through Processing (STP) vs. Human Review.
-- Generated: 2026-08-02
-- ============================================================================

CREATE DATABASE IF NOT EXISTS payout_mandate_db;
USE payout_mandate_db;

-- Drop existing objects if re-running
DROP PROCEDURE IF EXISTS sp_evaluate_payout_mandate;
DROP TABLE IF EXISTS claim_scenario_rules;
DROP TABLE IF EXISTS approval_authority_levels;

-- ----------------------------------------------------------------------------
-- Table 1: approval_authority_levels
-- Defines authority tiers for manual review routing when STP threshold is exceeded
-- ----------------------------------------------------------------------------
CREATE TABLE approval_authority_levels (
    tier_id INT AUTO_INCREMENT PRIMARY KEY,
    authority_role VARCHAR(100) NOT NULL UNIQUE, -- e.g., 'STP_Automated', 'Junior_Adjuster', 'Senior_Claims_Manager', 'Chief_Risk_Officer'
    max_payout_limit DECIMAL(15, 2) NOT NULL,
    description VARCHAR(255) NOT NULL
);

-- ----------------------------------------------------------------------------
-- Table 2: claim_scenario_rules
-- Auto-approval limits, maximum discrepancy tolerances, and risk constraints
-- ----------------------------------------------------------------------------
CREATE TABLE claim_scenario_rules (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_type VARCHAR(100) NOT NULL,            -- e.g., 'Individual Health Insurance', 'Private Car Motor Insurance', 'Cyber & Data Privacy Insurance', 'Commercial Property & Fire Insurance'
    claim_scenario VARCHAR(150) NOT NULL,         -- e.g., 'Cataract / Standard Hospitalization', 'Motor Collision Damage', 'Ransomware / Cyber Breach', 'Fire & Material Damage'
    auto_approval_limit DECIMAL(15, 2) NOT NULL,  -- Maximum calculated net payout allowed for STP (Straight-Through Processing)
    max_discrepancy_tolerance DECIMAL(15, 2) DEFAULT 0.00, -- Maximum allowed difference between claimed amount and 3rd party verified evidence total
    max_allowed_risk_score DECIMAL(3, 2) DEFAULT 0.20,     -- Max fraud/risk score (0.00 to 1.00) allowed for STP
    min_verifier_trust_score DECIMAL(3, 2) DEFAULT 0.90,  -- Minimum acceptable trust score of 3rd party verifier
    requires_zero_dep_addon BOOLEAN DEFAULT FALSE,         -- Flag if zero depreciation rule strictness applies
    mandatory_human_review_flag BOOLEAN DEFAULT FALSE,    -- Force human review regardless of amount (e.g., total loss, fatality, high-risk flags)
    routing_tier_id_on_breach INT NOT NULL,               -- Which tier handles review if STP rules are breached
    rule_status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
-- 1. Health Claims: Standard hospitalization / Daycare (e.g., Cataract, Dengue)
(
    'Individual Health Insurance',
    'Standard Inpatient / Daycare Procedures',
    150000.00, -- Auto-approve net payouts up to ₹1,50,000
    10000.00,  -- Discrepancy up to ₹10,000 allowed for auto-adjustment
    0.15,      -- Low risk score requirement
    0.95,      -- High verifier trust required (e.g., TPA/Hospital Network)
    FALSE,
    FALSE,
    2          -- Route to Junior Adjuster if exceeded
),

-- 2. Motor Claims: Collision / Partial Own Damage
(
    'Private Car Motor Insurance',
    'Partial Loss Accidental Collision',
    100000.00, -- Auto-approve payouts up to ₹1,00,000 post depreciation & deductibles
    15000.00,  -- Max discrepancy ₹15,000
    0.20,
    0.90,
    TRUE,      -- Zero Dep verification required for plastic/metal waivers
    FALSE,
    2          -- Route to Junior Adjuster if exceeded
),

-- 3. Motor Claims: Total Loss / Theft (Mandatory Human Review)
(
    'Private Car Motor Insurance',
    'Total Loss / Vehicle Theft',
    0.00,      -- 0.00 auto-approval limit -> Always requires human review
    0.00,
    0.05,
    0.95,
    FALSE,
    TRUE,      -- Mandatory human review forced
    3          -- Route to Senior Manager
),

-- 4. Cyber Insurance: SME Breach / Ransomware
(
    'Cyber & Data Privacy Insurance',
    'Extortion & Incident Response Recovery',
    500000.00, -- Auto-approve up to ₹5,00,000 if CERT-In / Forensic log is verified
    50000.00,  -- Max discrepancy tolerance
    0.10,      -- Strict risk score threshold
    0.98,      -- Requires CERT-In or accredited forensic verifier
    FALSE,
    FALSE,
    3          -- Route to Senior Claims Manager if exceeded
),

-- 5. Commercial Fire Insurance: Material Damage (Requires Senior Approval)
(
    'Commercial Property & Fire Insurance',
    'Industrial Fire & Material Damage',
    0.00,      -- Commercial property fire claims always require surveyor & manager sign-off
    0.00,
    0.10,
    0.95,
    FALSE,
    TRUE,      -- Mandatory human review
    4          -- Route to Chief Risk Officer / Executive Panel
);

-- ============================================================================
-- AGENT QUERY INTERFACE (Stored Procedure)
-- The LLM invokes this procedure passing calculated net payout, risk score,
-- verifier trust, and discrepancy to determine STP eligibility or human routing.
-- ============================================================================

DELIMITER //

CREATE PROCEDURE sp_evaluate_payout_mandate(
    IN p_policy_type VARCHAR(100),
    IN p_claim_scenario VARCHAR(150),
    IN p_calculated_net_payout DECIMAL(15, 2),
    IN p_discrepancy_amount DECIMAL(15, 2),
    IN p_claim_risk_score DECIMAL(3, 2),
    IN p_verifier_trust_score DECIMAL(3, 2)
)
BEGIN
    SELECT 
        r.rule_id,
        r.policy_type,
        r.claim_scenario,
        p_calculated_net_payout AS net_payout_evaluated,
        r.auto_approval_limit,
        p_discrepancy_amount AS discrepancy_evaluated,
        r.max_discrepancy_tolerance,
        
        -- Decision Logic: Qualified for STP or Requires Human Review?
        CASE 
            WHEN r.mandatory_human_review_flag = TRUE THEN 'HUMAN_REVIEW_REQUIRED'
            WHEN p_calculated_net_payout > r.auto_approval_limit THEN 'HUMAN_REVIEW_REQUIRED'
            WHEN p_discrepancy_amount > r.max_discrepancy_tolerance THEN 'HUMAN_REVIEW_REQUIRED'
            WHEN p_claim_risk_score > r.max_allowed_risk_score THEN 'HUMAN_REVIEW_REQUIRED'
            WHEN p_verifier_trust_score < r.min_verifier_trust_score THEN 'HUMAN_REVIEW_REQUIRED'
            ELSE 'STP_QUALIFIED'
        END AS processing_decision,

        -- Decision Reason Breakdown
        CONCAT_WS(' | ',
            CASE WHEN r.mandatory_human_review_flag = TRUE THEN 'Mandatory human review scenario rule enforced' END,
            CASE WHEN p_calculated_net_payout > r.auto_approval_limit THEN CONCAT('Calculated payout (₹', p_calculated_net_payout, ') exceeds auto-approval limit (₹', r.auto_approval_limit, ')') END,
            CASE WHEN p_discrepancy_amount > r.max_discrepancy_tolerance THEN CONCAT('Evidence discrepancy (₹', p_discrepancy_amount, ') exceeds tolerance (₹', r.max_discrepancy_tolerance, ')') END,
            CASE WHEN p_claim_risk_score > r.max_allowed_risk_score THEN CONCAT('Claim risk score (', p_claim_risk_score, ') exceeds max allowed (', r.max_allowed_risk_score, ')') END,
            CASE WHEN p_verifier_trust_score < r.min_verifier_trust_score THEN CONCAT('Verifier trust score (', p_verifier_trust_score, ') below required threshold (', r.min_verifier_trust_score, ')') END,
            CASE WHEN (
                r.mandatory_human_review_flag = FALSE AND 
                p_calculated_net_payout <= r.auto_approval_limit AND 
                p_discrepancy_amount <= r.max_discrepancy_tolerance AND 
                p_claim_risk_score <= r.max_allowed_risk_score AND 
                p_verifier_trust_score >= r.min_verifier_trust_score
            ) THEN 'All conditions met for Straight-Through Processing (STP)' END
        ) AS decision_reasoning,

        -- Assigned Routing Authority
        CASE 
            WHEN (
                r.mandatory_human_review_flag = FALSE AND 
                p_calculated_net_payout <= r.auto_approval_limit AND 
                p_discrepancy_amount <= r.max_discrepancy_tolerance AND 
                p_claim_risk_score <= r.max_allowed_risk_score AND 
                p_verifier_trust_score >= r.min_verifier_trust_score
            ) THEN 'STP_Automated_Engine'
            ELSE a.authority_role
        END AS designated_approval_authority

    FROM claim_scenario_rules r
    JOIN approval_authority_levels a ON r.routing_tier_id_on_breach = a.tier_id
    WHERE r.policy_type = p_policy_type
      AND r.claim_scenario = p_claim_scenario
      AND r.rule_status = 'Active';
END //

DELIMITER ;
