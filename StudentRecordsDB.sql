-- StudentRecordsDB.sql
-- Full-featured Student Records relational schema for MySQL
-- Idempotent creation: drop and recreate database
DROP DATABASE IF EXISTS StudentRecordsDB;
CREATE DATABASE StudentRecordsDB
    DEFAULT CHARACTER SET = utf8mb4
    DEFAULT COLLATE = utf8mb4_unicode_ci;
USE StudentRecordsDB;

-- Ensure InnoDB for referential integrity
SET default_storage_engine = 'InnoDB';

-- Table: Students
CREATE TABLE Students (
    StudentID INT NOT NULL AUTO_INCREMENT,
    StudentNumber VARCHAR(20) NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    MiddleName VARCHAR(50),
    Gender ENUM('F','M','X') DEFAULT 'X',
    DateOfBirth DATE,
    Email VARCHAR(150) UNIQUE,
    Phone VARCHAR(30),
    CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (StudentID),
    UNIQUE KEY UQ_Students_StudentNumber (StudentNumber)
) ENGINE=InnoDB;

-- Table: Addresses (one-to-many)
CREATE TABLE Addresses (
    AddressID INT NOT NULL AUTO_INCREMENT,
    StudentID INT NOT NULL,
    AddressType ENUM('home','mailing','billing') DEFAULT 'home',
    Line1 VARCHAR(200) NOT NULL,
    Line2 VARCHAR(200),
    City VARCHAR(100) NOT NULL,
    StateProvince VARCHAR(100),
    PostalCode VARCHAR(20),
    Country VARCHAR(100) NOT NULL DEFAULT 'USA',
    IsPrimary TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (AddressID),
    INDEX idx_addresses_student (StudentID),
    CONSTRAINT fk_addresses_student FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table: Departments
CREATE TABLE Departments (
    DepartmentID INT NOT NULL AUTO_INCREMENT,
    DeptCode VARCHAR(10) NOT NULL,
    DeptName VARCHAR(150) NOT NULL,
    PRIMARY KEY (DepartmentID),
    UNIQUE KEY UQ_Departments_DeptCode (DeptCode)
) ENGINE=InnoDB;

-- Table: Programs
CREATE TABLE Programs (
    ProgramID INT NOT NULL AUTO_INCREMENT,
    ProgramCode VARCHAR(20) NOT NULL,
    ProgramName VARCHAR(200) NOT NULL,
    DepartmentID INT NOT NULL,
    Level ENUM('Undergraduate','Postgraduate','Doctoral') DEFAULT 'Undergraduate',
    PRIMARY KEY (ProgramID),
    UNIQUE KEY UQ_Programs_ProgramCode (ProgramCode),
    CONSTRAINT fk_programs_department FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Table: Instructors
CREATE TABLE Instructors (
    InstructorID INT NOT NULL AUTO_INCREMENT,
    EmployeeNumber VARCHAR(20),
    FirstName VARCHAR(80) NOT NULL,
    LastName VARCHAR(80) NOT NULL,
    Email VARCHAR(150) UNIQUE,
    DepartmentID INT,
    HireDate DATE,
    PRIMARY KEY (InstructorID),
    UNIQUE KEY UQ_Instructors_EmployeeNumber (EmployeeNumber),
    CONSTRAINT fk_instructors_department FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Table: Courses
CREATE TABLE Courses (
    CourseID INT NOT NULL AUTO_INCREMENT,
    CourseCode VARCHAR(20) NOT NULL,
    CourseTitle VARCHAR(200) NOT NULL,
    Credits TINYINT NOT NULL,
    DepartmentID INT,
    Description TEXT,
    PRIMARY KEY (CourseID),
    UNIQUE KEY uq_course_code (CourseCode),
    CONSTRAINT fk_courses_department FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Many-to-many: Course prerequisites
CREATE TABLE CoursePrerequisites (
    CourseID INT NOT NULL,
    PrereqCourseID INT NOT NULL,
    PRIMARY KEY (CourseID, PrereqCourseID),
    CONSTRAINT fk_prereq_course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID) ON DELETE CASCADE,
    CONSTRAINT fk_prereq_prereq FOREIGN KEY (PrereqCourseID) REFERENCES Courses(CourseID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table: CourseOfferings
CREATE TABLE CourseOfferings (
    OfferingID INT NOT NULL AUTO_INCREMENT,
    CourseID INT NOT NULL,
    InstructorID INT,
    Term VARCHAR(20) NOT NULL,
    Year SMALLINT NOT NULL,
    Section VARCHAR(10) DEFAULT 'A',
    Capacity SMALLINT UNSIGNED DEFAULT 0,
    Location VARCHAR(100),
    StartDate DATE,
    EndDate DATE,
    PRIMARY KEY (OfferingID),
    UNIQUE KEY uq_course_term_section (CourseID, Term, Year, Section),
    INDEX idx_offering_course (CourseID),
    CONSTRAINT fk_offering_course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID) ON DELETE CASCADE,
    CONSTRAINT fk_offering_instructor FOREIGN KEY (InstructorID) REFERENCES Instructors(InstructorID) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Table: Enrollments
CREATE TABLE Enrollments (
    EnrollmentID INT NOT NULL AUTO_INCREMENT,
    StudentID INT NOT NULL,
    OfferingID INT NOT NULL,
    EnrollmentDate DATE NOT NULL DEFAULT (CURRENT_DATE()),
    Status ENUM('enrolled','dropped','completed','withdrawn') NOT NULL DEFAULT 'enrolled',
    Grade VARCHAR(4),
    PRIMARY KEY (EnrollmentID),
    UNIQUE KEY uq_student_offering (StudentID, OfferingID),
    INDEX idx_enrollment_student (StudentID),
    INDEX idx_enrollment_offering (OfferingID),
    CONSTRAINT fk_enrollment_student FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_offering FOREIGN KEY (OfferingID) REFERENCES CourseOfferings(OfferingID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table: StudentPrograms
CREATE TABLE StudentPrograms (
    StudentID INT NOT NULL,
    ProgramID INT NOT NULL,
    StartDate DATE,
    EndDate DATE,
    IsPrimary TINYINT(1) DEFAULT 0,
    PRIMARY KEY (StudentID, ProgramID),
    CONSTRAINT fk_studentprogram_student FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE,
    CONSTRAINT fk_studentprogram_program FOREIGN KEY (ProgramID) REFERENCES Programs(ProgramID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Sample data inserts
INSERT INTO Departments (DeptCode, DeptName) VALUES
('CS','Computer Science'),('MATH','Mathematics'),('ENG','English');

INSERT INTO Programs (ProgramCode, ProgramName, DepartmentID, Level) VALUES
('BSC-CS','BSc Computer Science', (SELECT DepartmentID FROM Departments WHERE DeptCode='CS'),'Undergraduate'),
('BSC-MATH','BSc Mathematics', (SELECT DepartmentID FROM Departments WHERE DeptCode='MATH'),'Undergraduate');

INSERT INTO Instructors (EmployeeNumber, FirstName, LastName, Email, DepartmentID, HireDate) VALUES
('EMP1001','Laura','Adams','laura.adams@university.edu',(SELECT DepartmentID FROM Departments WHERE DeptCode='CS'),'2015-08-01'),
('EMP1002','Daniel','Khan','daniel.khan@university.edu',(SELECT DepartmentID FROM Departments WHERE DeptCode='CS'),'2019-02-15');

INSERT INTO Courses (CourseCode, CourseTitle, Credits, DepartmentID, Description) VALUES
('CS101','Introduction to Computer Science',3,(SELECT DepartmentID FROM Departments WHERE DeptCode='CS'),'Fundamentals of programming and computing.'),
('CS102','Data Structures',3,(SELECT DepartmentID FROM Departments WHERE DeptCode='CS'),'Core data structures and algorithms.'),
('CS201','Database Fundamentals',3,(SELECT DepartmentID FROM Departments WHERE DeptCode='CS'),'Relational databases, SQL and design.'),
('MATH101','Calculus I',4,(SELECT DepartmentID FROM Departments WHERE DeptCode='MATH'),'Limits, derivatives, integrals.');

-- Course prerequisites
INSERT INTO CoursePrerequisites (CourseID, PrereqCourseID)
SELECT c.CourseID, p.CourseID FROM Courses c JOIN Courses p ON p.CourseCode='CS101' WHERE c.CourseCode='CS102';
INSERT INTO CoursePrerequisites (CourseID, PrereqCourseID)
SELECT c.CourseID, p.CourseID FROM Courses c JOIN Courses p ON p.CourseCode='CS102' WHERE c.CourseCode='CS201';

-- Course offerings
-- Course offerings
INSERT INTO CourseOfferings (CourseID, InstructorID, Term, Year, Section, Capacity, Location, StartDate, EndDate)
SELECT CourseID, (SELECT InstructorID FROM Instructors WHERE EmployeeNumber='EMP1001'), 'Fall', 2023, 'A', 50, 'Building 1, Room 101','2023-09-01','2023-12-15' FROM Courses WHERE CourseCode='CS101';
INSERT INTO CourseOfferings (CourseID, InstructorID, Term, Year, Section, Capacity, Location, StartDate, EndDate)
SELECT CourseID, (SELECT InstructorID FROM Instructors WHERE EmployeeNumber='EMP1002'), 'Fall', 2023, 'A', 40, 'Building 2, Room 201','2023-09-01','2023-12-15' FROM Courses WHERE CourseCode='CS201';
-- Add an offering for MATH101 so math students can enroll
INSERT INTO CourseOfferings (CourseID, InstructorID, Term, Year, Section, Capacity, Location, StartDate, EndDate)
SELECT CourseID, (SELECT InstructorID FROM Instructors WHERE EmployeeNumber='EMP1002'), 'Fall', 2023, 'A', 30, 'Building 3, Room 301', '2023-09-01', '2023-12-15' FROM Courses WHERE CourseCode='MATH101';

-- Students
INSERT INTO Students (StudentNumber, FirstName, LastName, DateOfBirth, Email, Phone) VALUES
('S2023001','Alice','Smith','2000-01-15','alice.smith@example.com','+1-555-0101'),
('S2023002','Bob','Johnson','2002-05-20','bob.johnson@example.com','+1-555-0102'),
('S2023003','Joy','Gray','2004-06-18','joy.gray@example.com','+1-555-0103'),
('S2023004','Mike','White','2006-02-24','mike.white@example.com','+1-555-0104');

-- Additional sample students
INSERT INTO Students (StudentNumber, FirstName, LastName, DateOfBirth, Email, Phone) VALUES
('S2023005','Lina','Martinez','2001-11-05','lina.martinez@example.com','+1-555-0105'),
('S2023006','Ethan','Brown','1999-03-12','ethan.brown@example.com','+1-555-0106'),
('S2023007','Priya','Singh','2003-07-30','priya.singh@example.com','+1-555-0107');

-- Addresses
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','123 Maple St','Springfield','IL','62701','USA',1 FROM Students WHERE StudentNumber='S2023001';
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','456 Oak Ave','Springfield','IL','62702','USA',1 FROM Students WHERE StudentNumber='S2023002';
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','789 Pine Rd','Springfield','IL','62703','USA',1 FROM Students WHERE StudentNumber='S2023003';
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','101 Elm St','Springfield','IL','62704','USA',1 FROM Students WHERE StudentNumber='S2023004';
-- Addresses for newly added students
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','12 Cedar Lane','Springfield','IL','62705','USA',1 FROM Students WHERE StudentNumber='S2023005';
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','34 Birch Blvd','Springfield','IL','62706','USA',1 FROM Students WHERE StudentNumber='S2023006';
INSERT INTO Addresses (StudentID, AddressType, Line1, City, StateProvince, PostalCode, Country, IsPrimary)
SELECT StudentID,'home','56 Walnut Way','Springfield','IL','62707','USA',1 FROM Students WHERE StudentNumber='S2023007';

-- StudentPrograms
INSERT INTO StudentPrograms (StudentID, ProgramID, StartDate, IsPrimary)
SELECT s.StudentID, p.ProgramID, '2023-08-15',1 FROM Students s JOIN Programs p ON p.ProgramCode='BSC-CS' WHERE s.StudentNumber='S2023001';
INSERT INTO StudentPrograms (StudentID, ProgramID, StartDate, IsPrimary)
SELECT s.StudentID, p.ProgramID, '2023-08-15',1 FROM Students s JOIN Programs p ON p.ProgramCode='BSC-CS' WHERE s.StudentNumber='S2023002';

-- Program assignments for newly added students
INSERT INTO StudentPrograms (StudentID, ProgramID, StartDate, IsPrimary)
SELECT s.StudentID, p.ProgramID, '2023-08-15',1 FROM Students s JOIN Programs p ON p.ProgramCode='BSC-CS' WHERE s.StudentNumber='S2023005';
INSERT INTO StudentPrograms (StudentID, ProgramID, StartDate, IsPrimary)
SELECT s.StudentID, p.ProgramID, '2023-08-15',1 FROM Students s JOIN Programs p ON p.ProgramCode='BSC-MATH' WHERE s.StudentNumber='S2023006';
INSERT INTO StudentPrograms (StudentID, ProgramID, StartDate, IsPrimary)
SELECT s.StudentID, p.ProgramID, '2023-08-15',1 FROM Students s JOIN Programs p ON p.ProgramCode='BSC-CS' WHERE s.StudentNumber='S2023007';

-- Add an offering for MATH101 so math students can enroll
-- Enrollments
INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Status, Grade)
SELECT s.StudentID, o.OfferingID, '2023-09-01', 'enrolled', NULL FROM Students s JOIN CourseOfferings o ON o.CourseID = (SELECT CourseID FROM Courses WHERE CourseCode='CS101') WHERE s.StudentNumber='S2023001' AND o.Term='Fall' AND o.Year=2023;
INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Status, Grade)
SELECT s.StudentID, o.OfferingID, '2023-09-01', 'enrolled', NULL FROM Students s JOIN CourseOfferings o ON o.CourseID = (SELECT CourseID FROM Courses WHERE CourseCode='CS201') WHERE s.StudentNumber='S2023002' AND o.Term='Fall' AND o.Year=2023;
-- Enroll the newly added students
INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Status, Grade)
SELECT s.StudentID, o.OfferingID, '2023-09-02', 'enrolled', NULL FROM Students s JOIN CourseOfferings o ON o.CourseID = (SELECT CourseID FROM Courses WHERE CourseCode='CS101') WHERE s.StudentNumber='S2023005' AND o.Term='Fall' AND o.Year=2023;
INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Status, Grade)
SELECT s.StudentID, o.OfferingID, '2023-09-02', 'enrolled', NULL FROM Students s JOIN CourseOfferings o ON o.CourseID = (SELECT CourseID FROM Courses WHERE CourseCode='MATH101') WHERE s.StudentNumber='S2023006' AND o.Term='Fall' AND o.Year=2023;
INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Status, Grade)
SELECT s.StudentID, o.OfferingID, '2023-09-02', 'enrolled', NULL FROM Students s JOIN CourseOfferings o ON o.CourseID = (SELECT CourseID FROM Courses WHERE CourseCode='CS201') WHERE s.StudentNumber='S2023007' AND o.Term='Fall' AND o.Year=2023;

-- Useful example query
SELECT s.StudentNumber, s.FirstName, s.LastName, c.CourseCode, c.CourseTitle, o.Term, o.Year, e.Status, e.Grade
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
ORDER BY s.StudentNumber, o.Year, o.Term;

-- Trigger: update UpdatedAt on Students when a row is updated
DROP TRIGGER IF EXISTS trg_students_updatedat;
DELIMITER $$
CREATE TRIGGER trg_students_updatedat
BEFORE UPDATE ON Students
FOR EACH ROW
BEGIN
    SET NEW.UpdatedAt = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- Sample grades: set final grades for some enrollments
-- Alice (S2023001) completed CS101 with A
UPDATE Enrollments e
JOIN Students s ON e.StudentID = s.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
SET e.Grade = 'A', e.Status = 'completed'
WHERE s.StudentNumber = 'S2023001' AND c.CourseCode = 'CS101';

-- Bob (S2023002) completed CS201 with B+
UPDATE Enrollments e
JOIN Students s ON e.StudentID = s.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
SET e.Grade = 'B+', e.Status = 'completed'
WHERE s.StudentNumber = 'S2023002' AND c.CourseCode = 'CS201';

-- S2023005 (Lina) completed CS101 with B
UPDATE Enrollments e
JOIN Students s ON e.StudentID = s.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
SET e.Grade = 'B', e.Status = 'completed'
WHERE s.StudentNumber = 'S2023005' AND c.CourseCode = 'CS101';

-- S2023006 (Ethan) completed MATH101 with A-
UPDATE Enrollments e
JOIN Students s ON e.StudentID = s.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
SET e.Grade = 'A-', e.Status = 'completed'
WHERE s.StudentNumber = 'S2023006' AND c.CourseCode = 'MATH101';

-- S2023007 (Priya) completed CS201 with B
UPDATE Enrollments e
JOIN Students s ON e.StudentID = s.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
SET e.Grade = 'B', e.Status = 'completed'
WHERE s.StudentNumber = 'S2023007' AND c.CourseCode = 'CS201';

-- View: CourseRoster — students enrolled in offerings with grades/status
DROP VIEW IF EXISTS CourseRoster;
CREATE VIEW CourseRoster AS
SELECT o.OfferingID, c.CourseCode, c.CourseTitle, o.Term, o.Year, o.Section,
             s.StudentID, s.StudentNumber, CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
             e.Status, e.Grade
FROM CourseOfferings o
JOIN Courses c ON o.CourseID = c.CourseID
JOIN Enrollments e ON e.OfferingID = o.OfferingID
JOIN Students s ON e.StudentID = s.StudentID;

-- View: StudentTranscript — list of completed courses and grades per student
DROP VIEW IF EXISTS StudentTranscript;
CREATE VIEW StudentTranscript AS
SELECT s.StudentID, s.StudentNumber, CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
             c.CourseCode, c.CourseTitle, c.Credits, o.Term, o.Year, e.Grade
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
WHERE e.Grade IS NOT NULL;

-- View: StudentGPA — weighted GPA per student using common letter scale
DROP VIEW IF EXISTS StudentGPA;
CREATE VIEW StudentGPA AS
SELECT s.StudentID, s.StudentNumber, CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
             ROUND(SUM(
                 CASE e.Grade
                     WHEN 'A'  THEN 4.0
                     WHEN 'A-' THEN 3.7
                     WHEN 'B+' THEN 3.3
                     WHEN 'B'  THEN 3.0
                     WHEN 'B-' THEN 2.7
                     WHEN 'C+' THEN 2.3
                     WHEN 'C'  THEN 2.0
                     WHEN 'C-' THEN 1.7
                     WHEN 'D'  THEN 1.0
                     WHEN 'F'  THEN 0.0
                     ELSE NULL
                 END * c.Credits
             ),2) / NULLIF(SUM(c.Credits),0) AS GPA
FROM Enrollments e
JOIN Students s ON e.StudentID = s.StudentID
JOIN CourseOfferings o ON e.OfferingID = o.OfferingID
JOIN Courses c ON o.CourseID = c.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY s.StudentID, s.StudentNumber;

