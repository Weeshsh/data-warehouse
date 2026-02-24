USE Hurtownia_Goradol;
GO

DECLARE @StartDate date = '2024-11-01';
DECLARE @EndDate   date = '2026-02-28';

INSERT INTO Data (Data, Miesiac, Tydzien, Dzien, Rok, Dzien_Tygodnia)
SELECT 
    D.Data,
    MONTH(D.Data) AS Miesiac,
    DATEPART(WEEK, D.Data) AS Tydzien,
    DAY(D.Data) AS Dzien,
    YEAR(D.Data) AS Rok,
    DATEPART(WEEKDAY, D.Data) AS Dzien_Tygodnia
FROM (
    SELECT DATEADD(DAY, n.number, @StartDate) AS Data
    FROM master..spt_values AS n
    WHERE n.type = 'P'
      AND n.number BETWEEN 0 AND DATEDIFF(DAY, @StartDate, @EndDate)
) AS D
ORDER BY D.Data;
GO