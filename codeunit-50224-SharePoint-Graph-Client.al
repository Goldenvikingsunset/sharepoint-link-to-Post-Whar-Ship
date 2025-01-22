codeunit 50224 "SharePoint Graph Client"
{
    procedure GetDriveItem(SharePointSetup: Record "SharePoint Setup"; FolderPath: Text; var ResponseText: Text): Boolean
    var
        SharePointAuth: Codeunit "SharePoint Auth";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        RequestUrl: Text;
        AuthToken: SecretText;
    begin
        AuthToken := SharePointAuth.GetOAuthToken();
        if AuthToken.IsEmpty() then
            exit(false);

        // Construct the URL to get drive item
        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1/drives/%2/root:/%3',
            SharePointSetup."SharePoint Site ID",
            SharePointSetup."SharePoint Drive ID",
            FolderPath);

        HttpRequestMessage.SetRequestUri(RequestUrl);
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));
        Headers.Add('Accept', 'application/json');

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        HttpResponseMessage.Content.ReadAs(ResponseText);
        exit(true);
    end;
}