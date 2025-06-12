page 50230 "SharePoint Setup"
{
    ApplicationArea = All;
    Caption = 'SharePoint Setup';
    PageType = Card;
    SourceTable = "SharePoint Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether SharePoint integration is enabled';
                }
            }

            group("Azure AD")
            {
                Caption = 'Azure AD App Registration';

                field("Client ID"; Rec."Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Application (Client) ID from your Azure AD app registration';
                    ShowMandatory = true;
                }
                field("Client Secret"; Rec."Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the client secret value from your Azure AD app registration';
                    ShowMandatory = true;
                }
                field("Tenant ID"; Rec."Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Directory (Tenant) ID from your Azure AD';
                    ShowMandatory = true;
                }
            }

            group(SharePoint)
            {
                Caption = 'SharePoint Configuration';

                field("SharePoint Site ID"; Rec."SharePoint Site ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SharePoint site ID where delivery images are stored';
                    ShowMandatory = true;
                }
                field("SharePoint Drive ID"; Rec."SharePoint Drive ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SharePoint drive ID where delivery images are stored';
                    ShowMandatory = true;
                }
                field("Base Folder Path"; Rec."Base Folder Path")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base folder path for delivery images in SharePoint';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Image = TestDatabase;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SharePointAuth: Codeunit "SharePoint Auth";
                begin
                    SharePointAuth.TestConnection();
                    Message('Connection test completed successfully.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}