# Project 3 Data Analysis
USE Pokemon;

# Question 1) What Pokemon Type combinations have not been done as of the generation this data is from?
WITH TypeCombos (DexNumber, FirstType, SecondType) AS (
SELECT	PT.DexNumber,
		A.TypeID,
        B.TypeID
FROM Pokemon_Type AS PT
INNER JOIN Pokemon_Type AS PT2 ON (PT.DexNumber = PT2.DexNumber)
INNER JOIN `Type` AS A ON (A.TypeID = PT.TypeID)
INNER JOIN `Type` AS B ON (B.TypeID = PT2.TypeID AND A.TypeID < B.TypeID)
)

SELECT	A.TypeName AS `First Type`,
		(CASE WHEN B.TypeID = A.TypeID THEN NULL ELSE B.TypeName END) AS `Second Type`
FROM `Type` AS A
JOIN `Type` AS B
WHERE (CASE WHEN B.TypeID = A.TypeID THEN NULL ELSE B.TypeID END) IS NOT NULL
	AND (A.TypeID, (CASE WHEN B.TypeID = A.TypeID THEN NULL ELSE B.TypeID END)) NOT IN (
		SELECT FirstType, SecondType
        FROM TypeCombos
    )
    AND ((CASE WHEN B.TypeID = A.TypeID THEN NULL ELSE B.TypeID END), A.TypeID) NOT IN (
		SELECT FirstType, SecondType
        FROM TypeCombos
    )
GROUP BY A.TypeName, A.TypeID, (CASE WHEN B.TypeID = A.TypeID THEN NULL ELSE B.TypeName END)
ORDER BY A.TypeID;

# Question 2) What are the most popular type combinations as of this generation of data?
WITH TypeCombosCount (DexNumber, FirstType, SecondType, ComboCount) AS (
SELECT	PT.DexNumber,
		A.TypeID,
        B.TypeID,
        COUNT(*) OVER (
			PARTITION BY A.TypeID, B.TypeID
        )
FROM Pokemon_Type AS PT
INNER JOIN Pokemon_Type AS PT2 ON (PT.DexNumber = PT2.DexNumber)
INNER JOIN `Type` AS A ON (A.TypeID = PT.TypeID)
INNER JOIN `Type` AS B ON (B.TypeID = PT2.TypeID AND A.TypeID < B.TypeID)
)

SELECT	T1.TypeName AS `First Type`,
        T2.TypeName AS `Second Type`,
        CONCAT(T1.TypeName, ' ', T2.TypeName) AS `Types Concatenated`,
		ComboCount AS `Pokemon Count`,
        DENSE_RANK() OVER (
			ORDER BY ComboCount DESC
        ) AS `Type Combo Rank`
FROM TypeCombosCount AS TC
INNER JOIN `Type` AS T1 ON (FirstType = T1.TypeID)
INNER JOIN `Type` AS T2 ON (SecondType = T2.TypeID)
GROUP BY FirstType, SecondType;

# Question 3) What is the most powerful type as of this generation of data? Types with fewer weaknesses and more powerful moves are more powerful than those that have many weaknesses and weaker moves
WITH MovePower (AvgMovePower, TypeID) AS (
SELECT	FORMAT(AVG(MovePower), 0),
		TypeID
FROM Move
WHERE MovePower IS NOT NULL
GROUP BY TypeID
ORDER BY AVG(MovePower) DESC
)

SELECT	TypeName,
		COUNT(CASE WHEN EffectiveID = 4 THEN 1 ELSE NULL END) AS WeaknessCount,
		COUNT(CASE WHEN EffectiveID = 3 THEN 1 ELSE NULL END) AS ImmunityCount,
        COUNT(CASE WHEN EffectiveID = 2 THEN 1 ELSE NULL END) AS ResistanceCount,
        AvgMovePower,
        RANK() OVER (
			ORDER BY	COUNT(CASE WHEN EffectiveID = 3 THEN 1 ELSE NULL END) DESC,
						COUNT(CASE WHEN EffectiveID = 2 THEN 1 ELSE NULL END) DESC,
                        COUNT(CASE WHEN EffectiveID = 4 THEN 1 ELSE NULL END) ASC,
                        AvgMovePower DESC                        
        ) AS StrengthRank
FROM Type_Chart
INNER JOIN `Type` ON (DefenseTypeID = TypeID)
INNER JOIN MovePower USING (TypeID)
GROUP BY DefenseTypeID;

# Question 4) Ranking of types and their pokemon count for each generation
# For this question/query I altered my data. I added a column to the Pokemon table that lists the generation the pokemon first appeared in
# I wanted to take a look at Pokemon type distributions over time. Since each main series game (or generation) comes about every 3 years, separating over generation was the best way to look at this data.
# This data is up to the beginning of generation 6.

# Update Table Data
ALTER TABLE Pokemon.Pokemon
ADD Generation INT NOT NULL DEFAULT 1;

UPDATE Pokemon.Pokemon
SET Generation = 1
WHERE DexNumber BETWEEN 1 AND 151;
UPDATE Pokemon.Pokemon
SET Generation = 2
WHERE DexNumber BETWEEN 152 AND 250;
UPDATE Pokemon.Pokemon
SET Generation = 3
WHERE DexNumber BETWEEN 251 AND 386.3;
UPDATE Pokemon.Pokemon
SET Generation = 4
WHERE DexNumber BETWEEN 387 AND 493;
UPDATE Pokemon.Pokemon
SET Generation = 5
WHERE DexNumber BETWEEN 494 AND 649;
# NOTE: Generation 6 gets weird and added some new versions of old pokemon, thus the need to add the IN statement with the specific IDs of those older pokemon
UPDATE Pokemon.Pokemon
SET Generation = 6
WHERE DexNumber BETWEEN 650 AND 718
	OR DexNumber IN (3.1, 6.1, 6.2, 9.1, 65.1, 94.1, 115.1, 127.1, 130.1, 142.1, 150.1, 150.2, 181.1, 212.1, 214.1, 229.1, 248.1);
    
# Getting how many pokemon of each type are in each generation. Dual type Pokemon will count for both types they are part of.
SELECT	T.TypeName AS `Type Name`,
		COUNT(CASE WHEN P.Generation = 1 AND PT.TypeID = T.TypeID THEN 1 ELSE NULL END) AS `Generation 1 Counts`,
        COUNT(CASE WHEN P.Generation = 2 AND PT.TypeID = T.TypeID THEN 1 ELSE NULL END) AS `Generation 2 Counts`,
        COUNT(CASE WHEN P.Generation = 3 AND PT.TypeID = T.TypeID THEN 1 ELSE NULL END) AS `Generation 3 Counts`,
        COUNT(CASE WHEN P.Generation = 4 AND PT.TypeID = T.TypeID THEN 1 ELSE NULL END) AS `Generation 4 Counts`,
        COUNT(CASE WHEN P.Generation = 5 AND PT.TypeID = T.TypeID THEN 1 ELSE NULL END) AS `Generation 5 Counts`,
        COUNT(CASE WHEN P.Generation = 6 AND PT.TypeID = T.TypeID THEN 1 ELSE NULL END) AS `Generation 6 Counts`
FROM Pokemon_Type AS PT
INNER JOIN `Type` AS T USING (TypeID)
INNER JOIN Pokemon AS P USING (DexNumber)
GROUP BY T.TypeName;


# Question 5: What is the weakest Pokemon of each type? The strongest?
# Base Stat total will be used to determine strength of Pokemon
# NOTE: A dual type Pokemon could be the weakest for both of its types.
# NOTE: There are quite a few pokemon that are considered legendary, mythical, pseudo-legendary, or special in some other way. These Pokemon are literally the strongest in the games, so I have excluded them.
#		They are not very common pokemon so I don't think they should be included

# Weakest Pokemon of each type
WITH BSTMin (TypeID, TypeName, MinBST) AS (
SELECT	T.TypeID,
		T.TypeName,
		MIN(P.BaseStatTotal)
FROM Pokemon AS P
INNER JOIN Pokemon_Type AS PT USING (DexNumber)
INNER JOIN `Type` AS T USING (TypeID)
GROUP BY T.TypeID, T.TypeName
)

SELECT	BST.TypeName,
		P.PkmnName,
        BST.MinBST
FROM Pokemon AS P
INNER JOIN Pokemon_Type AS PT USING (DexNumber)
INNER JOIN BSTMin AS BST USING (TypeID)
WHERE PT.TypeID = BST.TypeID
	AND BST.MinBST >= P.BaseStatTotal
ORDER BY BST.MinBST ASC;

# Strongest Pokemon of each type
# Excluding legendary, mythical, pseudo-legendary, and mega evolutions
WITH BSTMax (TypeID, TypeName, MaxBST) AS (
SELECT	T.TypeID,
		T.TypeName,
        MAX(P.BaseStatTotal)
FROM Pokemon AS P
INNER JOIN Pokemon_Type AS PT USING (DexNumber)
INNER JOIN `Type` AS T USING (TypeID)
WHERE P.BaseStatTotal < 550
GROUP BY T.TypeID, T.TypeName
)

SELECT	BST.TypeName,
		P.PkmnName,
        BST.MaxBST
FROM Pokemon AS P
INNER JOIN Pokemon_Type AS PT USING (DexNumber)
INNER JOIN BSTMax AS BST USING (TypeID)
WHERE PT.TypeID = BST.TypeID
	AND BST.MaxBST = P.BaseStatTotal
ORDER BY BST.MaxBST DESC;

