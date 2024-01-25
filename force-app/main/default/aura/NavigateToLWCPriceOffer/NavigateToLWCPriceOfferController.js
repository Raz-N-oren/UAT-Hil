({
    init : function(component, event, helper) {
        console.log(`004. In NavigationToLWCPriceOfferController -> init`);
        var myPageRef = component.get("v.pageReference");
        console.log(`005. In NavigationToLWCPriceOfferController -> init -> myPageRef: ${JSON.stringify(myPageRef)}`);
        var recordTypeId = myPageRef.state.c__recordTypeId;
        component.set("v.recordTypeId", recordTypeId);
    },
})