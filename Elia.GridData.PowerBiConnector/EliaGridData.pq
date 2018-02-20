// This file contains your Data Connector logic
section EliaGridData;

[DataSource.Kind="EliaGridData", Publish="EliaGridData.Publish"]
shared EliaGridData.GenerationWind = Value.ReplaceType(EliaGridData.GenerationWindImpl, EliaGridDataType);

EliaGridData.GenerationWindImpl = (beginDate as date, dayCount as number) =>
    let
        url = "http://publications.elia.be/Publications/Publications/WindForecasting.v2.svc/GetForecastData?beginDate=" & Date.ToText(beginDate, "yyyy-MM-dd") & "&endDate=" & Date.ToText(Date.AddDays(beginDate, dayCount), "yyyy-MM-dd") & "&isOffshore=&isEliaConnected",
        source = Xml.Tables(Web.Contents(url)),
        table = source{1}[Table]{0}[Table],
        expandedTable = Custom.ExpandTable(table, {"Bid", "Realtime", "LoadFactor"}),
        removedColumns = Table.RemoveColumns(expandedTable,{"Bid"}),
        changedType = Table.TransformColumnTypes(removedColumns,{{"DayAheadConfidence10", type number}, {"DayAheadConfidence90", type number}, {"DayAheadForecast", type number}, {"LoadFactor", type number}, {"MonitoredCapacity", type number}, {"MostRecentConfidence10", type number}, {"MostRecentConfidence90", type number}, {"MostRecentForecast", type number}, {"Realtime", type number}, {"WeekAheadConfidence10", type number}, {"WeekAheadConfidence90", type number}, {"WeekAheadForecast", type number}}),
        expandedTimeInformation = Custom.ExpandTimeInformation(changedType),
        selectedColumns = Table.SelectColumns(expandedTimeInformation, {"UtcDate", "UtcTime", "LocalDate", "LocalTime", "LocalDateTime", "LocalString", "MonitoredCapacity", "Realtime", "LoadFactor", "MostRecentForecast", "DayAheadForecast", "WeekAheadForecast"}),
        reorderedColumns = Table.ReorderColumns(selectedColumns,{"UtcDate", "UtcTime", "LocalDate", "LocalTime", "LocalDateTime", "LocalString", "MonitoredCapacity", "Realtime", "LoadFactor", "MostRecentForecast", "DayAheadForecast", "WeekAheadForecast"})    
    in
        reorderedColumns;

EliaGridDataType = type function (
    beginDate as (type date meta[
        Documentation.FieldCaption = "Begin date",
        Documentation.FieldDescription = "The first date (in local time) to get data.",
        Documentation.SampleValues = {#date(2017,5,1), #date(2015,1,25)}
    ]),
    dayCount as (type number meta[
        Documentation.FieldCaption = "Days to retrieve",
        Documentation.FieldDescription = "How many days do you want to retrieve from this service.",
        Documentation.SampleValues = {2, 10}
    ])
)
as table meta [
    Documentation.Name = "Observations and forecasts at the quarter-hour granularity",
    Documentation.LongDescription = "List of quarter-hour values for observed and forecasted power produced in Belgium",
    Documentation.Examples = {[
        Description = "Returns a table with all forecasts and observations for the days between 5th of October 2017 and 9th of October 2017.",
        Code = "EliaWindForecast.Contents(date(#2017,10,5), 5)",
        Result = "#table({""UtcDate""}, {{""UtcTime""}, {""LocalDate""}})"
        ]}
];

// Data Source Kind description
EliaGridData = [
    Authentication = [
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel") //Label visible when requesting credentials
];

// Data Source UI publishing description
EliaGridData.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") }, //List of text items that will be displayed next to the data source's icon in the Power BI Get Data dialog.
    LearnMoreUrl = Extension.LoadString("LearnMoreUrl"),
    SourceImage = EliaGridData.Icons,
    SourceTypeImage = EliaGridData.Icons
];

EliaGridData.Icons = [
    Icon16 = { Extension.Contents("EliaGridData16.png"), Extension.Contents("EliaGridData20.png"), Extension.Contents("EliaGridData24.png"), Extension.Contents("EliaGridData32.png") },
    Icon32 = { Extension.Contents("EliaGridData32.png"), Extension.Contents("EliaGridData40.png"), Extension.Contents("EliaGridData48.png"), Extension.Contents("EliaGridData64.png") }
];

Today = Date.From(DateTime.LocalNow());
SevenDaysAgo = Date.AddDays(Today, -7);

Custom.ExpandTable = (table as table, columnNames as list) =>  
    let
        columnType = (columnName as text) as text => Table.SingleRow(Table.SelectRows(Table.Schema(table), each [Name] = columnName))[TypeName],
        expandColumn = (table as table, columnName as text) as table => if columnType(columnName) = "Table.Type" or columnType(columnName) = "Any.Type" then Table.ExpandTableColumn(table, columnName, {"Element:Text"}, {columnName}) else table,
        expandedTable = List.Accumulate({"Bid", "Realtime", "LoadFactor"}, table, (state, current) => expandColumn(state, current))
    in
        expandedTable;

Custom.ExpandTimeInformation = (table as table) =>  
    let
        expandedStartsOn = Table.ExpandTableColumn(table, "StartsOn", {"http://schemas.datacontract.org/2004/07/System"}, {"StartsOn"}),
        expandedStartsOn2 = Table.ExpandTableColumn(expandedStartsOn, "StartsOn", {"DateTime"}, {"DateTime"}),
        split = Table.SplitColumn(expandedStartsOn2, "DateTime", Splitter.SplitTextByDelimiter("T", QuoteStyle.Csv), {"UtcDate", "UtcTime"}),
        typeToDate = Table.TransformColumnTypes(split,{{"UtcDate", type date}, {"UtcTime", type text}}),
        removeZ = Table.ReplaceValue(typeToDate,"Z","",Replacer.ReplaceText,{"UtcTime"}),
        typeToTime = Table.TransformColumnTypes(removeZ,{{"UtcTime", type time}}),
        addLocalTime = Table.AddColumn(typeToTime, "localTimeRecord", each Elia.UtcToLocalTime([UtcDate], [UtcTime]), Record.Type),
        splitLocalTime = Table.ExpandRecordColumn(addLocalTime, "localTimeRecord", {"LocalDate", "LocalTime", "LocalDateTime", "LocalString"}, {"LocalDate", "LocalTime", "LocalDateTime", "LocalString"}),
        changeTypeLocalTime = Table.TransformColumnTypes(splitLocalTime,{{"LocalDate", type date}, {"LocalTime", type time}, {"LocalDateTime", type datetime}, {"LocalString", type text}})
    in
        changeTypeLocalTime;

Elia.UtcToLocalTime = (date as date, time as time) =>
let
    lastSundayOfOctober = Date.StartOfWeek(#date(Date.Year(date), 10, 31), Day.Sunday),
    lastSundayOfMarch = Date.StartOfWeek(#date(Date.Year(date), 3, 31), Day.Sunday),
    isSummerTime = (date > lastSundayOfMarch and date < lastSundayOfOctober) or (date = lastSundayOfOctober and time < #time(1,0,0)) or (date = lastSundayOfMarch and time > #time(1,0,0)),
    timeZone = 1 + Number.From(isSummerTime),
    localTime = DateTime.From(date) + #duration(0, Time.Hour(time), Time.Minute(time), Time.Second(time))  + #duration(0, timeZone, 0, 0),
    isWinterDouble = (date = lastSundayOfOctober) and time = #time(1,0,0),
    localString = DateTime.ToText(localTime, "yyyy-MM-dd HH:mm:ss") & Text.Repeat("*", Number.From(isWinterDouble)),
    record = [LocalDate = Date.From(localTime), LocalTime = Time.From(localTime), LocalDateTime = localTime, LocalString = localString]
in
    record;