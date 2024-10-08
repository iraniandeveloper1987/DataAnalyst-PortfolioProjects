/*
    Author: Ali
    Date: [Insert Date Here]
    Description: Cleaning Nashville Housing Data using SQL Queries. This script includes steps to standardize formats, handle missing values, split address data, update boolean values, remove duplicates, and delete unused columns.
*/

-- ----------------------------------------------------------------------------
--                     Standardize Data Format

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate);

-- ----------------------------------------------------------------------------
--                     Populate Property Address Data

-- Check for missing Property Addresses
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Retrieve missing PropertyAddress by matching ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) AS UpdatedAddress
FROM NashvilleHousing AS a 
INNER JOIN NashvilleHousing AS b
ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update missing PropertyAddress
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a 
INNER JOIN NashvilleHousing AS b
ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- ----------------------------------------------------------------------------
--                     Breaking Out Address Into Individual Columns (Address, City, State)

-- Split PropertyAddress into Address and City
SELECT
    PropertyAddress,
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS PropertySplitAddress,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS PropertySplitCity
FROM NashvilleHousing;

-- Add new columns to store split Address and City
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255), PropertySplitCity NVARCHAR(255);

-- Populate PropertySplitAddress and PropertySplitCity
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split OwnerAddress into Address, City, and Province
SELECT
    OwnerAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitProvince
FROM NashvilleHousing;

-- Add new columns to store split OwnerAddress, City, and Province
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255), OwnerSplitProvince NVARCHAR(255);

-- Populate OwnerSplitAddress, OwnerSplitCity, and OwnerSplitProvince
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE NashvilleHousing
SET OwnerSplitProvince = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- ----------------------------------------------------------------------------
--                     Change 'Y' and 'N' to 'Yes' and 'No' in "SoldAsVacant" Field

-- Check current distinct values in SoldAsVacant
SELECT DISTINCT SoldAsVacant
FROM NashvilleHousing;

-- Count occurrences of each SoldAsVacant value
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Update 'Y' to 'Yes' and 'N' to 'No'
SELECT 
    SoldAsVacant, 
    CASE 
        WHEN SoldAsVacant = 'N' THEN 'No'
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        ELSE SoldAsVacant
    END AS UpdatedSoldAsVacant
FROM NashvilleHousing;

-- Apply the changes in the SoldAsVacant field
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
                      WHEN SoldAsVacant = 'N' THEN 'No'
                      WHEN SoldAsVacant = 'Y' THEN 'Yes'
                      ELSE SoldAsVacant
                   END;

-- ----------------------------------------------------------------------------
--                     Remove Duplicates

WITH RowNumberCTE AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
    ORDER BY UniqueID) AS RowNumber, *
    FROM NashvilleHousing
)

-- Preview duplicate rows
SELECT * 
FROM RowNumberCTE 
WHERE RowNumber > 1;

-- Uncomment to delete duplicates
-- DELETE 
-- FROM RowNumberCTE 
-- WHERE RowNumber > 1;

-- ----------------------------------------------------------------------------
--                     Delete Unused Columns

-- Remove unnecessary columns
ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate;

-- Preview final cleaned data
SELECT * 
FROM NashvilleHousing;
