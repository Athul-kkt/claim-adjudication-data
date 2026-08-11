-- ============================================================================
-- Database: claims_adjudication_db (SQLite Dialect)
-- Description: Consolidated adjudication history tracking policy terms, 
--              evidence totals, mathematical deductions, and final STP/Manual decisions.
-- Generated: 2026-08-11
-- ============================================================================

PRAGMA foreign_keys = ON;

-- Drop existing objects if re-running
DROP VIEW IF EXISTS v_claim_adjudication_details;
DROP TABLE IF EXISTS claim_adjudication_records;

-- ----------------------------------------------------------------------------
-- Table: claim_adjudication_records
-- Stores the final executed decision and calculation breakdown per claim
-- ----------------------------------------------------------------------------
CREATE TABLE claim_adjudication_records (
    adjudication_id INTEGER PRIMARY KEY AUTOINCREMENT,
    claim_id INTEGER NOT NULL UNIQUE,
    claim_reference_no TEXT NOT NULL UNIQUE,
    policy_number TEXT NOT NULL,
    policy_type TEXT NOT NULL,
    claim_scenario TEXT NOT NULL,
    claimant_name TEXT NOT NULL,
    
    -- Claimed vs Evidence Totals
    claimed_amount REAL NOT NULL,
    verified_evidence_total REAL NOT NULL,
    discrepancy_amount REAL NOT NULL,
    
    -- Calculation Audit Breakdown
    sub_limit_applied REAL,
    applicable_deductible REAL DEFAULT 0.00,
    copay_percentage_applied REAL DEFAULT 0.00,
    copay_deducted_amount REAL DEFAULT 0.00,
    depreciation_deducted_amount REAL DEFAULT 0.00,
    final_calculated_net_payout REAL NOT NULL,
    
    -- Decision & Routing
    adjudication_status TEXT NOT NULL, -- 'APPROVED_STP', 'ROUTED_FOR_HUMAN_REVIEW', 'REJECTED'
    designated_authority TEXT NOT NULL, -- 'STP_Automated_Engine', 'Junior_Claims_Adjuster', 'Senior_Claims_Manager'
    adjudication_reasoning TEXT NOT NULL,
    
    -- Metadata
    risk_score REAL NOT NULL,
    verifier_trust_score REAL NOT NULL,
    adjudicated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED DATA INSERTION (Historical Adjudicated Claims)
-- ============================================================================

-- Claim 1: Health Insurance (Cataract Claim - Approved via STP)
INSERT INTO claim_adjudication_records (
    claim_id, claim_reference_no, policy_number, policy_type, claim_scenario,
    claimant_name, claimed_amount, verified_evidence_total, discrepancy_amount,
    sub_limit_applied, applicable_deductible, copay_percentage_applied, copay_deducted_amount,
    depreciation_deducted_amount, final_calculated_net_payout, adjudication_status,
    designated_authority, adjudication_reasoning, risk_score, verifier_trust_score
) VALUES (
    1, 
    'CLM-2026-HLT-001', 
    'IRDAI/HLT/2026/IND-8849102', 
    'Individual Health Insurance', 
    'Standard Inpatient / Daycare Procedures',
    'Rajesh Kumar Sharma', 
    125000.00, 
    118000.00, 
    7000.00,
    40000.00,  -- Cataract sub-limit enforced (₹40,000 cap)
    0.00, 
    5.00,      -- 5% mandatory co-pay
    2000.00,   -- 5% of ₹40,000
    0.00, 
    38000.00,  -- Net Payout: ₹40,000 - ₹2,000 = ₹38,000
    'APPROVED_STP', 
    'STP_Automated_Engine', 
    'Claim verified by MediAssist TPA. Cataract sub-limit of ₹40,000 applied. 5% co-pay deducted (₹2,000). Net payout of ₹38,000 is within the ₹1,50,000 auto-approval threshold.',
    0.05, 
    0.98
);

-- Claim 2: Motor Insurance (Collision Claim - Exceeds Auto-Approval, Routed to Adjuster)
INSERT INTO claim_adjudication_records (
    claim_id, claim_reference_no, policy_number, policy_type, claim_scenario,
    claimant_name, claimed_amount, verified_evidence_total, discrepancy_amount,
    sub_limit_applied, applicable_deductible, copay_percentage_applied, copay_deducted_amount,
    depreciation_deducted_amount, final_calculated_net_payout, adjudication_status,
    designated_authority, adjudication_reasoning, risk_score, verifier_trust_score
) VALUES (
    2, 
    'CLM-2026-MOT-044', 
    'MOT-PVT-2026-0049281', 
    'Private Car Motor Insurance', 
    'Partial Loss Accidental Collision',
    'Hyundai Creta (KA-01-MJ-8819)', 
    185000.00, 
    160000.00, 
    25000.00,
    1250000.00, -- IDV Limit
    3500.00,    -- ₹1,000 Compulsory + ₹2,500 Voluntary Deductible
    0.00, 
    0.00, 
    0.00,       -- Zero Dep Add-On active
    156500.00,  -- Net Payout: ₹160,000 - ₹3,500 = ₹1,56,500
    'ROUTED_FOR_HUMAN_REVIEW', 
    'Junior_Claims_Adjuster', 
    'Calculated net payout (₹1,56,500.00) exceeds the motor collision auto-approval limit (₹1,00,000.00). Discrepancy of ₹25,000 exceeds ₹15,000 tolerance. Assigned to Junior Adjuster.',
    0.12, 
    0.95
);

-- Claim 3: Cyber Insurance (Ransomware Recovery - Approved via STP)
INSERT INTO claim_adjudication_records (
    claim_id, claim_reference_no, policy_number, policy_type, claim_scenario,
    claimant_name, claimed_amount, verified_evidence_total, discrepancy_amount,
    sub_limit_applied, applicable_deductible, copay_percentage_applied, copay_deducted_amount,
    depreciation_deducted_amount, final_calculated_net_payout, adjudication_status,
    designated_authority, adjudication_reasoning, risk_score, verifier_trust_score
) VALUES (
    3, 
    'CLM-2026-CYB-902', 
    'CYBER-SME-2026-10293', 
    'Cyber & Data Privacy Insurance', 
    'Extortion & Incident Response Recovery',
    'Bharat Tech Solutions Pvt. Ltd.', 
    500000.00, 
    500000.00, 
    0.00,
    5000000.00, -- Aggregate Cap
    100000.00,  -- Self-Insured Retention (SIR)
    0.00, 
    0.00, 
    0.00, 
    400000.00,  -- Net Payout: ₹500,000 - ₹100,000 = ₹400,000
    'APPROVED_STP', 
    'STP_Automated_Engine', 
    'CERT-In forensic logs verified MFA compliance and 18-hour downtime. Net payout of ₹400,000 after ₹100,000 SIR is within the ₹500,000 Cyber STP threshold.',
    0.04, 
    0.99
);

-- ============================================================================
-- VIEW: Replaces Stored Procedure for Single Point Lookup
-- Usage: 
--   SELECT * FROM v_claim_adjudication_details WHERE claim_id = 1;
--   OR
--   SELECT * FROM v_claim_adjudication_details WHERE claim_reference_no = 'CLM-2026-HLT-001';
-- ============================================================================

CREATE VIEW v_claim_adjudication_details AS
SELECT 
    r.claim_id,
    r.claim_reference_no,
    r.policy_number,
    r.policy_type,
    r.claim_scenario,
    r.claimant_name,
    
    -- Summary Financials
    r.claimed_amount,
    r.verified_evidence_total,
    r.discrepancy_amount,
    
    -- Detailed Deductions
    r.sub_limit_applied,
    r.applicable_deductible,
    r.copay_percentage_applied || '%' AS copay_rate,
    r.copay_deducted_amount,
    r.depreciation_deducted_amount,
    r.final_calculated_net_payout,
    
    -- Decision Audit
    r.adjudication_status,
    r.designated_authority,
    r.adjudication_reasoning,
    
    -- Risk Audit Metrics
    r.risk_score,
    r.verifier_trust_score,
    r.adjudicated_at
FROM claim_adjudication_records r;
