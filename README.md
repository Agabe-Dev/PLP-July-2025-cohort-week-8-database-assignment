# StudentRecordsDB — Final Assignment

This repository contains a single, self-contained SQL deliverable that implements a Student Records database (schema, sample data, views, and a trigger) for MySQL.

Files
- `StudentRecordsDB.sql` — complete, idempotent SQL script that creates the `StudentRecordsDB` database, tables, constraints, inserts sample data, defines views and a trigger, and includes example queries.

Requirements
- MySQL server (recommended 5.7+; MySQL 8.0 recommended for full SQL feature parity)
- mysql client available on your PATH

How to run (Windows PowerShell)
1. Open PowerShell.
2. From this workspace directory run:

```powershell
mysql -u root -p < "C:\Users\USER\Desktop\DATABASE\Week 8\Final Assignment\StudentRecordsDB.sql"
```

Enter your MySQL password when prompted. The script is idempotent (it drops and recreates the `StudentRecordsDB` database), so it is safe to re-run.

Alternative (inside mysql client)
```sql
-- Start mysql client then run
SOURCE C:/Users/USER/Desktop/DATABASE/Week 8/Final Assignment/StudentRecordsDB.sql;
```

Quick verification queries (run inside mysql client connected to the server)
```sql
USE StudentRecordsDB;
-- Counts
SELECT COUNT(*) AS offerings FROM CourseOfferings;
SELECT COUNT(*) AS students FROM Students;
SELECT COUNT(*) AS enrollments FROM Enrollments;

-- Course roster
SELECT * FROM CourseRoster WHERE CourseCode='CS101' AND Term='Fall' AND Year=2023 ORDER BY StudentName;

-- Transcript and GPA
SELECT * FROM StudentTranscript WHERE StudentNumber='S2023001' ORDER BY Year, Term;
SELECT * FROM StudentGPA WHERE StudentNumber='S2023001';
```

Notes and assumptions
- Storage engine: tables use InnoDB to support foreign keys.
- Character set/collation: `utf8mb4` / `utf8mb4_unicode_ci` (declared when database is created).
- The script creates some dependent data using `INSERT ... SELECT` (e.g., inserting offerings, addresses, enrollments). The file has been ordered so creations happen before dependents (Courses → Offerings → Students → Addresses → StudentPrograms → Enrollments → Grades → Views/Triggers).
- A trigger (`trg_students_updatedat`) updates `Students.UpdatedAt` on row updates; the script sets the `DELIMITER` where required.
- GPA calculation in `StudentGPA` uses a simplified letter-grade mapping; adjust the CASE mapping as needed for your institution's policy.

Created by Gabriel Akinbile.