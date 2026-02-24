USE Hurtownia_Goradol;
GO

INSERT INTO Czas (Godzina, Minuta)
SELECT 
    RIGHT('0' + CAST(H.number AS nvarchar(2)), 2) AS Godzina,
    RIGHT('0' + CAST(M.number AS nvarchar(2)), 2) AS Minuta
FROM master..spt_values AS H
CROSS JOIN master..spt_values AS M
WHERE H.type = 'P' AND H.number BETWEEN 0 AND 23
  AND M.type = 'P' AND M.number BETWEEN 0 AND 59
ORDER BY H.number, M.number;
GO