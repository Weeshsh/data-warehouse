IF OBJECT_ID('vETLAwariaWyciagu') IS NOT NULL 
    DROP VIEW vETLAwariaWyciagu;
GO

CREATE VIEW vETLAwariaWyciagu
AS
	SELECT 
		P.Koszt,
		D.ID_Data AS ID_Data_Awarii,
		D2.ID_Data AS ID_Data_Zakonczenia,
		H.ID_Wyciagu,
		AA.ID_Awarii,
		DATEDIFF(day, LP.Data_wykonania, P.Data_zdarzenia) AS DniOdPrzegladu
			FROM Goradol_Osrodek.dbo.Awarie P
				JOIN Goradol_Osrodek.dbo.Wyciagi W
					ON P.FK_Wyciag = W.ID
				LEFT JOIN Hurtownia_Goradol.dbo.Wyciag H
					ON W.Nazwa = H.Nazwa AND H.Czy_Aktualny = 1
				LEFT JOIN Hurtownia_Goradol.dbo.Data D
					ON P.Data_zdarzenia = D.Data
				LEFT JOIN Hurtownia_Goradol.dbo.Data D2
					ON P.Data_zakonczenia = D2.Data
				LEFT JOIN Goradol_Osrodek.dbo.Typy_Awarii TA
					ON TA.ID = P.FK_Typ
				LEFT JOIN Hurtownia_Goradol.dbo.Awaria AA
					ON AA.Nazwa = TA.Nazwa
				OUTER APPLY (
					SELECT TOP 1 *
					FROM Goradol_Osrodek.dbo.Przeglady PR
					WHERE PR.FK_Wyciag = P.FK_Wyciag
					  AND PR.Data_wykonania <= P.Data_zdarzenia
					ORDER BY PR.Data_wykonania DESC
				) LP;
GO

MERGE INTO Hurtownia_Goradol.dbo.Awaria_Wyciagu as TT
	USING vETLAwariaWyciagu as ST
		ON TT.Koszt = ST.Koszt
		AND TT.ID_DataAwarii = ST.ID_Data_Awarii
		AND TT.ID_DataNaprawy = ST.ID_Data_Zakonczenia
		AND TT.ID_Wyciagu = ST.ID_Wyciagu
		AND TT.ID_Awarii = ST.ID_Awarii
		AND TT.IleDniOdPrzegladu = ST.DniOdPrzegladu 
			WHEN Not Matched
				THEN
					INSERT
					Values (
					ST.ID_Data_Awarii,
					ST.ID_Data_Zakonczenia,
					ST.ID_Wyciagu,
					ST.ID_Awarii,
					ST.DniOdPrzegladu,
					ST.Koszt)
			WHEN Not Matched By Source
				THEN DELETE;

Drop View vETLAwariaWyciagu ;
