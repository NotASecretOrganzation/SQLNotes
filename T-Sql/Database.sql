CREATE DATABASE FullTextSearchDemo;
GO

-- Use the database
USE FullTextSearchDemo;
GO

-- Drop existing tables
DROP TABLE IF EXISTS Articles;
DROP TABLE IF EXISTS Products;
GO

-- Create Products table with named PK
CREATE TABLE Products (
    ProductID int IDENTITY(1,1),
    ProductName nvarchar(100) NOT NULL,
    Description nvarchar(max),
    Category nvarchar(50),
    Price decimal(10,2),
    CreatedDate datetime2 DEFAULT GETDATE(),
    CONSTRAINT PK_Products PRIMARY KEY (ProductID)
);

-- Create Articles table with named PK
CREATE TABLE Articles (
    ArticleID int IDENTITY(1,1),
    Title nvarchar(200) NOT NULL,
    Content nvarchar(max),
    Author nvarchar(100),
    PublishedDate datetime2 DEFAULT GETDATE(),
    Tags nvarchar(500),
    CONSTRAINT PK_Articles PRIMARY KEY (ArticleID)
);
GO

-- Insert sample products
INSERT INTO Products (ProductName, Description, Category, Price) VALUES
('Gaming Laptop Pro', 'High-performance gaming laptop with RTX 4080 graphics card, Intel Core i7 processor, 32GB RAM, perfect for gaming enthusiasts and content creators', 'Electronics', 1999.99),
('Office Desktop Computer', 'Reliable desktop computer for office work, business applications, and productivity tasks. Intel Core i5, 16GB RAM, SSD storage', 'Electronics', 899.99),
('Wireless Gaming Mouse', 'Ergonomic wireless mouse designed for competitive gaming with high DPI sensor and customizable RGB lighting', 'Accessories', 79.99),
('Mechanical Keyboard RGB', 'Premium mechanical keyboard with RGB backlighting, Cherry MX switches, perfect for typing and gaming', 'Accessories', 149.99),
('4K Gaming Monitor', 'Ultra-wide 4K monitor with HDR support, 144Hz refresh rate, ideal for gaming and professional video editing', 'Electronics', 699.99),
('Laptop Cooling Pad', 'Advanced cooling solution for laptops to prevent overheating during intensive gaming sessions', 'Accessories', 39.99),
('Smartphone Pro Max', 'Latest smartphone with advanced camera system, 5G connectivity, and all-day battery life for mobile productivity', 'Electronics', 1299.99),
('Bluetooth Headphones', 'Noise-canceling wireless headphones with premium sound quality for music and calls', 'Audio', 299.99),
('Gaming Chair Executive', 'Comfortable ergonomic gaming chair with lumbar support, adjustable height, perfect for long gaming sessions', 'Furniture', 399.99),
('Portable SSD Drive', 'Fast external SSD storage device with USB-C connectivity for backup and file transfer', 'Storage', 129.99);

-- Insert sample articles
INSERT INTO Articles (Title, Content, Author, Tags) VALUES
('The Future of Gaming Technology', 'Gaming technology continues to evolve at a rapid pace. Modern graphics cards like the RTX 4080 and RTX 4090 are pushing the boundaries of what''s possible in real-time rendering. Ray tracing technology is becoming mainstream, providing incredibly realistic lighting and reflections in games. Virtual reality is also gaining momentum with improved headsets offering higher resolution and better tracking. Cloud gaming services are making high-end gaming accessible to users with modest hardware. The integration of artificial intelligence in game development is creating more dynamic and responsive gaming experiences.', 'John Smith', 'gaming, technology, graphics, VR'),
('Best Practices for Remote Work Setup', 'Creating an effective remote work environment requires careful consideration of both hardware and software. A reliable computer with sufficient processing power is essential, whether it''s a desktop or laptop setup. Ergonomic accessories like a good chair, keyboard, and mouse can prevent strain during long work sessions. High-speed internet connectivity ensures smooth video calls and file transfers. Proper lighting and a quiet workspace improve productivity and video call quality. Organization tools and project management software help maintain workflow efficiency.', 'Sarah Johnson', 'remote work, productivity, office setup'),
('Understanding Modern Computer Hardware', 'Modern computers consist of several key components working together. The processor (CPU) handles general computing tasks, while the graphics card (GPU) manages visual rendering. Memory (RAM) provides temporary storage for active programs, and storage drives (SSD/HDD) offer permanent data storage. The motherboard connects all components together, and the power supply unit provides electricity to the system. Cooling systems prevent overheating during intensive operations. Understanding these components helps users make informed purchasing decisions and troubleshoot issues.', 'Mike Chen', 'hardware, computer, components, CPU, GPU'),
('Mobile Technology Trends 2024', 'Smartphone technology continues advancing with improved cameras, faster processors, and better battery life. 5G connectivity is becoming standard, enabling faster data speeds and lower latency. Foldable phones are gaining popularity, offering larger screens in compact form factors. Artificial intelligence integration provides smarter photo processing, voice assistants, and predictive text input. Wireless charging and reverse charging capabilities are becoming common features. Privacy and security features are also being enhanced to protect user data.', 'Lisa Park', 'mobile, smartphone, 5G, AI, technology'),
('Audio Equipment for Content Creators', 'Quality audio equipment is crucial for content creation, whether for podcasting, streaming, or video production. Professional microphones capture clear voice recordings with minimal background noise. Studio headphones provide accurate audio monitoring during recording and editing. Audio interfaces connect microphones and instruments to computers for digital recording. Acoustic treatment in recording spaces improves sound quality by reducing echo and unwanted reflections. Software tools for audio editing and processing help achieve professional results.', 'David Wilson', 'audio, content creation, microphone, headphones');
GO

-- Check the structure of your indexes
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    c.name AS ColumnName,
    c.is_nullable,
    ty.name AS DataType,
    c.max_length
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.types ty ON c.system_type_id = ty.system_type_id
WHERE t.name IN ('Products', 'Articles')
    AND i.is_primary_key = 1;

-- Check if full-text is installed
SELECT SERVERPROPERTY('IsFullTextInstalled')

EXEC sp_fulltext_database 'enable'

-- Drop existing catalog if it exists
IF EXISTS (SELECT * FROM sys.fulltext_catalogs WHERE name = 'ProductCatalog')
    DROP FULLTEXT CATALOG ProductCatalog;
GO

-- Create full-text catalog
CREATE FULLTEXT CATALOG ProductCatalog AS DEFAULT;
GO

-- Create full-text index on Products table
CREATE FULLTEXT INDEX ON Products(ProductName, Description, Category)
KEY INDEX PK_Products
ON ProductCatalog
WITH CHANGE_TRACKING AUTO;

-- Create full-text index on Articles table
CREATE FULLTEXT INDEX ON Articles(Title, Content, Author, Tags)
KEY INDEX PK_Articles
ON ProductCatalog
WITH CHANGE_TRACKING AUTO;
GO