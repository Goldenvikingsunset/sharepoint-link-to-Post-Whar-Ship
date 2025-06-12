table 50230 "SharePoint Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Client ID"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Application (Client) ID';
            NotBlank = true;
        }
        field(3; "Client Secret"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Client Secret';
            ExtendedDatatype = Masked;
            NotBlank = true;
        }
        field(4; "Tenant ID"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Directory (Tenant) ID';
            NotBlank = true;
        }
        field(5; "SharePoint Site ID"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'SharePoint Site ID';
            NotBlank = true;
        }
        field(6; "SharePoint Drive ID"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'SharePoint Drive ID';
            NotBlank = true;
        }
        field(7; "Base Folder Path"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Base Folder Path';
            InitValue = 'Delivery Images';
        }
        field(8; "Enabled"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}