page 50221 "Delivery Images FactBox"
{
    PageType = CardPart;
    Caption = 'Delivery Images';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;

                field(Details; 'Details')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    StyleExpr = DetailStyleExpr;

                    trigger OnDrillDown()
                    begin
                        ToggleDetailsVisibility();
                    end;
                }

                field(AttachmentsPart; 'Attachments (' + Format(GetAttachmentCount()) + ')')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    StyleExpr = AttachmentStyleExpr;

                    trigger OnDrillDown()
                    begin
                        ShowAttachments();
                    end;
                }
            }

            group(DetailsArea)
            {
                ShowCaption = false;
                Visible = DetailsVisible;

                field("SharePoint Folder"; 'Open in SharePoint')
                {
                    ApplicationArea = All;
                    StyleExpr = 'StandardAccent';
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        SharePointUrlHandler: Codeunit "SharePoint URL Handler";
                        Url: Text;
                    begin
                        // Remove the debug message and use new URL handler
                        Url := SharePointUrlHandler.GetSharePointWebUrl(CurrentRecord);
                        if Url <> '' then
                            Hyperlink(Url)
                        else
                            Message('Could not access SharePoint folder. Please check your setup and permissions.');
                    end;
                }

                field(AttachmentsCount; StrSubstNo('%1 Attachment(s)', GetAttachmentCount()))
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        ShowAttachments();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateStyles();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateStyles();
    end;

    procedure Set(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        CurrentRecord := SalesShipmentHeader;
        UpdateAttachmentCount();
        UpdateStyles();
        CurrPage.Update(false);
    end;

    local procedure ShowAttachments()
    var
        DocAttDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CurrentRecord);
        DocAttDetails.OpenForRecRef(RecRef);
        DocAttDetails.RunModal();
        UpdateAttachmentCount();
        CurrPage.Update(false);
    end;

    local procedure ToggleDetailsVisibility()
    begin
        DetailsVisible := true;
        DetailStyleExpr := 'Strong';
        AttachmentStyleExpr := 'Standard';
        CurrPage.Update(false);
    end;

    local procedure GetAttachmentCount(): Integer
    var
        DocAttachment: Record "Document Attachment";
    begin
        DocAttachment.SetRange("Table ID", Database::"Sales Shipment Header");
        DocAttachment.SetRange("No.", CurrentRecord."No.");
        exit(DocAttachment.Count);
    end;

    local procedure UpdateAttachmentCount()
    begin
        AttachmentCount := GetAttachmentCount();
    end;

    local procedure UpdateStyles()
    begin
        if DetailsVisible then begin
            DetailStyleExpr := 'Strong';
            AttachmentStyleExpr := 'Standard';
        end else begin
            DetailStyleExpr := 'Standard';
            AttachmentStyleExpr := 'Standard';
        end;
    end;

    local procedure OpenSharePointFolder()
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.SetRange("Record ID", CurrentRecord.RecordId);
        RecordLink.SetRange(Type, RecordLink.Type::Link);
        RecordLink.SetRange(Description, 'SharePoint Delivery Images');
        if RecordLink.FindFirst() then
            Hyperlink(RecordLink.URL1);
    end;

    var
        CurrentRecord: Record "Sales Shipment Header";
        AttachmentCount: Integer;
        DetailsVisible: Boolean;
        DetailStyleExpr: Text;
        AttachmentStyleExpr: Text;
}