IF DB_ID('Hurtownia_Goradol') IS NOT NULL
    DROP DATABASE Hurtownia_Goradol;
GO

CREATE DATABASE Hurtownia_Goradol;
GO

USE Hurtownia_Goradol;
GO

CREATE TABLE Wyciag (
    ID_Wyciagu INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(15) NOT NULL,
    Dlugosc_Przjazdu NVARCHAR(50) NULL,
    Trudnosc INT CHECK (Trudnosc BETWEEN 1 AND 5),
    Czy_Aktualny BIT DEFAULT 1
);


CREATE TABLE Przystoj (
    ID_Przystoju INT IDENTITY(1,1) PRIMARY KEY,
    Dlugosc NVARCHAR(20) NOT NULL
);


CREATE TABLE Awaria (
    ID_Awarii INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(120) NOT NULL,
    Opis NVARCHAR(500) NULL
);


CREATE TABLE Czas (
    ID_Czasu INT IDENTITY(1,1) PRIMARY KEY,
    Godzina INT CHECK (Godzina BETWEEN 0 AND 24),
    Minuta INT CHECK (Minuta BETWEEN 0 AND 59)
);


CREATE TABLE Data (
    ID_Data INT IDENTITY(1,1) PRIMARY KEY,
    Data DATE NOT NULL,
    Miesiac INT CHECK (Miesiac BETWEEN 1 AND 12),
    Tydzien INT CHECK (Tydzien BETWEEN 1 AND 53),
    Dzien INT CHECK (Dzien BETWEEN 1 AND 31),
    Rok INT CHECK (Rok BETWEEN 2000 AND 2100),
    Dzien_Tygodnia INT CHECK (Dzien_Tygodnia BETWEEN 1 AND 7)
);


CREATE TABLE Przejazd_Narciarza (
    ID_Przejazdu INT IDENTITY(1,1) PRIMARY KEY,
    ID_Wyciag_Startowy INT NOT NULL,
    ID_Wyciag_Koncowy INT NOT NULL,
    ID_Czas_Startu INT NOT NULL,
    ID_Czas_Konca INT NOT NULL,
    ID_Daty INT NOT NULL,
    ID_Przystoju INT NOT NULL,
    Dlugosc_Zjazdu NUMERIC(10,2),
    Przewidywana_Dlugosc_Zjazdu NUMERIC(10,2),
    Dlugosc_Przystojow NUMERIC(10,2),
    Dlugosc_Kolejki NUMERIC(10,2),
    CONSTRAINT FK_Przejazd_WyciagStart FOREIGN KEY (ID_Wyciag_Startowy) REFERENCES Wyciag(ID_Wyciagu),
    CONSTRAINT FK_Przejazd_WyciagKoniec FOREIGN KEY (ID_Wyciag_Koncowy) REFERENCES Wyciag(ID_Wyciagu),
    CONSTRAINT FK_Przejazd_CzasStart FOREIGN KEY (ID_Czas_Startu) REFERENCES Czas(ID_Czasu),
    CONSTRAINT FK_Przejazd_CzasKoniec FOREIGN KEY (ID_Czas_Konca) REFERENCES Czas(ID_Czasu),
    CONSTRAINT FK_Przejazd_Data FOREIGN KEY (ID_Daty) REFERENCES Data(ID_Data),
    CONSTRAINT FK_Przejazd_Przystoj FOREIGN KEY (ID_Przystoju) REFERENCES Przystoj(ID_Przystoju)
);


CREATE TABLE Przeglad_Wyciagu (
    ID_Przegladu INT IDENTITY(1,1) PRIMARY KEY,
    ID_Data INT NOT NULL,
    ID_Czas INT NOT NULL,
    ID_Wyciagu INT NOT NULL,
    Koszt MONEY,
    CONSTRAINT FK_Przeglad_Data FOREIGN KEY (ID_Data) REFERENCES Data(ID_Data),
    CONSTRAINT FK_Przeglad_Czas FOREIGN KEY (ID_Czas) REFERENCES Czas(ID_Czasu),
    CONSTRAINT FK_Przeglad_Wyciag FOREIGN KEY (ID_Wyciagu) REFERENCES Wyciag(ID_Wyciagu)
);


CREATE TABLE Awaria_Wyciagu (
    ID_Awaria_Wyciagu INT IDENTITY(1,1) PRIMARY KEY,
    ID_DataAwarii INT NOT NULL,
    ID_DataNaprawy INT NOT NULL,
    ID_Wyciagu INT NOT NULL,
    ID_Awarii INT NOT NULL,
    IleDniOdPrzegladu INT,
    Koszt MONEY,
    CONSTRAINT FK_Awaria_DataAwarii FOREIGN KEY (ID_DataAwarii) REFERENCES Data(ID_Data),
    CONSTRAINT FK_Awaria_DataNaprawy FOREIGN KEY (ID_DataNaprawy) REFERENCES Data(ID_Data),
    CONSTRAINT FK_Awaria_Wyciag FOREIGN KEY (ID_Wyciagu) REFERENCES Wyciag(ID_Wyciagu),
    CONSTRAINT FK_Awaria_Typ FOREIGN KEY (ID_Awarii) REFERENCES Awaria(ID_Awarii)
);

CREATE INDEX IX_Przejazd_Data ON Przejazd_Narciarza(ID_Daty);
CREATE INDEX IX_Przeglad_Data ON Przeglad_Wyciagu(ID_Data);
CREATE INDEX IX_Awaria_DataAwarii ON Awaria_Wyciagu(ID_DataAwarii);
CREATE INDEX IX_Awaria_DataNaprawy ON Awaria_Wyciagu(ID_DataNaprawy);
