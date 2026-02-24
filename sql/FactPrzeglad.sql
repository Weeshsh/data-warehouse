
IF (object_id('vETLPrzegladWyciagu') is not null) DROP VIEW vETLPrzegladWyciagu;
GO

CREATE VIEW vETLPrzegladWyciagu
AS
	SELECT 
		Koszt,D.ID_Data, H.ID_Wyciagu, T.ID_Czasu
	FROM Goradol_Osrodek.dbo.Przeglady P
		JOIN Goradol_Osrodek.dbo.Wyciagi W
			ON P.FK_Wyciag = W.ID
		LEFT JOIN Hurtownia_Goradol.dbo.Wyciag H
			ON W.Nazwa = H.Nazwa AND H.Czy_Aktualny = 1
		LEFT JOIN Hurtownia_Goradol.dbo.Data D
			 ON CAST(P.Data_wykonania AS DATE) = D.Data 
		LEFT JOIN Hurtownia_Goradol.dbo.Czas T
			ON DATEPART(HOUR, P.Data_wykonania) = T.Godzina
			AND DATEPART(MINUTE, P.Data_wykonania) = T.Minuta
GO


MERGE INTO Hurtownia_Goradol.dbo.Przeglad_Wyciagu AS TT
	USING vETLPrzegladWyciagu AS ST
		ON TT.Koszt = ST.Koszt
		AND TT.ID_Data = ST.ID_Data
		AND TT.ID_Wyciagu = ST.ID_Wyciagu
		AND TT.ID_Czas = ST.ID_Czasu
			WHEN Not Matched
				THEN INSERT Values (ST.ID_Data,ST.ID_Czasu, ST.ID_Wyciagu,ST.Koszt)
			WHEN Not Matched By Source
				THEN DELETE;

DROP VIEW vETLPrzegladWyciagu ;