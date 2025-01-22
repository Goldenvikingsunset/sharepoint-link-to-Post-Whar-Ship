codeunit 50220 "SharePoint Management"
{
    procedure CreateDeliveryFolder(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        FolderPath: Text;
        ParentPath: Text;
        FolderName: Text;
        RequestUrl: Text;
        AuthToken: SecretText;
        JObject: JsonObject;
        RequestBody: Text;
        ResponseText: Text;
        PathParts: List of [Text];
        i: Integer;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit;

        // Split the path into parts
        FolderPath := GetFolderPath(SalesShipmentHeader);
        PathParts := FolderPath.Split('/');

        // Create parent folders one by one
        ParentPath := '';
        for i := 1 to PathParts.Count do begin
            if i > 1 then
                ParentPath += '/';
            ParentPath += PathParts.Get(i);

            if not FolderExists(ParentPath) then
                CreateFolder(ParentPath, PathParts.Get(i));
        end;
    end;

    local procedure CreateFolder(FolderPath: Text; FolderName: Text)
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestUrl: Text;
        AuthToken: SecretText;
        JObject: JsonObject;
        RequestBody: Text;
        ResponseText: Text;
    begin
        SharePointSetup.Get();
        AuthToken := GetOAuthToken();

        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/root:/%3:/children',
            SharePointSetup."SharePoint Site ID",
            SharePointSetup."SharePoint Drive ID",
            FolderPath);

        Clear(JObject);
        JObject.Add('name', FolderName);
        JObject.Add('@microsoft.graph.conflictBehavior', 'fail');
        JObject.Add('folder', JObject.AsToken());
        JObject.WriteTo(RequestBody);

        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Method := 'POST';
        HttpRequestMessage.SetRequestUri(RequestUrl);
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));
        HttpRequestMessage.Content := Content;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            if not (HttpResponseMessage.HttpStatusCode = 409) then // 409 means folder exists
                Error('Failed to create SharePoint folder');

        if not HttpResponseMessage.IsSuccessStatusCode() and (HttpResponseMessage.HttpStatusCode <> 409) then begin
            HttpResponseMessage.Content.ReadAs(ResponseText);
            Error('Failed to create SharePoint folder: %1', ResponseText);
        end;
    end;

    local procedure FolderExists(FolderPath: Text): Boolean
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        RequestUrl: Text;
        AuthToken: SecretText;
        ResponseText: Text;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit(false);

        // Construct the request URL to check if the folder exists
        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/root:/%3',
            SharePointSetup."SharePoint Site ID",
            SharePointSetup."SharePoint Drive ID",
            FolderPath);

        // Get auth token
        AuthToken := GetOAuthToken();

        // Prepare the HTTP GET request
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.SetRequestUri(RequestUrl);
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));

        // Send the request
        if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            if HttpResponseMessage.IsSuccessStatusCode() then
                exit(true) // Folder exists
            else if HttpResponseMessage.HttpStatusCode = 404 then
                exit(false); // Folder does not exist
        end;

        HttpResponseMessage.Content.ReadAs(ResponseText);
        Error('Error checking folder existence: %1', ResponseText);
    end;



    procedure GetDomainName(SiteId: Text): Text
    begin
        exit(CopyStr(SiteId, 1, SiteId.IndexOf('.')));
    end;

    procedure GetSiteName(SiteId: Text): Text
    begin
        exit('DeliveryImages');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        if SalesShptHdrNo = '' then
            exit;

        if SalesShipmentHeader.Get(SalesShptHdrNo) then
            CreateDeliveryFolder(SalesShipmentHeader);
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

    local procedure GetOAuthToken() AuthToken: SecretText
    var
        SharePointSetup: Record "SharePoint Setup";
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
    begin
        if not SharePointSetup.Get() then
            Error('SharePoint setup is not configured.');

        if not SharePointSetup.Enabled then
            Error('SharePoint integration is not enabled.');

        Scopes.Add('https://graph.microsoft.com/.default');

        if not OAuth2.AcquireTokenWithClientCredentials(
            SharePointSetup."Client ID",
            SharePointSetup."Client Secret",
            'https://login.microsoftonline.com/' + SharePointSetup."Tenant ID" + '/oauth2/v2.0/token',
            '',
            Scopes,
            AuthToken) then
            Error('Failed to get access token from response\%1', GetLastErrorText());
    end;

    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; var Stream: InStream): Boolean
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        Headers: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        AuthToken: SecretText;
        RequestUrl: Text;
        ResponseText: Text;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit(false);

        AuthToken := GetOAuthToken();

        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/root:/%3/%4:/content',
            SharePointSetup."SharePoint Site ID",
            DriveId,
            FolderPath,
            FileName);

        RequestMessage.Method := 'PUT';
        RequestMessage.SetRequestUri(RequestUrl);
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));

        RequestContent.WriteFrom(Stream);
        RequestMessage.Content := RequestContent;

        if not HttpClient.Send(RequestMessage, ResponseMessage) then
            exit(false);

        exit(ResponseMessage.IsSuccessStatusCode());
    end;

    procedure DownloadFile(DriveId: Text; ItemId: Text; var Stream: InStream): Boolean
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        AuthToken: SecretText;
        RequestUrl: Text;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit(false);

        AuthToken := GetOAuthToken();

        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/items/%3/content',
            SharePointSetup."SharePoint Site ID",
            DriveId,
            ItemId);

        HttpRequestMessage.SetRequestUri(RequestUrl);
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        exit(HttpResponseMessage.Content.ReadAs(Stream));
    end;

    procedure GetFolderFiles(FolderPath: Text; var DeliveryFiles: Record "SharePoint Delivery Files" temporary): Boolean
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        AuthToken: SecretText;
        RequestUrl: Text;
        ResponseText: Text;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        EntryNo: Integer;
    begin
        if not SharePointSetup.Get() or not SharePointSetup.Enabled then
            exit(false);

        AuthToken := GetOAuthToken();

        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/root:/%3:/children',
            SharePointSetup."SharePoint Site ID",
            SharePointSetup."SharePoint Drive ID",
            FolderPath);

        HttpRequestMessage.SetRequestUri(RequestUrl);
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        if not HttpResponseMessage.Content.ReadAs(ResponseText) then
            exit(false);

        if not JsonObject.ReadFrom(ResponseText) then
            exit(false);

        if not JsonObject.Get('value', JsonToken) then
            exit(false);

        JsonArray := JsonToken.AsArray();

        DeliveryFiles.Reset();
        DeliveryFiles.DeleteAll();

        foreach JsonToken in JsonArray do begin
            // Skip folders
            if not HasFolderProperty(JsonToken) then
                ReadFileProperties(JsonToken, DeliveryFiles, SharePointSetup);
        end;

        exit(true);
    end;

    local procedure HasFolderProperty(JToken: JsonToken): Boolean
    var
        JObject: JsonObject;
        JFolderToken: JsonToken;
    begin
        JObject := JToken.AsObject();
        exit(JObject.Get('folder', JFolderToken));
    end;

    local procedure ReadFileProperties(JToken: JsonToken; var DeliveryFiles: Record "SharePoint Delivery Files"; SharePointSetup: Record "SharePoint Setup")
    var
        JObject: JsonObject;
        JValue: JsonToken;
    begin
        JObject := JToken.AsObject();

        DeliveryFiles.Init();

        if JObject.Get('id', JValue) then
            DeliveryFiles.id := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(DeliveryFiles.id));

        DeliveryFiles.driveId := SharePointSetup."SharePoint Drive ID";

        if JObject.Get('name', JValue) then
            DeliveryFiles.name := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(DeliveryFiles.name));

        if JObject.Get('size', JValue) then
            DeliveryFiles.size := JValue.AsValue().AsBigInteger();

        if JObject.Get('file', JValue) then begin
            JObject := JValue.AsObject();
            if JObject.Get('mimeType', JValue) then
                DeliveryFiles.mimeType := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(DeliveryFiles.mimeType));
        end;

        if JObject.Get('createdDateTime', JValue) then
            DeliveryFiles.createdDateTime := JValue.AsValue().AsDateTime();

        if JObject.Get('webUrl', JValue) then
            DeliveryFiles.webUrl := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(DeliveryFiles.webUrl));

        DeliveryFiles.Insert();
    end;
}