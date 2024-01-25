public class SuperCloneService {


    public Id doCloneOppWithPlots(String parentId, Id accountId, String plotNames, String growthName, Decimal plotsSize) {

        Set<String> querySobject = new Set<String>();
   
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        String objectAPIName = 'Opportunity';
       
        Set <String> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap().keySet();
        List<String> finalFields = new List<String>() ;
        finalFields.addAll(fieldMap);
        
        SObjectType objToken = Schema.getGlobalDescribe().get(objectAPIName); 
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String,String> so = new Map<String,String>();
        Map<String,String> so1 = new Map<String,String>();
        
        for (Schema.ChildRelationship cr: objDef.getChildRelationships()) 
        {
            if(cr.getRelationshipName() == 'OpportunityLineItems' && cr.getField().getDescribe().isAccessible()&& cr.getField().getDescribe().isCreateable()&&cr.getField().getDescribe().isAccessible() ){
                    so.put(''+cr.getChildSObject()  , ''+cr.getRelationshipName());
                    so1.put(''+cr.getRelationshipName()  , ''+cr.getField());
                
            }
        } 
        
        List<String> subqueries = prepareSubqueries(so, schemaMap);
        String query =
            'SELECT ' + String.join(finalFields, ',')+
            ','+String.join(subqueries, ',') +
            ' FROM ' +objectAPIName +
            ' WHERE Id = \''+parentId+'\' ' ;
        
        List<Sobject> parentObj = Database.query(query);
        Sobject parentRecordId = parentObj[0];
        
        Opportunity clonedRecord = (Opportunity) parentRecordId.clone();
        if(accountId != null) {clonedRecord.AccountId = accountId;}
        insert clonedRecord;
        List<sObject> childObjects =cloneChildren(parentRecordId, clonedRecord, so  ,so1);
        for(OpportunityLineItem oppli : (List<OpportunityLineItem>)childObjects){
            oppli.Date__c = Date.newinstance(Date.today().year(), oppli.Date__c.month(), oppli.Date__c.day());
            oppli.TotalPrice = null;
            
            if(accountId == null && plotNames == null && growthName == null && plotsSize == null) continue; 
            
            oppli.Plot__c = null;
            oppli.Plots__c=plotNames;
            oppli.Plot_Size__c=plotsSize;
            if(oppli.Is_Extension__c){
                oppli.Quantity = (oppli.Quantity_per_hectare__c * plotsSize) ;
            }else {
                oppli.Quantity = Math.floor(((oppli.Quantity_per_hectare__c * plotsSize)/1000) * 100) / 100 ;                
            }
            
        
            // oppli.growthName=growthName;
            System.debug(oppli);

        }
        insert childObjects;       

        relateOppToAddIns((List<OpportunityLineItem>) childObjects);

        return clonedRecord.Id ;
        
    }

    private void relateOppToAddIns(List<OpportunityLineItem> newOpportunityLineItems){

        List<OpportunityLineItem> mainOppsToUpdate = new  List<OpportunityLineItem>();

        for(Integer i =0; i< newOpportunityLineItems.size() ; i++){
            if(newOpportunityLineItems[i].Is_Extension__c) continue;
            Boolean updateThisOpp = false;
            Integer extentionIndex = 0;
            for(Integer j = 1; j<9 ; j++){
                if(newOpportunityLineItems[i].get('Extension_'+j + '__c') != null){
                    extentionIndex++;
                    newOpportunityLineItems[i].put('Extension_'+j + '__c', newOpportunityLineItems[i+extentionIndex].Id + '-' + newOpportunityLineItems[i+extentionIndex].Quantity_per_hectare__c);
                    updateThisOpp = true;
               }
                             
            }
            if(updateThisOpp){
                newOpportunityLineItems[i].TotalPrice = 0;
                mainOppsToUpdate.add(newOpportunityLineItems[i]);        
            }            
                        
        }

        if(!mainOppsToUpdate.isEmpty()){
            update mainOppsToUpdate;
        }


    }
    

//////////////////////////////////////////////////////////////////////////////////////////

    public Id doClone(String parentId) {
        Set<String> querySobject = new Set<String>();
        for(Super_Clone_Objects__mdt m : [select Id, DeveloperName, Label, API_Name__c 
                                          from Super_Clone_Objects__mdt  ]){ 
                                              querySobject.add(m.API_Name__c) ;  
                                          }
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        String objectAPIName = '';
        String keyPrefix = parentId.substring(0,3);
        for( Schema.SObjectType obj : schemaMap.Values() ){
            String prefix = obj.getDescribe().getKeyPrefix();
            if(prefix == keyPrefix){
                objectAPIName = obj.getDescribe().getName();
                break;
            }
        }
        Set <String> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap().keySet();
        List<String> finalFields = new List<String>() ;
        finalFields.addAll(fieldMap);
        
        SObjectType objToken = Schema.getGlobalDescribe().get(objectAPIName); 
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String,String> so = new Map<String,String>();
        Map<String,String> so1 = new Map<String,String>();
        
        for (Schema.ChildRelationship cr: objDef.getChildRelationships()) 
        {
            if(cr.getField().getDescribe().isAccessible()&& cr.getField().getDescribe().isCreateable()&&cr.getField().getDescribe().isAccessible() && cr.getRelationshipName()!=null){
                if(querySobject.contains(''+cr.getChildSObject())){
                    so.put(''+cr.getChildSObject()  , ''+cr.getRelationshipName());
                    so1.put(''+cr.getRelationshipName()  , ''+cr.getField());
                }
            }
        } 
        
        List<String> subqueries = prepareSubqueries(so, schemaMap);
        String query =
            'SELECT ' + String.join(finalFields, ',')+
            ','+String.join(subqueries, ',') +
            ' FROM ' +objectAPIName +
            ' WHERE Id = \''+parentId+'\'';
        
        List<Sobject> parentObj = Database.query(query);
        Sobject parentRecordId = parentObj[0];
        
        Sobject clonedRecord = parentRecordId.clone();
        insert clonedRecord;
        List<sObject> childObjects =cloneChildren(parentRecordId, clonedRecord, so  ,so1);
        insert childObjects;
        return clonedRecord.Id ;
        
    }
    
    private List<sObject> cloneChildren(
        Sobject parent,
        Sobject child,
        Map<String , String> childRelatedListObjects,
        Map<String , String> childRelatedListObjects1
    ){
        
        List<sObject> childObjects = new List<SObject>();
        for (String childObjectDefinition : childRelatedListObjects.values()) {
            List<sObject> parentRecords = parent.getSObjects(childObjectDefinition);
            if (parentRecords != null) {
                List<sObject> records = parentRecords.deepClone();
                for (sObject record : records) {
                    record.put(childRelatedListObjects1.get(childObjectDefinition), child.Id);
                }
                childObjects.addAll(records);
            }
        }
        return childObjects;
    }
    
    private List<String> prepareSubqueries(
        Map<String , String> childrelatedListObjects,
        Map <String, Schema.SObjectType> schemaMap
    ){
        List<String> subqueries = new List<String>();
        for(String childObject : childrelatedListObjects.keySet()){
            List<String> childFields = new List<String>();
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get(childObject).getDescribe().fields.getMap();
            for(Schema.SObjectField sof : fieldMap.values()){
                DescribeFieldResult dfr = sof.getDescribe();
                if(dfr.isCreateable()){
                        childFields.add(dfr.getName());
                }                
            }
            if(!childFields.isEmpty()){
                String query = '(SELECT ' + String.join(childFields, ',') + ' FROM ' + childrelatedListObjects.get(childObject) ;
                query += (childObject=='OpportunityLineItem' ?  + ' Order By Date__c, CreatedDate , LastModifiedDate DESC, Is_Extension__c' :'') ;
                query +=  ')';
                subqueries.add(query);
            }
            
        }
        return subqueries;
    }
    
}