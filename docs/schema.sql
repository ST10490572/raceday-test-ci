-- ============================================================
-- PROG6212 POE Part 1: RaceDay Management System Schema
-- Database Engine: SQL Server Management Studio (SSMS)
-- ============================================================


IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'RaceDayDB')
BEGIN
    EXEC('CREATE DATABASE RaceDayDB');
END
GO

USE RaceDayDB;
GO

-- Drop tables in reverse dependency order
IF OBJECT_ID('dbo.Result', 'U') IS NOT NULL DROP TABLE dbo.Result;
IF OBJECT_ID('dbo.Enrolment', 'U') IS NOT NULL DROP TABLE dbo.Enrolment;
IF OBJECT_ID('dbo.Category', 'U') IS NOT NULL DROP TABLE dbo.Category;
IF OBJECT_ID('dbo.Event', 'U') IS NOT NULL DROP TABLE dbo.Event;
IF OBJECT_ID('dbo.Venue', 'U') IS NOT NULL DROP TABLE dbo.Venue;
IF OBJECT_ID('dbo.[User]', 'U') IS NOT NULL DROP TABLE dbo.[User];
GO

-- 1. User Entity
CREATE TABLE dbo.[User] (
    User_Id INT IDENTITY(1,1) PRIMARY KEY,
    Full_Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Password_Hash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Organiser', 'Participant')),
    Phone_Number NVARCHAR(20) NULL
);

-- 2. Venue Entity
CREATE TABLE dbo.Venue (
    Venue_Id INT IDENTITY(1,1) PRIMARY KEY,
    Venue_Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    Capacity INT NOT NULL,
    Contact_Person NVARCHAR(100) NULL
);

-- 3. Event Entity (User creates Event / Venue hosts Event)
CREATE TABLE dbo.Event (
    Event_Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Event_Date DATETIME2 NOT NULL,
    Location NVARCHAR(150) NOT NULL,
    Distance_Km DECIMAL(5,2) NOT NULL,
    Event_Type NVARCHAR(50) NOT NULL,
    Banner_ImageURL NVARCHAR(255) NULL,
    User_Id INT NOT NULL,
    Venue_Id INT NOT NULL,
    CONSTRAINT FK_Event_User FOREIGN KEY (User_Id) REFERENCES dbo.[User](User_Id) ON DELETE CASCADE,
    CONSTRAINT FK_Event_Venue FOREIGN KEY (Venue_Id) REFERENCES dbo.Venue(Venue_Id)
);

-- 4. Category Entity (Event contains Category)
CREATE TABLE dbo.Category (
    Category_Id INT IDENTITY(1,1) PRIMARY KEY,
    Category_Name NVARCHAR(50) NOT NULL,
    Min_Age INT NOT NULL,
    Max_Age INT NOT NULL,
    Distance_Km DECIMAL(5,2) NOT NULL,
    Event_Id INT NOT NULL,
    CONSTRAINT FK_Category_Event FOREIGN KEY (Event_Id) REFERENCES dbo.Event(Event_Id) ON DELETE CASCADE
);

-- 5. Enrolment Entity (User makes Enrolment / Category receives Enrolment)
CREATE TABLE dbo.Enrolment (
    Enrolment_Id INT IDENTITY(1,1) PRIMARY KEY,
    Enrolment_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Confirmed',
    User_Id INT NOT NULL,
    Event_Id INT NOT NULL,
    Category_Id INT NOT NULL,
    CONSTRAINT FK_Enrolment_User FOREIGN KEY (User_Id) REFERENCES dbo.[User](User_Id),
    CONSTRAINT FK_Enrolment_Event FOREIGN KEY (Event_Id) REFERENCES dbo.Event(Event_Id),
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (Category_Id) REFERENCES dbo.Category(Category_Id)
);

-- 6. Result Entity (Enrolment generates Result)
CREATE TABLE dbo.Result (
    Result_Id INT IDENTITY(1,1) PRIMARY KEY,
    Finish_Time TIME NULL,
    Position INT NULL,
    Enrolment_Id INT NOT NULL UNIQUE,
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (Enrolment_Id) REFERENCES dbo.Enrolment(Enrolment_Id) ON DELETE CASCADE
);
GO

-- Seed Data Insertion
INSERT INTO dbo.[User] (Full_Name, Email, Password_Hash, Role, Phone_Number) VALUES
('Sipho Nkosi', 'sipho@raceday.co.za', 'hashedpassword123', 'Organiser', '0821234567'),
('Jane Doe', 'jane@gmail.com', 'hashedpassword456', 'Participant', '0839876543');

INSERT INTO dbo.Venue (Venue_Name, Address, Capacity, Contact_Person) VALUES
('Moses Mabhida Stadium', '44 Isaiah Ntshangase Rd, Durban', 56000, 'John Smith');

INSERT INTO dbo.Event (Name, Description, Event_Date, Location, Distance_Km, Event_Type, Banner_ImageURL, User_Id, Venue_Id) VALUES
('Durban City Marathon', 'Annual coastal marathon event.', '2026-11-15 06:00:00', 'Durban Beachfront', 42.20, 'Run', 'https://storage.blob.core.windows.net/banners/durban.jpg', 1, 1);

INSERT INTO dbo.Category (Category_Name, Min_Age, Max_Age, Distance_Km, Event_Id) VALUES
('Open Male 42km', 18, 39, 42.20, 1),
('Open Female 42km', 18, 39, 42.20, 1);

INSERT INTO dbo.Enrolment (Enrolment_Date, Status, User_Id, Event_Id, Category_Id) VALUES
(GETDATE(), 'Confirmed', 2, 1, 1);

INSERT INTO dbo.Result (Finish_Time, Position, Enrolment_Id) VALUES
('03:15:42', 1, 1);
GO

-- Verifying the tables
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('User', 'Venue', 'Event', 'Category', 'Enrolment', 'Result')
ORDER BY t.name, c.column_id;