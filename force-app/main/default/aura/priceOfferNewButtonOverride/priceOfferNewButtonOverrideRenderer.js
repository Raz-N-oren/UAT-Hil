({
    rerender : function(cmp, helper) {
        this.superRerender();
        var recordTypeId = cmp.get("v.pageReference").state.recordTypeId;
        cmp.set("v.selectedRecordId", recordTypeId);        
        cmp.find('priceOfferNewButton').navigateToLwc();
    },
})