-- ============================================================================
-- Database: claims_adjudication_db
-- Description: Consolidated adjudication history tracking policy terms, 
--              evidence totals, mathematical deductions, and final STP/Manual decisions.
-- Generated: 2026-08-02
-- ============================================================================

CREATE DATABASE IF NOT EXISTS claims_adjudication_db;
USE claims_adjudication_db;

-- Drop existing objects if re-running
DROP PROCEDURE IF EXISTS sp_get_claim_adjudication_details;
DROP TABLE IF EXISTS claim_adjudication_records;

-- ----------------------------------------------------------------------------
-- Table: claim_adjudication_records
-- Stores the final executed decision and calculation breakdown per claim
-- ----------------------------------------------------------------------------
CREATE TABLE claim_adjudication_records (
    adjudication_id INT AUTO_INCREMENT PRIMARY KEY,
    claim_id INT NOT NULL UNIQUE,
    claim_reference_no VARCHAR(100) NOT NULL UNIQUE,
    policy_number VARCHAR(100) NOT NULL,
    policy_type VARCHAR(100) NOT NULL,
    claim_scenario VARCHAR(150) NOT NULL,
    claimant_name VARCHAR(255) NOT NULL,
    
    -- Claimed vs Evidence Totals
    claimed_amount DECIMAL(15, 2) NOT NULL,
    verified_evidence_total DECIMAL(15, 2) NOT NULL,
    discrepancy_amount DECIMAL(15, 2) NOT NULL,
    
    -- Calculation Audit Breakdown
    sub_limit_applied DECIMAL(15, 2),
    applicable_deductible DECIMAL(15, 2) DEFAULT 0.00,
    copay_percentage_applied DECIMAL(5, 2) DEFAULT 0.00,
    copay_deducted_amount DECIMAL(15, 2) DEFAULT 0.00,
    depreciation_deducted_amount DECIMAL(15, 2) DEFAULT 0.00,
    final_calculated_net_payout DECIMAL(15, 2) NOT NULL,
    
    -- Decision & Routing
    adjudication_status VARCHAR(50) NOT NULL, -- 'APPROVED_STP', 'ROUTED_FOR_HUMAN_REVIEW', 'REJECTED'
    designated_authority VARCHAR(100) NOT NULL, -- 'STP_Automated_Engine', 'Junior_Claims_Adjuster', 'Senior_Claims_Manager'
    adjudication_reasoning TEXT NOT NULL,
    
    -- Metadata
    risk_score DECIMAL(3, 2) NOT NULL,
    verifier_trust_score DECIMAL(3, 2) NOT NULL,
    adjudicated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
-- STORED PROCEDURE: Single Point Lookup by Claim ID
-- Accepts numeric claim_id (e.g. '1') or string reference (e.g. 'CLM-2026-HLT-001')
-- ============================================================================

DELIMITER //

CREATE PROCEDURE sp_get_claim_adjudication_details(
    IN p_claim_identifier VARCHAR(100)
)
BEGIN
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
        CONCAT(r.copay_percentage_applied, '%') AS copay_rate,
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
    FROM claim_adjudication_records r
    WHERE CAST(r.claim_id AS CHAR) = p_claim_identifier
       OR r.claim_reference_no = p_claim_identifier;
END //

DELIMITER ;

-- ============================================================================
-- SQL Schema and Seed Data for Synthetic Insurance Policy Contracts (India Market)
-- Generated: 2026-07-31
-- Description: Structured representation of synthetic insurance policy contracts
--              including deductibles, coverage caps, exclusions, and active terms.
-- ============================================================================

-- Drop existing tables if re-running
DROP TABLE IF EXISTS policy_exclusions;
DROP TABLE IF EXISTS policy_deductibles;
DROP TABLE IF EXISTS policy_coverages;
DROP TABLE IF EXISTS policy_terms;
DROP TABLE IF EXISTS policy_contracts;

-- ----------------------------------------------------------------------------
-- Table: policy_contracts
-- Core policy details and metadata
-- ----------------------------------------------------------------------------
CREATE TABLE policy_contracts (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_number VARCHAR(100) NOT NULL UNIQUE,
    scheme_or_product_name VARCHAR(255),
    policy_type VARCHAR(100) NOT NULL,
    insured_entity_name VARCHAR(255) NOT NULL,
    effective_start_date DATE NOT NULL,
    effective_end_date DATE NOT NULL,
    policy_status VARCHAR(50) DEFAULT 'Active',
    regulatory_framework VARCHAR(100) DEFAULT 'IRDAI',
    currency VARCHAR(10) DEFAULT 'INR',
    full_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- Table: policy_coverages
-- Coverage details, limits, and financial caps
-- ----------------------------------------------------------------------------
CREATE TABLE policy_coverages (
    coverage_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_id INT NOT NULL,
    coverage_name VARCHAR(255) NOT NULL,
    coverage_limit_amount DECIMAL(15, 2),
    coverage_limit_description VARCHAR(500),
    sub_limit_percentage DECIMAL(5, 2),
    time_waiting_period_hours INT,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table: policy_deductibles
-- Deductibles, copayments, retention, and excesses
-- ----------------------------------------------------------------------------
CREATE TABLE policy_deductibles (
    deductible_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_id INT NOT NULL,
    deductible_type VARCHAR(100) NOT NULL, -- e.g., Mandatory, Voluntary, Co-payment, SIR
    deductible_amount DECIMAL(15, 2),
    deductible_percentage DECIMAL(5, 2),
    description VARCHAR(500) NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table: policy_exclusions
-- Explicit policy exclusions and waiting periods
-- ----------------------------------------------------------------------------
CREATE TABLE policy_exclusions (
    exclusion_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_id INT NOT NULL,
    exclusion_code VARCHAR(50),
    exclusion_category VARCHAR(100), -- e.g., Waiting Period, Standard Exclusion, Specific Event
    waiting_period_months INT,
    exclusion_description TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table: policy_terms
-- Special conditions, riders, bonuses, and active statutory clauses
-- ----------------------------------------------------------------------------
CREATE TABLE policy_terms (
    term_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_id INT NOT NULL,
    term_category VARCHAR(100) NOT NULL, -- e.g., Rider, Renewal, Reporting, Endorsement
    term_name VARCHAR(255) NOT NULL,
    term_details TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- ============================================================================
-- SEED DATA INSERTION
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SAMPLE 1: Arogya Sanjeevani Health Insurance Policy
-- ----------------------------------------------------------------------------
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'IRDAI/HLT/2026/IND-8849102',
    'Arogya Sanjeevani Policy',
    'Individual Health Insurance',
    'Rajesh Kumar Sharma',
    '2026-04-10',
    '2027-04-09',
    'Active',
    'IRDAI Standard Health Product',
    'INR',
    'POLICY SCHEME: Arogya Sanjeevani Policy, IRDAI Standard Health Product
POLICY NUMBER: IRDAI/HLT/2026/IND-8849102
INSURED PERSON: Rajesh Kumar Sharma
POLICY PERIOD: 10-Apr-2026 to 09-Apr-2027 (Active)
PRIMARY TPA: MediAssist India TPA Services Pvt. Ltd.

1. SUM INSURED & COVERAGE CAPS
- Base Sum Insured (SI): ₹10,00,000 per policy year.
- Room Rent, Boarding, and Nursing Expenses Cap: 2% of Sum Insured per day, capped at maximum ₹10,00,000. Intensive Care Unit (ICU) expenses capped at 5% of Sum Insured per day.
- Cataract Treatment Cap: Sub-limit of 25% of Sum Insured or ₹40,000, whichever is lower, per eye.
- AYUSH Treatment (Ayurveda, Unani, Siddha, Homeopathy): Up to 100% of Sum Insured at government-recognized institutes/hospitals.
- Pre-Hospitalization & Post-Hospitalization: 30 days prior and 60 days post-discharge covered up to actuals within Sum Insured.

2. DEDUCTIBLES & CO-PAYMENT
- Standard Mandatory Co-payment: 5% co-payment applied on every admissible claim amount under Arogya Sanjeevani terms.
- Deductible: NIL (Voluntary deductible not opted).

3. EXCLUSIONS & WAITING PERIODS
- Initial Waiting Period: Any disease contracted during the first 30 days from policy inception, except accidental injuries.
- Specific Illness Waiting Period (24 Months): Cataract, Hernia, Hydrocele, Joint replacement unless due to accident, Piles, Sinusitis.
- Pre-Existing Diseases (PED) Waiting Period (Code: Excl01): 36 months of continuous coverage before treatment expenses for declared pre-existing conditions (e.g., Type-2 Diabetes) are admissible.
- General Exclusions: Domiciliary hospitalization, cosmetic/aesthetic procedures, hazardous sports injuries, alcohol/substance abuse treatments, and unproven/experimental treatments.

4. ACTIVE TERMS & STATUTORY PROVISIONS
- No Claim Bonus (NCB): Cumulative bonus increases Sum Insured by 5% for every claim-free year, up to a maximum of 50%.
- Grace Period & Continuity: 30-day grace period allowed for renewal without break-in-policy benefit loss. 8-year moratorium clause applies (claims cannot be contested for non-disclosure after 8 continuous renewal years, except for proven fraud).'
);

SET @policy_1_id = LAST_INSERT_ID();

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
(@policy_1_id, 'Base Sum Insured', 1000000.00, 'Base Sum Insured per policy year', NULL),
(@policy_1_id, 'Room Rent, Boarding & Nursing', 1000000.00, 'Capped at 2% of Sum Insured per day', 2.00),
(@policy_1_id, 'ICU Expenses', 1000000.00, 'Capped at 5% of Sum Insured per day', 5.00),
(@policy_1_id, 'Cataract Treatment', 40000.00, 'Sub-limit of 25% of Sum Insured or ₹40,000, whichever is lower, per eye', 25.00),
(@policy_1_id, 'AYUSH Treatment', 1000000.00, 'Up to 100% of Sum Insured at government-recognized institutes/hospitals', 100.00),
(@policy_1_id, 'Pre-Hospitalization', NULL, '30 days prior to hospitalization covered up to actuals within Sum Insured', NULL),
(@policy_1_id, 'Post-Hospitalization', NULL, '60 days post-discharge covered up to actuals within Sum Insured', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
(@policy_1_id, 'Co-payment', NULL, 5.00, 'Standard Mandatory Co-payment applied on every admissible claim amount'),
(@policy_1_id, 'Voluntary Deductible', 0.00, NULL, 'Deductible NIL (Voluntary deductible not opted)');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
(@policy_1_id, NULL, 'Initial Waiting Period', 1, 'Any disease contracted during the first 30 days from policy inception, except accidental injuries'),
(@policy_1_id, NULL, 'Specific Illness Waiting Period', 24, 'Cataract, Hernia, Hydrocele, Joint replacement unless due to accident, Piles, Sinusitis'),
(@policy_1_id, 'Excl01', 'Pre-Existing Diseases (PED)', 36, 'Pre-existing conditions (e.g., Type-2 Diabetes) admissible only after 36 months of continuous coverage'),
(@policy_1_id, NULL, 'General Exclusion', NULL, 'Domiciliary hospitalization, cosmetic/aesthetic procedures, hazardous sports injuries, alcohol/substance abuse treatments, and unproven/experimental treatments');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(@policy_1_id, 'Bonus', 'No Claim Bonus (NCB)', 'Cumulative bonus increases Sum Insured by 5% for every claim-free year, up to a maximum of 50%'),
(@policy_1_id, 'Renewal', 'Grace Period & Continuity', '30-day grace period allowed for renewal without break-in-policy benefit loss'),
(@policy_1_id, 'Statutory', 'Moratorium Clause', '8-year moratorium clause applies; claims cannot be contested for non-disclosure after 8 continuous renewal years except for proven fraud');


-- ----------------------------------------------------------------------------
-- SAMPLE 2: Private Car Comprehensive Motor Policy
-- ----------------------------------------------------------------------------
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'MOT-PVT-2026-0049281',
    'Comprehensive Motor Policy',
    'Private Car Motor Insurance',
    'Hyundai Creta 1.5 L (Regn: KA-01-MJ-8819)',
    '2026-07-01',
    '2027-06-30',
    'Active',
    'Motor Vehicles Act, 1988',
    'INR',
    'POLICY NUMBER: MOT-PVT-2026-0049281
INSURED VEHICLE: Hyundai Creta 1.5 L (Regn: KA-01-MJ-8819)
INSURED DECLARED VALUE (IDV): ₹12,50,000
POLICY TERM: 01-Jul-2026 to 30-Jun-2027 (Active - Own Damage + 3-Year Third-Party Continuous)

1. COVERAGE LIMITS & STATUTORY COVERS
- Section I: Own Damage (OD) Limit: Up to Vehicle IDV (₹12,50,000) for loss due to fire, theft, flood, landslide, or accidental collision.
- Section II: Statutory Third-Party Liability (Compulsory under MV Act, 1988): Unlimited coverage for third-party bodily injury/death; Third-Party Property Damage (TPPD) capped at ₹7,50,000.
- Personal Accident (PA) Cover for Owner-Driver: Mandatory statutory cap of ₹15,00,000.

2. DEDUCTIBLE STRUCTURE
- IRDAI Compulsory Deductible: ₹1,000 for private cars with engine capacity not exceeding 1500 cc.
- Voluntary Deductible Opted: ₹2,500 additional deductible per claim.
- Total Deductible Payable per OD Claim: ₹3,500.

3. EXCLUSIONS
- Driving without a valid driving license or under the influence of intoxicating liquor/drugs at the time of accident.
- Consequential loss, depreciation, wear and tear, electrical/mechanical breakdown (e.g., engine hydrostatic lock during waterlogging unless Hydroblast Add-on Rider is attached).
- Claims arising outside the geographical boundaries of India.
- Usage of private vehicle for commercial transport or hire/reward purposes.

4. ACTIVE PROVISIONS & ADD-ONS
- No Claim Bonus (NCB) Entitlement: 20% discount applied at inception. Transferable upon sale of vehicle within 90 days.
- Zero Depreciation Add-on (Dep Shield): Depreciation deduction waived on plastic, rubber, glass, and metal replacement parts during repairs at authorized network garages.'
);

SET @policy_2_id = LAST_INSERT_ID();

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
(@policy_2_id, 'Section I: Own Damage (OD)', 1250000.00, 'Up to Insured Declared Value (IDV) for loss due to fire, theft, flood, landslide, or collision', NULL),
(@policy_2_id, 'Section II: Third-Party Bodily Injury/Death', NULL, 'Unlimited coverage as per Motor Vehicles Act, 1988', NULL),
(@policy_2_id, 'Section II: Third-Party Property Damage (TPPD)', 750000.00, 'Statutory cap on property damage liability', NULL),
(@policy_2_id, 'Personal Accident (PA) Cover for Owner-Driver', 1500000.00, 'Mandatory statutory cover cap', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
(@policy_2_id, 'Compulsory Deductible', 1000.00, NULL, 'IRDAI Compulsory Deductible for private cars <= 1500 cc'),
(@policy_2_id, 'Voluntary Deductible', 2500.00, NULL, 'Voluntary Deductible opted by the policyholder'),
(@policy_2_id, 'Total OD Deductible', 3500.00, NULL, 'Total combined deductible payable per Own Damage claim');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
(@policy_2_id, NULL, 'General Exclusion', NULL, 'Driving without a valid driving license or under the influence of intoxicating liquor or drugs'),
(@policy_2_id, NULL, 'General Exclusion', NULL, 'Consequential loss, depreciation, wear and tear, electrical/mechanical breakdown (e.g., hydrostatic lock)'),
(@policy_2_id, NULL, 'Geographical Exclusion', NULL, 'Claims arising outside the geographical boundaries of India'),
(@policy_2_id, NULL, 'Limitation of Use', NULL, 'Usage of private vehicle for commercial transport, hire, or reward');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(@policy_2_id, 'Discount', 'No Claim Bonus (NCB) Entitlement', '20% discount applied at inception. Transferable upon sale of vehicle within 90 days'),
(@policy_2_id, 'Add-On Rider', 'Zero Depreciation Add-on (Dep Shield)', 'Depreciation deduction waived on plastic, rubber, glass, and metal parts at authorized network garages');


-- ----------------------------------------------------------------------------
-- SAMPLE 3: Standard Fire and Special Perils (SFSP) Policy
-- ----------------------------------------------------------------------------
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'SFSP-COMM-2026-77102',
    'Standard Fire and Special Perils Policy (SFSP)',
    'Commercial Property & Fire Insurance',
    'Apex Textiles India Pvt. Ltd. (Facility: MIDC Industrial Area, Pune, MH)',
    '2026-01-01',
    '2026-12-31',
    'Active',
    'IRDAI / Commercial Property Framework',
    'INR',
    'POLICY NUMBER: SFSP-COMM-2026-77102
NAMED INSURED: Apex Textiles India Pvt. Ltd. (Facility: MIDC Industrial Area, Pune, MH)
PERIOD OF INSURANCE: 01-Jan-2026 to 31-Dec-2026 (Active)

1. SUM INSURED & CAP DETAILS
- Building / Factory Structure: ₹8,50,00,000.
- Plant & Machinery: ₹4,00,00,000.
- Stock of Finished & Raw Materials: ₹2,50,00,000.
- Total Sum Insured (TSI): ₹15,00,00,000 (Subject to 18% GST additional on premium paid).

2. DEDUCTIBLE CLAUSE (EXCESS)
- Standard Excess: 5% of claim amount subject to a minimum of ₹10,00,000 per event for material damage claims.
- AOF (Act of God / STFI) Excess: 5% of claim amount subject to a minimum of ₹25,000 per loss occurrence arising from Storm, Tempest, Flood, or Inundation.

3. EXCLUDED RISKS
- Loss, destruction, or damage caused by war, invasion, act of foreign enemy, nuclear radiation, or radioactive contamination.
- Pollution or contamination, except where resulting from a peril hereby insured.
- Loss by theft during or after the occurrence of any insured peril.
- Spontaneous combustion or damage caused by heating or drying processes carried out on stocks.

4. ACTIVE TERMS & SPECIAL ENDORSEMENTS
- Earthquake (Fire & Shock) Endorsement: Extended coverage included subject to seismic Zone III rates.
- Reinstatement Value Clause: Claims for building and plant machinery settled on repair/replacement cost without deducting depreciation, provided reinstatement is completed within 12 months.'
);

SET @policy_3_id = LAST_INSERT_ID();

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
(@policy_3_id, 'Building / Factory Structure', 85000000.00, 'Coverage for real factory building assets', NULL),
(@policy_3_id, 'Plant & Machinery', 40000000.00, 'Coverage for industrial equipment and machinery', NULL),
(@policy_3_id, 'Stock of Finished & Raw Materials', 25000000.00, 'Coverage for commercial inventory', NULL),
(@policy_3_id, 'Total Sum Insured (TSI)', 150000000.00, 'Aggregate policy coverage cap (Exclusive of 18% GST)', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
(@policy_3_id, 'Standard Excess', 1000000.00, 5.00, '5% of claim amount subject to a minimum of ₹10,00,000 per event for material damage'),
(@policy_3_id, 'AOG / STFI Excess', 25000.00, 5.00, '5% of claim amount subject to a minimum of ₹25,000 per loss for Storm, Tempest, Flood, Inundation');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
(@policy_3_id, NULL, 'Catastrophic Exclusion', NULL, 'War, invasion, act of foreign enemy, nuclear radiation, or radioactive contamination'),
(@policy_3_id, NULL, 'General Exclusion', NULL, 'Pollution or contamination, except where resulting from a peril hereby insured'),
(@policy_3_id, NULL, 'Peril Exclusion', NULL, 'Loss by theft during or after the occurrence of any insured peril'),
(@policy_3_id, NULL, 'Operational Exclusion', NULL, 'Spontaneous combustion or damage caused by heating or drying processes carried out on stocks');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(@policy_3_id, 'Endorsement', 'Earthquake (Fire & Shock) Endorsement', 'Extended coverage included subject to seismic Zone III rating'),
(@policy_3_id, 'Settlement Clause', 'Reinstatement Value Clause', 'Building and machinery claims settled on replacement cost without depreciation if completed in 12 months');


-- ----------------------------------------------------------------------------
-- SAMPLE 4: SME Cyber & Data Protection Policy (DPDP Act Compliant)
-- ----------------------------------------------------------------------------
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'CYBER-SME-2026-10293',
    'SME Cyber Liability & Data Protection Policy',
    'Cyber & Data Privacy Insurance',
    'Bharat Tech Solutions Pvt. Ltd.',
    '2026-05-01',
    '2027-04-30',
    'Active',
    'DPDP Act, 2023 / CERT-In Guidelines',
    'INR',
    'POLICY NUMBER: CYBER-SME-2026-10293
INSURED COMPANY: Bharat Tech Solutions Pvt. Ltd.
POLICY PERIOD: 01-May-2026 to 30-Apr-2027 (Active)

1. COVERAGE CAPS & INDEMNITY LIMITS
- Cyber Extortion & Ransomware Liability Cap: ₹50,00,000 aggregate.
- Digital Data Restoration & Forensic Costs Cap: ₹25,00,000 per incident.
- DPDP Act (Digital Personal Data Protection) Regulatory Fines & Defence Costs: ₹1,00,00,000 policy aggregate limit.
- Business Interruption Loss of Profit Cap: ₹50,00,000 subject to a 12-hour waiting period.

2. RETENTION / DEDUCTIBLES
- Self-Insured Retention (SIR): ₹1,00,000 for each claim under Data Recovery and Third-Party Cyber Claims.
- Time Excess: 12 consecutive hours of operational halt required for Business Interruption claims.

3. EXCLUSIONS
- Failure to adhere to basic IT security parameters (e.g., failure to update critical security patches within 60 days of vendor release or missing 2-factor authentication on administrative portals).
- Infrastructure outages caused by public utility failures (e.g., state electricity board power grid shutoffs or national telecom backhaul failures).
- Unexplained accounting discrepancies or wire fraud caused by social engineering without out-of-band phone verification.

4. ACTIVE TERMS
- Incident Reporting Timelines: Mandatory reporting to the insurer''s Incident Response Panel and CERT-In within 6 hours of discovery of a breach.'
);

SET @policy_4_id = LAST_INSERT_ID();

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, time_waiting_period_hours) VALUES
(@policy_4_id, 'Cyber Extortion & Ransomware Liability', 5000000.00, 'Aggregate policy limit for ransomware demands and negotiation', NULL),
(@policy_4_id, 'Digital Data Restoration & Forensic Costs', 2500000.00, 'Per incident cap for IT forensics and data rebuilding', NULL),
(@policy_4_id, 'DPDP Act Fines & Defence Costs', 10000000.00, 'Regulatory penalties and legal defense costs under Digital Personal Data Protection Act', NULL),
(@policy_4_id, 'Business Interruption Loss of Profit', 5000000.00, 'Net profit loss coverage subject to 12-hour time excess', 12);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, description) VALUES
(@policy_4_id, 'Self-Insured Retention (SIR)', 1000000.00, 'Applicable to each claim under Data Recovery and Third-Party Cyber Claims'),
(@policy_4_id, 'Time Excess', NULL, '12 consecutive hours of operational halt required before Business Interruption pays out');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, exclusion_description) VALUES
(@policy_4_id, NULL, 'Security Protocol Failure', 'Failure to apply security patches within 60 days or missing 2FA on admin portals'),
(@policy_4_id, NULL, 'Infrastructure Failure', 'Public utility failures including state power grid shutoffs and national telecom backbone outages'),
(@policy_4_id, NULL, 'Social Engineering', 'Unexplained accounting discrepancies or wire fraud without out-of-band phone verification');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(@policy_4_id, 'Mandatory Condition', 'Incident Reporting Timelines', 'Mandatory reporting to insurer Panel and CERT-In within 6 hours of breach discovery');

-- ============================================================================
-- Database: evidence_db (Simplified)
-- Description: Simple flat evidence lookup table linking 3rd-party verified details 
--              (receipts, damage descriptions, estimates) directly to claim IDs.
-- Generated: 2026-08-02
-- ============================================================================

CREATE DATABASE IF NOT EXISTS evidence_db;
USE evidence_db;

DROP TABLE IF EXISTS evidence_records;

-- Single, flat table for straightforward query execution
CREATE TABLE evidence_records (
    claim_id INT PRIMARY KEY,
    claim_reference_no VARCHAR(100) NOT NULL UNIQUE,
    policy_number VARCHAR(100) NOT NULL,
    claimant_name VARCHAR(255) NOT NULL,
    
    -- Claimed vs Verified Totals (For simple LLM math comparison)
    claimed_amount DECIMAL(15, 2) NOT NULL,
    validated_evidence_total DECIMAL(15, 2) NOT NULL,
    discrepancy_amount DECIMAL(15, 2) NOT NULL,
    
    -- Evidence Details
    verifier_name VARCHAR(255) NOT NULL,        -- e.g., 'MediAssist TPA Network'
    evidence_type VARCHAR(100) NOT NULL,        -- e.g., 'Hospital Receipt & Bill'
    receipt_reference_no VARCHAR(100) NOT NULL, -- e.g., 'RCPT-APOLLO-991'
    damage_description TEXT NOT NULL,          -- Description of loss / procedure
    verification_status VARCHAR(50) DEFAULT 'Verified'
);

-- ============================================================================
-- SEED DATA (Aligned with claim_ids: 1, 2, and 3 from claims_adjudication_db)
-- ============================================================================

INSERT INTO evidence_records (
    claim_id, claim_reference_no, policy_number, claimant_name,
    claimed_amount, validated_evidence_total, discrepancy_amount,
    verifier_name, evidence_type, receipt_reference_no, damage_description, verification_status
) VALUES 
(
    1, 
    'CLM-2026-HLT-001', 
    'IRDAI/HLT/2026/IND-8849102', 
    'Rajesh Kumar Sharma',
    125000.00, 
    118000.00, 
    7000.00,
    'MediAssist TPA Network', 
    'Hospital Receipt & Bill', 
    'RCPT-APOLLO-991', 
    'Cataract surgery OD (Right Eye) and 3-day inpatient stay at Apollo Hospital.', 
    'Verified'
),
(
    2, 
    'CLM-2026-MOT-044', 
    'MOT-PVT-2026-0049281', 
    'Hyundai Creta (KA-01-MJ-8819)',
    185000.00, 
    160000.00, 
    25000.00,
    'IRT Surveyors Pvt Ltd', 
    'Motor Repair Estimate', 
    'EST-HYD-00412', 
    'Front bumper and headlamp crushed due to collision with guardrail.', 
    'Verified'
),
(
    3, 
    'CLM-2026-CYB-902', 
    'CYBER-SME-2026-10293', 
    'Bharat Tech Solutions Pvt. Ltd.',
    500000.00, 
    500000.00, 
    0.00,
    'CERT-In Cyber Forensics', 
    'Forensics & Recovery Invoice', 
    'INV-CERT-9902', 
    'Ransomware encryption recovery and 18 hours database downtime.', 
    'Verified'
);

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
