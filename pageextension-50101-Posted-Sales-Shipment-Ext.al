pageextension 50222 "Posted Sales Shipment Ext" extends "Posted Sales Shipment"
{
    layout
    {
        addfirst(factboxes)
        {
            part(DeliveryImages; "Delivery Images FactBox")
            {
                ApplicationArea = All;
                Caption = 'Delivery Images';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CurrPage.DeliveryImages.Page.Set(Rec);
    end;
}
