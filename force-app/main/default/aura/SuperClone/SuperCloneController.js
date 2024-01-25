({
    doInit: function(cmp, event, helper) {
        var action = cmp.get("c.doClone");
        action.setParams(
            {
                parentId : cmp.get("v.recordId")
            }
        );
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state sucess'+state);
            
            if (cmp.isValid()) {
                if (state === "SUCCESS") {
                    console.log('state sucess'+state);
                    
                    var clonedId = response.getReturnValue();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": clonedId
                    });
                    navEvt.fire();
                } else if(state == "ERROR"){
                    console.log('state'+state);
                    var errors = response.getError();
                    if(errors) {
                        console.log(errors[0].message);
                        var hideQuickAcion = $A.get("e.force:closeQuickAction");
                        hideQuickAcion.fire();
                    }
                }
            }
            helper.hideElement(cmp, 'modalSpinner');
        });
        
        $A.enqueueAction(action);
    },
    
})