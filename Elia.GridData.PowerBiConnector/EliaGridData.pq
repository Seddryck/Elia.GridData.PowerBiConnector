// This file contains your Data Connector logic
section EliaGridData;

[DataSource.Kind="EliaGridData", Publish="EliaGridData.Publish"]
shared EliaGridData.Contents = () =>
    let
        Source = {1 .. 50}
    in
        Source; 

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
