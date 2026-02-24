# HD LAB 6 Report
## KPI
### Obniżenie kosztów utrzymania wyciągów o 5% w skali miesiąca
#### Value
```
[Measures].[Koszt] + [Measures].[Koszt - Przeglad Wyciagu]
```
#### Goal
```
(ParallelPeriod([ID Data].[Data hierarchia].[Miesiac],1,[ID Data].[Data hierarchia].CurrentMember), KPIValue("Cel Biznesowy 1")) * 0.95
```
#### Status
```
IIF(KPIValue("Cel Biznesowy 1") <= KPIGoal("Cel Biznesowy 1"), 1, 0 )
```
#### Trend
```
IIF(
    KPIValue("Cel Biznesowy 1") >= (
        (ParallelPeriod([ID Data].[Data hierarchia].[Miesiac], 1, [ID Data].[Data hierarchia].CurrentMember),
        KPIValue("Cel Biznesowy 1"))
    ),
    1,
    -1
)
```
### Skrócenie średniego czasu oczekiwania w kolejce o 8.5% względem zeszłego miesiąca
#### Value
```
[Measures].[SredniaDlugoscKolejki]
```
#### Goal
```
(ParallelPeriod([ID Data].[Data hierarchia].[Miesiac],1,[ID Data].[Data hierarchia].CurrentMember), KPIValue("Cel Biznesowy 2")) * 0.915
```
#### Status
```
IIF(KPIValue("Cel Biznesowy 2") <= KPIGoal("Cel Biznesowy 2"), 1, 0 )
```
#### Trend
```
IIF(
    KPIValue("Cel Biznesowy 2") >= (
        (ParallelPeriod([ID Data].[Data hierarchia].[Miesiac], 1, [ID Data].[Data hierarchia].CurrentMember),
        KPIValue("Cel Biznesowy 2"))
    ),
    1,
    -1
)
```

## Zapytania MDX
### 1 Porównaj długość kolejki w godzinach, których nie wystąpiły przestoje z tymi w których
wystąpiły?
```SQL
SELECT 
    NON EMPTY { 
        [Measures].[CzyBylPrzystoj], 
        [Measures].[SredniaDlugoscKolejki] 
    } ON COLUMNS,

    NON EMPTY 
        FILTER(
            [ID Czas Konca].[Godzina].[Godzina].ALLMEMBERS,
            NOT ISEMPTY([Measures].[Dlugosc Przystojow])
        ) ON ROWS

FROM [Hurtownia Goradol]
```

### 2 Porównaj średni czas oczekiwania na różnych trasach w różnych godzinach dnia. 

```SQL
SELECT 
	NON EMPTY { [Measures].[SredniaDlugoscKolejki] 
	} ON COLUMNS,
	 NON EMPTY { ([ID Czas Konca].[Godzina].[Godzina].ALLMEMBERS *
	 [ID Wyciag Koncowy].[ID Wyciagu].[ID Wyciagu].ALLMEMBERS )
	 }ON ROWS 
FROM [Hurtownia Goradol]
```

### 3 Zestawienie ilości historycznych awarii z średnim czasem oczekiwania na danej trasie. 

```SQL
SELECT 
	NON EMPTY {
	[Measures].[Awaria Wyciagu Count], 
	[Measures].[SredniaDlugoscKolejki] 
	} ON COLUMNS,

	 NON EMPTY {
	 ([ID Wyciagu].[ID Wyciagu].[ID Wyciagu].ALLMEMBERS *
	 [ID Wyciagu].[Nazwa].[Nazwa].ALLMEMBERS ) 
	 } ON ROWS 
FROM [Hurtownia Goradol]
```

### 4 W których dniach tygodnia jest największy średni czas oczekiwania?  

```SQL
SELECT 
	NON EMPTY { 
	[Measures].[SredniaDlugoscKolejki] 
	} ON COLUMNS, 
	NON EMPTY { 
	([ID Data].[Dzien Tygodnia].[Dzien Tygodnia].ALLMEMBERS ) 
	} ON ROWS 
FROM [Hurtownia Goradol]
```

### 5 Jaki jest stosunek kosztów przeglądów do awarii w danym miesiącu? 

```SQL
WITH MEMBER [Measures].[Koszt_Utrzymania] AS [Measures].[Koszt] + [Measures].[Koszt - Przeglad Wyciagu] 
SELECT 
	NON EMPTY { 
	[Measures].[Koszt], [Measures].[Koszt - Przeglad Wyciagu] 
	} ON COLUMNS, 
	NON EMPTY { 
	([ID Data].[Miesiac].[Miesiac].ALLMEMBERS ) 
	} ON ROWS 
FROM [Hurtownia Goradol]
```

### 6 Po ilu dniach od przeglądu zdarzają się awarie?
```sql
SELECT 
	NON EMPTY { [Measures].[IleDniOdPrzegladuAVG] } ON COLUMNS, 
	NON EMPTY { ([ID Wyciagu].[Nazwa].[Nazwa].ALLMEMBERS ) } ON ROWS 
FROM [Hurtownia Goradol]
```

### 7 Zależność między częstotliwością przeglądów a liczbą awarii w miesiącu
```sql
SELECT 
	NON EMPTY {[ID Data].[Miesiac].[Miesiac].ALLMEMBERS} ON ROWS, 
	NON EMPTY{[Measures].[Przeglad Wyciagu Count], [Measures].[Awaria Wyciagu Count]} ON COLUMNS 
FROM [Hurtownia Goradol]
```

### 8 Ile osób tygodniowo korzysta z danego wyciągu w skali miesiąca?
```SQL
SELECT 
	NON EMPTY { [Measures].[Przejazd Narciarza Count] } ON COLUMNS, 
	NON EMPTY { ([ID Data].[Tydzien].[Tydzien].ALLMEMBERS * [ID Wyciag Koncowy].[Nazwa].[Nazwa].ALLMEMBERS ) } ON ROWS
FROM [Hurtownia Goradol]
```

### 9 Jakie typy awarii najczęściej występują na danym wyciągu?
```SQL
SELECT 
	NON EMPTY {[Measures].[Awaria Wyciagu Count]} ON COLUMNS, 
	NON EMPTY { GENERATE( 
		[ID Wyciagu].[Nazwa].[Nazwa].MEMBERS, 
		[ID Wyciagu].[Nazwa].CURRENTMEMBER * TOPCOUNT(
			[Typ Awarii].[Nazwa].[Nazwa].MEMBERS, 
			1, 
			([Measures].[Awaria Wyciagu Count], [ID Wyciagu].[Nazwa].CURRENTMEMBER)
		)  ) } ON ROWS
FROM [Hurtownia Goradol]	
```

### 10 Koszty utrzymania na przewiezioną osobę na konkretnym wyciągu w danym miesiącu?
```SQL
WITH MEMBER [Measures].[KosztNaPrzejazd] AS
    IIF([Measures].[Przejazd Narciarza Count] = 0,
        NULL,
        ([Measures].[Koszt] + [Measures].[Koszt - Przeglad Wyciagu]) / [Measures].[Przejazd Narciarza Count]
    )
SELECT 
    NON EMPTY { [Measures].[KosztNaPrzejazd] } ON COLUMNS,
    NON EMPTY { ([ID Data].[Miesiac].[Miesiac].ALLMEMBERS * [ID Wyciagu].[Nazwa].[Nazwa].ALLMEMBERS) } ON ROWS
FROM [Hurtownia Goradol]
```