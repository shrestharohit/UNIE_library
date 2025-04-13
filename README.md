# Reflections on Database Design: From Concept to Implementation

## Introduction

Database design is a journey that takes us from abstract concepts to concrete implementation. In this blog post, I'll share my experience designing a library management system database, highlighting the challenges, decisions, and valuable lessons learned throughout the process.

## Part 1: Refining the Normalized Tables

### Streamlining the Database Structure

My initial design included 20 tables, which I later reduced to 17 during the physical design phase. This reduction was based on both instructor feedback and careful reconsideration of the business rules established during the initial phase.

The revised EER diagram contained 14 entity tables:
- item
- book
- journal
- onlineDatabase
- copyOfItem
- physicalCopy
- digitalCopy
- collection
- loan
- holdRequest
- member
- memberType
- privilege
- newItemRequest

### Handling Multivalued Attributes

Several tables contained multivalued attributes that required special handling. For instance, the item table had an author attribute that could contain up to 10 authors per item. To properly manage these multivalued attributes, I created three new entities:
- itemAuthor
- memberPhone
- newItemRequestAuthor

### Breaking Down Tables for BCNF Compliance

While normalizing to Boyce-Codd Normal Form (BCNF), I split some entities to remove dependencies:
- The privilege table was divided into privilegeMain and privilegeName based on the dependency of description with the name
- The members table was broken into memberMain and memberTypeExpiry to handle expiry dates for each member

Later, I simplified this approach by removing the memberExpiryType and adding a validityPeriod attribute to the memberType table. This allowed the expiryDate to be derived based on memberType validity and the member's join date.

### Performance Optimization

After consulting with my instructor, I made some significant structural changes:

1. **Removed the item and copyOfItem tables**: These tables contained attributes that were already covered by book, journal, and onlineDatabase tables. By merging these tables, I reduced query latency and eliminated unnecessary maintenance overhead.

2. **Moved attributes**: I transferred attributes from the copyOfItem table to the physical and digital copies tables, improving performance.

3. **Eliminated unnecessary foreign key constraints**: By making these changes, I removed constraints between entities that would never have relationships (e.g., onlineDatabase and physicalCopy, book and digitalCopy).

The result: 17 tables with 19 foreign key constraints—a more streamlined and efficient design.

### Tackling Multiple Cascade Paths

One significant challenge I encountered was dealing with multiple cascade paths in foreign keys. For example, having both bookNo and journalNo as foreign keys with cascading updates could create ambiguity and data integrity issues:

```sql
-- Multiple CASCADE paths could potentially delete the same row
FOREIGN KEY (bookNo) REFERENCES Book(bookNo) ON UPDATE NO ACTION ON DELETE NO ACTION,
FOREIGN KEY (journalNo) REFERENCES Journal(journalNo) ON UPDATE NO ACTION ON DELETE NO ACTION,
```

To resolve this, I set "NO ACTION" on updates and deletes, planning to use triggers instead to maintain data integrity while meeting business requirements.

### Additional Improvements

As I worked on later assignments, I identified more areas for improvement:
- Added a requestedDate attribute to the newItemRequest table
- Revised attribute names for clarity (e.g., changed dateTime to dtLoaned, dtRequested)
- Renamed acquisition to newItemRequest for better understanding
- Changed association tables for loan and hold to separate entities for query optimization

## Part 2: Comprehensive Reflection on the Design Process

### Conceptual Design Phase

The conceptual design phase began with a simple requirement: create a database for a library management system. The challenge was understanding what this system needed to accomplish at a functional level. I approached this by:

1. Gathering requirements through observation of existing systems
2. Thinking from multiple perspectives (library user, librarian, etc.)
3. Defining strict business requirements to set boundaries

I quickly learned the importance of setting clear boundaries around what the system should include, focusing on what was truly needed rather than every possible feature.

### Logical Design Phase

During the logical design phase, I refined my EER diagram based on provided guidelines. This phase revealed the need for additional tables not originally identified in the EER:

- Tables for handling multivalued attributes
- Clear patterns for relationships with foreign and primary keys
- Normalization according to business requirements

For example, I separated the dateOfExpiry from the member table since it depended on memberType rather than the member themselves, bringing the schema into BCNF normal form.

### Physical Design Phase

The physical design phase brought the abstract schema into reality through DDL (Data Definition Language) and DML (Data Manipulation Language). Using Microsoft SQL Server, I:

- Created databases and tables
- Loaded test data
- Performed queries to test functionality

This phase was exciting but challenging, requiring me to learn SQL Server syntax and make numerous adjustments to my logical design during implementation.

## Key Takeaways

### Balancing Creativity with Focus

I learned to think broadly at first to identify potential issues, while eventually narrowing my focus to meet specific requirements—a crucial skill for creating efficient prototypes and MVPs in real-world environments.

### The Power of Clear Business Requirements

Clear, precise business requirements and rules are essential guides for the entire design process. They help identify necessary entities, relationships, and attributes while preventing scope creep.

### Thoughtful Attribute Design

When creating entities and attributes, I discovered the importance of:
- Keeping designs as minimal as possible
- Creating clear, descriptive attribute names
- Properly identifying attribute types (multivalued, derived, etc.)
- Selecting appropriate data types

### Normalization Isn't Always the Answer

While normalization is valuable, I found that strictly following normalization rules sometimes added unnecessary complexity. In some cases, denormalization improved query performance and simplified database management.

### The Value of Realistic Testing Data

When testing queries, I realized the importance of using varied, realistic data to identify edge cases and ensure the database structure could handle all required operations.

## Conclusion

Database design is truly an iterative process that requires balancing theoretical principles with practical considerations. Through this project, I gained valuable experience in all aspects of database design—from conceptual modeling to physical implementation. The greatest lesson was understanding that database design isn't just about following rules; it's about creating a system that efficiently meets business needs while remaining adaptable to future changes.