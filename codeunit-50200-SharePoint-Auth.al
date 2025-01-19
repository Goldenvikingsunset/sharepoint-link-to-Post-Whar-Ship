codeunit 50200 "SharePoint Auth"
{
    procedure GetOAuthToken() AuthToken: SecretText
    var
        SharePointSetup: Record "SharePoint Setup";
        OAuth2: Codeunit OAuth2;
        AccessTokenURL: Text;
        ResourceUrl: Text;
        Scopes: List of [Text];
    begin
        if not SharePointSetup.Get() then
            Error('SharePoint setup is not configured.');

        if not SharePointSetup.Enabled then
            Error('SharePoint integration is not enabled.');

        ValidateSetup(SharePointSetup);

        // Use exact scope from the Azure Portal
        Clear(Scopes);
        Scopes.Add('https://graph.microsoft.com/.default');

        AccessTokenURL := StrSubstNo(
            'https://login.microsoftonline.com/%1/oauth2/v2.0/token',
            SharePointSetup."Tenant ID");

        // Try to acquire token
        if not OAuth2.AcquireTokenWithClientCredentials(
            SharePointSetup."Client ID",
            SharePointSetup."Client Secret",
            AccessTokenURL,
            '',  // Empty for v2.0 endpoint
            Scopes,
            AuthToken)
        then
            Error('Failed to acquire token: %1', GetLastErrorText());

        if AuthToken.IsEmpty() then
            Error('Received empty token');
    end;

    procedure TestConnection()
    var
        SharePointSetup: Record "SharePoint Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        AuthToken: SecretText;
        ResponseText: Text;
        RequestUrl: Text;
    begin
        if not SharePointSetup.Get() then
            Error('SharePoint setup is not configured.');

        SharePointSetup.TestField(Enabled, true);
        ValidateSetup(SharePointSetup);

        // Get the token
        AuthToken := GetOAuthToken();

        // Test access with a simple Graph API call
        RequestUrl := StrSubstNo(
            'https://graph.microsoft.com/v1.0/sites/%1',
            SharePointSetup."SharePoint Site ID");

        HttpRequestMessage.SetRequestUri(RequestUrl);
        HttpRequestMessage.Method := 'GET';

        HttpRequestMessage.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));
        Headers.Add('Accept', 'application/json');

        Clear(HttpClient);
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Failed to send request');

        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            HttpResponseMessage.Content.ReadAs(ResponseText);
            Error('Connection test failed:\%1\URL: %2', ResponseText, RequestUrl);
        end;

        Message('Connection test completed successfully!');
    end;

    local procedure ValidateSetup(SharePointSetup: Record "SharePoint Setup")
    begin
        SharePointSetup.TestField("Client ID");
        SharePointSetup.TestField("Client Secret");
        SharePointSetup.TestField("Tenant ID");
        SharePointSetup.TestField("SharePoint Site ID");
        SharePointSetup.TestField("SharePoint Drive ID");
    end;
}