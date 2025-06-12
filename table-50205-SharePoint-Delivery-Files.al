table 50225 "SharePoint Delivery Files"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; id; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(2; driveId; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(3; name; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(4; size; BigInteger)
        {
            DataClassification = CustomerContent;
        }
        field(5; mimeType; Text[80])
        {
            DataClassification = CustomerContent;
        }
        field(6; createdDateTime; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(7; webUrl; Text[250])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }
}