public with sharing class OrderCustomerController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccountNameMethod (String accStrName){
        
        String searchValue = accStrName;
        List<sObject> returnList = new List <sObject>();
        // CHANGE BY YARON TO REMOVE THE OBJECT Branch_growth__c FROM THE SELECT
        String query1 = 'FIND \''+searchValue+'\' IN NAME FIELDS RETURNING Account(Id,Name, SAP_Account_Group__c, AccountSource,AccountDivision__c, LastViewedDate, Setelment__c, Sensitive_Customer__c, Default_warehouse__c, Default_warehouse__r.Name, Default_warehouse__r.Parent.Name, Default_warehouse__r.ParentId WHERE Sap_Number__c != null AND Status__c != \''+'Inactive Credit'+'\''+' AND Status__c != \''+'Inactive'+'\''+') LIMIT 30';
      //24/08/23  String query1 = 'FIND \''+searchValue+'\' IN NAME FIELDS RETURNING Account(Id,Name, SAP_Account_Group__c, AccountSource,AccountDivision__c, LastViewedDate, Setelment__c, Sensitive_Customer__c, Default_warehouse__c, Default_warehouse__r.Name, Default_warehouse__r.Parent.Name, Default_warehouse__r.ParentId WHERE Sap_Number__c != null AND Status__c != \''+'Inactive Credit'+'\''+' AND Status__c != \''+'Inactive'+'\''+'),Branch_growth__c(Name, Account__c, AccountName__c) LIMIT 30';
       // String query1 = 'FIND \''+searchValue+'\' IN NAME FIELDS RETURNING Account(Id,Name, SAP_Account_Group__c, AccountSource,AccountDivision__c, LastViewedDate, Setelment__c, Sensitive_Customer__c, Default_warehouse__c, Default_warehouse__r.Name, Default_warehouse__r.Parent.Name, Default_warehouse__r.ParentId),Branch_growth__c(Name, Account__c, AccountName__c) LIMIT 30';
        System.debug(logginglevel.ERROR,'squery1 FIND b4 sending to DB ' + query1);
        List <list<sObject>> lstOfRecords = search.query(query1);
        for (List<SObject> dynamicList: lstOfRecords) {
            for (sObject obj: dynamicList) {
                returnList.add(obj);
            }
        }
        return returnList;
    }
    
    @AuraEnabled
    public static void updateTankStatus(String recordId) {
        // Create a new Tank__c object with the specified Id and Status__c value
        Tank__c tank = new Tank__c(Id = recordId, Status__c = true);
        try {
            // Update the Tank__c record in the database
            Database.update(tank);
        } catch (DmlException e) {
            // Handle any exceptions that occur during the update
            for (Integer i = 0; i < e.getNumDml(); i++) {
                System.debug('DML Operation ' + i + ' failed: ' + e.getDmlMessage(i));
            }
        }
    }
    
    @AuraEnabled
    public static Boolean isProductChosen(String recordId, String productId){
        Boolean orderedBefore = false;
        List<OrderItem> relatedOrderItems = [SELECT Id, Product2Id, Product2.Name FROM OrderItem WHERE Order.AccountId = :recordId AND Product2Id = :productId];
        orderedBefore = relatedOrderItems.size() > 0?true:false;
        return orderedBefore;
    }

    @AuraEnabled
    public static Boolean isHazardMaterial(String productId) {
        boolean isHazardMaterial= false;
        Product2 p = [SELECT Dingers_Good__c FROM Product2 WHERE Id = :productId LIMIT 1];
        System.debug(logginglevel.Error+'001. isHazardous: ' + p);
        isHazardMaterial=String.isBlank(p.Dingers_Good__c)?true:false;
        return isHazardMaterial;
    } 

    @AuraEnabled
    public static List<SObject> getProductNameAndDetails(String productId) {
        return [SELECT Name, IL_BU__c, IL_Group_name__c, Packing__c, QuantityUnitOfMeasure FROM Product2 WHERE Id =: productId LIMIT 1];
    } 
    
    @AuraEnabled
    public static List<SObject> isFramDealExit(String recordId, string productId){
        List<OrderItem> relatedOrderItems = new List<OrderItem>([
            SELECT Id, Product2Id, Product2.Name, orderId, order.OrderCreatedDate__c, order.Payer_Approval__c, framework_agreement_Usege_Quntity__c, Price_from_customer_order__c,DeliveryUnitOfMeasure__c ,DeliveryPrice__c
            FROM OrderItem WHERE order.AccountId = :recordId AND Product2Id = :productId AND order.TransactionType__c = '70' AND order.Status NOT IN ('50', '60') AND Status__c NOT IN ('40', '50')
        ]);
        System.debug(logginglevel.ERROR,'isFramDealExit: relatedOrderItems: ' + relatedOrderItems );
        return relatedOrderItems;
    }
    
    @AuraEnabled
    public static List<SObject> getFramDealDetails(String recordId, string productId){
        List<OrderItem> relatedOrderItems = new List<OrderItem>([SELECT Id, Product2Id, Quantity,Product2.Name,orderId,order.OrderCreatedDate__c,order.Payer_Approval__c,framework_agreement_Usege_Quntity__c,Price_from_customer_order__c,DeliveryPrice__c,DeliveryUnitOfMeasure__c FROM OrderItem WHERE order.AccountId = :recordId  
                                                                 AND Product2Id=:productId AND  order.TransactionType__c =: '70' AND order.Status NOT IN ('50', '60') AND Status__c NOT IN ('40', '50')]);
        return relatedOrderItems;
    }
    

    @AuraEnabled
    public static void updateOrderAndOrderItemStatusNew(Id orderId, Id orderItemId){
        // Get the Order and OrderItem objects
        Order order = [SELECT Id, Status FROM Order WHERE Id = :orderId];
        Map<Id,OrderItem> orderItemList = new Map<Id,OrderItem>([SELECT Id, Status__c FROM OrderItem WHERE orderId = :orderId]);
        for(OrderItem rec:orderItemList.values()){
            orderItemList.get(rec.Id).status__c='70';
        }
        // Update the Status fields
        order.Status = '50';
        // Save the changes
        update order;
        update orderItemList.values();     
    }

    @AuraEnabled
    public static List<SObject> getWarehousePhone(String accountId){
        return [SELECT Phone FROM Account where Id =: accountId LIMIT 1];
    }
    
    @AuraEnabled
    public static string getDefaultLP(){
        List<DefaultLoadingPoint__c> defaultLP = [select loadingPointId__c  from DefaultLoadingPoint__c];
        return defaultLP[0].loadingPointId__c;
    }
    
    @AuraEnabled
    public static List<Account> getAccountAndContacts(String recordId){
        return [SELECT Id, Name, Website, SAP_Account_Group__c, Phone, (SELECT Name, Email, Phone FROM Contacts) FROM Account WHERE Id = :recordId AND Sap_Number__c != null];
    }
    
    @AuraEnabled
    public static List<Contact> getContactsForAccount(String recordId){
        return [SELECT Id, Name, Email, Phone, MobilePhone,Job_Tittle__c FROM Contact WHERE AccountId = :recordId AND OperationalContact__c = true];
    }
    @AuraEnabled
    public static List<Branch_Contact_Link__c> getContactsForBranch(String recordId){
        return [SELECT 	Id, BranchGrowth__c, Contact__r.Name, Contact__r.Phone, Contact__r.Job_Tittle__c, Contact__r.MobilePhone, Contact__r.Email FROM Branch_Contact_Link__c WHERE BranchGrowth__c = :recordId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> recentlyViewRecords(){
        
        return [SELECT Id, Name,LastViewedDate, AccountDivision__c, Setelment__c, Sensitive_Customer__c, AccountSource, SAP_Account_Group__c, Default_warehouse__c, Default_warehouse__r.Name, Default_warehouse__r.Parent.Name, Default_warehouse__r.ParentId FROM Account WHERE LastViewedDate != null AND Sap_Number__c != null ORDER BY LastViewedDate DESC limit 10];
    }
    
    @AuraEnabled
    public static List<SObject> getParentAccount(String recordId){
        return [SELECT Account__c, Account__r.SAP_Account_Group__c, Account__r.Name FROM Branch_growth__c WHERE Id = :recordId];
    }
    
    @AuraEnabled
    public static List<Product2> searchProductByNameMethod(String searchText){
        String searchValue = searchText;
        List<sObject> returnList = new List <sObject>();
        String query1 = 'FIND \''+searchValue+'\' IN NAME FIELDS RETURNING Product2(Id, Name, Global_Product_Group__c, Sap_Number__c, QuantityUnitOfMeasure, Quantity_in_surface__c, IL_Group__c, Accumulation_state__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id, specific_gravity__c, LoadingPoint__c,LoadingPoint__r.Name,LoadingPoint__r.LoadingPointType__c,NumberOfOrders__c, IL_BU__c, IL_Group_name__c, Packing__c WHERE CurrencyIsoCode=\''+'ILS'+'\' AND IsActive=true ORDER BY NumberOfOrders__c DESC,NAME ASC) LIMIT 20';
        // String query1 = 'FIND \''+searchValue+'\' IN NAME FIELDS RETURNING Product2(Id, Name, Sap_Number__c, QuantityUnitOfMeasure, Quantity_in_surface__c, IL_Group__c, Accumulation_state__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id,Extension_6__r.Name, Extension_6__r.Id,Extension_7__r.Name, Extension_7__r.Id,Extension_8__r.Name, Extension_8__r.Id,LoadingPoint__c ) LIMIT 20';
        //  String query1 = 'FIND {' +searchValue +'} IN NAME FIELDS RETURNING Product2(Id, Name, Sap_Number__c, QuantityUnitOfMeasure, Quantity_in_surface__c, IL_Group__c, Accumulation_state__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id,Extension_6__r.Name, Extension_6__r.Id,Extension_7__r.Name, Extension_7__r.Id,Extension_8__r.Name, Extension_8__r.Id WHERE CurrencyIsoCode__c= ' +'ILS '+ ') LIMIT 30';
        System.debug(logginglevel.ERROR,'squery1 FIND b4 sending to DB ' + query1);
        List <list<sObject>> lstOfRecords = search.query(query1);
        for (List<SObject> dynamicList: lstOfRecords) {
            for (sObject obj: dynamicList) {
                returnList.add(obj);
            }
        }
        system.debug(loggingLevel.ERROR,'searchProductByNameMethod results:'+returnList);
        return returnList;
        // String searchValue = '%'+searchText+'%';
        // return [SELECT Id, Name, Sap_Number__c, QuantityUnitOfMeasure, Quantity_in_surface__c, IL_Group__c, Accumulation_state__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id,Extension_6__r.Name, Extension_6__r.Id,Extension_7__r.Name, Extension_7__r.Id,Extension_8__r.Name, Extension_8__r.Id FROM Product2 WHERE Name like :searchValue limit 20];
    }
    @AuraEnabled
    public static List<Product2> searchProductByNameAndMasterProductMethod(String searchText, String masterProduct){
        //String searchValue = '%'+searchText+'%';
        // return [SELECT Id, Name, Sap_Number__c, QuantityUnitOfMeasure, Quantity_in_surface__c, IL_Group__c, Accumulation_state__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id,Extension_6__r.Name, Extension_6__r.Id,Extension_7__r.Name, Extension_7__r.Id,Extension_8__r.Name, Extension_8__r.Id FROM Product2 WHERE Name like :searchValue AND Product_hierarchy__r.Name = :masterProduct limit 20];
        List<sObject> returnList = new List <sObject>();
        
        String searchValue =searchText;
        System.debug(logginglevel.ERROR,'searchProductByNameAndMasterProductMethod: searchText: ' + searchValue + '  -->masterProduct'+ masterProduct);
        
        String query1 = 'FIND {' +searchValue +'} IN NAME FIELDS RETURNING Product2(Id, Name, Sap_Number__c, QuantityUnitOfMeasure, Quantity_in_surface__c, IL_Group__c, Accumulation_state__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id,Extension_6__r.Name, Extension_6__r.Id,Extension_7__r.Name, Extension_7__r.Id,Extension_8__r.Name, Extension_8__r.Id, specific_gravity__c, LoadingPoint__c,LoadingPoint__r.Name,LoadingPoint__r.LoadingPointType__c, IL_BU__c, IL_Group_name__c, Packing__c WHERE Product_hierarchy__r.Name = :masterProduct AND IsActive=true) LIMIT 10';
        System.debug('squery1 FIND b4 sending to DB ' + query1);
        List <list<sObject>> lstOfRecords = search.query(query1);
        for (List<SObject> dynamicList: lstOfRecords) {
            for (sObject obj: dynamicList) {
                returnList.add(obj);
            }
        }
        system.debug(loggingLevel.ERROR,'searchProductByNameAndMasterProductMethod results:'+returnList);

        return returnList;
        
    }
    
    @AuraEnabled
    public static List<SObject> getSalesPoints(){
        // return [SELECT Id, Name, LoadingPointName__c , LoadingPointSapId__c, LoadingPointType__c FROM LoadingPoint__c ];
       return [SELECT Id, Name, LoadingPointName__c , LoadingPointSapId__c, LoadingPointType__c FROM LoadingPoint__c WHERE LoadingPointType__c != 'מחסן קונסיגנציה'];
    }
    
    @AuraEnabled
    public static List<SObject> getTankPoints(String accountId){
        return [SELECT Id, Name, Account__c, Account__r.Name, RelatedContact__c, RelatedContact__r.Name, RelatedContact__r.Phone, RelatedContact__r.MobilePhone FROM Tank__c WHERE Account__c = :accountId];
    }
    
    @AuraEnabled
    public static List<Account> getNotesToAccount(String recordId){
        return [SELECT Id, Regular_note_to_the_driver__c, Note_for_discharge__c, Description FROM Account WHERE Id = :recordId];
    }
    
    @AuraEnabled
    public static List<SObject> getLastOrdersForAccount(String recordId, Integer offset){
        // return [SELECT Id, OwnerId, AccountId, Account.Name, Account.SAP_Account_Group__c , Account.AccountDivision__c, Description, Account.AccountSource , PrivateTransport__c, PassingPermit__c, RequestedSupplyDate__c, TransactionType__c, Status, EffectiveDate, ActivatedDate, ActivatedById, OrderNumber, TotalAmount ,CreatedDate, CreatedById, LastModifiedById, IsDeleted, LastViewedDate, LastReferencedDate ,AgentReceivesCommission__c,AgentReceivesCommission__r.Name,IntermediaryWarehouse__c, IntermediaryWarehouse__r.Name, Paying_Customer__c, Paying_Customer__r.Name , Branch_growth__c,Branch_growth__r.Name, Payer_Approval__c, Invoice__c, BioHazardousMaterialCheck__c, InventoryCheck__c, (SELECT Id, Product2Id, Product2.Name, RelatedContactName__c, Product2.QuantityUnitOfMeasure, Product2.Sap_Number__c, Product2.IL_Group__c, Product2.Accumulation_state__c, RelatedContactPhone__c, DeliveryNoteExist__c, Status__c, RefuelingTransport__c, IsDeleted, OrderId, Quantity, UnitPrice, TotalPrice, Description, CreatedDate, CreatedById, NonFreightCharge__c,Extension_1__c,Extension_2__c,Extension_3__c ,Extension_1__r.Name,Extension_2__r.Name,Extension_3__r.Name ,Extension_Quantity_1__c,Extension_Quantity_2__c,Extension_Quantity_3__c,Extension_Unit_1__c,Extension_Unit_2__c,Extension_Unit_3__c, OrderItemNumber, OriginalDeliveryNote__c, Plot__c, UnitOfMeasure__c, DischargeLocation__c,DischargeLocation__r.Name, LoadingPoint__c, LoadingPoint__r.LoadingPointName__c, Price_from_customer_order__c, Purchase_Order__c, combined_Packaging__c, combinedTransport__c, Truck_code__c, DeliveryDate__c, specialTransport__c FROM OrderItems) from Order WHERE AccountId = :recordId Order by CreatedDate DESC LIMIT 10 OFFSET :offset];
        List<order> lastOrders = new List<order>([SELECT Id, OwnerId, AccountId, Account.Name, Account.SAP_Account_Group__c , Account.AccountDivision__c, Description, Account.AccountSource , PrivateTransport__c, PassingPermit__c, RequestedSupplyDate__c, TransactionType__c, Status, EffectiveDate, ActivatedDate, ActivatedById, OrderNumber, TotalAmount ,CreatedDate, CreatedById, LastModifiedById, IsDeleted, LastViewedDate, LastReferencedDate ,AgentReceivesCommission__c,AgentReceivesCommission__r.Name,IntermediaryWarehouse__c, IntermediaryWarehouse__r.Name, Paying_Customer__c, Paying_Customer__r.Name , Branch_growth__c,Branch_growth__r.Name, Payer_Approval__c, Invoice__c, BioHazardousMaterialCheck__c, InventoryCheck__c, (SELECT Id, Product2Id, Product2.Name,Product2.specific_gravity__c, Product2.LoadingPoint__c ,Product2.IL_BU__c, Product2.IL_Group_name__c,Product2.LoadingPoint__r.Name,Product2.LoadingPoint__r.LoadingPointType__c, RelatedContactName__c, Product2.QuantityUnitOfMeasure, Product2.Sap_Number__c, Product2.Packing__c, Product2.IL_Group__c, Product2.Accumulation_state__c, RelatedContactPhone__c, DeliveryNoteExist__c, Status__c, RefuelingTransport__c,CraneTransport__c, IsDeleted, OrderId, Quantity, UnitPrice, TotalPrice, Description, CreatedDate, CreatedById, NonFreightCharge__c,Extension_1__c,Extension_2__c,Extension_3__c ,Extension_1__r.Name,Extension_2__r.Name,Extension_3__r.Name ,Extension_Quantity_1__c,Extension_Quantity_2__c,Extension_Quantity_3__c,Extension_Unit_1__c,Extension_Unit_2__c,Extension_Unit_3__c, OrderItemNumber, OriginalDeliveryNote__c, Plot__c, UnitOfMeasure__c, DischargeLocation__c,DischargeLocation__r.Name, LoadingPoint__c, LoadingPoint__r.LoadingPointName__c, Price_from_customer_order__c,DeliveryPrice__c,DeliveryUnitOfMeasure__c, Purchase_Order__c, combined_Packaging__c, combinedTransport__c, Truck_code__c, DeliveryDate__c, specialTransport__c, CustomerPackaging__c, WaitingRequired__c FROM OrderItems ORDER BY Product2.Name ASC) from Order WHERE AccountId = :recordId Order by CreatedDate DESC LIMIT 10 OFFSET :offset]);
        
        return  lastOrders;
    }
    
    @AuraEnabled
    public static List<Order> getOrderAndOrderItems(String recordId){
        System.debug(logginglevel.ERROR,'getOrderAndOrderItems: recordId: ' + recordId );
        List<Order> temp = [SELECT Id, OwnerId, AccountId, CreatedBy.Name, Agronom__c, Account.Name, Account.SAP_Account_Group__c ,Account.AccountDivision__c, Account.Sensitive_Customer__c,  
                            Description,Order_Delivered_By__c, Account.AccountSource ,PrivateTransport__c, PassingPermit__c, RequestedSupplyDate__c, TransactionType__c, Status, EffectiveDate, ActivatedDate,
                            ActivatedById, OrderNumber, TotalAmount ,CreatedDate, CreatedById, LastModifiedById,LastModifiedBy.Name, IsDeleted, LastViewedDate, LastReferencedDate ,AgentReceivesCommission__c,
                            AgentReceivesCommission__r.Name,IntermediaryWarehouse__c, IntermediaryWarehouse__r.Name, Paying_Customer__c, Paying_Customer__r.Name , Branch_growth__c,
                            Branch_growth__r.Name, Payer_Approval__c,CosignationWarehouseApproval__c, Invoice__c, BioHazardousMaterialCheck__c, InventoryCheck__c,OriginalDeliveryNote__c,OriginalDeliveryNote__r.Name, 
                            responsibility__c, reasonForReturn__c, reasonForReturnDescription__c, (SELECT Id, Comment__c,Product2Id, Product2.Name,Product2.LoadingPoint__c, Product2.Sap_Number__c, Product2.IL_Group__c, 
                                                                                                   RelatedContactName__c, RelatedContactPhone__c, RefuelingTransport__c,CraneTransport__c, IsDeleted, OrderId, DeliveryNoteExist__c, Quantity, UnitPrice, TotalPrice, Description, CreatedDate,
                                                                                                   CreatedById, NonFreightCharge__c,Extension_1__c,Extension_2__c,Extension_3__c ,Extension_1__r.Name,Extension_2__r.Name,Extension_3__r.Name ,Extension_Quantity_1__c,
                                                                                                   Extension_Quantity_2__c,Extension_Quantity_3__c,Extension_Unit_1__c,Extension_Unit_2__c,Extension_Unit_3__c, OrderItemNumber, Plot__c, Status__c,DisplayStatus__c,
                                                                                                   Truck_code__c, DeliveryDate__c, UnitOfMeasure__c, DischargeLocation__c,DischargeLocation__r.Name, LoadingPoint__c,LoadingPoint__r.LoadingPointType__c, 
                                                                                                   LoadingPoint__r.LoadingPointName__c, Price_from_customer_order__c,DeliveryPrice__c,DeliveryUnitOfMeasure__c, Purchase_Order__c, combined_Packaging__c, combinedTransport__c, CustomerPackaging__c, WaitingRequired__c, specialTransport__c, 
                                                                                                   framework_agreement_Usege_Quntity__c FROM OrderItems) from Order WHERE Id = :recordId LIMIT 20];
        return temp;
    }
    
    @AuraEnabled
    public static List<OrderItem> getOrderItemsById(String orderId){
        return [SELECT Id, Product2Id, IsDeleted, OrderId, Quantity, UnitPrice, TotalPrice, Description, CreatedDate, CreatedById, OrderItemNumber, RefuelingTransport__c,CraneTransport__c, Plot__c, UnitOfMeasure__c, DischargeLocation__c, LoadingPoint__c, combined_Packaging__c, combinedTransport__c, specialTransport__c, CustomerPackaging__c, WaitingRequired__c FROM OrderItem WHERE OrderId = :orderId LIMIT 20];
    }
    
    @AuraEnabled
    public static List<Order> getPreviousOrdersPayerAgentAndWarehouseForAccount(String accountId){
        return [SELECT Id, AccountId ,CreatedDate ,AgentReceivesCommission__c, AgentReceivesCommission__r.Name,IntermediaryWarehouse__c, IntermediaryWarehouse__r.Name, Paying_Customer__c, Paying_Customer__r.Name from Order WHERE AccountId = :accountId order by Id DESC LIMIT 10];
    }
    @AuraEnabled
    public static List<Account> forViewAccount(String accId){
        return [SELECT Id FROM Account WHERE Id = :accId FOR VIEW];
    }
    
    
    @AuraEnabled
    public static List<Product2> getProductById(String productId){
        return [SELECT Id, Name,Quantity_in_surface__c, Extension_1__r.Name, Extension_1__r.Id, Extension_2__r.Name, Extension_2__r.Id,Extension_3__r.Name, Extension_3__r.Id,Extension_4__r.Name, Extension_4__r.Id,Extension_5__r.Name, Extension_5__r.Id,Extension_6__r.Name, Extension_6__r.Id,Extension_7__r.Name, Extension_7__r.Id,Extension_8__r.Name, Extension_8__r.Id FROM Product2 WHERE Id = :productId LIMIT 20];
    }
    
    @AuraEnabled
    public static List<PricebookEntry> getPricebookEntryId(String productId){
        System.debug(logginglevel.ERROR,'getPricebookEntryId ' + productId );
        return [SELECT Id, Product2Id from PricebookEntry WHERE Product2Id = :productId 
                AND IsActive=true 
                AND CurrencyIsoCode='ILS'];
    }
    
    @AuraEnabled
    public static List<SObject> getMasterProduct(String searchKey){
        return [SELECT Product_hierarchy__r.Name from Product2 WHERE Name like :searchKey GROUP BY Product_hierarchy__r.Name limit 50];
    }
    
    @AuraEnabled
    public static List<DeliveryNote__c> getDeliveryNoteId(String orderItemId){
        return [SELECT Id FROM DeliveryNote__c WHERE OrderItem__c = :orderItemId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUserProfile(Id Id){
        return [SELECT Profile.Name, DefaultCurrencyIsoCode,LanguageLocaleKey  FROM User WHERE Id = :Id];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<LoadingPoint__c > getRelatedLoadingPoint(String name){
        return [SELECT Id FROM LoadingPoint__c WHERE Name = :name];
    }

    @AuraEnabled(cacheable=true)
    public static List<LoadingPoint__c > getLoadingPointName(String Id){
        return [SELECT Name FROM LoadingPoint__c WHERE Id = :id];
    }
    
    @AuraEnabled
    public static List<Account> getParent(Id recordId){
        return [SELECT ParentId FROM Account WHERE Id = :recordId];
    }
    
    @AuraEnabled
    public static boolean isBH(Date requestedDate){ // בודק שהתאריך שהוזן ידנית בשדה תאריך מבוקש - אכן יום עבודה
        String dayOfWeek = ((DateTime) requestedDate).format('E');
        List<Holiday> holidaysFound = new  List<Holiday>([Select ActivityDate from Holiday where ActivityDate=:requestedDate]);
        boolean isWorkDays = holidaysFound.size()>0 ||dayOfWeek=='Sat'?false:true;
        return isWorkDays;
    }
    
    @AuraEnabled(cacheable=true)
    public  static Date  calculateBH(Date requestedDate){ // מחשב את התאריך המבוקש בעת עלייה של ההזמנה בהתחשבות בימי חופשה ושבתות
        getActiveHoliday();
        return requestedDate.addDays(setAmountOfDays(requestedDate));
    }
    
    private static integer setAmountOfDays(Date requestedDate){
        set<Date> holidaysSet = new set<Date>();
        integer addedDays = 0;
        integer limitOfDays =0;
        for(integer i=0; i <= 20; i++){
            addedDays++;
            String dayOfWeek = ((DateTime) requestedDate.addDays(addedDays)).format('E');
            if(!holidaysSet.contains(requestedDate.addDays(addedDays)) && dayOfWeek!='Sat'){
                limitOfDays++;  
            }
            
            if(limitOfDays==2){
                break;
            }
        }
        return addedDays;
    }
    
    private  static  set<Date> getActiveHoliday(){
        set<Date> holidaysSet = new set<Date>();
        for(Holiday currHoliday : [Select ActivityDate from Holiday]){  
            holidaysSet.add(currHoliday.ActivityDate);  
        }   
        return holidaysSet;
    } 
    
    @AuraEnabled
    public static boolean isFcSubAdmin(){
        boolean isFCAdmin = false;
        List<PermissionSetAssignment> FCAdmin = new  List<PermissionSetAssignment>([select PermissionSetId,AssigneeId FROM PermissionSetAssignment 
                                                                                    WHERE PermissionSet.Name='F_C_Sub_Admin'
                                                                                    AND AssigneeId=:UserInfo.getUserId()]);
        isFCAdmin=FCAdmin.size()>0?true:false;
        return isFCAdmin;
    }
    
    @AuraEnabled
    public static boolean CosignationWarehouseApprovalExist(string loadingPointId,string CosignationWarehouseApproval){
        List<orderItem> orderItemsExist = new List<orderItem>([SELECT Id FROM OrderItem 
                                                               WHERE order.CosignationWarehouseApproval__c=:CosignationWarehouseApproval 
                                                               AND LoadingPoint__c =:loadingPointId]);
        
        boolean exist=!orderItemsExist.isEmpty()?true:false; 
        return exist;
    }

    @AuraEnabled
    public static void updateAccountDescription(Id accountId, String newDescription) {
        try{
        Account acc = [SELECT Id, Description FROM Account WHERE Id = :accountId];
        acc.Description = newDescription;
        system.debug(loggingLevel.error,'updateAccountDescription:'+acc);
        update acc;
        }
        catch(System.DmlException e){
                system.debug(loggingLevel.error,'updateAccountDescription:'+  e.getMessage());
                            throw new AuraHandledException('updateAccountDescription:'+  e.getMessage());

        
        }
    }
}