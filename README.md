
# 🐾 Pet Clinic Relational Database Design

A robust, normalized relational database schema designed to transition a pet clinic from outdated spreadsheets and manual cross-referencing to a modern, efficient system.

This repository showcases the end-to-end database design for a rural veterinary practice supporting up to 2,000 pets. The system is designed to simplify workflows, enforce data integrity constraints, and formalise complex treatment paths including diagnoses, prescriptions, referrals, deferrals, and follow-ups.

---

## System Requirements

The database was designed to meet a strict set of requirements.

### Functional Requirements
* **Receptionists:** Manage (retrieve, store, update, and delete) client, pet, consultation, treatment, and payment records.
* **Veterinary Staff (Doctors & Nurses):** Review client, pet, and consultation data, and record treatment data. Nurses only handle treatment data on behalf of a doctor.
* **System Administrators:** Have full access control to manage all system data across every relation in the database.

### Non-Functional Requirements
* **Data Integrity:** Strict enforcement of data formats, specific primary key increments, and domain restrictions.
* **User-Based Qualities:** The system must be intuitive, require minimal staff training (1 business day), and respond to user interactions within 2 seconds.
* **System-Based Qualities:** Must support up to 20 simultaneous users without performance drops, perform daily backups with a 30-day restoration window, and enforce strict security protocols like data encryption and automatic logouts.

---

## Design Methodology

The database schema was developed through a rigorous, multi-step modelling process to eliminate redundancy and ensure high data integrity.

### 1. Top-Down Conceptual Modelling
* Initial designs were drafted using top-down Entity-Relationship Diagrams.
* Flaws in these early iterations—such as over-reliance on natural keys, strict 1:1 relationships between appointments and payments (which failed for cancelled appointments), and poorly defined referral/deferral handling—were identified and analysed.

### 2. Bottom-Up Normalization
* To resolve conceptual hurdles, existing clinic input forms (consultation, appointment, and pet registration) were normalized to Third Normal Form (3NF).
* These 3NF tables were then merged to create a data-driven, bottom-up model. This process successfully clarified complex recursive relationships, particularly connecting diagnoses, medications, and pharmacies via a central "Prescription" entity.

### 3. Final ERD Refinement
* **Unary Relationships:** A self-referencing relationship was introduced for `Consultations` to elegantly handle follow-up appointments, making it easy to track a pet's full treatment arc without needing a separate entity.
* **Attribute Enhancements:** Attributes like "client balance" were added to handle both debts (cancellation fees) and credits (deposits/refunds), and names were split into `first_name` and `last_name` to improve demographic querying.

---

## System Diagrams

### Entity-Relationship Diagram (ERD)
The final ERD provides rigorous coverage of the clinic's main processes. 

![Pet Clinic ERD](./docs/final-erd.png)
*(Note: Upload the Final ERD from your appendix here)*

### Use Case Diagram (UCD)
The UCD prioritises the understanding of primary users who routinely interact with clinic data, outlining core processes like booking consultations, assessing pets, and managing payments.

![Use Case Diagram](./docs/use-case-diagram.png)
*(Note: Upload the Use Case Diagram from your appendix here)*

---

## Business Rules & Constraints

This database enforces several strict business rules to prevent costly clinical errors:
* Consultations only occur on Mondays and Fridays, between 9 AM and 5 PM.
* Pets must be aged 0-12 years inclusive, and gender is restricted to 'M' or 'F'.
* Primary keys use incrementing surrogate keys (e.g., Doctor IDs must be within 2200-2299, Pet IDs within 1000-3000).
* Staff employment status can only be 'part-time' or 'full-time'.

---

## Tech Stack

* **RDBMS:** Oracle SQL (utilising specific data types like `VARCHAR2`, `NUMBER`, and `TIMESTAMP(0)`).
* **Design Tools:** Visual Paradigm (for ERD diagrams).

---

## Schema Overview

The system architecture is built on interconnected tables:
* **Entities:** `Client`, `Pet`, `Doctor`, `Nurse`, `Specialist`, `Medication`, `Pharmacy`.
* **Transactions & Medical Records:** `Consultation`, `Diagnosis`, `Prescription`, `Referral`, `Deferral`, `Payment`, `Nurse Attendance`.

---
