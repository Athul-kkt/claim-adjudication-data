-- ============================================================================
-- Database: evidence_db (Simplified - SQLite Dialect)
-- Description: Simple flat evidence lookup table linking 3rd-party verified details 
--              (receipts, damage descriptions, estimates) directly to claim IDs.
-- Generated: 2026-08-11
-- ============================================================================

-- Drop existing objects if re-running
DROP TABLE IF EXISTS evidence_records;

-- Single, flat table for straightforward query execution
CREATE TABLE evidence_records (
    claim_id INTEGER PRIMARY KEY,
    claim_reference_no TEXT NOT NULL UNIQUE,
    policy_number TEXT NOT NULL,
    claimant_name TEXT NOT NULL,
    
    -- Claimed vs Verified Totals (For simple LLM math comparison)
    claimed_amount REAL NOT NULL,
    validated_evidence_total REAL NOT NULL,
    discrepancy_amount REAL NOT NULL,
    
    -- Evidence Details
    verifier_name TEXT NOT NULL,         -- e.g., 'MediAssist TPA Network'
    evidence_type TEXT NOT NULL,         -- e.g., 'Hospital Receipt & Bill'
    receipt_reference_no TEXT NOT NULL,  -- e.g., 'RCPT-APOLLO-991'
    damage_description TEXT NOT NULL,   -- Description of loss / procedure
    verification_status TEXT DEFAULT 'Verified'
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
