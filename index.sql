CREATE DATABASE UNIE_Library;
GO

USE UNIE_Library;

IF OBJECT_ID('OnlineDatabase', 'U') IS NOT NULL DROP TABLE OnlineDatabase;
IF OBJECT_ID('PhysicalCopy', 'U') IS NOT NULL DROP TABLE PhysicalCopy;
IF OBJECT_ID('DigitalCopy', 'U') IS NOT NULL DROP TABLE DigitalCopy;
IF OBJECT_ID('Book', 'U') IS NOT NULL DROP TABLE Book;
IF OBJECT_ID('Journal', 'U') IS NOT NULL DROP TABLE Journal;
IF OBJECT_ID('ItemAuthor', 'U') IS NOT NULL DROP TABLE ItemAuthor;
IF OBJECT_ID('Loan', 'U') IS NOT NULL DROP TABLE Loan;
IF OBJECT_ID('HoldRequest', 'U') IS NOT NULL DROP TABLE HoldRequest;
IF OBJECT_ID('PrivilegeCollection', 'U') IS NOT NULL DROP TABLE PrivilegeCollection;
IF OBJECT_ID('MemberPhone', 'U') IS NOT NULL DROP TABLE MemberPhone;
IF OBJECT_ID('NewItemRequestAuthor', 'U') IS NOT NULL DROP TABLE NewItemRequestAuthor;
IF OBJECT_ID('NewItemRequest', 'U') IS NOT NULL DROP TABLE NewItemRequest;
IF OBJECT_ID('Member', 'U') IS NOT NULL DROP TABLE Member;
IF OBJECT_ID('Collection', 'U') IS NOT NULL DROP TABLE Collection;
IF OBJECT_ID('PrivilegeMain', 'U') IS NOT NULL DROP TABLE PrivilegeMain;
IF OBJECT_ID('PrivilegeName', 'U') IS NOT NULL DROP TABLE PrivilegeName;
IF OBJECT_ID('MemberType', 'U') IS NOT NULL DROP TABLE MemberType;

-- Create Item Author table
CREATE TABLE ItemAuthor (
    authorId INT PRIMARY KEY,
    author VARCHAR(100) NOT NULL,
);

-- Create Book table
CREATE TABLE Book (
    bookNo INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    publisher VARCHAR(100),
    description VARCHAR(500),
    notes VARCHAR(500),
    year INT,
    subject VARCHAR(100),
    edition VARCHAR(50),
    contents VARCHAR(500),
    summary VARCHAR(500),
    isbn VARCHAR(20) UNIQUE,
    authorId INT,
    FOREIGN KEY (authorId) REFERENCES ItemAuthor(authorId) ON UPDATE CASCADE ON DELETE CASCADE,
);

-- Create Journal table
CREATE TABLE Journal (
    journalNo INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    publisher VARCHAR(100),
    description VARCHAR(500),
    notes VARCHAR(500),
    year INT,
    subject VARCHAR(100),
    frequency VARCHAR(50),
    abbrTitle VARCHAR(100),
    mainSeries VARCHAR(100),
    issn VARCHAR(20) UNIQUE,
    authorId INT,
    FOREIGN KEY (authorId) REFERENCES ItemAuthor(authorId) ON UPDATE CASCADE ON DELETE CASCADE,
);

-- Create Online Database table
CREATE TABLE OnlineDatabase (
    databaseNo INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    publisher VARCHAR(100),
    description VARCHAR(500),
    notes VARCHAR(500),
    year INT,
    subject VARCHAR(100),
    contents VARCHAR(500),
    releaseDate DATE,
    authorId INT,
    FOREIGN KEY (authorId) REFERENCES ItemAuthor(authorId) ON UPDATE CASCADE ON DELETE CASCADE,
);

-- Create Collection table
CREATE TABLE Collection (
    collectionId INT PRIMARY KEY,
    physicalLocation VARCHAR(255),
    campus VARCHAR(100),
    building VARCHAR(100),
    room VARCHAR(50),
    shelf VARCHAR(50)
);

-- Create Physical Copy table
CREATE TABLE PhysicalCopy (
    accessionNumber INT PRIMARY KEY,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Available',
    dateAdded DATE NOT NULL DEFAULT GETDATE(),
    costInAUD DECIMAL(10,2),
    bookNo INT NULL,
    journalNo INT NULL,
    collectionId INT,
    -- here no action on update and delete because of warning, it may cause cycles or multiple cascade paths
    -- since there can be only one type book or journal for a single physical copy, we can check condition
    -- and rather set up a trigger to delete and update

    -- understanding problem:
    -- When you have multiple CASCADE paths that could potentially delete the same row,
    -- SQL Server rejects the definition to avoid ambiguity and potential data integrity issues.
    FOREIGN KEY (bookNo) REFERENCES Book(bookNo) ON UPDATE NO ACTION ON DELETE NO ACTION,
    FOREIGN KEY (journalNo) REFERENCES Journal(journalNo) ON UPDATE NO ACTION ON DELETE NO ACTION,
    FOREIGN KEY (collectionId) REFERENCES Collection(collectionId) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create Digital Copy table
CREATE TABLE DigitalCopy (
     accessionNumber INT PRIMARY KEY,
     dateAdded DATE NOT NULL DEFAULT GETDATE(),
     costInAUD DECIMAL(10,2),
     url VARCHAR(255) NOT NULL,
     format VARCHAR(50) NOT NULL,
     accessPeriod INT,
     size INT,
     databaseNo INT NULL,
     FOREIGN KEY (databaseNo) REFERENCES OnlineDatabase(databaseNo) ON UPDATE CASCADE ON DELETE CASCADE,
);

-- Create Member Type table
CREATE TABLE MemberType (
    typeId INT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    description VARCHAR(500),
    notes VARCHAR(500),
    validityPeriod INT NOT NULL -- added member validity period to compute dtExpiry for each member
);

-- Create Privilege Name table
CREATE TABLE PrivilegeName (
    name VARCHAR(100) PRIMARY KEY,
    description VARCHAR(500),
);

-- Create Privilege Main table
CREATE TABLE PrivilegeMain (
    privilegeId INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    loanPeriod INT NOT NULL,
    maxRenewal INT NOT NULL,
    maxItems INT NOT NULL,
    maxHolds INT NOT NULL,
    typeId INT NOT NULL,
    FOREIGN KEY (typeId) REFERENCES MemberType(typeId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (name) REFERENCES PrivilegeName(name) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create Member table
CREATE TABLE Member (
    memberNumber INT PRIMARY KEY,
    pin VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    dateOfBirth DATE,
    homeAddress VARCHAR(500),
    email VARCHAR(100),
    dtJoined DATE NOT NULL DEFAULT GETDATE(),
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    notes VARCHAR(500),
    typeId INT NOT NULL,
    FOREIGN KEY (typeId) REFERENCES MemberType(typeId) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create Loan table
CREATE TABLE Loan (
    loanId INT PRIMARY KEY,
    dtLoaned DATE NOT NULL DEFAULT GETDATE(),
    dtDue DATE NOT NULL,
    dtReturned DATE,
    numOfRenewals INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    memberNumber INT NOT NULL,
    accessionNumber INT NOT NULL,
    privilegeId INT NOT NULL,
    FOREIGN KEY (memberNumber) REFERENCES Member(memberNumber) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (accessionNumber) REFERENCES PhysicalCopy(accessionNumber),
);

-- Create Hold Request table
CREATE TABLE HoldRequest (
    holdNo INT PRIMARY KEY,
    dtTimeRequested DATETIME NOT NULL DEFAULT GETDATE(),
    dtTimeInformed DATETIME,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    comments VARCHAR(500),
    memberNumber INT NOT NULL,
    accessionNumber INT NOT NULL,
    FOREIGN KEY (memberNumber) REFERENCES Member(memberNumber) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (accessionNumber) REFERENCES PhysicalCopy(accessionNumber) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create New Item Request table
CREATE TABLE NewItemRequest (
    requestId INT PRIMARY KEY,
    typeOfItem VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    publisher VARCHAR(100),
    edition VARCHAR(50),
    description VARCHAR(500),
    reason VARCHAR(500),
    memberNumber INT NOT NULL,
    requestedDate DATE NOT NULL,
    FOREIGN KEY (memberNumber) REFERENCES Member(memberNumber) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create Privilege-Collection relationship table
CREATE TABLE PrivilegeCollection (
    privilegeId INT,
    collectionId INT,
    PRIMARY KEY (privilegeId, collectionId),
    FOREIGN KEY (privilegeId) REFERENCES PrivilegeMain(privilegeId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (collectionId) REFERENCES Collection(collectionId) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create table for Member Phone numbers
CREATE TABLE MemberPhone (
    memberNumber INT,
    phone VARCHAR(20) NOT NULL,
    PRIMARY KEY (memberNumber, phone),
    FOREIGN KEY (memberNumber) REFERENCES Member(memberNumber) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create table for NewItemRequest Author
CREATE TABLE NewItemRequestAuthor (
    requestId INT,
    author VARCHAR(100) NOT NULL,
    PRIMARY KEY (requestId, author),
    FOREIGN KEY (requestId) REFERENCES NewItemRequest(requestId) ON UPDATE CASCADE ON DELETE CASCADE
);


INSERT INTO ItemAuthor (authorId, author) VALUES
(1, 'John Doe'),
(2, 'Jane Smith'),
(3, 'F. Scott Fitzgerald'),
(4, 'Guido van Rossum'),
(5, 'Christopher L.C.E. Witcombe');

INSERT INTO Book (bookNo, title, publisher, description, notes, year, subject, edition, contents, summary, isbn, authorId) VALUES
(1, 'Database Design', 'Pearson', 'Comprehensive guide to database systems.', 'Includes case studies.', 2023, 'Computer Science', '3rd', 'Introduction to relational databases.', 'A detailed introduction to database design.', '978-0135288831', 1),
(2, 'Intro to AI', 'OReilly', 'Basic concepts of Artificial Intelligence.', 'For beginners.', 2024, 'Computer Science', '2nd', 'Includes machine learning concepts.', 'A beginners guide to artificial intelligence.', '978-1492040320', 2),
(3, 'The Great Gatsby', 'Scribner', 'Classic novel by F. Scott Fitzgerald.', 'Best seller of the 20th century.', 1925, 'Literature', '1st', 'Modern literature study guide.', 'An analysis of F. Scott Fitzgerald work.', '978-0743273565', 3),
(4, 'Learning Python', 'OReilly', 'Python programming from scratch.', 'Includes exercises.', 2022, 'Programming', '4th', 'Includes data analysis in Python.', 'Comprehensive Python guide.', '978-1449355739',  4),
(5, 'History of Art', 'Thames & Hudson', 'A journey through art history.', 'Used in college courses.', 2020, 'Art', '1st', 'Art history overview.', 'Exploration of art movements and famous artists.', '978-0500239140', 5);

INSERT INTO Journal (journalNo, title, publisher, description, notes, year, subject, frequency, abbrTitle, mainSeries, issn, authorId) VALUES
(1, 'Database Journal', 'Pearson', 'Monthly updates on database design.', 'Includes expert opinions.', 2023, 'Computer Science', 'Monthly', 'DBDesign', 'Database Journal', '1234-5678', 1),
(2, 'AI Insights', 'OReilly', 'Quarterly research on AI and ML.', 'Includes case studies.', 2024, 'Computer Science', 'Quarterly', 'AIReview', 'AI Insights', '2345-6789', 2),
(3, 'Art Journal', 'Thames & Hudson', 'Annual research on art history.', 'Curated by experts.', 2020, 'Art', 'Annually', 'ArtHistory', 'Art Journal', '3456-7890', 3),
(4, 'Programming Today', 'OReilly', 'Monthly Python development insights.', 'Covers latest updates.', 2022, 'Programming', 'Monthly', 'PythonWeekly', 'Programming Today', '4567-8901', 4),
(5, 'Art and Culture', 'Thames & Hudson', 'Bi-Annual journal on art and culture.', 'Collaboration with museums.', 2020, 'Art', 'Bi-Annually', 'HistoryArts', 'Art and Culture', '5678-9012', 5);

INSERT INTO OnlineDatabase (databaseNo, title, publisher, description, notes, year, subject, contents, releaseDate, authorId) VALUES
(1, 'DB Resource Hub', 'Pearson', 'Online database for database design tools.', 'Includes case studies.', 2023, 'Computer Science', 'Database design tools and resources.', '2023-03-01', 1),
(2, 'AI Research Library', 'OReilly', 'Collection of AI research papers.', 'Curated by AI experts.', 2024, 'Computer Science', 'AI research papers and journals.', '2024-01-15', 2),
(3, 'Literary Archive', 'Scribner', 'Digital library of literary works.', 'Includes rare collections.', 2022, 'Literature', 'Online archives of literary works.', '2022-05-20', 3),
(4, 'Python Academy', 'OReilly', 'Educational resources for Python.', 'Includes interactive exercises.', 2022, 'Programming', 'Python tutorials and examples.', '2022-07-10', 4),
(5, 'Art & Culture Online', 'Thames & Hudson', 'Digital research on art movements.', 'Collaboration with galleries.', 2020, 'Art', 'Art and culture research publications.', '2020-08-18', 5);

INSERT INTO Collection (collectionId, physicalLocation, campus, building, room, shelf) VALUES
(1, 'Library A', 'Main Campus', 'Science Building', 'Room 101', 'Shelf 1'),
(2, 'Library B', 'West Campus', 'Arts Building', 'Room 202', 'Shelf 2'),
(3, 'Library C', 'East Campus', 'Engineering Building', 'Room 303', 'Shelf 3'),
(4, 'Library D', 'North Campus', 'Library Building', 'Room 404', 'Shelf 4'),
(5, 'Library E', 'South Campus', 'Computer Science Building', 'Room 505', 'Shelf 5');

INSERT INTO PhysicalCopy (accessionNumber, barcode, status, dateAdded, costInAUD, bookNo, journalNo, collectionId) VALUES
(1001, '1234567890', 'Available', '2025-04-02', 29.99, 1, NULL, 1),
(1002, '2345678901', 'Available', '2025-04-02', 24.50, 2, NULL, 1),
(1003, '3456789012', 'Borrowed', '2025-04-01', 34.95, 3, NULL, 2),
(1004, '4567890123', 'Available', '2025-03-30', 19.99, NULL, 4, 3),
(1005, '5678901234', 'Available', '2025-03-25', 45.00, NULL, 5, 3),
(1006, '5678901239', 'Available', '2025-04-02', 22.75, 4, NULL, 2),
(1007, '5678901240', 'Available', '2025-04-08', 22.75, 4, NULL, 2),
(1008, '5678901241', 'Available', '2025-04-08', 22.75, 1, NULL, 1);

INSERT INTO DigitalCopy (accessionNumber, dateAdded, costInAUD, url, format, accessPeriod, size, databaseNo) VALUES
(1001, '2025-04-02', 19.99, 'http://example.com/dbdesign.pdf', 'PDF', 30, 15.7, 5),
(1002, '2025-04-01', 24.50, 'http://example.com/aiintro.pdf', 'PDF', 60, 12.3, 4),
(1003, '2025-03-30', 0.00, 'http://example.com/gatsby.pdf', 'PDF', 90, 8.5, 3),
(1004, '2025-03-28', 29.99, 'http://example.com/learnpython.pdf', 'PDF', 30, 22.8, 2),
(1005, '2025-03-25', 49.95, 'http://example.com/arthistory.pdf', 'PDF', 120, 35.2, 1);

INSERT INTO MemberType (typeId, type, description, notes, validityPeriod) VALUES
(1, 'Student', 'Full-time student member.', 'Valid for 1 year.', 365),
(2, 'Faculty', 'Faculty member with extended privileges.', 'Valid for 2 years.', 730),
(3, 'Alumni', 'Former student member with limited privileges.', 'Valid for 3 years.', 1095),
(4, 'Guest', 'Temporary membership for visitors.', 'Valid for 30 days.', 30),
(5, 'Staff', 'Staff member with special privileges.', 'Valid for 5 years.', 1825);

INSERT INTO PrivilegeName (name, description) VALUES
('Owner', 'Library owner with full access to all resources and administrative privileges.'),
('Staff', 'Library staff with elevated privileges for managing resources and members.'),
('Premium Member', 'Paid membership with extended privileges and priority service.'),
('Regular Member', 'Standard library membership with basic borrowing privileges.'),
('Guest', 'Limited temporary access for non-members.');

INSERT INTO PrivilegeMain (privilegeId, name, loanPeriod, maxRenewal, maxItems, maxHolds, typeId) VALUES
(1, 'Owner', 60, 10, 50, 25, 1),
(2, 'Staff', 30, 5, 20, 15, 2),
(3, 'Premium Member', 21, 3, 10, 7, 3),
(4, 'Regular Member', 14, 2, 5, 3, 4),
(5, 'Guest', 7, 0, 2, 0, 5);

INSERT INTO Member (memberNumber, pin, name, dateOfBirth, homeAddress, email, dtJoined, status, notes, typeId) VALUES
(1, '1234', 'John Doe', '1990-02-01', '123 Main St', 'johndoe@example.com', '2023-01-01', 'Active', 'New member joined in January 2023.', 1),
(2, '2345', 'Jane Smith', '1985-05-15', '456 Oak St', 'janesmith@example.com', '2022-11-01', 'Active', 'Recently updated contact details.', 2),
(3, '3456', 'Michael Johnson', '1992-07-21', '789 Pine St', 'michaelj@example.com', '2021-03-10', 'Active', 'Frequent borrower of books on technology.', 3),
(4, '4567', 'Emily Davis', '1995-10-30', '123 Birch St', 'emilydavis@example.com', '2020-08-22', 'Active', 'Interested in mystery novels and thrillers.', 4),
(5, '5678', 'David Wilson', '1980-12-15', '321 Maple St', 'davidwilson@example.com', '2019-06-05', 'Active', 'Has a long history with the library.', 5);

INSERT INTO Loan (loanId, dtLoaned, dtDue, dtReturned, numOfRenewals, status, memberNumber, accessionNumber, privilegeId) VALUES
(1, '2025-06-01', '2025-06-15', NULL, 0, 'Active', 1, 1001, 1),
(2, '2024-02-10', '2024-02-24', NULL, 1, 'Active', 2, 1002, 2),
(3, '2025-12-05', '2025-12-19', '2025-12-15', 0, 'Returned', 3, 1003, 3),
(4, '2023-09-10', '2023-09-24', NULL, 2, 'Active', 4, 1004, 4),
(5, '2025-06-22', '2025-07-06', '2025-06-29', 0, 'Returned', 5, 1005, 5),
(6, '2025-06-12', '2025-06-21', NULL, 0, 'Active', 2, 1008, 1);

INSERT INTO HoldRequest (holdNo, dtTimeRequested, dtTimeInformed, status, comments, memberNumber, accessionNumber) VALUES
(1, '2025-06-01', '2025-06-02', 'Pending', 'Request for book "Database Design".', 1, 1001),
(2, '2024-02-14', '2024-02-15', 'Pending', 'Request for book "Intro to AI".', 2, 1002),
(3, '2025-10-05', '2025-10-06', 'Completed', 'Request for book "The Great Gatsby".', 3, 1003),
(4, '2021-05-20', '2021-05-21', 'Cancelled', 'Request for book "Learning Python".', 4, 1004),
(5, '2025-07-10', '2025-07-12', 'Completed', 'Request for book "History of Art".', 5, 1005);

INSERT INTO MemberPhone (memberNumber, phone)
VALUES
    (1, '123-456-7890'),
    (2, '234-567-8901'),
    (3, '345-678-9012'),
    (4, '456-789-0123'),
    (5, '567-890-1234');

INSERT INTO NewItemRequest (requestId, typeOfItem, title, publisher, edition, description, reason, memberNumber, requestedDate)
VALUES
    (1, 'Book', 'The Great Gatsby', 'Scribner', '1st', 'A novel about the American dream set in the 1920s.', 'Requested for a reading assignment in literature class.', 1, GETDATE()),
    (2, 'DVD', 'Inception', 'Warner Bros.', 'Blu-ray', 'A mind-bending thriller directed by Christopher Nolan.', 'Needed for a film analysis course.', 2, GETDATE()),
    (3, 'Book', 'The Catcher in the Rye', 'Little, Brown and Company', '1st', 'A novel about the struggles of adolescence and alienation.', 'Required for an English literature course.', 3, GETDATE()),
    (4, 'Magazine', 'National Geographic', 'National Geographic Society', '2023', 'A monthly magazine featuring articles on geography, science, and nature.', 'Requested for research on environmental topics.', 4, GETDATE()),
    (5, 'Book', '1984', 'Secker & Warburg', '1st', 'A dystopian novel about a totalitarian regime led by Big Brother.', 'Requested for a political science course.', 5, GETDATE());

INSERT INTO NewItemRequestAuthor (requestId, author) VALUES
(1, 'Mark Twain'),
(2, 'Alfred Hitchcock'),
(3, 'J.D. Salinger'),
(4, 'David Attenborough'),
(5, 'George Orwell');

INSERT INTO PrivilegeCollection (privilegeId, collectionId) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(1, 5);


-- SQL Queries

-- Q1: Print the details about the NewItemRequest that were requested by the member
-- named 'John Doe' in 2025, including the member’s name, mobile phone number, and the
-- title(s) of the requested items.

SELECT
    name, phone, title
FROM
    NewItemRequest n
JOIN
    Member m ON n.memberNumber = m.memberNumber
Full OUTER JOIN MemberPhone mp on n.memberNumber = mp.memberNumber
WHERE name = 'John Doe'
    AND YEAR(n.requestedDate) = '2025'


-- Q2: For a member named 'Jane Smith', print the maximum number of items they can borrow,
-- provided that all the items belong to the collection with collectionId 2.

SELECT
    m.name,
    IIF(COUNT(phc.accessionNumber) < pm.maxItems, COUNT(phc.accessionNumber), pm.maxItems) AS actualMaxBorrowLimit
FROM
    Member m
JOIN
    PrivilegeMain pm ON m.typeId = pm.typeId
JOIN
    PrivilegeCollection pc ON pm.privilegeId = pc.privilegeId
JOIN
    PhysicalCopy phc ON pc.collectionId = phc.collectionId
WHERE
    m.name = 'Jane Smith'
    AND pc.collectionId = 2
GROUP BY
    m.name, pm.maxItems;


-- Q3: For a member with id number 1, print their name and phone number, the total
-- number of Hold Request that the member has made in 2025.

SELECT
    m.name,
    mp.phone,
    COUNT(hr.holdNo) AS totalHoldRequests
FROM
    Member m
JOIN
    MemberPhone mp on m.memberNumber = mp.memberNumber
JOIN
    HoldRequest hr on m.memberNumber = hr.memberNumber
WHERE m.memberNumber = 1
    AND YEAR(hr.dtTimeRequested) = '2025'
GROUP BY
    m.name, mp.phone


-- Q4: Print the name(s) of the member(s) who has/have borrowed the book with the
-- title “Database Design” this year, and print the barcode(s) of the book(s) that had
-- been borrowed. Note: “this year” must be decided by the system.

SELECT
    name,
    barcode
FROM
    Loan l
JOIN
    Member m ON l.memberNumber = m.memberNumber
JOIN
    PhysicalCopy c ON l.accessionNumber = c.accessionNumber
Full OUTER JOIN Book b on c.bookNo = b.bookNo
WHERE
    b.title = 'Database Design'
    AND YEAR(l.dtLoaned) = YEAR(GETDATE())


