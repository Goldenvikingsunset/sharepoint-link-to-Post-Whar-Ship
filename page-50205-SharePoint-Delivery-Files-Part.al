page 50205 "SharePoint Delivery Files Part"
{
    PageType = ListPart;
    SourceTable = "SharePoint Delivery Files";
    Caption = 'Delivery Files';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Files)
            {
                field(Name; Rec.name)
                {
                    ApplicationArea = All;
                    StyleExpr = 'StandardAccent';
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        SharePointMgt: Codeunit "SharePoint Management";
                        Stream: InStream;
                    begin
                        if SharePointMgt.DownloadFile(Rec.driveId, Rec.id, Stream) then
                            DownloadFromStream(Stream, '', '', '', Rec.name);
                    end;
                }
                field(Size; GetFormattedSize())
                {
                    ApplicationArea = All;
                    Caption = 'Size';
                }
                field("Created Date"; Rec.createdDateTime)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    local procedure GetFormattedSize(): Text
    begin
        if Rec.size < 1024 then
            exit(StrSubstNo('%1 B', Rec.size))
        else
            if Rec.size < 1024 * 1024 then
                exit(StrSubstNo('%.1f KB', Rec.size / 1024))
            else
                exit(StrSubstNo('%.1f MB', Rec.size / (1024 * 1024)));
    end;
}