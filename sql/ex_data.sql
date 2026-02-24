USE Hurtownia_Goradol;
GO

INSERT INTO Wyciag (Nazwa, Dlugosc_Przjazdu, Trudnosc, Czy_Aktualny) VALUES
('Wyciag A', 1200.50, 2, 1),
('Wyciag B', 950.00, 3, 1),
('Wyciag C', 1500.75, 4, 1),
('Wyciag D', 800.25, 1, 1),
('Wyciag E', 1700.00, 5, 0);

INSERT INTO Przystoj (Dlugosc) VALUES
('Brak'),
('<2 minuty'),
('2-5 minut'),
('>5 minut');

INSERT INTO Awaria (Nazwa, Opis) VALUES
('Awaria silnika','Problemy z praca jednostki napedowej.'),
('Awaria liny','Uszkodzenie, przetarcie lub zerwanie liny.'),
('Awaria czujnikow','Nieprawidlowy lub brakujacy odczyt z czujnikow.'),
('Awaria systemowa','Blad dzialania oprogr. lub ukladow sterujacych.'),
('Awaria wspornikow','Uszkodzenie lub poluzowanie el. konstrukcyjnych.');


INSERT INTO Przejazd_Narciarza (
    ID_Wyciag_Startowy, ID_Wyciag_Koncowy, ID_Czas_Startu, ID_Czas_Konca,
    ID_Daty, ID_Przystoju, Dlugosc_Zjazdu, Przewidywana_Dlugosc_Zjazdu,
    Dlugosc_Przystojow, Dlugosc_Kolejki
) VALUES
(1, 2, 1, 2, 1, 1, 900.00, 950.00, 0.00, 20.00),
(2, 3, 3, 4, 2, 3, 1000.00, 980.00, 2.50, 15.00),
(3, 4, 5, 6, 3, 1, 1100.50, 1200.00, 0.00, 25.00),
(4, 5, 7, 8, 4, 3, 800.00, 820.00, 3.00, 10.00),
(5, 1, 9, 10, 5, 4, 1500.00, 1400.00, 8.00, 40.00),
(2, 4, 11, 12, 6, 2, 950.00, 970.00, 1.00, 15.00),
(3, 5, 13, 14, 7, 2, 1050.00, 1070.00, 2.00, 18.00),
(4, 1, 15, 16, 8, 1, 870.00, 900.00, 0.50, 12.00),
(1, 3, 17, 18, 9, 3, 1230.00, 1250.00, 2.00, 22.00),
(2, 5, 19, 20, 10, 2, 980.00, 950.00, 1.50, 16.00),
(5, 2, 21, 22, 11, 3, 890.00, 910.00, 2.00, 19.00),
(4, 3, 23, 24, 12, 1, 970.00, 960.00, 0.00, 14.00),
(1, 5, 25, 26, 13, 2, 1300.00, 1280.00, 3.00, 28.00),
(3, 2, 27, 28, 14, 3, 780.00, 800.00, 2.50, 10.00),
(5, 4, 29, 30, 15, 3, 1550.00, 1500.00, 4.00, 35.00),
(2, 1, 31, 32, 16, 4, 920.00, 940.00, 1.00, 17.00),
(4, 2, 33, 34, 17, 2, 1000.00, 990.00, 1.50, 20.00),
(3, 1, 35, 36, 18, 1, 870.00, 860.00, 0.00, 15.00),
(1, 4, 37, 38, 19, 2, 1150.00, 1180.00, 2.00, 25.00),
(5, 3, 39, 40, 20, 4, 1400.00, 1350.00, 3.50, 30.00);


INSERT INTO Przeglad_Wyciagu (ID_Data, ID_Czas, ID_Wyciagu, Koszt) VALUES
(1, 1, 1, 500.00),
(2, 2, 2, 650.00),
(3, 3, 3, 800.00),
(4, 4, 4, 550.00),
(5, 5, 5, 1000.00),
(6, 6, 1, 520.00),
(7, 7, 2, 600.00),
(8, 8, 3, 850.00),
(9, 9, 4, 560.00),
(10, 10, 5, 950.00),
(11, 11, 1, 510.00),
(12, 12, 2, 670.00),
(13, 13, 3, 780.00),
(14, 14, 4, 590.00),
(15, 15, 5, 980.00),
(16, 16, 1, 530.00),
(17, 17, 2, 620.00),
(18, 18, 3, 870.00),
(19, 19, 4, 570.00),
(20, 20, 5, 990.00);

INSERT INTO Awaria_Wyciagu (
    ID_DataAwarii, ID_DataNaprawy, ID_Wyciagu, ID_Awarii,
    IleDniOdPrzegladu, Koszt
) VALUES
(1, 2, 1, 1, 5, 2000.00),
(3, 4, 2, 2, 10, 1500.00),
(5, 6, 3, 3, 8, 3000.00),
(7, 8, 4, 4, 4, 1200.00),
(9, 10, 5, 3, 12, 2500.00),
(11, 12, 3, 2, 7, 1800.00),
(13, 14, 2, 4, 9, 2200.00),
(15, 16, 3, 3, 6, 1600.00),
(17, 18, 4, 1, 11, 2700.00),
(19, 20, 4, 2, 5, 1300.00),
(21, 22, 1, 4, 8, 2100.00),
(23, 24, 2, 5, 10, 2500.00),
(25, 26, 5, 3, 7, 1700.00),
(27, 28, 4, 1, 6, 1900.00),
(29, 30, 5, 5, 9, 2300.00),
(31, 32, 2, 2, 5, 1500.00),
(33, 34, 2, 4, 8, 1750.00),
(35, 36, 3, 3, 6, 2800.00),
(37, 38, 2, 2, 7, 2400.00),
(39, 40, 5, 1, 9, 3000.00);
GO