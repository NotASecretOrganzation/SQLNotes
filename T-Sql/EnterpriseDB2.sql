-- ========================================================================
-- T-SQL Development Reference for Traditional Chinese Enterprise Systems
-- ========================================================================
-- Version: 1.1 (Corrected)
-- Target: SQL Server 2016+ with Traditional Chinese collation support
-- ========================================================================

-- ========================================================================
-- SECTION 1: DATABASE SETUP & COLLATION
-- ========================================================================

-- Create database with Traditional Chinese collation (if not exists)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EnterpriseDB2')
BEGIN
    CREATE DATABASE EnterpriseDB2
    COLLATE Chinese_Taiwan_Stroke_CI_AS;
END
GO

USE EnterpriseDB2;
GO

-- Common collations for Traditional Chinese:
-- Chinese_Taiwan_Stroke_CI_AS (Case-insensitive, Accent-sensitive, Stroke order)
-- Chinese_Taiwan_Bopomofo_CI_AS (Bopomofo phonetic order)
-- Chinese_Traditional_Stroke_Order_100_CI_AS (SQL Server 2012+)

-- ========================================================================
-- SECTION 2: COMMON SCHEMA PATTERNS
-- ========================================================================

-- Drop existing objects if they exist (for clean re-run)
IF OBJECT_ID('銷貨單明細', 'U') IS NOT NULL DROP TABLE 銷貨單明細;
IF OBJECT_ID('銷貨單主檔', 'U') IS NOT NULL DROP TABLE 銷貨單主檔;
IF OBJECT_ID('產品主檔', 'U') IS NOT NULL DROP TABLE 產品主檔;
IF OBJECT_ID('員工主檔', 'U') IS NOT NULL DROP TABLE 員工主檔;
IF OBJECT_ID('客戶主檔', 'U') IS NOT NULL DROP TABLE 客戶主檔;
GO

-- Customer Master Table (客戶主檔)
CREATE TABLE 客戶主檔 (
    客戶編號 NVARCHAR(20) PRIMARY KEY,
    客戶名稱 NVARCHAR(100) NOT NULL,
    統一編號 NVARCHAR(8), -- Taiwan Business Registration Number
    負責人 NVARCHAR(50),
    聯絡人 NVARCHAR(50),
    電話 NVARCHAR(20),
    傳真 NVARCHAR(20),
    手機 NVARCHAR(20),
    郵遞區號 NVARCHAR(5),
    地址 NVARCHAR(200),
    電子郵件 NVARCHAR(100),
    付款條件 NVARCHAR(50),
    信用額度 DECIMAL(18, 2),
    客戶類別 NVARCHAR(20),
    業務員編號 NVARCHAR(20),
    建立日期 DATETIME DEFAULT GETDATE(),
    修改日期 DATETIME DEFAULT GETDATE(),
    備註 NVARCHAR(500),
    狀態 NVARCHAR(10) DEFAULT '啟用' CHECK (狀態 IN ('啟用', '停用'))
);
GO

-- Employee Master Table (員工主檔)
CREATE TABLE 員工主檔 (
    員工編號 NVARCHAR(20) PRIMARY KEY,
    姓名 NVARCHAR(50) NOT NULL,
    英文姓名 NVARCHAR(100),
    身分證號 NVARCHAR(10) UNIQUE,
    出生日期 DATE,
    性別 NVARCHAR(2) CHECK (性別 IN ('男', '女')),
    部門編號 NVARCHAR(20),
    職稱 NVARCHAR(50),
    到職日期 DATE,
    離職日期 DATE,
    電話 NVARCHAR(20),
    手機 NVARCHAR(20),
    緊急聯絡人 NVARCHAR(50),
    緊急聯絡電話 NVARCHAR(20),
    地址 NVARCHAR(200),
    電子郵件 NVARCHAR(100),
    銀行帳號 NVARCHAR(20),
    月薪 DECIMAL(18, 2),
    狀態 NVARCHAR(10) DEFAULT '在職' CHECK (狀態 IN ('在職', '留職停薪', '離職'))
);
GO

-- Product Master Table (產品主檔)
CREATE TABLE 產品主檔 (
    產品編號 NVARCHAR(20) PRIMARY KEY,
    產品名稱 NVARCHAR(100) NOT NULL,
    產品規格 NVARCHAR(200),
    產品類別 NVARCHAR(50),
    單位 NVARCHAR(10) DEFAULT '個',
    標準成本 DECIMAL(18, 2),
    售價 DECIMAL(18, 2),
    安全存量 INT DEFAULT 0,
    現有庫存 INT DEFAULT 0,
    供應商編號 NVARCHAR(20),
    條碼 NVARCHAR(50),
    建立日期 DATETIME DEFAULT GETDATE(),
    修改日期 DATETIME DEFAULT GETDATE(),
    備註 NVARCHAR(500),
    狀態 NVARCHAR(10) DEFAULT '啟用' CHECK (狀態 IN ('啟用', '停用', '停產'))
);
GO

-- Sales Order Header (銷貨單主檔)
CREATE TABLE 銷貨單主檔 (
    銷貨單號 NVARCHAR(20) PRIMARY KEY,
    銷貨日期 DATE NOT NULL,
    客戶編號 NVARCHAR(20) NOT NULL,
    客戶名稱 NVARCHAR(100),
    業務員編號 NVARCHAR(20),
    付款條件 NVARCHAR(50),
    交貨地址 NVARCHAR(200),
    備註 NVARCHAR(500),
    稅別 NVARCHAR(10) DEFAULT '應稅' CHECK (稅別 IN ('應稅', '免稅', '零稅率')),
    稅率 DECIMAL(5, 2) DEFAULT 5.00,
    銷貨金額 DECIMAL(18, 2) DEFAULT 0,
    稅額 DECIMAL(18, 2) DEFAULT 0,
    總金額 DECIMAL(18, 2) DEFAULT 0,
    狀態 NVARCHAR(10) DEFAULT '未結' CHECK (狀態 IN ('未結', '部分結清', '已結清', '作廢')),
    建立人員 NVARCHAR(20),
    建立日期 DATETIME DEFAULT GETDATE(),
    修改日期 DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (客戶編號) REFERENCES 客戶主檔(客戶編號)
);
GO

-- Sales Order Detail (銷貨單明細)
CREATE TABLE 銷貨單明細 (
    銷貨單號 NVARCHAR(20),
    項次 INT,
    產品編號 NVARCHAR(20) NOT NULL,
    產品名稱 NVARCHAR(100),
    數量 DECIMAL(18, 3) NOT NULL,
    單位 NVARCHAR(10),
    單價 DECIMAL(18, 2) NOT NULL,
    折扣率 DECIMAL(5, 2) DEFAULT 0,
    金額 DECIMAL(18, 2),
    備註 NVARCHAR(200),
    PRIMARY KEY (銷貨單號, 項次),
    FOREIGN KEY (銷貨單號) REFERENCES 銷貨單主檔(銷貨單號),
    FOREIGN KEY (產品編號) REFERENCES 產品主檔(產品編號)
);
GO

-- ========================================================================
-- SECTION 3: ESSENTIAL QUERY TEMPLATES
-- ========================================================================

-- Query 1: Customer list with contact information
SELECT 
    客戶編號 AS [Customer ID],
    客戶名稱 AS [Customer Name],
    統一編號 AS [Tax ID],
    聯絡人 AS [Contact],
    電話 AS [Phone],
    地址 AS [Address],
    信用額度 AS [Credit Limit],
    狀態 AS [Status]
FROM 客戶主檔
WHERE 狀態 = '啟用'
ORDER BY 客戶名稱;

-- Query 2: Sales report by customer (月報表)
SELECT 
    c.客戶編號,
    c.客戶名稱,
    COUNT(DISTINCT h.銷貨單號) AS 訂單數量,
    SUM(h.銷貨金額) AS 銷貨金額,
    SUM(h.稅額) AS 稅額,
    SUM(h.總金額) AS 總金額
FROM 客戶主檔 c
LEFT JOIN 銷貨單主檔 h ON c.客戶編號 = h.客戶編號
WHERE h.銷貨日期 >= DATEADD(MONTH, -1, GETDATE())
    AND h.狀態 <> '作廢'
GROUP BY c.客戶編號, c.客戶名稱
ORDER BY 總金額 DESC;

-- Query 3: Product inventory status (庫存狀況)
SELECT 
    產品編號,
    產品名稱,
    產品類別,
    現有庫存,
    安全存量,
    CASE 
        WHEN 現有庫存 <= 安全存量 THEN '需補貨'
        WHEN 現有庫存 <= 安全存量 * 1.5 THEN '注意'
        ELSE '正常'
    END AS 庫存狀態,
    售價,
    現有庫存 * 售價 AS 庫存金額
FROM 產品主檔
WHERE 狀態 = '啟用'
ORDER BY 
    CASE 
        WHEN 現有庫存 <= 安全存量 THEN 1
        WHEN 現有庫存 <= 安全存量 * 1.5 THEN 2
        ELSE 3
    END,
    產品名稱;

-- Query 4: ROC Calendar Date Formatting (民國年格式)
SELECT 
    GETDATE() AS 西元日期,
    CAST(YEAR(GETDATE()) - 1911 AS NVARCHAR) + '年' +
    CAST(MONTH(GETDATE()) AS NVARCHAR) + '月' +
    CAST(DAY(GETDATE()) AS NVARCHAR) + '日' AS 民國日期;

-- Query 5: Monthly sales summary (月銷售統計)
SELECT 
    YEAR(銷貨日期) - 1911 AS 民國年,
    MONTH(銷貨日期) AS 月份,
    COUNT(*) AS 訂單數,
    SUM(銷貨金額) AS 銷貨金額,
    SUM(稅額) AS 稅額,
    SUM(總金額) AS 總金額,
    AVG(總金額) AS 平均訂單金額
FROM 銷貨單主檔
WHERE 狀態 <> '作廢'
GROUP BY YEAR(銷貨日期), MONTH(銷貨日期)
ORDER BY YEAR(銷貨日期) DESC, MONTH(銷貨日期) DESC;

-- ========================================================================
-- SECTION 4: STORED PROCEDURE EXAMPLES
-- ========================================================================

-- Drop existing procedures if they exist
IF OBJECT_ID('sp_建立銷貨單', 'P') IS NOT NULL DROP PROCEDURE sp_建立銷貨單;
IF OBJECT_ID('sp_新增銷貨明細', 'P') IS NOT NULL DROP PROCEDURE sp_新增銷貨明細;
GO

-- Procedure 1: Create new sales order (建立銷貨單)
CREATE PROCEDURE sp_建立銷貨單
    @客戶編號 NVARCHAR(20),
    @銷貨日期 DATE,
    @業務員編號 NVARCHAR(20),
    @備註 NVARCHAR(500) = NULL,
    @銷貨單號 NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Generate sales order number (format: SO + YYYYMMDD + sequence)
        DECLARE @今日 NVARCHAR(8) = CONVERT(NVARCHAR(8), @銷貨日期, 112);
        DECLARE @序號 INT;
        
        SELECT @序號 = ISNULL(MAX(CAST(RIGHT(銷貨單號, 4) AS INT)), 0) + 1
        FROM 銷貨單主檔
        WHERE 銷貨單號 LIKE 'SO' + @今日 + '%';
        
        SET @銷貨單號 = 'SO' + @今日 + RIGHT('0000' + CAST(@序號 AS NVARCHAR), 4);
        
        -- Get customer information
        DECLARE @客戶名稱 NVARCHAR(100), @付款條件 NVARCHAR(50);
        SELECT @客戶名稱 = 客戶名稱, @付款條件 = 付款條件
        FROM 客戶主檔
        WHERE 客戶編號 = @客戶編號;
        
        IF @客戶名稱 IS NULL
            THROW 50001, '客戶編號不存在', 1;
        
        -- Insert sales order header
        INSERT INTO 銷貨單主檔 (
            銷貨單號, 銷貨日期, 客戶編號, 客戶名稱, 
            業務員編號, 付款條件, 備註, 建立人員
        )
        VALUES (
            @銷貨單號, @銷貨日期, @客戶編號, @客戶名稱,
            @業務員編號, @付款條件, @備註, SUSER_SNAME()
        );
        
        COMMIT TRANSACTION;
        
        SELECT @銷貨單號 AS 銷貨單號, '銷貨單建立成功' AS 訊息;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedure 2: Add sales order detail (新增銷貨明細)
CREATE PROCEDURE sp_新增銷貨明細
    @銷貨單號 NVARCHAR(20),
    @產品編號 NVARCHAR(20),
    @數量 DECIMAL(18, 3),
    @折扣率 DECIMAL(5, 2) = 0,
    @備註 NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get product information
        DECLARE @產品名稱 NVARCHAR(100), @單位 NVARCHAR(10), @單價 DECIMAL(18, 2);
        SELECT @產品名稱 = 產品名稱, @單位 = 單位, @單價 = 售價
        FROM 產品主檔
        WHERE 產品編號 = @產品編號 AND 狀態 = '啟用';
        
        IF @產品名稱 IS NULL
            THROW 50002, '產品編號不存在或已停用', 1;
        
        -- Get next item number
        DECLARE @項次 INT;
        SELECT @項次 = ISNULL(MAX(項次), 0) + 1
        FROM 銷貨單明細
        WHERE 銷貨單號 = @銷貨單號;
        
        -- Calculate amount
        DECLARE @金額 DECIMAL(18, 2);
        SET @金額 = @數量 * @單價 * (1 - @折扣率 / 100);
        
        -- Insert detail
        INSERT INTO 銷貨單明細 (
            銷貨單號, 項次, 產品編號, 產品名稱,
            數量, 單位, 單價, 折扣率, 金額, 備註
        )
        VALUES (
            @銷貨單號, @項次, @產品編號, @產品名稱,
            @數量, @單位, @單價, @折扣率, @金額, @備註
        );
        
        -- Update header totals
        DECLARE @稅率 DECIMAL(5, 2);
        SELECT @稅率 = 稅率 FROM 銷貨單主檔 WHERE 銷貨單號 = @銷貨單號;
        
        UPDATE 銷貨單主檔
        SET 銷貨金額 = (SELECT SUM(金額) FROM 銷貨單明細 WHERE 銷貨單號 = @銷貨單號),
            稅額 = (SELECT SUM(金額) FROM 銷貨單明細 WHERE 銷貨單號 = @銷貨單號) * @稅率 / 100,
            總金額 = (SELECT SUM(金額) FROM 銷貨單明細 WHERE 銷貨單號 = @銷貨單號) * (1 + @稅率 / 100),
            修改日期 = GETDATE()
        WHERE 銷貨單號 = @銷貨單號;
        
        COMMIT TRANSACTION;
        
        SELECT '明細新增成功' AS 訊息;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Drop existing functions if they exist
IF OBJECT_ID('fn_驗證統一編號', 'FN') IS NOT NULL DROP FUNCTION fn_驗證統一編號;
GO

-- Procedure 3: Validate Taiwan Tax ID (驗證統一編號)
CREATE FUNCTION fn_驗證統一編號(@統一編號 NVARCHAR(8))
RETURNS BIT
AS
BEGIN
    -- Taiwan Business Registration Number validation logic
    IF LEN(@統一編號) <> 8 OR @統一編號 NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        RETURN 0;
    
    -- Checksum calculation (simplified)
    DECLARE @cx INT = 1, @sum INT = 0, @i INT = 1;
    DECLARE @weights TABLE (pos INT, weight INT);
    INSERT INTO @weights VALUES (1,1),(2,2),(3,1),(4,2),(5,1),(6,2),(7,4),(8,1);
    
    WHILE @i <= 8
    BEGIN
        DECLARE @digit INT = CAST(SUBSTRING(@統一編號, @i, 1) AS INT);
        DECLARE @weight INT = (SELECT weight FROM @weights WHERE pos = @i);
        DECLARE @product INT = @digit * @weight;
        SET @sum = @sum + (@product / 10) + (@product % 10);
        SET @i = @i + 1;
    END
    
    IF @sum % 10 = 0 OR (@sum + 1) % 10 = 0
        RETURN 1;
    
    RETURN 0;
END;
GO

-- ========================================================================
-- SECTION 5: DATA VALIDATION & CONSTRAINTS
-- ========================================================================

-- Drop existing trigger if exists
IF OBJECT_ID('trg_更新庫存', 'TR') IS NOT NULL DROP TRIGGER trg_更新庫存;
GO

-- Trigger: Update product inventory on sales
CREATE TRIGGER trg_更新庫存
ON 銷貨單明細
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update inventory from inserted records
    UPDATE p
    SET 現有庫存 = 現有庫存 - i.數量
    FROM 產品主檔 p
    INNER JOIN inserted i ON p.產品編號 = i.產品編號;
    
    -- Restore inventory from deleted records
    UPDATE p
    SET 現有庫存 = 現有庫存 + d.數量
    FROM 產品主檔 p
    INNER JOIN deleted d ON p.產品編號 = d.產品編號;
END;
GO

-- Check constraint examples (only add if not exists)
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_客戶信用額度')
    ALTER TABLE 客戶主檔 ADD CONSTRAINT CK_客戶信用額度 CHECK (信用額度 >= 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_產品售價')
    ALTER TABLE 產品主檔 ADD CONSTRAINT CK_產品售價 CHECK (售價 >= 0 AND 售價 >= 標準成本);
GO

-- ========================================================================
-- SECTION 6: PERFORMANCE OPTIMIZATION
-- ========================================================================

-- Create full-text catalog if not exists
IF NOT EXISTS (SELECT * FROM sys.fulltext_catalogs WHERE name = 'ft_企業資料')
    CREATE FULLTEXT CATALOG ft_企業資料;
GO

-- Note: Full-text index requires specific setup - see documentation for your environment
-- Example commented out to avoid errors:
/*
CREATE FULLTEXT INDEX ON 客戶主檔(客戶名稱, 地址, 備註)
KEY INDEX [PRIMARY_KEY_NAME] ON ft_企業資料
WITH CHANGE_TRACKING AUTO;
GO
*/

-- Common indexes for frequently queried fields
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_客戶主檔_狀態')
    CREATE INDEX IX_客戶主檔_狀態 ON 客戶主檔(狀態) INCLUDE (客戶名稱, 客戶編號);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_銷貨單主檔_日期')
    CREATE INDEX IX_銷貨單主檔_日期 ON 銷貨單主檔(銷貨日期) INCLUDE (客戶編號, 總金額);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_銷貨單主檔_客戶')
    CREATE INDEX IX_銷貨單主檔_客戶 ON 銷貨單主檔(客戶編號, 銷貨日期);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_產品主檔_類別')
    CREATE INDEX IX_產品主檔_類別 ON 產品主檔(產品類別, 狀態);
GO

-- Statistics update for better query plans
IF NOT EXISTS (SELECT * FROM sys.stats WHERE name = 'ST_客戶名稱' AND object_id = OBJECT_ID('客戶主檔'))
    CREATE STATISTICS ST_客戶名稱 ON 客戶主檔(客戶名稱);

IF NOT EXISTS (SELECT * FROM sys.stats WHERE name = 'ST_產品名稱' AND object_id = OBJECT_ID('產品主檔'))
    CREATE STATISTICS ST_產品名稱 ON 產品主檔(產品名稱);
GO

-- ========================================================================
-- SECTION 7: COMMON PITFALLS & SOLUTIONS
-- ========================================================================

-- Problem 1: Chinese character sorting
-- Solution: Use appropriate collation in ORDER BY
SELECT 客戶名稱
FROM 客戶主檔
ORDER BY 客戶名稱 COLLATE Chinese_Taiwan_Stroke_CI_AS;

-- Problem 2: String length for Chinese characters
-- Always use NVARCHAR instead of VARCHAR for Chinese text
-- Each Chinese character takes 2 bytes in NVARCHAR

-- Drop existing function if exists
IF OBJECT_ID('fn_民國日期', 'FN') IS NOT NULL DROP FUNCTION fn_民國日期;
GO

-- Problem 3: Date display in ROC calendar
-- Solution: Create a function for consistent formatting
CREATE FUNCTION fn_民國日期(@日期 DATE)
RETURNS NVARCHAR(20)
AS
BEGIN
    RETURN CAST(YEAR(@日期) - 1911 AS NVARCHAR) + '/' +
           RIGHT('0' + CAST(MONTH(@日期) AS NVARCHAR), 2) + '/' +
           RIGHT('0' + CAST(DAY(@日期) AS NVARCHAR), 2);
END;
GO

-- Problem 4: Full-text search for Chinese
-- Note: Requires full-text index to be created first
-- Example (commented out):
/*
SELECT 客戶名稱, 地址
FROM 客戶主檔
WHERE CONTAINS(客戶名稱, '"張*"', LANGUAGE 1028); -- 1028 = Traditional Chinese
*/

-- Problem 5: Currency rounding
-- Solution: Use ROUND function with 2 decimal places
-- Example:
/*
UPDATE 銷貨單主檔
SET 總金額 = ROUND(銷貨金額 * (1 + 稅率/100), 0); -- Round to nearest dollar
*/

-- ========================================================================
-- SECTION 8: USEFUL UTILITY QUERIES
-- ========================================================================

-- Drop sequence if exists
IF EXISTS (SELECT * FROM sys.sequences WHERE name = 'seq_客戶編號')
    DROP SEQUENCE seq_客戶編號;
GO

-- Generate sequence numbers (流水號)
CREATE SEQUENCE seq_客戶編號
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 50;
GO

-- Use sequence in insert (example - commented out)
/*
INSERT INTO 客戶主檔 (客戶編號, 客戶名稱)
VALUES ('C' + RIGHT('000000' + CAST(NEXT VALUE FOR seq_客戶編號 AS NVARCHAR), 6), '新客戶');
*/

-- Backup database (example - adjust path for your environment)
-- Note: Requires appropriate permissions and valid backup path
/*
DECLARE @BackupFile NVARCHAR(500);
SET @BackupFile = 'D:\Backup\EnterpriseDB_' + CONVERT(NVARCHAR, GETDATE(), 112) + '.bak';

BACKUP DATABASE EnterpriseDB 
TO DISK = @BackupFile
WITH COMPRESSION, INIT;
GO
*/

-- Common system queries
-- Check database collation
SELECT DATABASEPROPERTYEX('EnterpriseDB', 'Collation') AS 資料庫定序;

-- Check table sizes
SELECT 
    t.NAME AS 資料表名稱,
    p.rows AS 資料筆數,
    SUM(a.total_pages) * 8 AS 總空間KB,
    SUM(a.used_pages) * 8 AS 使用空間KB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.Name, p.Rows
ORDER BY 總空間KB DESC;

-- ========================================================================
-- END OF REFERENCE GUIDE
-- ========================================================================