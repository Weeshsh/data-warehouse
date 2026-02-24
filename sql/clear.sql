USE Hurtownia_Goradol

EXEC sp_MSforeachtable "DELETE FROM ?";
EXEC sp_MSforeachtable "DBCC CHECKIDENT ('?', RESEED, 0)";