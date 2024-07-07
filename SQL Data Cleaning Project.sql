--- Nashville Housing Data cleaning using Sql 

SELECT* 
FROM nashvillehousingcsv;

--------------------------------------------------------------------------------------------------------------------------------------------

---- 1 Standardize  Date Format

SELECT saledate, 
STR_TO_DATE(saledate, '%M %d, %Y') 
AS converted_saledate
FROM nashvillehousingcsv;

update nashvillehousingcsv
set saledate = STR_TO_DATE(saledate, '%M %d, %Y');

--------------------------------------------------------------------------------------------------------------------------------------------

--- 2 Populate Property Address data

SELECT PropertyAddress
FROM nashvillehousingcsv
-- WHERE PropertyAddress is null
order by ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousingcsv a
JOIN nashvillehousingcsv b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL;

SET SQL_SAFE_UPDATES=0;

UPDATE nashvillehousingcsv a
JOIN nashvillehousingcsv b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

--- Breaking out Address into Individual Columns (Adress, State, City)

SELECT PropertyAddress
FROM nashvillehousingcsv;

SELECT 
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 )
AS Address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1,
LENGTH(PropertyAddress)) 
AS Address
FROM nashvillehousingcsv;

ALTER TABLE nashvillehousingcsv
ADD PropertySplitAddress NVARCHAR(255);

UPDATE nashvillehousingcsv
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1);

ALTER TABLE nashvillehousingcsv
ADD PropertySplitCity NVARCHAR(255);

UPDATE nashvillehousingcsv
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress));

SELECT* 
FROM nashvillehousingcsv;

--------------------------------------------------------------------------------------------------------------------------------------------

--- 3 Populate Owner Address data

SELECT OwnerAddress
FROM nashvillehousingcsv;

SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -3), '.', 1),
    SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -2), '.', 1),
    SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1), '.', 1)
FROM nashvillehousingcsv;

ALTER TABLE nashvillehousingcsv
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE nashvillehousingcsv
SET OwnerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -3), '.', 1);

ALTER TABLE nashvillehousingcsv
ADD OwnerSplitCity NVARCHAR(255);

UPDATE nashvillehousingcsv
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -2), '.', 1);

ALTER TABLE nashvillehousingcsv
ADD OwnerSplitState NVARCHAR(255);

UPDATE nashvillehousingcsv
SET OwnerSplitState = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1), '.', 1);

SELECT* 
FROM nashvillehousingcsv;

--------------------------------------------------------------------------------------------------------------------------------------------

--- 4 Change Y and N to Yes and No in "Solid as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashvillehousingcsv
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
 CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	  WHEN SoldAsVacant = 'N' THEN 'No'
      ELSE SoldAsVacant
END
FROM nashvillehousingcsv;

UPDATE nashvillehousingcsv
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	  WHEN SoldAsVacant = 'N' THEN 'No'
      ELSE SoldAsVacant
	  END;
      
--------------------------------------------------------------------------------------------------------------------------------------------

--- 5 Remove Duplicates 

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) row_num
FROM nashvillehousingcsv
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


DELETE FROM nashvillehousingcsv
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER (
                   PARTITION BY ParcelID, 
								PropertyAddress,
                                SalePrice, SaleDate,
                                LegalReference
                   ORDER BY UniqueID
               ) AS row_num
        FROM nashvillehousingcsv
    ) AS RowNumCTE
    WHERE row_num > 1
);

--------------------------------------------------------------------------------------------------------------------------------------------

--- 6 Delete Unused Columns 

SELECT *
FROM nashvillehousingcsv;

ALTER TABLE nashvillehousingcsv
DROP COLUMN OwnerAddress,
DROP COLUMN PropertyAddress,
DROP COLUMN TaxDistrict;

------------------------------------------------------------------------------------------------------------------------------------------
