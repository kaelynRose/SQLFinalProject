# Project 2 Data Population
USE Pokemon;
SET FOREIGN_KEY_CHECKS = 0;

# Truncate tables
TRUNCATE TABLE Effectiveness;
TRUNCATE TABLE Evolution;
TRUNCATE TABLE Evolution_Type;
TRUNCATE TABLE Move;
TRUNCATE TABLE Pokemon;
TRUNCATE TABLE Pokemon_Type;
TRUNCATE TABLE TM;
TRUNCATE TABLE `Type`;
TRUNCATE TABLE Type_Chart;

# Populate Effectiveness Table
INSERT INTO Effectiveness (Effectiveness, Multiplier)
SELECT DISTINCT Effectiveness, Multiplier
FROM _Staging_Type;

# Populate Type Table
INSERT INTO `Type` (TypeName)
SELECT DISTINCT Attack
FROM _Staging_Type
ORDER BY Attack ASC;

# Populate Evolution_Type Table
INSERT INTO Evolution_Type (EvoName)
SELECT DISTINCT `Evolution Type`
FROM _Staging_Evolution;

# Populate Pokemon Table
INSERT INTO Pokemon(DexNumber, PkmnName, BaseStatTotal, HP, Attack, Defense, SpAttack, SpDefense, Speed)
SELECT DISTINCT CAST(`#` AS DECIMAL(5,1)),
				`Name`,
				CAST(`Total` AS UNSIGNED),
				CAST(HP AS UNSIGNED),
				CAST(Attack AS UNSIGNED),
				CAST(Defense AS UNSIGNED),
				CAST(`Special Attack` AS UNSIGNED),
				CAST(`Special Defense` AS UNSIGNED),
				CAST(Speed AS UNSIGNED)
FROM _Staging_Pokemon;

# Populate Move Table
INSERT INTO Move(MoveName, Category, MovePower, Accuracy, PowerPoints, Probability, SideEffect, TypeID)
SELECT DISTINCT `Name`,
				`Cat.`,
                CAST(`Power` AS UNSIGNED),
                CAST(`Acc.` AS UNSIGNED),
                CAST(`PP` AS UNSIGNED),
                CAST(`Prob. (%)` AS UNSIGNED),
                `Effect`,
                TypeID
FROM _Staging_Moves AS ST
INNER JOIN `Type` AS T ON (ST.`Type` = T.TypeName);

# Populate Type_Chart Table
INSERT INTO Type_Chart(AttackTypeID, DefenseTypeID, EffectiveID)
SELECT	TA.TypeID AS Attack_TypeID,
        TD.TypeID AS Defense_TypeID,
        EffectiveID
FROM ((_Staging_Type AS ST
	INNER JOIN `Type` AS TA ON (ST.Attack = TA.TypeName))
		INNER JOIN `Type` AS TD ON (ST.Defense = TD.TypeName))
			INNER JOIN Effectiveness USING (Effectiveness)
ORDER BY Attack_TypeID;

# Populate Pokemon_Type Table
INSERT IGNORE INTO Pokemon_Type(TypeID, DexNumber)
SELECT	TypeID,
		DexNumber
FROM (Pokemon AS P
	INNER JOIN _Staging_Pokemon AS ST ON (ST.`Name` = P.PkmnName))
		INNER JOIN `Type` AS T ON (ST.`Type` = T.TypeName)
ORDER BY DexNumber;

# Populate TM Table
INSERT INTO TM(TMID, MoveID)
SELECT	TM,
        MoveID
FROM _Staging_Moves AS ST
INNER JOIN Move AS M On (ST.`Name` = M.MoveName)
WHERE ST.TM != ''
ORDER BY TM ASC;

# Populate Evolution Table
INSERT INTO Evolution(EvoLevel, EvoCondition, Pkmn_EvoFrom, Pkmn_EvoTo, EvoTypeID)
SELECT		CAST(`Level` AS UNSIGNED),
			`Condition`,
            PF.DexNumber AS DexNumber_EvoFrom,
            PT.DexNumber AS DexNumber_EvoTo,
            EvoTypeID
FROM ((_Staging_Evolution AS ST
	INNER JOIN Pokemon AS PF ON (ST.`Evolving From` = PF.PkmnName))
		INNER JOIN Pokemon AS PT ON (ST.`Evolving To` = PT.PkmnName))
			INNER JOIN Evolution_Type AS E ON (ST.`Evolution Type` = E.EvoName)
ORDER BY DexNumber_EvoFrom;