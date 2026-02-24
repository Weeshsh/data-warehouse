IF (object_id('dbo.PrzejazdTemp') is not null) DROP TABLE dbo.PrzejazdTemp;
CREATE TABLE dbo.PrzejazdTemp (
    ID INT PRIMARY KEY,
    Timestamp DATETIME2 NOT NULL,
    ID_Wyc INT NOT NULL,
    ID_Karty INT NOT NULL
);
GO

BULK INSERT dbo.PrzejazdTemp
FROM 'C:\Users\mikow\OneDrive\Pulpit\EVERYTHING\studia\sem5\hurtownie-danych\laby\full-hd\lab2\snapshot_1\logi_bramek.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

IF (object_id('vETLPrzejazdNarciarza') is not null) DROP VIEW vETLPrzejazdNarciarza;
GO

CREATE VIEW vETLPrzejazdNarciarza
AS
    WITH CalculatedMoves AS (
        SELECT 
            ID_Wyc,
            Timestamp,
            ID_Karty,
            LEAD(ID_Wyc) OVER (
                PARTITION BY ID_Karty, CAST(Timestamp AS DATE) 
                ORDER BY Timestamp ASC
            ) AS Nastepny_Wyciag,
            
            LEAD(Timestamp) OVER (
                PARTITION BY ID_Karty, CAST(Timestamp AS DATE) 
                ORDER BY Timestamp ASC
            ) AS Nastepny_Zjazd
        FROM dbo.PrzejazdTemp)
    SELECT 
        WS.ID_Wyciagu AS ID_Wyciag_Startowy,
        ISNULL(WK.ID_Wyciagu, WS.ID_Wyciagu) AS ID_Wyciag_Koncowy,
        T_Start.ID_Czasu AS ID_Czas_Startu,
        ISNULL(T_End.ID_Czasu, T_Start.ID_Czasu) AS ID_Czas_Konca,
        D.ID_Data AS ID_Daty,
        ISNULL(P.ID_Przystoju, -1) AS ID_Przystoju,
        ISNULL(DATEDIFF(MINUTE, CM.Timestamp, CM.Nastepny_Zjazd), 0) AS Dlugosc_Zjazdu,
        CAST(ISNULL(Wdb.Czas_zjazdu, 0) AS INT) AS Przewidywana_Dlugosc_Zjazdu,
        SumatorPrzystojow.Suma_Przystojow AS Dlugosc_Przystojow,
       CASE 
    WHEN (
        (ISNULL(DATEDIFF(MINUTE, CM.Timestamp, CM.Nastepny_Zjazd), 0) * 60)
        - CAST(ISNULL(Wdb.Czas_zjazdu, 0) AS INT)
        - SumatorPrzystojow.Suma_Przystojow * 60
    ) < 0 THEN 0

    WHEN (
        (ISNULL(DATEDIFF(MINUTE, CM.Timestamp, CM.Nastepny_Zjazd), 0) * 60)
        - CAST(ISNULL(Wdb.Czas_zjazdu, 0) AS INT)
        - SumatorPrzystojow.Suma_Przystojow * 60
    ) > 60 THEN 0

    ELSE (
        (ISNULL(DATEDIFF(MINUTE, CM.Timestamp, CM.Nastepny_Zjazd), 0) * 60)
        - CAST(ISNULL(Wdb.Czas_zjazdu, 0) AS INT)
        - SumatorPrzystojow.Suma_Przystojow * 60
    )
END AS Dlugosc_Kolejki

    FROM CalculatedMoves CM
        JOIN Hurtownia_Goradol.dbo.Wyciag WS 
            ON CM.ID_Wyc = WS.ID_Wyciagu 
            AND WS.Czy_Aktualny = 1 
        LEFT JOIN Goradol_Osrodek.dbo.Wyciagi Wdb
            ON WS.Nazwa= Wdb.Nazwa
        LEFT JOIN Hurtownia_Goradol.dbo.Wyciag WK 
            ON CM.Nastepny_Wyciag = WK.ID_Wyciagu
            AND WK.Czy_Aktualny = 1
        LEFT JOIN Hurtownia_Goradol.dbo.Data D 
            ON CAST(CM.Timestamp AS DATE) = D.Data 
        LEFT JOIN Hurtownia_Goradol.dbo.Czas T_Start 
            ON DATEPART(HOUR, CM.Timestamp) = T_Start.Godzina 
            AND DATEPART(MINUTE, CM.Timestamp) = T_Start.Minuta
        LEFT JOIN Hurtownia_Goradol.dbo.Czas T_End 
            ON DATEPART(HOUR, CM.Nastepny_Zjazd) = T_End.Godzina 
            AND DATEPART(MINUTE, CM.Nastepny_Zjazd) = T_End.Minuta
        CROSS APPLY (
            SELECT ISNULL(SUM(Pdb.Dlugosc_przystoju), 0) AS Suma_Przystojow
            FROM Goradol_Osrodek.dbo.Przystoje Pdb
            WHERE Pdb.FK_Wyciag = Wdb.ID 
              AND CAST(Pdb.Data_zdarzenia AS DATETIME2) >= CM.Timestamp
              AND CAST(Pdb.Data_zdarzenia AS DATETIME2) < ISNULL(CM.Nastepny_Zjazd, DATEADD(MINUTE, 120, CM.Timestamp))
        ) AS SumatorPrzystojow
        LEFT JOIN Hurtownia_Goradol.dbo.Przystoj P
            ON P.Dlugosc = 
                CASE 
                    WHEN SumatorPrzystojow.Suma_Przystojow = 0 THEN 'Brak'
                    WHEN SumatorPrzystojow.Suma_Przystojow < 2 THEN '<2 minuty'
                    WHEN SumatorPrzystojow.Suma_Przystojow BETWEEN 2 AND 5 THEN '2-5 minut'
                    ELSE '>5 minut'
                END
    WHERE CM.Nastepny_Zjazd IS NOT NULL
GO

MERGE INTO Hurtownia_Goradol.dbo.Przejazd_Narciarza AS TT
    USING vETLPrzejazdNarciarza AS ST
        ON TT.ID_Wyciag_Startowy = ST.ID_Wyciag_Startowy
        AND TT.ID_Daty = ST.ID_Daty
        AND TT.ID_Czas_Startu = ST.ID_Czas_Startu
        AND TT.ID_Wyciag_Koncowy = ST.ID_Wyciag_Koncowy
        AND TT.ID_Czas_Konca = ST.ID_Czas_Konca
        AND TT.ID_Przystoju = ST.ID_Przystoju
            WHEN NOT MATCHED THEN 
                INSERT 
                VALUES (
                    ST.ID_Wyciag_Startowy,
                    ST.ID_Wyciag_Koncowy,
                    ST.ID_Czas_Startu,
                    ST.ID_Czas_Konca,
                    ST.ID_Daty,
                    ST.ID_Przystoju,
                    ST.Dlugosc_Zjazdu,
                    ST.Przewidywana_Dlugosc_Zjazdu,
                    ST.Dlugosc_Przystojow,
                    ST.Dlugosc_Kolejki)
            WHEN NOT MATCHED BY SOURCE 
                THEN DELETE;

DROP VIEW vETLPrzejazdNarciarza;
DROP TABLE dbo.PrzejazdTemp;