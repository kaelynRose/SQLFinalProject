# Project 2 Database Definition
# DROP SCHEMA IF EXISTS Pokemon;

CREATE SCHEMA IF NOT EXISTS PokemonDB;
USE Pokemon;

# Drop tables if they exist
DROP TABLE IF EXISTS `Type_Chart`;
DROP TABLE IF EXISTS `Effectiveness`;
DROP TABLE IF EXISTS `Evolution`;
DROP TABLE IF EXISTS `Evolution_Type`;
DROP TABLE IF EXISTS `TM`;
DROP TABLE IF EXISTS `Move`;
DROP TABLE IF EXISTS `Pokemon_Type`;
DROP TABLE IF EXISTS `Pokemon`;
DROP TABLE IF EXISTS `Type`;

# Create tables
CREATE TABLE `Effectiveness` (
	EffectiveID		INTEGER			AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Effectiveness	VARCHAR(20)		NOT NULL,
    Multiplier		DECIMAL(2,1)	NOT NULL
);

CREATE TABLE `Evolution_Type` (
	EvoTypeID		INTEGER			AUTO_INCREMENT NOT NULL PRIMARY KEY,
    EvoName			VARCHAR(10)		NOT NULL
);

CREATE TABLE `Evolution` (
	EvoID			INTEGER			AUTO_INCREMENT NOT NULL PRIMARY KEY,
    EvoLevel		INTEGER			NULL,
    EvoCondition	VARCHAR(100)		NULL,
    Pkmn_EvoFrom	DECIMAL(5,1)	NOT NULL,
    Pkmn_EvoTo		DECIMAL(5,1)	NOT NULL,
    EvoTypeID		INTEGER			NOT NULL
);

CREATE TABLE `Move` (
	MoveID			INTEGER			AUTO_INCREMENT NOT NULL PRIMARY KEY,
    MoveName		VARCHAR(20)		NOT NULL,
    Category		ENUM('Physical', 'Special', 'Status', 'Dynamax Move', 'G-Max Move', 'Z-Move')	NOT NULL,
    MovePower		INTEGER			NULL,
    Accuracy		INTEGER			NULL,
    PP				INTEGER			NULL,
    Probability		INTEGER			NULL,
    SideEffect		VARCHAR(125)	NULL,
    TypeID			INTEGER			NOT NULL
);

CREATE TABLE `Pokemon_Type` (
	TypeID			INTEGER			NOT NULL,
    DexNumber		DECIMAL(5,1)	NOT NULL,
    PRIMARY KEY(TypeID, DexNumber)
);

CREATE TABLE `Pokemon` (
	DexNumber		DECIMAL(5,1)	NOT NULL PRIMARY KEY,
    PkmnName		VARCHAR(30)		NOT NULL,
    BaseStatTotal	INTEGER			NOT NULL,
    HP				INTEGER			NOT NULL,
    Attack			INTEGER			NOT NULL,
    Defense			INTEGER			NOT NULL,
    SpAttack		INTEGER			NOT NULL,
    SpDefense		INTEGER			NOT NULL,
    Speed			INTEGER			NOT NULL
);

CREATE TABLE `TM` (
	TMID			CHAR(5)			NOT NULL PRIMARY KEY,
    MoveID			INTEGER			NOT NULL
);

CREATE TABLE `Type_Chart` (
	AttackTypeID	INTEGER			NOT NULL,
    DefenseTypeID	INTEGER			NOT NULL,
    EffectiveID		INTEGER			NOT NULL,
    PRIMARY KEY(AttackTypeID, DefenseTypeID)
);

CREATE TABLE `Type` (
	TypeID 			INTEGER 		AUTO_INCREMENT NOT NULL PRIMARY KEY,
    TypeName 		VARCHAR(10)		NOT NULL
);

# Define relationships
ALTER TABLE `Evolution`
ADD CONSTRAINT FK_EvoTypeID FOREIGN KEY (EvoTypeID)
	REFERENCES `Evolution_Type`(EvoTypeID),
ADD CONSTRAINT FK_EvolveFrom FOREIGN KEY (Pkmn_EvoFrom)
	REFERENCES `Pokemon`(DexNumber),
ADD CONSTRAINT FK_EvolveTo FOREIGN KEY (Pkmn_EvoTo)
	REFERENCES `Pokemon`(DexNumber);

ALTER TABLE `Move`
ADD CONSTRAINT FK_MoveTypeID FOREIGN KEY (TypeID)
	REFERENCES `Type`(TypeID);

ALTER TABLE `Pokemon_Type`
ADD CONSTRAINT FK_PkmnTypeID FOREIGN KEY (TypeID)
	REFERENCES `Type`(TypeID),
ADD CONSTRAINT FK_DexNumber FOREIGN KEY (DexNumber)
	REFERENCES `Pokemon`(DexNumber);
    
ALTER TABLE `TM`
ADD CONSTRAINT FK_TMMoveID FOREIGN KEY (MoveID)
	REFERENCES `Move`(MoveID);

ALTER TABLE `Type_Chart`
ADD CONSTRAINT FK_AttackTypeID FOREIGN KEY (AttackTypeID)
	REFERENCES `Type`(TypeID),
ADD CONSTRAINT FK_DefenseTypeID FOREIGN KEY (DefenseTypeID)
	REFERENCES `Type`(TypeID),
ADD CONSTRAINT FK_EffectiveID FOREIGN KEY (EffectiveID)
	REFERENCES `Effectiveness`(EffectiveID);

# Define constraints
ALTER TABLE `Move`
ADD CONSTRAINT MoveName_Unique UNIQUE (MoveName);

# Indexes
CREATE INDEX IX_PokemonName
	ON `Pokemon`(PkmnName);
    
CREATE INDEX IX_MoveName
	ON `Move`(MoveName);