-- ============================================================
-- PROG6212 POE Part 1 - Section C : RaceDay Management System Schema
-- Database Engine: SQL Server Management Studio (SSMS)
-- Purpose: Builds the full database schema and populates sample data.
-- ============================================================

-- Step 1: Create the database if it does not already exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'RaceDayDB')
BEGIN
    EXEC('CREATE DATABASE RaceDayDB');
END
GO

-- Step 2: Switch context to use the RaceDay database
USE RaceDayDB;
GO

-- Step 3: Safe teardown - Drop existing tables in reverse dependency order
-- Drops child tables first to avoid foreign key conflict errors on fresh runs
IF OBJECT_ID('dbo.Result', 'U') IS NOT NULL DROP TABLE dbo.Result;
IF OBJECT_ID('dbo.Enrolment', 'U') IS NOT NULL DROP TABLE dbo.Enrolment;
IF OBJECT_ID('dbo.Category', 'U') IS NOT NULL DROP TABLE dbo.Category;
IF OBJECT_ID('dbo.Event', 'U') IS NOT NULL DROP TABLE dbo.Event;
IF OBJECT_ID('dbo.Venue', 'U') IS NOT NULL DROP TABLE dbo.Venue;
IF OBJECT_ID('dbo.[User]', 'U') IS NOT NULL DROP TABLE dbo.[User];
GO

-- ============================================================
-- TABLE CREATION SECTION (6 Entities with Keys & Constraints)
-- ============================================================

-- 1. User Entity: Stores system login accounts for both Organisers and Participants
CREATE TABLE dbo.[User] (
    User_Id INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incrementing primary key
    Full_Name NVARCHAR(100) NOT NULL,       -- User full name
    Email NVARCHAR(100) NOT NULL UNIQUE,    -- Unique constraint prevents duplicate email signups
    Password_Hash NVARCHAR(255) NOT NULL,   -- Secure hashed password
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Organiser', 'Participant')), -- Restricts role values
    Phone_Number NVARCHAR(20) NULL          -- Optional contact phone number
);

-- 2. Venue Entity: Represents physical locations hosting race events
CREATE TABLE dbo.Venue (
    Venue_Id INT IDENTITY(1,1) PRIMARY KEY, 
    Venue_Name NVARCHAR(100) NOT NULL,      
    Address NVARCHAR(255) NOT NULL,         
    Capacity INT NOT NULL,                  
    Contact_Person NVARCHAR(100) NULL       
);

-- 3. Event Entity: Represents organised race events linked to an Organiser and Venue
CREATE TABLE dbo.Event (
    Event_Id INT IDENTITY(1,1) PRIMARY KEY,  
    Name NVARCHAR(100) NOT NULL,             
    Description NVARCHAR(MAX) NULL,          
    Event_Date DATETIME2 NOT NULL,           
    Location NVARCHAR(150) NOT NULL,         
    Distance_Km DECIMAL(5,2) NOT NULL,       
    Event_Type NVARCHAR(50) NOT NULL,        
    Banner_ImageURL NVARCHAR(255) NULL,      -- Azure Blob Storage URL for event banner
    User_Id INT NOT NULL,                    -- Foreign key pointing to the creating Organiser
    Venue_Id INT NOT NULL,                   -- Foreign key pointing to the hosting Venue
    CONSTRAINT FK_Event_User FOREIGN KEY (User_Id) REFERENCES dbo.[User](User_Id) ON DELETE CASCADE,
    CONSTRAINT FK_Event_Venue FOREIGN KEY (Venue_Id) REFERENCES dbo.Venue(Venue_Id)
);

-- 4. Category Entity: Sub-divisions/divisions belonging to a specific event
CREATE TABLE dbo.Category (
    Category_Id INT IDENTITY(1,1) PRIMARY KEY, 
    Category_Name NVARCHAR(50) NOT NULL,       
    Min_Age INT NOT NULL,                      
    Max_Age INT NOT NULL,                      
    Distance_Km DECIMAL(5,2) NOT NULL,         -- Specific distance for this category
    Event_Id INT NOT NULL,                     -- Foreign key linking category to its parent event
    CONSTRAINT FK_Category_Event FOREIGN KEY (Event_Id) REFERENCES dbo.Event(Event_Id) ON DELETE CASCADE
);

-- 5. Enrolment Entity: Tracks participant registrations for specific event categories
CREATE TABLE dbo.Enrolment (
    Enrolment_Id INT IDENTITY(1,1) PRIMARY KEY, 
    Enrolment_Date DATETIME2 NOT NULL DEFAULT GETDATE(), 
    Status NVARCHAR(20) NOT NULL DEFAULT 'Confirmed',    
    User_Id INT NOT NULL,                      -- Foreign key linking to registered Participant
    Event_Id INT NOT NULL,                     -- Foreign key linking to registered Event
    Category_Id INT NOT NULL,                  -- Foreign key linking to chosen Category
    CONSTRAINT FK_Enrolment_User FOREIGN KEY (User_Id) REFERENCES dbo.[User](User_Id),
    CONSTRAINT FK_Enrolment_Event FOREIGN KEY (Event_Id) REFERENCES dbo.Event(Event_Id),
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (Category_Id) REFERENCES dbo.Category(Category_Id)
);

-- 6. Result Entity: Records finish times and positions for completed enrolments
CREATE TABLE dbo.Result (
    Result_Id INT IDENTITY(1,1) PRIMARY KEY,  
    Finish_Time TIME NULL,                    
    Position INT NULL,                       
    Enrolment_Id INT NOT NULL UNIQUE,         -- 1:1 foreign key restriction per enrolment
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (Enrolment_Id) REFERENCES dbo.Enrolment(Enrolment_Id) ON DELETE CASCADE
);
GO

-- ============================================================
-- SEED DATA SECTION (Populates Required Minimum Quantities)
-- ============================================================

-- Seed 1: Populate Users (2 Organisers, 2 Participants)
INSERT INTO dbo.[User] (Full_Name, Email, Password_Hash, Role, Phone_Number) VALUES
('Sipho Nkosi', 'sipho@raceday.co.za', 'hashedpassword123', 'Organiser', '0821234567'),
('Amanda Govender', 'amanda@raceday.co.za', 'hashedpassword123', 'Organiser', '0829876543'),
('Jane Doe', 'jane@gmail.com', 'hashedpassword456', 'Participant', '0839876543'),
('Kabelo Mokoena', 'kabelo@gmail.com', 'hashedpassword789', 'Participant', '0841112233');

-- Seed 2: Populate Venues (2 Locations)
INSERT INTO dbo.Venue (Venue_Name, Address, Capacity, Contact_Person) VALUES
('Moses Mabhida Stadium', '44 Isaiah Ntshangase Rd, Durban', 56000, 'John Smith'),
('Cape Town Stadium', 'Fritz Sonnenberg Rd, Green Point, Cape Town', 55000, 'Sarah Jenkins');

-- Seed 3: Populate Events (3 Events minimum)
INSERT INTO dbo.Event (Name, Description, Event_Date, Location, Distance_Km, Event_Type, Banner_ImageURL, User_Id, Venue_Id) VALUES
('Durban City Marathon', 'Annual coastal marathon event.', '2026-11-15 06:00:00', 'Durban Beachfront', 42.20, 'Run', 'https://storage.blob.core.windows.net/banners/durban.jpg', 1, 1),
('Cape Town Trail Challenge', 'Scenic mountain trail run.', '2026-12-05 07:00:00', 'Table Mountain Trail Head', 21.10, 'Trail Run', 'https://storage.blob.core.windows.net/banners/capetown.jpg', 2, 2),
('Durban Night 10K', 'Exciting 10km evening road race.', '2026-12-20 18:30:00', 'Durban Promenade', 10.00, 'Road Run', 'https://storage.blob.core.windows.net/banners/night10k.jpg', 1, 1);

-- Seed 4: Populate Categories (Specific categories for each event)
INSERT INTO dbo.Category (Category_Name, Min_Age, Max_Age, Distance_Km, Event_Id) VALUES
('Open Male 42km', 18, 39, 42.20, 1),
('Open Female 42km', 18, 39, 42.20, 1),
('Half Marathon Open', 18, 49, 21.10, 2),
('10K Fun Run', 14, 70, 10.00, 3);

-- Seed 5: Populate Enrolments (Link participants to event categories)
INSERT INTO dbo.Enrolment (Enrolment_Date, Status, User_Id, Event_Id, Category_Id) VALUES
(GETDATE(), 'Confirmed', 3, 1, 1), -- Jane Doe registered for Durban Marathon
(GETDATE(), 'Confirmed', 4, 1, 1), -- Kabelo Mokoena registered for Durban Marathon
(GETDATE(), 'Confirmed', 3, 2, 3); -- Jane Doe registered for Cape Town Trail

-- Seed 6: Populate Results (Finish times and positions)
INSERT INTO dbo.Result (Finish_Time, Position, Enrolment_Id) VALUES
('03:15:42', 1, 1),
('03:45:10', 2, 2);
GO

-- ============================================================
-- VERIFICATION SECTION: Displays generated schema structure
-- ============================================================
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('User', 'Venue', 'Event', 'Category', 'Enrolment', 'Result')
ORDER BY t.name, c.column_id;