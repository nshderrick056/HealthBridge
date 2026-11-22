# HealthBridge ERD (Cloud Firestore)

The database is Cloud Firestore, project `healthbridge-rwanda`, location `africa-south1`. Each box below is a
top-level collection (or a subcollection, marked); field names are exactly those stored and checked by
[firestore.rules](../firestore.rules). Paste the diagram into [mermaid.live](https://mermaid.live) to export a
PNG for the report.

`PK` is the document ID, `FK` a field holding another document's ID. Firestore has no joins or foreign-key
constraints; the relationships are kept by the app and the server and checked by the security rules (for
example, a visit may only point at a patient owned by the same CHW).

```mermaid
erDiagram
    healthCenters ||--o{ users : "employs (healthCenterId)"
    healthCenters ||--o{ patients : "serves (healthCenterId)"
    healthCenters ||--o{ alerts : "receives (healthCenterId)"
    users ||--o{ patients : "cares for (chwId)"
    users ||--o{ visits : "records (chwId)"
    users ||--o{ devices : "registers (userId)"
    users ||--|| credentials : "PIN (server only)"
    patients ||--o{ visits : "has (patientId)"
    devices ||--o{ visits : "sent from (deviceId)"
    devices ||--|| deviceKeys : "SMS key (server only)"
    visits ||--o| alerts : "raises if urgent (same ID)"
    alerts ||--o{ events : "status history (subcollection)"
    dangerSigns ||--o{ visits : "ticked in (dangerSigns[])"
    users ||--o{ resetRequests : "asks for a reset (server only)"

    healthCenters {
        string id PK
        string name
        string district
        string sector
        string callNumber "nullable, the Call fallback"
    }
    users {
        string id PK "Firebase Auth UID"
        string role "chw | supervisor | admin (also a custom claim)"
        string chwRole "nullable, asm | binome"
        string fullName
        string phone "E.164, unique"
        string email "nullable, unique"
        string healthCenterId FK "nullable for admins (also a custom claim)"
        string village "nullable"
        string language "en | rw"
        bool active
        timestamp createdAt
    }
    patients {
        string id PK "UUID made on the phone"
        string shortId "e.g. P3FA9C1, safe for SMS"
        string chwId FK
        string healthCenterId FK
        string fullName
        string sex "nullable, F | M"
        timestamp birthDate "nullable"
        int ageEstimate "nullable, 0-130"
        string village
        string phone "nullable"
        timestamp consentAt
        timestamp createdAt
        timestamp updatedAt
        timestamp archivedAt "nullable, the app's delete"
    }
    visits {
        string id PK "UUID made on the phone"
        string shortCode "first 8 hex of id, used in SMS"
        string patientId FK
        string chwId FK
        string healthCenterId FK
        string deviceId FK
        string type "maternal | child | malaria | nutrition"
        map answers
        string notes "nullable"
        bool isUrgent "true exactly when dangerSigns is not empty"
        array dangerSigns "codes, FK to dangerSigns"
        timestamp followUpOn "nullable"
        timestamp recordedAt "phone clock"
        timestamp receivedAt "server time"
        string source "app | sms"
        bool isPartial "true for an SMS case until the full visit syncs"
    }
    dangerSigns {
        string id PK "code, e.g. HB heavy bleeding"
        string visitType
        string labelEn
        string labelRw
    }
    alerts {
        string id PK "= the visit's ID"
        string visitId FK
        string chwId FK
        string healthCenterId FK
        string channel "internet | sms"
        string status "new | reviewed | escalated | follow_up | resolved"
        timestamp createdAt
        timestamp ackedToChwAt "nullable"
    }
    events {
        string id PK
