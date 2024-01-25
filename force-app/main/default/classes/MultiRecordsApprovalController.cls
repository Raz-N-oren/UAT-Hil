/**
* @description       : 
* @author            : lilach mis
* @group             : 
* @last modified on  : 04-10-2022
* @last modified by  : lilach mis
**/
public with sharing class MultiRecordsApprovalController {
    
    //Wrapper class to store the column values of data table
    public class SubmittedRecordsWrapper{
        @AuraEnabled public Id workItemId;
        @AuraEnabled public Boolean isChecked;
        @AuraEnabled public String recordId;
        @AuraEnabled public String recDescription;
        @AuraEnabled public String relatedTo;// Object API Name
        @AuraEnabled public String recordName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ProductName;
        @AuraEnabled public String submittedBy;
        @AuraEnabled public String submittercomment;
        @AuraEnabled public String submittedDate;
        @AuraEnabled public String comments;
        @AuraEnabled public string LastActorId;
        @AuraEnabled public Object relatedObjRec;
        @AuraEnabled public Discount__c relatedDis;
        @AuraEnabled public Opportunity relatedOpp;
        @AuraEnabled public IL_Price_Book__c relatedIPB;
        @AuraEnabled public Discount_Matrix__c relatedDisMat;
        @AuraEnabled public New_Product_request__c relatedNPR;
    }
 
    @AuraEnabled
    public static Boolean getCurrentUserPermissionSetIds(){
        Boolean result = false;
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name = 'F_C_Sub_Admin' LIMIT 1];
        if (!permissionSets.isEmpty()){
            List<PermissionSetAssignment> assignments = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :permissionSets[0].Id AND AssigneeId = :UserInfo.getUserId()];
            result = !assignments.isEmpty();
        }
        return result;
    }
    
        @AuraEnabled
    public static List<SubmittedRecordsWrapper> getSubmittedRecords(){
        Set<Id> recIds 										= new Set<Id>();
        Map<string,SubmittedRecordsWrapper> relatedRecs 	= new Map<string,SubmittedRecordsWrapper>();
         List<ProcessInstance> allPI 						= new List<ProcessInstance>();
        Map<Id,string> mapDescription 						= new Map<Id,string>();
        List<SubmittedRecordsWrapper> lstSubmissionWrapper 	= new List<SubmittedRecordsWrapper>();
        
        List<PermissionSetAssignment> FCAdmin				= new  List<PermissionSetAssignment> ([select PermissionSetId,AssigneeId FROM PermissionSetAssignment 
                                                                                                  WHERE PermissionSet.Name='F_C_Sub_Admin'
                                                                                                  AND AssigneeId=:UserInfo.getUserId()]);
        
        if(FCAdmin.size()>0){
            allPI =[SELECT Id,TargetObjectId,TargetObject.Name,SubmittedBy.FirstName,SubmittedBy.LastName,
                    CreatedDate,LastActorId,LastActor.Name,
                    (SELECT ID FROM WorkItems ),
                    (SELECT Actor.Name,Comments FROM Steps WHERE StepStatus = 'Started') FROM ProcessInstance
                    ORDER BY CreatedDate DESC ]; 
        }else{
            allPI =[SELECT Id,TargetObjectId,TargetObject.Name,SubmittedBy.FirstName,SubmittedBy.LastName,
                    CreatedDate,LastActorId,LastActor.Name,
                    (SELECT ID FROM WorkItems WHERE  ActorId =:userInfo.getUserId()),
                    (SELECT Actor.Name,Comments FROM Steps WHERE StepStatus = 'Started') FROM ProcessInstance 
                    ORDER BY CreatedDate DESC ]; 
        }
        for(ProcessInstance TargetRecId :allPI){
            recIds.add(TargetRecId.TargetObjectId);
        }
        
        if(!recIds.isEmpty()){
   
            relatedRecs=getRelatedObjRecords(recIds);
            system.debug(loggingLEVEL.ERROR, 'relatedRecs SIZE:'+relatedRecs);
        }
        //Process instance stores the info of records submitted for approval,
        // Process instance work item are the records an approver sees while approving/rejecting, Process instance step stores approved/rejected record including approva;/rejection comments
        for(ProcessInstance PI :allPI){
            if(!PI.WorkItems.isEmpty()){
                SubmittedRecordsWrapper obj    = relatedRecs.get(PI.TargetObjectId);
                            system.debug(loggingLEVEL.ERROR, 'relatedRec:'+relatedRecs.get(PI.TargetObjectId));

                if(obj!=null){
                    obj.workItemId           = PI.WorkItems[0].Id;
                    obj.recordId             = PI.TargetObjectId;
                    obj.recordName           = PI.TargetObject.Name;
                    obj.comments             = '';
                    obj.LastActorId          = PI.LastActor.Name;
                    obj.submittedBy			 = PI.SubmittedBy.FirstName+' '+PI.SubmittedBy.LastName;
                    obj.submittedDate        = PI.CreatedDate.format();
                    
                    system.debug(loggingLevel.ERROR,'objSubmittedRecordsWrapper:'+obj);
                    
                    if(!PI.steps.isEmpty()){
                        obj.submittedBy = PI.steps[0].Actor.Name;
                        if(PI.steps[0].Comments == '' || PI.steps[0].Comments == null)
                            obj.submittercomment = 'No comments from submitter';
                        else
                            obj.submittercomment = PI.steps[0].Comments;
                    }
                    lstSubmissionWrapper.add(obj);
                    
                }
            }
        }
        system.debug('lstSubmissionWrapper.size():'+lstSubmissionWrapper.size());
        return lstSubmissionWrapper;
    }
    
    @AuraEnabled
    public static String processRecords(String processType,String strwraprecs){
        system.debug('processType'+processType);
        system.debug('wraprecs'+strwraprecs);
        List<SubmittedRecordsWrapper> wraprecs = (List<SubmittedRecordsWrapper>)System.JSON.deserialize(strwraprecs, List<SubmittedRecordsWrapper>.class);
        Map<string,SubmittedRecordsWrapper> mapSubmittedRecordsWrapper = new map<String,SubmittedRecordsWrapper>();
        List<String> lstWorkItemIds = new List<String>();
        for(SubmittedRecordsWrapper iwrap: wraprecs){
            mapSubmittedRecordsWrapper.put(iwrap.workItemId,iwrap);
            lstWorkItemIds.add(iwrap.workItemId);
        }
        
        //Approve,reject the record programmatically
        String message = ''; 
        Integer recordsProcessed = 0;
        String comments = processType == 'Approve' ? 'Approved' : 'Rejected';
        List<Approval.ProcessWorkitemRequest> lstWorkItemRequest = new List<Approval.ProcessWorkitemRequest>();//ProcessWorkitemRequest class has methods to programmatically process submitted records
        for(String workItemId : lstWorkItemIds){
            Approval.ProcessWorkitemRequest objWorkItemRequest = new Approval.ProcessWorkitemRequest();
            if(mapSubmittedRecordsWrapper.containsKey(workItemId))
                objWorkItemRequest.setComments(mapSubmittedRecordsWrapper.get(workItemId).comments);
            else
                objWorkItemRequest.setComments(comments);
            objWorkItemRequest.setAction(processType);//approve or reject
            objWorkItemRequest.setWorkitemId(workItemId);
            lstWorkItemRequest.add(objWorkItemRequest);
        }
        Approval.ProcessResult[] lstProcessResult = Approval.process(lstWorkItemRequest,FALSE);//process method is used for approving/rejecting records depending on setAction attribute
        for(Approval.ProcessResult processResult : lstProcessResult){
            if(processResult.isSuccess()){
                recordsProcessed++;
            }
            else{
                for(Database.Error error : processResult.getErrors()){
                    message += error.getMessage();
                }
            }
        }
        if(recordsProcessed == lstWorkItemIds.size()){
            message = 'All records are '+comments+' successfully';
        }
        return message;
    }
    
    public static  Map<string,SubmittedRecordsWrapper> getRelatedObjRecords(Set<Id> recIds){
        Manage_Approval_Objects__mdt getObjFields = [SELECT ILPriceBookFields__c,DiscountFields__c,
                                                     OpportunityFields__c,OpportunityLineItemFields__c 
                                                     FROM Manage_Approval_Objects__mdt];
        string[] relatedOBJ=new  string[] {'Discount__c','Opportunity','IL_Price_Book__c' ,'Discount_Matrix__c', 'New_Product_request__c'};
        string relatedFields;
          Map<string,SubmittedRecordsWrapper> relatedRec = new Map<string,SubmittedRecordsWrapper>();
     
        try {
            for(string objName:relatedOBJ){
                Switch on objName{
                      WHEN 'IL_Price_Book__c'{
                          relatedFields		= getObjFields.ILPriceBookFields__c!=null?getObjFields.ILPriceBookFields__c:null;
                        relatedRec.putAll(dynamicQuery(relatedFields,relatedRec ,recIds,objName));
                    }
                    WHEN 'Discount__c'{
                        relatedFields			= getObjFields.DiscountFields__c!=null?getObjFields.DiscountFields__c:null;
                        relatedRec.putAll(dynamicQuery(relatedFields,relatedRec ,recIds,objName));
                    }
                       WHEN 'Discount_Matrix__c'{
                        relatedFields			= '';
                        relatedRec.putAll(dynamicQuery(relatedFields,relatedRec ,recIds,objName));
                    }
                       WHEN 'New_Product_request__c'{
                      relatedFields			= '';
                        relatedRec.putAll(dynamicQuery(relatedFields,relatedRec ,recIds,objName));
                    }
                    WHEN 'Opportunity'{
                       relatedFields		= getObjFields.OpportunityFields__c!=null?getObjFields.OpportunityFields__c:null;
                        relatedRec.putAll(dynamicQuery(relatedFields,relatedRec ,recIds,objName));
                        string relatedOppItemsFields= getObjFields.OpportunityLineItemFields__c!=null?getObjFields.OpportunityLineItemFields__c:null;
                         relatedRec.putAll(dynamicQuery(relatedOppItemsFields,relatedRec ,recIds,'OpportunityLineItem'));      
                    }
                }
            }

        } catch (Exception e) {
            system.debug(loggingLevel.ERROR, 'Error msg:'+e.getCause()+'--'+e.getLineNumber()+'--'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        system.debug(loggingLevel.ERROR, 'relatedRec size:'+relatedRec);
        return relatedRec;
    }
    
    public static  Map<string,SubmittedRecordsWrapper> dynamicQuery(string fields,Map<string,SubmittedRecordsWrapper> relatedRec ,Set<Id> recIds,string objName){
        Map<string,SubmittedRecordsWrapper> recMap = new Map<string,SubmittedRecordsWrapper>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objSchema = schemaMap.get(objName);
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
        Map<string,List<string>> lookupfieldsName = setLookUpMap(recIds,objName);
       
        string soqlfields=fields!=''?','+fields.replaceAll(';',','):'';
        string soql = 'SELECT Id,Name '+soqlfields;
        soql+=objName!='OpportunityLineItem'?' FROM '+objName+' WHERE '+' Id IN:recIds' :',OpportunityId,toLabel(CurrencyIsoCode),CurrencyImage__c,product2.Name, toLabel(Unit_of_measure__c), TotalPrice  FROM '+objName+' WHERE OpportunityId IN:recIds'; 
         fields=fields.remove('toLabel(').remove(')');        
        string[] fieldsArray = fields!=null && fields!=''?fields.split(';'):null;
        system.debug(loggingLevel.ERROR, 'dynamicQuery:'+soql);
       


            SWITCH ON objName{
                WHEN 'OpportunityLineItem'{
                    for(OpportunityLineItem rec:database.query(soql)){
                         SubmittedRecordsWrapper recSRW = new SubmittedRecordsWrapper();
                        recSRW.recordId					= rec.Id;
                        recSRW.recordName				= rec.Name;
                        recSRW.relatedObjRec			= rec;
                        recSRW.relatedTo        		= objSchema.getDescribe().getLabel();
                        system.debug('recSRW.relatedObjRec:'+recSRW.relatedObjRec);
                        setDescription(objName,recSRW,relatedRec,fieldsArray, rec,fieldMap,lookupfieldsName);
                        recMap.put(rec.Id,recSRW);
                        system.debug('recMap:'+recMap +'\n'+recMap.size());
                    }
                }
                WHEN 'IL_Price_Book__c'{
                    for(IL_Price_Book__c IPB:database.query(soql)){
                         SubmittedRecordsWrapper recSRW = new SubmittedRecordsWrapper();
                        recSRW.relatedIPB		= IPB;
                        recSRW.accountName		= IPB.Account__r.Name;
                        recSRW.relatedTo        = objSchema.getDescribe().getLabel();
                        system.debug('recSRW.relatedObjRec:'+recSRW.relatedIPB);
                        setDescription(objName,recSRW,relatedRec,fieldsArray, IPB,fieldMap,lookupfieldsName);
                        recMap.put(IPB.Id,recSRW);
                    }
                }
                WHEN 'Discount__c'{
                    for(Discount__c DIS:database.query(soql)){
                         SubmittedRecordsWrapper recSRW = new SubmittedRecordsWrapper();
                        recSRW.relatedDis				= DIS;
                        recSRW.accountName				= DIS.Account__r.Name;
                        recSRW.relatedTo        		= objSchema.getDescribe().getLabel();
                        system.debug('recSRW.relatedObjRec:'+recSRW.relatedDis);
                        setDescription(objName,recSRW,relatedRec,fieldsArray, DIS,fieldMap,lookupfieldsName);

                        recMap.put(DIS.Id,recSRW);
                    }
                }
                WHEN 'Discount_Matrix__c'{
                    for(Discount_Matrix__c DISMAT:database.query(soql)){
                        SubmittedRecordsWrapper recSRW = new SubmittedRecordsWrapper();
                        recSRW.relatedDisMat	= DISMAT;
                        recSRW.relatedTo        = objSchema.getDescribe().getLabel();
                        system.debug('recSRW.relatedObjRec:'+recSRW.relatedDisMat);
                        setDescription(objName,recSRW,relatedRec,fieldsArray, DISMAT,fieldMap,lookupfieldsName);
                        recMap.put(DISMAT.Id,recSRW);
                    }
                }
                WHEN 'New_Product_request__c'{
                    for(New_Product_request__c NPR:database.query(soql)){
                         SubmittedRecordsWrapper recSRW = new SubmittedRecordsWrapper();
                        recSRW.relatedNPR	= NPR;
                        recSRW.relatedTo    = objSchema.getDescribe().getLabel();
                        system.debug('recSRW.relatedObjRec:'+recSRW.relatedNPR);
                        setDescription(objName,recSRW,relatedRec,fieldsArray, NPR,fieldMap,lookupfieldsName);
                        recMap.put(NPR.Id,recSRW);
                    }
                }
                WHEN 'Opportunity'{
                    for(Opportunity OPP:database.query(soql)){
                        SubmittedRecordsWrapper recSRW = new SubmittedRecordsWrapper();
                        recSRW.relatedOpp	= OPP;
                        recSRW.accountName		= OPP.Account.Name;
                        recSRW.relatedTo        = objSchema.getDescribe().getLabel();
                        system.debug('recSRW.relatedObjRec:'+recSRW.relatedOpp);
                        setDescription(objName,recSRW,relatedRec,fieldsArray, OPP,fieldMap,lookupfieldsName);
                        recMap.put(OPP.Id,recSRW);
                    }
                }
            }
        return recMap;
    }
    
    private Static void setDescription(string objName, SubmittedRecordsWrapper recSRW,Map<string,SubmittedRecordsWrapper> relatedRec,string[] fieldsArray, sobject rec,Map<String, Schema.SObjectField> fieldMap,Map<string,List<string>> lookupfieldsName ){
        string Description = '';
        if(fieldsArray!=null && objName!='OpportunityLineItem' ){
            for(Integer i = 0; i < fieldsArray.size(); i++){
                if(objName=='Opportunity' ){
                    Description+= recSRW.accountName +'\nמ '+modifyDateFormat(string.valueOf(rec.get('Valid_from__c')))+' עד- '+modifyDateFormat(string.valueOf(rec.get('Valid_To__c')))+'\n';
                    break; 
                }
                else if( !fieldsArray[i].contains('.Name')){
                    string  fId=lookupfieldsName.get(string.valueOf(rec.get(fieldsArray[i])))!=null?lookupfieldsName.get(string.valueOf(rec.get(fieldsArray[i])))[1]:string.valueOf(rec.get(fieldsArray[i]));
                    
                    if(fId!=null && fId!='' && fId.toLowerCase()!='false'){
                        //Date modification
                        if( string.valueOf(fieldMap.get(fieldsArray[i]).getDescribe().getType())=='DATE'){
                           modifyDateFormat(fid);
                        }
                        string label = fieldMap.get(fieldsArray[i]).getDescribe().getLabel();
                        Description+=label+':'+fId+'\n';
                    }  
                }
            }
        }
        if(objName=='OpportunityLineItem' ){
            OpportunityLineItem oppItem= (OpportunityLineItem)recSRW.relatedObjRec;
            Description+= oppItem.product2.Name+' '+oppItem.TotalPrice+' '+oppItem.CurrencyImage__c+' '+oppItem.Unit_of_measure__c+'\n';
            recSRW=  relatedRec.get(string.valueOf(rec.get('OpportunityId')));
            recSRW.ProductName=recSRW.ProductName==null?oppItem.product2.Name:recSRW.ProductName+';'+oppItem.product2.Name;
            recSRW.recDescription+=Description!=null?Description:'';
        }
        else if(objName=='Discount_Matrix__c'||objName=='New_Product_request__c' ){
            recSRW.recDescription 	= 'יש ללחוץ על הכותרת של האישור';
        }
        else{
            recSRW.recDescription 	= Description;
        }
    }

    private static Map<string,List<string>>  setLookUpMap(Set<Id> recIds,string objName){
        Map<string,List<string>> lookupfieldsName = new Map<string,List<string>>();
        
        Switch on objName{
            WHEN 'Discount__c'{
                for(Discount__c disc:[SELECT Account__c,Account__r.Name,Settlement__r.Name,Product__r.Name,
                                      Product_Family_new__r.Name,Sub_Product_Family__r.Name FROM Discount__c 
                                      WHERE Id IN:recIds]){
                                          if(disc.Account__c!=null){
                                              lookupfieldsName.put(disc.Account__c,new List<String>{'account',disc.Account__r.Name});
                                          }
                                          if(disc.Settlement__c!=null){
                                              lookupfieldsName.put(disc.Settlement__c,new List<String>{'settelment',disc.Settlement__r.Name});
                                          } 
                                          if(disc.Product__c!=null){
                                              lookupfieldsName.put(disc.Product__c,new List<String>{'Product',disc.Product__r.Name});
                                          } 
                                          if(disc.Product_Family_new__c!=null){
                                              lookupfieldsName.put(disc.Product_Family_new__c,new List<String>{'Product_Family',disc.Product_Family_new__r.Name});
                                          } 
                                          if(disc.Sub_Product_Family__c!=null){
                                              lookupfieldsName.put(disc.Sub_Product_Family__c,new List<String>{'Sub_Family',disc.Sub_Product_Family__r.Name});
                                          } 
                                      }
            }
            WHEN 'Opportunity'{
                for(Opportunity opp:[SELECT AccountId,Account.Name
                                     FROM Opportunity 
                                     WHERE Id IN:recIds]){
                                         if(opp.AccountId!=null){
                                             lookupfieldsName.put(opp.AccountId,new List<String>{'account',opp.Account.Name});
                                         }
                                         
                                     }
                
                
            }
            WHEN 'OpportunityLineItem'{
                for(OpportunityLineItem opp:[SELECT OpportunityId,Opportunity.Name,Loading_Point__c, Loading_Point__r.Name,Product2Id,Product2.Name
                                             FROM OpportunityLineItem 
                                             WHERE OpportunityId IN:recIds]){
                                                 if(opp.OpportunityId!=null){
                                                     lookupfieldsName.put(opp.OpportunityId,new List<String>{'Opportunity',opp.Opportunity.Name});
                                                 }
                                                 if(opp.Loading_Point__c!=null){
                                                     lookupfieldsName.put(opp.Loading_Point__c,new List<String>{'LoadingPoint',opp.Loading_Point__r.Name});
                                                 }
                                                 if(opp.Loading_Point__c!=null){
                                                     lookupfieldsName.put(opp.Loading_Point__c,new List<String>{'LoadingPoint',opp.Loading_Point__r.Name});
                                                 }
                                                 if(opp.Product2Id!=null){
                                                     lookupfieldsName.put(opp.Product2Id,new List<String>{'Product',opp.Product2.Name});
                                                 }
                                                 
                                             }
                
                
            }
            WHEN 'IL_Price_Book__c'{
                for(IL_Price_Book__c IL:[SELECT Account__c,Account__r.Name,Product_Service__c,Product_Service__r.Name,
                                         Product_Family_new__c,Product_Family_new__r.Name,Loading_Point__c,
                                         Loading_Point__r.Name,Opportunity__c,Opportunity__r.Name,OwnerId,Owner.Name
                                         FROM IL_Price_Book__c 
                                         WHERE Id IN:recIds]){
                                             lookupfieldsName.put(IL.OwnerId,new List<String>{'Owner',IL.Owner.Name});
                                             
                                             if(IL.Account__c!=null){
                                                 lookupfieldsName.put(IL.Account__c,new List<String>{'account',IL.Account__r.Name});
                                             }
                                             if(IL.Product_Service__c!=null){
                                                 lookupfieldsName.put(IL.Product_Service__c,new List<String>{'product',IL.Product_Service__r.Name});
                                             } 
                                             if(IL.Product_Family_new__c!=null){
                                                 lookupfieldsName.put(IL.Product_Family_new__c,new List<String>{'Product_Family',IL.Product_Family_new__r.Name});
                                             } 
                                             if(IL.Loading_Point__c!=null){
                                                 lookupfieldsName.put(IL.Loading_Point__c,new List<String>{'Loading_Point',IL.Loading_Point__r.Name});
                                                 
                                             }
                                             if(IL.Opportunity__c!=null){
                                                 lookupfieldsName.put(IL.Opportunity__c,new List<String>{'Opportunity',IL.Opportunity__r.Name});
                                                 
                                             }
                                         }
            }
        }
        return lookupfieldsName;
    }
    
    private static Map<string,List<string>>  setRelationshipRecords(Set<Id> recIds,string objName){
        Map<string,List<string>> lookupfieldsName = new Map<string,List<string>>();
        
        Switch on objName{
            WHEN 'Discount__c'{
                for(Discount__c disc:[SELECT Account__c,Account__r.Name,Settlement__r.Name,Product__r.Name,TonPriceAfterDiscount__c,
                                      Product_Family_new__r.Name,Sub_Product_Family__r.Name FROM Discount__c 
                                      WHERE Id IN:recIds]){
                                          if(disc.Account__c!=null){
                                              lookupfieldsName.put(disc.Account__c,new List<String>{'account',disc.Account__r.Name});
                                          }
                                          if(disc.Settlement__c!=null){
                                              lookupfieldsName.put(disc.Settlement__c,new List<String>{'settelment',disc.Settlement__r.Name});
                                          } 
                                          if(disc.Product__c!=null){
                                              lookupfieldsName.put(disc.Product__c,new List<String>{'Product',disc.Product__r.Name});
                                          } 
                                          if(disc.Product_Family_new__c!=null){
                                              lookupfieldsName.put(disc.Product_Family_new__c,new List<String>{'Product_Family',disc.Product_Family_new__r.Name});
                                          } 
                                          if(disc.Sub_Product_Family__c!=null){
                                              lookupfieldsName.put(disc.Sub_Product_Family__c,new List<String>{'Sub_Family',disc.Sub_Product_Family__r.Name});
                                          } 
                                      }
            }
            WHEN 'Opportunity'{
                for(Opportunity opp:[SELECT AccountId,Account.Name
                                     FROM Opportunity 
                                     WHERE Id IN:recIds]){
                                         if(opp.AccountId!=null){
                                             lookupfieldsName.put(opp.AccountId,new List<String>{'account',opp.Account.Name});
                                         }
                                         
                                     }
                
                
            }
            WHEN 'OpportunityLineItem'{
                for(OpportunityLineItem opp:[SELECT OpportunityId,Opportunity.Name,Loading_Point__c, Loading_Point__r.Name,Product2Id,Product2.Name
                                             FROM OpportunityLineItem 
                                             WHERE OpportunityId IN:recIds]){
                                                 if(opp.OpportunityId!=null){
                                                     lookupfieldsName.put(opp.OpportunityId,new List<String>{'Opportunity',opp.Opportunity.Name});
                                                 }
                                                 if(opp.Loading_Point__c!=null){
                                                     lookupfieldsName.put(opp.Loading_Point__c,new List<String>{'LoadingPoint',opp.Loading_Point__r.Name});
                                                 }
                                                 if(opp.Loading_Point__c!=null){
                                                     lookupfieldsName.put(opp.Loading_Point__c,new List<String>{'LoadingPoint',opp.Loading_Point__r.Name});
                                                 }
                                                 if(opp.Product2Id!=null){
                                                     lookupfieldsName.put(opp.Product2Id,new List<String>{'Product',opp.Product2.Name});
                                                 }
                                                 
                                             }
                
                
            }
            WHEN 'IL_Price_Book__c'{
                for(IL_Price_Book__c IL:[SELECT Account__c,Account__r.Name,Product_Service__c,Product_Service__r.Name,
                                         Product_Family_new__c,Product_Family_new__r.Name,Loading_Point__c,
                                         Loading_Point__r.Name,Opportunity__c,Opportunity__r.Name,OwnerId,Owner.Name
                                         FROM IL_Price_Book__c 
                                         WHERE Id IN:recIds]){
                                             lookupfieldsName.put(IL.OwnerId,new List<String>{'Owner',IL.Owner.Name});
                                             
                                             if(IL.Account__c!=null){
                                                 lookupfieldsName.put(IL.Account__c,new List<String>{'account',IL.Account__r.Name});
                                             }
                                             if(IL.Product_Service__c!=null){
                                                 lookupfieldsName.put(IL.Product_Service__c,new List<String>{'product',IL.Product_Service__r.Name});
                                             } 
                                             if(IL.Product_Family_new__c!=null){
                                                 lookupfieldsName.put(IL.Product_Family_new__c,new List<String>{'Product_Family',IL.Product_Family_new__r.Name});
                                             } 
                                             if(IL.Loading_Point__c!=null){
                                                 lookupfieldsName.put(IL.Loading_Point__c,new List<String>{'Loading_Point',IL.Loading_Point__r.Name});
                                                 
                                             }
                                             if(IL.Opportunity__c!=null){
                                                 lookupfieldsName.put(IL.Opportunity__c,new List<String>{'Opportunity',IL.Opportunity__r.Name});
                                                 
                                             }
                                         }
            }
        }
        return lookupfieldsName;
    }
    
    private static string modifyDateFormat(string fId){
        if(fId!=null){
            date dt =date.valueOf(fId);
            fId=dt.day()+'/'+dt.month()+'/'+dt.year();
          
        }
          return fId;
    }
}