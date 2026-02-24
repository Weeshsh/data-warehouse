IF (object_id('vETLDimAwaria') is not null) DROP VIEW vETLDimAwaria;
GO

CREATE VIEW vETLDimAwaria
AS
	SELECT DISTINCT Nazwa,Opis
	FROM Goradol_Osrodek.dbo.Typy_Awarii
GO

MERGE INTO Hurtownia_Goradol.dbo.Awaria AS TT
	USING vETLDimAwaria AS ST
		ON TT.Nazwa = ST.Nazwa
		AND TT.Opis = ST.Opis
			WHEN Not Matched
				THEN INSERT Values (ST.Nazwa,ST.Opis)
			WHEN Not Matched By Source
				Then DELETE;

DROP VIEW vETLDimAwaria ;