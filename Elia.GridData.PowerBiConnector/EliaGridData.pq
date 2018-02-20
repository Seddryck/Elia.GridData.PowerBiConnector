// This file contains your Data Connector logic
section EliaGridData;

[DataSource.Kind="EliaGridData", Publish="EliaGridData.Publish"]
shared EliaGridData.GenerationWind = () =>
    let
        today = Date.From(DateTime.LocalNow()),
        sevenDaysAgo = Date.AddDays(today, -7),
        url = "http://publications.elia.be/Publications/Publications/WindForecasting.v2.svc/GetForecastData?beginDate=" & Date.ToText(sevenDaysAgo, "yyyy-MM-dd") & "&endDate=" & Date.ToText(today, "yyyy-MM-dd") & "&isOffshore=&isEliaConnected",
        source = Xml.Tables(Web.Contents(url)),
        table = source{1}[Table]{0}[Table],
        expandedTable = Custom.ExpandTable(table, {"Bid", "Realtime", "LoadFactor"})
    in
        expandedTable;

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


Custom.ExpandTable = (table as table, columnNames as list) =>  
    let
        columnType = (columnName as text) as text => Table.SingleRow(Table.SelectRows(Table.Schema(table), each [Name] = columnName))[TypeName],
        expandColumn = (table as table, columnName as text) as table => if columnType(columnName) = "Table.Type" or columnType(columnName) = "Any.Type" then Table.ExpandTableColumn(table, columnName, {"Element:Text"}, {columnName}) else table,
        expandedTable = List.Accumulate({"Bid", "Realtime", "LoadFactor"}, table, (state, current) => expandColumn(state, current))
    in
        expandedTable;