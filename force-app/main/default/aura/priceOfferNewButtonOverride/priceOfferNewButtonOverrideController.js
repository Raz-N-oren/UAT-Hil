({
    
    doInit: function(cmp, event, helper) {
 
        var recordTypeId = cmp.get("v.pageReference").state.recordTypeId;
        cmp.set("v.selectedRecordId", recordTypeId);        
        cmp.find('priceOfferNewButton').navigateToLwc();
      
    },
})