({
    hideElement: function (cmp, elementId) {
        var elm = cmp.find(elementId);
        $A.util.addClass(elm, 'slds-hide');
    },
    showElement: function (cmp, elementId) {
                component.set("v.Spinner", true); 

        var elm = cmp.find(elementId);
        $A.util.removeClass(elm, 'slds-hide');
    },
    
    showToast : function(type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent) {
            toastEvent.setParams({
                "title": title,
                "message": message,
                "type": type
            });
            toastEvent.fire();
        }
    },
    
})