IF (object_id('vETLDimWyciag') is not null) DROP VIEW vETLDimWyciag;
GO

CREATE VIEW vETLDimWyciag
AS
	SELECT DISTINCT
		ID,
		Nazwa,
		Trudnosc,
		CASE
			WHEN Czas_zjazdu < 600 THEN 'krotka'
			WHEN Czas_zjazdu BETWEEN 601 AND 1200 THEN 'umiarkowana'
			ELSE 'dluga'
		END AS DlugoscPrzejazdu
	FROM Goradol_Osrodek.dbo.Wyciagi
GO

MERGE INTO Hurtownia_Goradol.dbo.Wyciag AS TT
	USING vETLDimWyciag AS ST
		ON  TT.Nazwa = ST.Nazwa
		AND TT.Trudnosc = ST.Trudnosc
		AND TT.Dlugosc_Przjazdu = ST.DlugoscPrzejazdu
			WHEN Not Matched
				THEN 
					INSERT Values (ST.Nazwa, ST.DlugoscPrzejazdu, ST.Trudnosc, 1)
			WHEN Not Matched By Source
				THEN UPDATE SET TT.Czy_aktualny = 0;

DROP VIEW vETLDimWyciag;