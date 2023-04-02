-- Data set used in this work: https://github.com/ildeniz/sql_projects/blob/master/data/Nashville%20Housing%20Data%20for%20Data%20Cleaning.csv

# Create database
CREATE SCHEMA `nashville_housing` ;

# Delete database
-- DROP SCHEMA nashville_housing ;

# Create table to work on
CREATE TABLE nashville_housing.nashville(
UniqueID VARCHAR(10) NULL,
ParcelID VARCHAR(40) NULL,
LandUse VARCHAR(40) NULL,
PropertyAddress VARCHAR(40) NULL,
SaleDate DATE,
SalePrice INT, 
LegalReference VARCHAR(40),
SoldAsVacant VARCHAR(5),
OwnerName VARCHAR(100),
OwnerAddress VARCHAR(100),
Acreage	DECIMAL(3,2), 
TaxDistrict	VARCHAR(40),
LandValue INT,
BuildingValue INT,
TotalValue INT,
YearBuilt YEAR,
Bedrooms INT,
FullBath INT,
HalfBath INT #,
# PRIMARY KEY(UniqueID)
);

# Delete table
-- DROP TABLE nashville_housing.nashville;

# Load data from CSV file and bulk insert it to the table created above
LOAD DATA LOCAL INFILE 'C:/Storage/SQL Projects/Nashville Housing Data for Data Cleaning.csv'
INTO TABLE nashville_housing.nashville FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, 
OwnerName, OwnerAddress, Acreage, TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath )
SET 
UniqueID = NULLIF(UniqueID,''),
ParcelID = NULLIF(ParcelID,''),
LandUse = NULLIF(LandUse,''),
PropertyAddress = NULLIF(PropertyAddress,''),
# SaleDate = NULLIF(SaleDate,''),
SalePrice = NULLIF(SalePrice,''),
LegalReference = NULLIF(LegalReference,''),
SoldAsVacant = NULLIF(SoldAsVacant,''),
OwnerName = NULLIF(OwnerName,''),
OwnerAddress = NULLIF(OwnerAddress,''),
Acreage = NULLIF(Acreage,''),
TaxDistrict = NULLIF(TaxDistrict,''),
LandValue = NULLIF(LandValue,''),
BuildingValue = NULLIF(BuildingValue,''),
TotalValue = NULLIF(TotalValue,''),
YearBuilt = NULLIF(YearBuilt,''),
Bedrooms = NULLIF(Bedrooms,''),
FullBath = NULLIF(FullBath,''),
HalfBath = NULLIF(HalfBath,'');
 
 /* Altering a table
ALTER TABLE `nashville_housing`.`nashville` 
CHANGE COLUMN `UniqueID` `UniqueID` VARCHAR(10) NOT NULL ,
ADD PRIMARY KEY (`UniqueID`);

ALTER TABLE `nashville_housing`.`nashville` 
CHANGE COLUMN `UniqueID` `UniqueID` VARCHAR(10) NULL ,
DROP PRIMARY KEY;
 */
 
/* Solutions to a couple of errors I encountered. Error Code: 3948 and 2068
-- if you get "Error Code: 3948. Loading local data is disabled; 
-- 			this must be enabled on both the client and server sides"
-- Do below;
-- 1- Open MYSQL Command Line
-- 2- Type in your password
-- 3- Enter the following:
--    SHOW GLOBAL VARIABLES LIKE 'local_infile';
-- 4- If local_infile value is equal to false set it to true by:
--    SET GLOBAL local_infile = true;
-- More info here: https://www.digitalocean.com/community/questions/how-to-enable-local-capability-in-mysql-workbench
 
-- if you get "Error Code: 2068. LOAD DATA LOCAL INFILE file request rejected due to restrictions on access."
-- [12 Nov 2020 12:28] Martin Baxter
-- This restriction can be removed from MySQL Workbench 8.0 in the following way.
-- Edit the connection, on the Connection tab, go to the 'Advanced' sub-tab, and in the 'Others:' box add the line 'OPT_LOCAL_INFILE=1'.
-- This should allow a client using the Workbench to run LOAD DATA INFILE as usual
*/

DESCRIBE nashville;

# Detecting the number of rows in the table
SELECT COUNT(*) as number_of_rows_in_nashville
FROM nashville_housing.nashville;

SELECT * FROM nashville_housing.nashville;

SELECT SaleDate
FROM nashville_housing.nashville;

# Missing Values
-- It is worth to check if there is any 'Null' values in the property address since address of a property, contrary to the other variables, is not expected to be absent or change.
SELECT * 
FROM nashville_housing.nashville
WHERE PropertyAddress IS NULL;

-- There are 'Null' values in 'PropertyAddress' column and we have to deal with this issue.
-- We can either drop the rows with missing values or find a reference point to detect the missing address.
-- The data set includes two type of IDs, 'UniqueID' and 'ParcelID', lets check 

SELECT 
	COUNT(DISTINCT UniqueID),
    COUNT(DISTINCT ParcelID)
FROM nashville_housing.nashville;

-- Recall from above that there are 56477 rows in the table and also 'UniqueID' has the same amount of unique values. 
-- 'ParcelID' has 48559 unique values and this means that some of the 'UniqueID's share the same 'ParcelID'.
-- We can use these to variables as reference points to detect the missing addresses.

SELECT left_.ParcelID, left_.PropertyAddress, right_.ParcelID, right_.PropertyAddress, IFNULL(left_.PropertyAddress, right_.PropertyAddress) AS MissingReplacement
FROM nashville_housing.nashville AS left_
JOIN nashville_housing.nashville AS right_
	ON left_.ParcelID = right_.ParcelID 
	AND left_.UniqueID <> right_.UniqueID
WHERE left_.PropertyAddress IS NULL;

-- Handling the missing values in 'PropertyAddress' column.
SET SQL_SAFE_UPDATES = 0; # To handle Error Code: 1175 of MySQL Workbench
UPDATE nashville_housing.nashville AS left_
JOIN nashville_housing.nashville AS right_
	ON (left_.ParcelID = right_.ParcelID 
	AND left_.UniqueID <> right_.UniqueID)
SET left_.PropertyAddress = IFNULL(left_.PropertyAddress, right_.PropertyAddress)
# FROM nashville_housing.nashville left_
WHERE (left_.PropertyAddress IS NULL);
SET SQL_SAFE_UPDATES = 1; # To handle Error Code: 1175 of MySQL Workbench

/* [Does NOT WORK]temp table soution 
CREATE TEMPORARY TABLE temp_table(
left_ParcelID VARCHAR(40), 
left_PropertyAddress VARCHAR(40), 
right_ParcelID VARCHAR(40), 
right_PropertyAddress VARCHAR(40),
missing_rep VARCHAR(40)
);

INSERT INTO temp_table
SELECT left_.ParcelID, left_.PropertyAddress, right_.ParcelID, right_.PropertyAddress, IFNULL(left_.PropertyAddress, right_.PropertyAddress) AS MissingReplacement
FROM nashville_housing.nashville left_
JOIN nashville_housing.nashville right_
	ON left_.ParcelID = right_.ParcelID 
	AND left_.UniqueID <> right_.UniqueID
WHERE left_.PropertyAddress IS NULL;

SELECT * FROM temp_table;

UPDATE nashville_housing.nashville AS left_
SET left_.PropertyAddress = IFNULL(left_.PropertyAddress, nashville_housing.temp_table.missing_rep)
WHERE left_.PropertyAddress IS NULL; 
*/

# Creating new individual columns from the 'PropertyAddress' column
-- 'PropertyAddress' column includes two types of information; street address and city which are seperated by delimiter ','.
-- Below we will extract 'StretAddress' and 'City' columns by breaking out 'PropertyAddress'
SELECT PropertyAddress
FROM nashville_housing.nashville;

-- 1st approach, utilising 'substring()' and 'locate()'
-- 		The substring(string, start, length) function extracts a substring from a string (starting at any position).
-- 		The locate(substring, string, start) function returns the position of the first occurrence of a substring in a string.
SELECT
substring(PropertyAddress, 1, locate(',', PropertyAddress, 1)-1) as Address, # '-1' is added to exclude ','
substring(PropertyAddress, locate(',', PropertyAddress, 1) + 1 , length(PropertyAddress)) as Address # '+1' is added to exclude ','
FROM nashville_housing.nashville;

-- Stored Generated Columns
ALTER TABLE nashville_housing.nashville
Add PropertySplitAddress VARCHAR(255);
    
SET SQL_SAFE_UPDATES = 0;
UPDATE nashville_housing.nashville
SET PropertySplitAddress = substring(PropertyAddress, 1, locate(',', PropertyAddress, 1)-1);
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE nashville_housing.nashville
Add PropertySplitCity VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville_housing.nashville
SET PropertySplitCity = substring(PropertyAddress, locate(',', PropertyAddress, 1) + 1 , length(PropertyAddress));
SET SQL_SAFE_UPDATES = 1;

-- 2nd approach, utilising 'substring_index()'
-- 		The substring_index(string, delimiter, number) function returns a substring of a string before a specified number of delimiter occurs.
-- 		We will use the ',' in values of 'OwnerAddress' as a 'delimiter'.
-- 		Actually I like this approach better than the 1st one.

SELECT OwnerAddress
FROM nashville_housing.nashville;

SELECT
substring_index(OwnerAddress, ',' , 1) AS OwnerSplitAddress,
substring_index(substring_index(OwnerAddress, ',' , 2), ',' , -1) AS OwnerSplitCity,
substring_index(OwnerAddress, ',' , -1) AS OwnerSplitState
FROM nashville_housing.nashville;

-- Virtual Generated Columns
ALTER TABLE nashville_housing.nashville
ADD OwnerSplitAddress VARCHAR(255)
GENERATED ALWAYS as (substring_index(OwnerAddress, ',' , 1));

ALTER TABLE nashville_housing.nashville
ADD OwnerSplitCity VARCHAR(255)
GENERATED ALWAYS as (substring_index(substring_index(OwnerAddress, ',' , 2), ',' , -1));

ALTER TABLE nashville_housing.nashville
ADD OwnerSplitState VARCHAR(255)
GENERATED ALWAYS as (substring_index(OwnerAddress, ',' , -1));

# Change 'Y' and 'N' entries in 'SoldAsVacant' column into 'Yes' and 'No' 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Count
FROM nashville_housing.nashville
GROUP BY SoldAsVacant
ORDER BY Count DESC; # instead of using 'Count' keyword, we can use the row order '2'
-- ORDER BY 2 DESC;

-- As the query below runs, it returns four different entries in 'SoldAsVacant' column; 'Y', 'N', 'Yes', and 'No'.
-- For the sake of consistency these values has to be either 'Y', 'N' or 'Yes', 'No'.

SELECT SoldAsVacant, 
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END AS CaseOccured
FROM nashville_housing.nashville;

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville_housing.nashville
SET SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
				   END;
SET SQL_SAFE_UPDATES = 1;

# Showing the difference between 'Stored Generated' columns and Virtual Generated' columns
# Delete unused columns
-- Since we have already extract additional data from 'PropertyAddress' and 'OwnerAddress', we can get rid of those columns.

ALTER TABLE nashville_housing.nashville
	DROP COLUMN PropertyAddress;

-- 'PropertyAddress' is successfully dropped from the table because the columns created from 'PropertyAddress' are 'Stored Generated' columns and they are written on actual disk space.
-- Contrary to the 'PropertyAddress', the columns created from 'OwnerAddress' are 'Virtual Generated' columns and they are NOT on actual disk space. 
-- Hence 'OwnerAddress' has a generated column dependency and when we try to delete this column the action returns an error as:
-- 'Error Code: 3108. Column 'OwnerAddress' has a generated column dependency.'

ALTER TABLE nashville_housing.nashville
    DROP COLUMN OwnerAddress;

SHOW CREATE TABLE nashville_housing.nashville;

-- Copy a table as a new one.
CREATE TABLE nashville_housing.nashville_cleaned
		LIKE nashville_housing.nashville;
