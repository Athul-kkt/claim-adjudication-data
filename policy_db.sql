-- ============================================================================
-- SQL Schema and Seed Data for Synthetic Insurance Policy Contracts (SQLite)
-- Description: Structured representation of synthetic insurance policy contracts
--              including deductibles, coverage caps, exclusions, and active terms.
-- Generated: 2026-08-11
-- ============================================================================

PRAGMA foreign_keys = ON;

-- Drop existing tables if re-running
DROP TABLE IF EXISTS policy_terms;
DROP TABLE IF EXISTS policy_exclusions;
DROP TABLE IF EXISTS policy_deductibles;
DROP TABLE IF EXISTS policy_coverages;
DROP TABLE IF EXISTS policy_contracts;

-- ----------------------------------------------------------------------------
-- Table: policy_contracts
-- Core policy details and metadata
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Table: policy_coverages
-- Coverage details, limits, and financial caps
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Table: policy_deductibles
-- Deductibles, copayments, retention, and excesses
-- ----------------------------------------------------------------------------
CREATE TABLE policy_deductibles (
    deductible_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    deductible_type TEXT NOT NULL, -- e.g., Mandatory, Voluntary, Co-payment, SIR
    deductible_amount REAL,
    deductible_percentage REAL,
    description TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table: policy_exclusions
-- Explicit policy exclusions and waiting periods
-- ----------------------------------------------------------------------------
CREATE TABLE policy_exclusions (
    exclusion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    exclusion_code TEXT,
    exclusion_category TEXT, -- e.g., Waiting Period, Standard Exclusion, Specific Event
    waiting_period_months INTEGER,
    exclusion_description TEXT NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES policy_contracts(policy_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table: policy_terms
-- Special conditions, riders, bonuses, and active statutory clauses
-- ----------------------------------------------------------------------------
CREATE TABLE policy_terms (
    term_id INTEGER PRIMARY KEY AUTOINCREMENT,
    policy_id INTEGER NOT NULL,
    term_category TEXT NOT NULL, -- e.g., Rider, Renewal, Reporting, Endorsement
    term_name TEXT NOT NULL,
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

-- Using subquery to replace MySQL LAST_INSERT_ID() / SET @variable
INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Base Sum Insured', 1000000.00, 'Base Sum Insured per policy year', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Room Rent, Boarding & Nursing', 1000000.00, 'Capped at 2% of Sum Insured per day', 2.00),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'ICU Expenses', 1000000.00, 'Capped at 5% of Sum Insured per day', 5.00),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Cataract Treatment', 40000.00, 'Sub-limit of 25% of Sum Insured or ₹40,000, whichever is lower, per eye', 25.00),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'AYUSH Treatment', 1000000.00, 'Up to 100% of Sum Insured at government-recognized institutes/hospitals', 100.00),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Pre-Hospitalization', NULL, '30 days prior to hospitalization covered up to actuals within Sum Insured', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Post-Hospitalization', NULL, '60 days post-discharge covered up to actuals within Sum Insured', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Co-payment', NULL, 5.00, 'Standard Mandatory Co-payment applied on every admissible claim amount'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Voluntary Deductible', 0.00, NULL, 'Deductible NIL (Voluntary deductible not opted)');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), NULL, 'Initial Waiting Period', 1, 'Any disease contracted during the first 30 days from policy inception, except accidental injuries'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), NULL, 'Specific Illness Waiting Period', 24, 'Cataract, Hernia, Hydrocele, Joint replacement unless due to accident, Piles, Sinusitis'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Excl01', 'Pre-Existing Diseases (PED)', 36, 'Pre-existing conditions (e.g., Type-2 Diabetes) admissible only after 36 months of continuous coverage'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), NULL, 'General Exclusion', NULL, 'Domiciliary hospitalization, cosmetic/aesthetic procedures, hazardous sports injuries, alcohol/substance abuse treatments, and unproven/experimental treatments');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Bonus', 'No Claim Bonus (NCB)', 'Cumulative bonus increases Sum Insured by 5% for every claim-free year, up to a maximum of 50%'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Renewal', 'Grace Period & Continuity', '30-day grace period allowed for renewal without break-in-policy benefit loss'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'IRDAI/HLT/2026/IND-8849102'), 'Statutory', 'Moratorium Clause', '8-year moratorium clause applies; claims cannot be contested for non-disclosure after 8 continuous renewal years except for proven fraud');


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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Section I: Own Damage (OD)', 1250000.00, 'Up to Insured Declared Value (IDV) for loss due to fire, theft, flood, landslide, or collision', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Section II: Third-Party Bodily Injury/Death', NULL, 'Unlimited coverage as per Motor Vehicles Act, 1988', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Section II: Third-Party Property Damage (TPPD)', 750000.00, 'Statutory cap on property damage liability', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Personal Accident (PA) Cover for Owner-Driver', 1500000.00, 'Mandatory statutory cover cap', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Compulsory Deductible', 1000.00, NULL, 'IRDAI Compulsory Deductible for private cars <= 1500 cc'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Voluntary Deductible', 2500.00, NULL, 'Voluntary Deductible opted by the policyholder'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Total OD Deductible', 3500.00, NULL, 'Total combined deductible payable per Own Damage claim');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), NULL, 'General Exclusion', NULL, 'Driving without a valid driving license or under the influence of intoxicating liquor or drugs'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), NULL, 'General Exclusion', NULL, 'Consequential loss, depreciation, wear and tear, electrical/mechanical breakdown (e.g., hydrostatic lock)'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), NULL, 'Geographical Exclusion', NULL, 'Claims arising outside the geographical boundaries of India'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), NULL, 'Limitation of Use', NULL, 'Usage of private vehicle for commercial transport, hire, or reward');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Discount', 'No Claim Bonus (NCB) Entitlement', '20% discount applied at inception. Transferable upon sale of vehicle within 90 days'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'MOT-PVT-2026-0049281'), 'Add-On Rider', 'Zero Depreciation Add-on (Dep Shield)', 'Depreciation deduction waived on plastic, rubber, glass, and metal parts at authorized network garages');


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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, sub_limit_percentage) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Building / Factory Structure', 85000000.00, 'Coverage for real factory building assets', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Plant & Machinery', 40000000.00, 'Coverage for industrial equipment and machinery', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Stock of Finished & Raw Materials', 25000000.00, 'Coverage for commercial inventory', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Total Sum Insured (TSI)', 150000000.00, 'Aggregate policy coverage cap (Exclusive of 18% GST)', NULL);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, deductible_percentage, description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Standard Excess', 1000000.00, 5.00, '5% of claim amount subject to a minimum of ₹10,00,000 per event for material damage'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'AOG / STFI Excess', 25000.00, 5.00, '5% of claim amount subject to a minimum of ₹25,000 per loss for Storm, Tempest, Flood, Inundation');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, waiting_period_months, exclusion_description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), NULL, 'Catastrophic Exclusion', NULL, 'War, invasion, act of foreign enemy, nuclear radiation, or radioactive contamination'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), NULL, 'General Exclusion', NULL, 'Pollution or contamination, except where resulting from a peril hereby insured'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), NULL, 'Peril Exclusion', NULL, 'Loss by theft during or after the occurrence of any insured peril'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), NULL, 'Operational Exclusion', NULL, 'Spontaneous combustion or damage caused by heating or drying processes carried out on stocks');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Endorsement', 'Earthquake (Fire & Shock) Endorsement', 'Extended coverage included subject to seismic Zone III rating'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'SFSP-COMM-2026-77102'), 'Settlement Clause', 'Reinstatement Value Clause', 'Building and machinery claims settled on replacement cost without depreciation if completed in 12 months');


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

INSERT INTO policy_coverages (policy_id, coverage_name, coverage_limit_amount, coverage_limit_description, time_waiting_period_hours) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'Cyber Extortion & Ransomware Liability', 5000000.00, 'Aggregate policy limit for ransomware demands and negotiation', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'Digital Data Restoration & Forensic Costs', 2500000.00, 'Per incident cap for IT forensics and data rebuilding', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'DPDP Act Fines & Defence Costs', 10000000.00, 'Regulatory penalties and legal defense costs under Digital Personal Data Protection Act', NULL),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'Business Interruption Loss of Profit', 5000000.00, 'Net profit loss coverage subject to 12-hour time excess', 12);

INSERT INTO policy_deductibles (policy_id, deductible_type, deductible_amount, description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'Self-Insured Retention (SIR)', 1000000.00, 'Applicable to each claim under Data Recovery and Third-Party Cyber Claims'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'Time Excess', NULL, '12 consecutive hours of operational halt required before Business Interruption pays out');

INSERT INTO policy_exclusions (policy_id, exclusion_code, exclusion_category, exclusion_description) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), NULL, 'Security Protocol Failure', 'Failure to apply security patches within 60 days or missing 2FA on admin portals'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), NULL, 'Infrastructure Failure', 'Public utility failures including state power grid shutoffs and national telecom backbone outages'),
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), NULL, 'Social Engineering', 'Unexplained accounting discrepancies or wire fraud without out-of-band phone verification');

INSERT INTO policy_terms (policy_id, term_category, term_name, term_details) VALUES
((SELECT policy_id FROM policy_contracts WHERE policy_number = 'CYBER-SME-2026-10293'), 'Mandatory Condition', 'Incident Reporting Timelines', 'Mandatory reporting to insurer Panel and CERT-In within 6 hours of breach discovery');
