-- ============================================================================
-- Database: Consolidated Claims & Policy Adjudication System (SQLite Dialect)
-- Includes: Adjudication Records, Policy Contracts, Evidence Records, and Mandates
-- Generated: 2026-08-11
-- ============================================================================

PRAGMA foreign_keys = ON;

-- Drop existing tables and views if re-running
DROP VIEW IF EXISTS v_claim_adjudication_details;
DROP VIEW IF EXISTS v_evaluate_payout_mandates;

DROP TABLE IF EXISTS evidence_records;
DROP TABLE IF EXISTS claim_adjudication_records;
DROP TABLE IF EXISTS claim_scenario_rules;
DROP TABLE IF EXISTS approval_authority_levels;
DROP TABLE IF EXISTS policy_terms;
DROP TABLE IF EXISTS policy_exclusions;
DROP TABLE IF EXISTS policy_deductibles;
DROP TABLE IF EXISTS policy_coverages;
DROP TABLE IF EXISTS policy_contracts;

-- ============================================================================
-- 1. CLAIMS ADJUDICATION RECORDS
-- ============================================================================

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

-- Seed Data: Adjudication Records
INSERT INTO claim_adjudication_records (
    claim_id, claim_reference_no, policy_number, policy_type, claim_scenario,
    claimant_name, claimed_amount, verified_evidence_total, discrepancy_amount,
    sub_limit_applied, applicable_deductible, copay_percentage_applied, copay_deducted_amount,
    depreciation_deducted_amount, final_calculated_net_payout, adjudication_status,
    designated_authority, adjudication_reasoning, risk_score, verifier_trust_score
) VALUES 
(
    1, 'CLM-2026-HLT-001', 'IRDAI/HLT/2026/IND-8849102', 'Individual Health Insurance', 
    'Standard Inpatient / Daycare Procedures', 'Rajesh Kumar Sharma', 
    125000.00, 118000.00, 7000.00, 40000.00, 0.00, 5.00, 2000.00, 0.00, 38000.00, 
    'APPROVED_STP', 'STP_Automated_Engine', 
    'Claim verified by MediAssist TPA. Cataract sub-limit of ₹40,000 applied. 5% co-pay deducted (₹2,000). Net payout of ₹38,000 is within the ₹1,50,000 auto-approval threshold.', 
    0.05, 0.98
),
(
    2, 'CLM-2026-MOT-044', 'MOT-PVT-2026-0049281', 'Private Car Motor Insurance', 
    'Partial Loss Accidental Collision', 'Hyundai Creta (KA-01-MJ-8819)', 
    185000.00, 160000.00, 25000.00, 1250000.00, 3500.00, 0.00, 0.00, 0.00, 156500.00, 
    'ROUTED_FOR_HUMAN_REVIEW', 'Junior_Claims_Adjuster', 
    'Calculated net payout (₹1,56,500.00) exceeds the motor collision auto-approval limit (₹1,00,000.00). Discrepancy of ₹25,000 exceeds ₹15,000 tolerance. Assigned to Junior Adjuster.', 
    0.12, 0.95
),
(
    3, 'CLM-2026-CYB-902', 'CYBER-SME-2026-10293', 'Cyber & Data Privacy Insurance', 
    'Extortion & Incident Response Recovery', 'Bharat Tech Solutions Pvt. Ltd.', 
    500000.00, 500000.00, 0.00, 5000000.00, 100000.00, 0.00, 0.00, 0.00, 400000.00, 
    'APPROVED_STP', 'STP_Automated_Engine', 
    'CERT-In forensic logs verified MFA compliance and 18-hour downtime. Net payout of ₹400,000 after ₹100,000 SIR is within the ₹500,000 Cyber STP threshold.', 
    0.04, 0.99
);

-- SQLite Alternative for Procedure `sp_get_claim_adjudication_details`
-- Query using: SELECT * FROM v_claim_adjudication_details WHERE claim_id = 1 OR claim_reference_no = 'CLM-2026-HLT-001';
CREATE VIEW v_claim_adjudication_details AS
SELECT 
    r.claim_id,
    r.claim_reference_no,
    r.policy_number,
    r.policy_type,
    r.claim_scenario,
    r.claimant_name,
    r.claimed_amount,
    r.verified_evidence_total,
    r.discrepancy_amount,
    r.sub_limit_applied,
    r.applicable_deductible,
    r.copay_percentage_applied || '%' AS copay_rate,
    r.copay_deducted_amount,
    r.depreciation_deducted_amount,
    r.final_calculated_net_payout,
    r.adjudication_status,
    r.designated_authority,
    r.adjudication_reasoning,
    r.risk_score,
    r.verifier_trust_score,
    r.adjudicated_at
FROM claim_adjudication_records r;

-- ============================================================================
-- 2. POLICY CONTRACTS & TERMS
-- ============================================================================

CREATE TABLE policy_contracts (
    policy_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_number TEXT NOT NULL UNIQUE,
    scheme_or_product_name TEXT,
    policy_type TEXT NOT NULL,
    insured_entity_name TEXT NOT NULL,
    effective_start_date TEXT NOT NULL,
    effective_end_date TEXT NOT NULL,
    policy_status TEXT DEFAULT 'Active',
    regulatory_framework TEXT DEFAULT 'IRDAI',
    currency TEXT DEFAULT 'INR',
    full_text TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE policy_coverages (
    coverage_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    coverage_name TEXT NOT NULL,
    coverage_limit_amount REAL,
    coverage_limit_description TEXT,
    sub_limit_percentage REAL,
    time_waiting_period_hours INTEGER,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

CREATE TABLE policy_deductibles (
    deductible_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    deductible_type TEXT NOT NULL,
    deductible_amount REAL,
    deductible_percentage REAL,
    description TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

CREATE TABLE policy_exclusions (
    exclusion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    exclusion_code TEXT,
    exclusion_category TEXT,
    waiting_period_months INTEGER,
    exclusion_description TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

CREATE TABLE policy_terms (
    term_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    term_category TEXT NOT NULL,
    term_name TEXT NOT NULL,
    term_details TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- Seed Data: Sample Policy 1 (Arogya Sanjeevani)
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'IRDAI/HLT/2026/IND-8849102', 'Arogya Sanjeevani Policy', 'Individual Health Insurance',
    'Rajesh Kumar Sharma', '2026-04-10', '2027-04-09', 'Active', 'IRDAI Standard Health Product', 'INR',
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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
(1, 'Base Sum Insured', 1000000.00, 'Base Sum Insured per policy year', NULL),
(1, 'Room Rent, Boarding & Nursing', 1000000.00, 'Capped at 2% of Sum Insured per day', 2.00),
(1, 'ICU Expenses', 1000000.00, 'Capped at 5% of Sum Insured per day', 5.00),
(1, 'Cataract Treatment', 40000.00, 'Sub-limit of 25% of Sum Insured or ₹40,000, whichever is lower, per eye', 25.00),
(1, 'AYUSH Treatment', 1000000.00, 'Up to 100% of Sum Insured at government-recognized institutes/hospitals', 100.00),
(1, 'Pre-Hospitalization', NULL, '30 days prior to hospitalization covered up to actuals within Sum Insured', NULL),
(1, 'Post-Hospitalization', NULL, '60 days post-discharge covered up to actuals within Sum Insured', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
(1, 'Co-payment', NULL, 5.00, 'Standard Mandatory Co-payment applied on every admissible claim amount'),
(1, 'Voluntary Deductible', 0.00, NULL, 'Deductible NIL (Voluntary deductible not opted)');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
(1, NULL, 'Initial Waiting Period', 1, 'Any disease contracted during the first 30 days from policy inception, except accidental injuries'),
(1, NULL, 'Specific Illness Waiting Period', 24, 'Cataract, Hernia, Hydrocele, Joint replacement unless due to accident, Piles, Sinusitis'),
(1, 'Excl01', 'Pre-Existing Diseases (PED)', 36, 'Pre-existing conditions (e.g., Type-2 Diabetes) admissible only after 36 months of continuous coverage'),
(1, NULL, 'General Exclusion', NULL, 'Domiciliary hospitalization, cosmetic/aesthetic procedures, hazardous sports injuries, alcohol/substance abuse treatments, and unproven/experimental treatments');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(1, 'Bonus', 'No Claim Bonus (NCB)', 'Cumulative bonus increases Sum Insured by 5% for every claim-free year, up to a maximum of 50%'),
(1, 'Renewal', 'Grace Period & Continuity', '30-day grace period allowed for renewal without break-in-policy benefit loss'),
(1, 'Statutory', 'Moratorium Clause', '8-year moratorium clause applies; claims cannot be contested for non-disclosure after 8 continuous renewal years except for proven fraud');

-- Seed Data: Sample Policy 2 (Motor Policy)
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'MOT-PVT-2026-0049281', 'Comprehensive Motor Policy', 'Private Car Motor Insurance',
    'Hyundai Creta 1.5 L (Regn: KA-01-MJ-8819)', '2026-07-01', '2027-06-30', 'Active', 'Motor Vehicles Act, 1988', 'INR',
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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
(2, 'Section I: Own Damage (OD)', 1250000.00, 'Up to Insured Declared Value (IDV) for loss due to fire, theft, flood, landslide, or collision', NULL),
(2, 'Section II: Third-Party Bodily Injury/Death', NULL, 'Unlimited coverage as per Motor Vehicles Act, 1988', NULL),
(2, 'Section II: Third-Party Property Damage (TPPD)', 750000.00, 'Statutory cap on property damage liability', NULL),
(2, 'Personal Accident (PA) Cover for Owner-Driver', 1500000.00, 'Mandatory statutory cover cap', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
(2, 'Compulsory Deductible', 1000.00, NULL, 'IRDAI Compulsory Deductible for private cars <= 1500 cc'),
(2, 'Voluntary Deductible', 2500.00, NULL, 'Voluntary Deductible opted by the policyholder'),
(2, 'Total OD Deductible', 3500.00, NULL, 'Total combined deductible payable per Own Damage claim');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
(2, NULL, 'General Exclusion', NULL, 'Driving without a valid driving license or under the influence of intoxicating liquor or drugs'),
(2, NULL, 'General Exclusion', NULL, 'Consequential loss, depreciation, wear and tear, electrical/mechanical breakdown (e.g., hydrostatic lock)'),
(2, NULL, 'Geographical Exclusion', NULL, 'Claims arising outside the geographical boundaries of India'),
(2, NULL, 'Limitation of Use', NULL, 'Usage of private vehicle for commercial transport, hire, or reward');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(2, 'Discount', 'No Claim Bonus (NCB) Entitlement', '20% discount applied at inception. Transferable upon sale of vehicle within 90 days'),
(2, 'Add-On Rider', 'Zero Depreciation Add-on (Dep Shield)', 'Depreciation deduction waived on plastic, rubber, glass, and metal parts at authorized network garages');

-- Seed Data: Sample Policy 3 (SFSP Policy)
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'SFSP-COMM-2026-77102', 'Standard Fire and Special Perils Policy (SFSP)', 'Commercial Property & Fire Insurance',
    'Apex Textiles India Pvt. Ltd. (Facility: MIDC Industrial Area, Pune, MH)', '2026-01-01', '2026-12-31', 'Active', 'IRDAI / Commercial Property Framework', 'INR',
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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
(3, 'Building / Factory Structure', 85000000.00, 'Coverage for real factory building assets', NULL),
(3, 'Plant & Machinery', 40000000.00, 'Coverage for industrial equipment and machinery', NULL),
(3, 'Stock of Finished & Raw Materials', 25000000.00, 'Coverage for commercial inventory', NULL),
(3, 'Total Sum Insured (TSI)', 150000000.00, 'Aggregate policy coverage cap (Exclusive of 18% GST)', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
(3, 'Standard Excess', 1000000.00, 5.00, '5% of claim amount subject to a minimum of ₹10,00,000 per event for material damage'),
(3, 'AOG / STFI Excess', 25000.00, 5.00, '5% of claim amount subject to a minimum of ₹25,000 per loss for Storm, Tempest, Flood, Inundation');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
(3, NULL, 'Catastrophic Exclusion', NULL, 'War, invasion, act of foreign enemy, nuclear radiation, or radioactive contamination'),
(3, NULL, 'General Exclusion', NULL, 'Pollution or contamination, except where resulting from a peril hereby insured'),
(3, NULL, 'Peril Exclusion', NULL, 'Loss by theft during or after the occurrence of any insured peril'),
(3, NULL, 'Operational Exclusion', NULL, 'Spontaneous combustion or damage caused by heating or drying processes carried out on stocks');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(3, 'Endorsement', 'Earthquake (Fire & Shock) Endorsement', 'Extended coverage included subject to seismic Zone III rating'),
(3, 'Settlement Clause', 'Reinstatement Value Clause', 'Building and machinery claims settled on replacement cost without depreciation if completed in 12 months');

-- Seed Data: Sample Policy 4 (Cyber Policy)
INSERT INTO policy_contracts (
    policy_number, scheme_or_product_name, policy_type, insured_entity_name, 
    effective_start_date, effective_end_date, policy_status, regulatory_framework, currency, full_text
) VALUES (
    'CYBER-SME-2026-10293', 'SME Cyber Liability & Data Protection Policy', 'Cyber & Data Privacy Insurance',
    'Bharat Tech Solutions Pvt. Ltd.', '2026-05-01', '2027-04-30', 'Active', 'DPDP Act, 2023 / CERT-In Guidelines', 'INR',
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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, time_waiting_period_hours) VALUES
(4, 'Cyber Extortion & Ransomware Liability', 5000000.00, 'Aggregate policy limit for ransomware demands and negotiation', NULL),
(4, 'Digital Data Restoration & Forensic Costs', 2500000.00, 'Per incident cap for IT forensics and data rebuilding', NULL),
(4, 'DPDP Act Fines & Defence Costs', 10000000.00, 'Regulatory penalties and legal defense costs under Digital Personal Data Protection Act', NULL),
(4, 'Business Interruption Loss of Profit', 5000000.00, 'Net profit loss coverage subject to 12-hour time excess', 12);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, description) VALUES
(4, 'Self-Insured Retention (SIR)', 1000000.00, 'Applicable to each claim under Data Recovery and Third-Party Cyber Claims'),
(4, 'Time Excess', NULL, '12 consecutive hours of operational halt required before Business Interruption pays out');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, exclusion_description) VALUES
(4, NULL, 'Security Protocol Failure', 'Failure to apply security patches within 60 days or missing 2FA on admin portals'),
(4, NULL, 'Infrastructure Failure', 'Public utility failures including state power grid shutoffs and national telecom backbone outages'),
(4, NULL, 'Social Engineering', 'Unexplained accounting discrepancies or wire fraud without out-of-band phone verification');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
(4, 'Mandatory Condition', 'Incident Reporting Timelines', 'Mandatory reporting to insurer Panel and CERT-In within 6 hours of breach discovery');

-- ============================================================================
-- 3. EVIDENCE RECORDS
-- ============================================================================

CREATE TABLE evidence_records (
    claim_id INTEGER PRIMARY KEY,
    claim_reference_no TEXT NOT NULL UNIQUE,
    policy_number TEXT NOT NULL,
    claimant_name TEXT NOT NULL,
    
    -- Claimed vs Verified Totals
    claimed_amount REAL NOT NULL,
    validated_evidence_total REAL NOT NULL,
    discrepancy_amount REAL NOT NULL,
    
    -- Evidence Details
    verifier_name TEXT NOT NULL,
    evidence_type TEXT NOT NULL,
    receipt_reference_no TEXT NOT NULL,
    damage_description TEXT NOT NULL,
    verification_status TEXT DEFAULT 'Verified'
);

INSERT INTO evidence_records (
    claim_id, claim_reference_no, policy_number, claimant_name,
    claimed_amount, validated_evidence_total, discrepancy_amount,
    verifier_name, evidence_type, receipt_reference_no, damage_description, verification_status
) VALUES 
(
    1, 'CLM-2026-HLT-001', 'IRDAI/HLT/2026/IND-8849102', 'Rajesh Kumar Sharma',
    125000.00, 118000.00, 7000.00, 'MediAssist TPA Network', 
    'Hospital Receipt & Bill', 'RCPT-APOLLO-991', 
    'Cataract surgery OD (Right Eye) and 3-day inpatient stay at Apollo Hospital.', 'Verified'
),
(
    2, 'CLM-2026-MOT-044', 'MOT-PVT-2026-0049281', 'Hyundai Creta (KA-01-MJ-8819)',
    185000.00, 160000.00, 25000.00, 'IRT Surveyors Pvt Ltd', 
    'Motor Repair Estimate', 'EST-HYD-00412', 
    'Front bumper and headlamp crushed due to collision with guardrail.', 'Verified'
),
(
    3, 'CLM-2026-CYB-902', 'CYBER-SME-2026-10293', 'Bharat Tech Solutions Pvt. Ltd.',
    500000.00, 500000.00, 0.00, 'CERT-In Cyber Forensics', 
    'Forensics & Recovery Invoice', 'INV-CERT-9902', 
    'Ransomware encryption recovery and 18 hours database downtime.', 'Verified'
);

-- ============================================================================
-- 4. PAYOUT MANDATE RULES & APPROVAL TIERS
-- ============================================================================

CREATE TABLE approval_authority_levels (
    tier_id INTEGER PRIMARY KEY AUTOINCREMENT,
    authority_role TEXT NOT NULL UNIQUE,
    max_payout_limit REAL NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE claim_scenario_rules (
    rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_type TEXT NOT NULL,
    claim_scenario TEXT NOT NULL,
    auto_approval_limit REAL NOT NULL,
    max_discrepancy_tolerance REAL DEFAULT 0.00,
    max_allowed_risk_score REAL DEFAULT 0.20,
    min_verifier_trust_score REAL DEFAULT 0.90,
    requires_zero_dep_addon INTEGER DEFAULT 0, -- 0 = FALSE, 1 = TRUE
    mandatory_human_review_flag INTEGER DEFAULT 0, -- 0 = FALSE, 1 = TRUE
    routing_tier_id_on_breach INTEGER NOT NULL,
    rule_status TEXT DEFAULT 'Active',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (routing_tier_id_on_breach) REFERENCES approval_authority_levels(tier_id)
);

-- Seed Data: Authority Levels
INSERT INTO approval_authority_levels (tier_id, authority_role, max_payout_limit, description) VALUES
(1, 'STP_Automated_Engine', 200000.00, 'Straight-through automated approval without human intervention'),
(2, 'Junior_Claims_Adjuster', 500000.00, 'Requires human review by a Level-1 Claims Adjuster'),
(3, 'Senior_Claims_Manager', 2500000.00, 'Requires review & approval by Senior Claims Manager'),
(4, 'Chief_Risk_Officer_Panel', 100000000.00, 'Requires executive committee / CRO level sign-off');

-- Seed Data: Scenario Rules
INSERT INTO claim_scenario_rules (
    policy_type, claim_scenario, auto_approval_limit, max_discrepancy_tolerance, 
    max_allowed_risk_score, min_verifier_trust_score, requires_zero_dep_addon, 
    mandatory_human_review_flag, routing_tier_id_on_breach
) VALUES
('Individual Health Insurance', 'Standard Inpatient / Daycare Procedures', 150000.00, 10000.00, 0.15, 0.95, 0, 0, 2),
('Private Car Motor Insurance', 'Partial Loss Accidental Collision', 100000.00, 15000.00, 0.20, 0.90, 1, 0, 2),
('Private Car Motor Insurance', 'Total Loss / Vehicle Theft', 0.00, 0.00, 0.05, 0.95, 0, 1, 3),
('Cyber & Data Privacy Insurance', 'Extortion & Incident Response Recovery', 500000.00, 50000.00, 0.10, 0.98, 0, 0, 3),
('Commercial Property & Fire Insurance', 'Industrial Fire & Material Damage', 0.00, 0.00, 0.10, 0.95, 0, 1, 4);

-- SQLite Alternative for Procedure `sp_evaluate_payout_mandate`
-- Evaluates claim parameters dynamically when queried against claim_scenario_rules
CREATE VIEW v_evaluate_payout_mandates AS
SELECT 
    r.rule_id,
    r.policy_type,
    r.claim_scenario,
    r.auto_approval_limit,
    r.max_discrepancy_tolerance,
    r.max_allowed_risk_score,
    r.min_verifier_trust_score,
    r.mandatory_human_review_flag,
    a.authority_role AS breach_routing_authority
FROM claim_scenario_rules r
JOIN approval_authority_levels a ON r.routing_tier_id_on_breach = a.tier_id
WHERE r.rule_status = 'Active';
