codeunit 50223 "SharePoint URL Handler"
{
    procedure GetSharePointFolderUrl(SalesShipmentHeader: Record "Sales Shipment Header"): Text
    var
        SharePointSetup: Record "SharePoint Setup";
        FolderPath: Text;
        EncodedPath: Text;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit('');

        // Get the folder path using existing function
        FolderPath := GetFolderPath(SalesShipmentHeader);

        // Microsoft Graph API format for accessing files
        exit(StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/root:/%3:/children',
            SharePointSetup."SharePoint Site ID",
            SharePointSetup."SharePoint Drive ID",
            FolderPath));
    end;

    procedure GetSharePointWebUrl(SalesShipmentHeader: Record "Sales Shipment Header"): Text
    var
        SharePointSetup: Record "SharePoint Setup";
        GraphClient: Codeunit "SharePoint Graph Client";
        JObject: JsonObject;
        JToken: JsonToken;
        FolderPath: Text;
        ResponseText: Text;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit('');

        // Get the folder path
        FolderPath := GetFolderPath(SalesShipmentHeader);

        // First, get the drive item using Graph API to retrieve the webUrl
        if not GraphClient.GetDriveItem(SharePointSetup, FolderPath, ResponseText) then
            exit('');

        if JObject.ReadFrom(ResponseText) then
            if JObject.Get('webUrl', JToken) then
                exit(JToken.AsValue().AsText());

        exit('');
    end;

    local procedure GetFolderPath(SalesShipmentHeader: Record "Sales Shipment Header"): Text
    var
        SharePointSetup: Record "SharePoint Setup";
        Year: Text;
        Month: Text;
    begin
        SharePointSetup.Get();
        Year := Format(Date2DMY(SalesShipmentHeader."Posting Date", 3));
        Month := GetMonthName(Date2DMY(SalesShipmentHeader."Posting Date", 2));
        exit(StrSubstNo('%1/%2/%3/%4',
            SharePointSetup."Base Folder Path",
            Year,
            Month,
            SalesShipmentHeader."No."));
    end;

    local procedure GetMonthName(Month: Integer): Text
    begin
        case Month of
            1:
                exit('January');
            2:
                exit('February');
            3:
                exit('March');
            4:
                exit('April');
            5:
                exit('May');
            6:
                exit('June');
            7:
                exit('July');
            8:
                exit('August');
            9:
                exit('September');
            10:
                exit('October');
            11:
                exit('November');
            12:
                exit('December');
        end;
    end;
}