/*
CLEANING NASHVILLE HOUSING DATA
*/

SELECT *
FROM HousingData

----------------------------------------------------------------------------------

--Standardize Date format

--Method 1: change datatype of SaleDate from datetime -> date
ALTER TABLE HousingData
ALTER COLUMN SaleDate Datetime

--Method 2: add a new column with date datatype and insert data from SaleDate into it
ALTER TABLE HousingData
ADD ConvertedSaleDate date

UPDATE HousingData
SET ConvertedSaleDate = CONVERT(Date, SaleDate)

SELECT SaleDate, ConvertedSaleDate
FROM HousingData

----------------------------------------------------------------------------------

--Populate Property Address data, since they can be null

SELECT *
FROM HousingData
WHERE PropertyAddress IS NULL

--Method 1: Using nested queries
SELECT * FROM HousingData --Get data of those have ParcelID has count > 1, and 1 or more NULL PropertyAddress
WHERE ParcelID IN (
	SELECT ParcelID FROM HousingData --Get ParcelID of those has count > 1 and PropertyAddress IS NULL
	WHERE ParcelID IN (
		SELECT ParcelID --Get ParcelID that has Count over 1
		FROM HousingData
		GROUP BY ParcelID
		HAVING COUNT(ParcelID) > 1
	)
	AND PropertyAddress IS NULL
)

--Method 2: Using JOIN (join HousingData with itself to see comparison) 
--*Note: this table can have duplicates
--ex: ParcelID 034 03 0 059.00 has 3 Unique ID: 33057, 36531, 36532 (36531 has NULL) => 36531 links 33057, 36531 links 36532 => 2 rows of 36531
SELECT self1.[UniqueID ],self1.ParcelID, self1.PropertyAddress, self2.ParcelID, self2.PropertyAddress
FROM HousingData self1
JOIN HousingData self2
  ON self1.ParcelID = self2.ParcelID
  AND self1.[UniqueID ] != self2.[UniqueID ]
WHERE self1.PropertyAddress IS NULL

--After having rows of NULL PropertyAddress, we update those
UPDATE self1
SET PropertyAddress = ISNULL(self1.PropertyAddress, self2.PropertyAddress)
FROM HousingData self1
JOIN HousingData self2
  ON self1.ParcelID = self2.ParcelID
  AND self1.[UniqueID ] != self2.[UniqueID ]
WHERE self1.PropertyAddress IS NULL


----------------------------------------------------------------------------------

--Breaking out address into separated columns (Address, City, State)

--Use SUBSTRING to break PropertyAddress
SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM HousingData

--Create columns for separated address and city, and insert data into them
ALTER TABLE HousingData
ADD SeparatedAddress nvarchar(255)

UPDATE HousingData
SET SeparatedAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE HousingData
ADD SeparatedCity nvarchar(255)

UPDATE HousingData
SET SeparatedCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT SeparatedAddress, SeparatedCity
FROM HousingData

--Use PARSENAME to break OwnerAddress
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM HousingData

ALTER TABLE HousingData
ADD SeparatedOwnerAddress nvarchar(255)

UPDATE HousingData
SET SeparatedOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE HousingData
ADD SeparatedOwnerCity nvarchar(255)

UPDATE HousingData
SET SeparatedOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE HousingData
ADD SeparatedOwnerState nvarchar(255)

UPDATE HousingData
SET SeparatedOwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT SeparatedOwnerAddress, SeparatedOwnerCity, SeparatedOwnerState
FROM HousingData


----------------------------------------------------------------------------------

--Change N -> No, Y -> Yes in SoldAsVacant

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM HousingData
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'N' THEN 'No'
     WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 ELSE SoldAsVacant
END
FROM HousingData

UPDATE HousingData
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'N' THEN 'No'
     WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 ELSE SoldAsVacant
END


----------------------------------------------------------------------------------

--Remove Duplicates

WITH CTE_rownum AS (
	SELECT *,
		ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SaleDate,
					 SalePrice,
					 LegalReference
					 ORDER BY UniqueID
					 ) row_num --NOTE: This means numbering row numbers for duplicates, first one as 1, duplicates as 2,3,4, 
							   --Based on ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference.
							   --This make senses because duplicates will have those in same
	FROM HousingData
)
--DELETE FROM CTE_rownum
--WHERE row_num > 1
SELECT * FROM CTE_rownum WHERE row_num > 1


----------------------------------------------------------------------------------

--Delete Unused Columns

--Create tmp table to prevent touching original database
select top 0 *
into #tmp
from HousingData

INSERT INTO #tmp
SELECT * FROM HousingData

SELECT * FROM #tmp

ALTER TABLE #tmp
DROP COLUMN TaxDistrict

drop table #tmp
