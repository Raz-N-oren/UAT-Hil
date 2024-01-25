public with sharing class AccountStagingTriggerHelper {
    public static final List<String> sourceSys = new List<String>{'FER', 'AMF', 'IBP', 'QAD', 'BRA', 'PLP', 'FNT', 'TRK', 'E0035', 'E0228'};
        
    @future
    public static void upsertRecords(Set<Id> accountStagingId){
            Map<String, List<Account>> srcAccountsToUpsertMap = new Map<String, List<Account>>();
            
            for(String srcSys : sourceSys){
                srcAccountsToUpsertMap.put(srcSys, new List<Account>());
            }
            Map<String, Account> accountsToUpdateMap = new Map<String, Account>();
            List<Contact> contactsToUpsert = new List<Contact>();
            List<Contact> contactsToUpdate = new List<Contact>();
            List<Function_Partner__c> functionPartnersToUpsert = new List<Function_Partner__c>();
            List<Sales_Area__c> salesAreasToUpsert = new List<Sales_Area__c>();
            List<Account_Staging__c> accountStagesToUpdate = new List<Account_Staging__c>();
            Map<String, String> groupTypeMap = new Map<String, String>();
            getGroupTypeMap(groupTypeMap);
            
            Map<Id, Account> CMAccountsToUpdate = new Map<Id, Account>();
            Map<String, Account> accRecs = new Map<String, Account>();
            
            //Map based on Credit File Identifier for the Credit Segment process
            Map<String, List<Account>> accCMSRecs= new Map<String, List<Account>>();
            Map<Id,Account_Staging__c> accountStagesToCMSRecs= new Map<Id, Account_Staging__c>();
            List<CraditSegment__c> insertCraditSegmentRecs = new List<CraditSegment__c>();
            
            List<Account_Staging__c> accRecords = [
                SELECT ABCD_Classification__c, Account2__c, Account__c,OPUFAEL30__c,OPUFAEL29__c,OPUFAEL14__c,OPUFAEL7__c, Account_Name__c, Account_Number__c, Account_Owner__c, Account_record_Type__c, Account_Source__c,Account_Type__c, Action_Type__c, ATLBRTG__c, bill_to_flag__c, Business_Unit__c, City__c, Country__c, Cpfname__c, Cplname__c, CPmail__c,  CpN__c, Cptel1__c, CPtel2__c, CreatedById, Currency__c, CurrencyIsoCode, Customer_credit_file_in_CM__c, Customer_grouping__c, customer_type_code__c, Description__c, Distribution_Channel__c, Division__c, domain_code__c, Email__c, Error__c, Error_Message__c, External_Id__c, Fax__c, Id, Inco_2__c, Inco_Terms__c, Industry__c, Inserted__c, JOINTCUS__c, KLIMK__c, LastModifiedById, Name, OBLIG__c, Old_Identfier__c, OPUFAEL__c, OwnerId, Parent_Account__c, Partnering_TYPE__c, Payment_Terms__c, Phone_2__c, Phone__c, Clerk_in_charge__c, Sgmnt_Txt__c, region_code__c, RISKCL__c, SABNR__c, Sales_Territory__c, salesperson1_code__c, salesperson2_code__c, salesperson2_name__c, salesperson3_code__c, salesperson4_Name__c, SAP_AccGr_text__c, SAP_Account_Group__c, Sap_Number_2__c, Sap_Number__c, ship_to_flag__c, sold_to_flag__c, State_Province__c, Status__c, Street__c, Type__c, VAT_Number__c, VIPCUS__c, Zip_Postal_Code__c, Invoice_Email__c,Name_2__c,Cell_phone_Number__c
                ,CRBLB__c,LOEVM__c,NIELS__c
                FROM Account_Staging__c
                WHERE Id IN :accountStagingId
                ORDER BY LastModifiedDate DESC
            ];
              
            // Get the Ids of all AccStaging records
            getAccsByExId(accRecords, accRecs);
            
            for (Account_Staging__c accStage : accRecords) {
                if (accStage.Action_Type__c == 'Account')
                    addToAccounts(
                        accStage,
                        srcAccountsToUpsertMap,
                        accountsToUpdateMap,
                        groupTypeMap,
                        accountStagesToUpdate
                    );
                if (accStage.Action_Type__c == 'Partner function')
                    addToFunctionPartners(accStage, functionPartnersToUpsert);
                if (accStage.Action_Type__c == 'Sales Area')
                    addToSalesAreas(accStage, salesAreasToUpsert);
                if (accStage.Action_Type__c == 'Contact Partner')
                    addToContacts(accStage, contactsToUpsert, contactsToUpdate, accountStagesToUpdate);
                if (accStage.Action_Type__c == 'CM'  && accstage.SABNR__c=='0000')
                    addToCMAccs(accStage, accRecs, CMAccountsToUpdate, accountStagesToUpdate);
            }
            
            if (!accountsToUpdateMap.isEmpty())
                processAccountsUpdate(accountsToUpdateMap.values(), accountStagesToUpdate);
            
            for(String srcSys : sourceSys){
                if(!((srcAccountsToUpsertMap.get(srcSys)).isEmpty()))
                    processAccountsUpsert(srcAccountsToUpsertMap.get(srcSys), accountStagesToUpdate, srcSys);
            }
            
            if (!contactsToUpdate.isEmpty())
                processContactsUpdate(contactsToUpdate, accountStagesToUpdate);
            if (!contactsToUpsert.isEmpty())
                processContactsUpsert(contactsToUpsert, accountStagesToUpdate);
            if (!salesAreasToUpsert.isEmpty()) 
                processSalesAreasUpsert(salesAreasToUpsert, accountStagesToUpdate);
            if (!functionPartnersToUpsert.isEmpty())
                processFunctionPartnersUpsert(functionPartnersToUpsert, accountStagesToUpdate);
            if (!CMAccountsToUpdate.isEmpty())
                processCMAccountsUpdate(CMAccountsToUpdate, accountStagesToUpdate);
            if (!accountStagesToUpdate.isEmpty())
                update accountStagesToUpdate;
        }
    
    public static void getGroupTypeMap(Map<String, String> groupTypeMap){
        for (Account_Type_Map__mdt at : [SELECT MasterLabel, DeveloperName FROM Account_Type_Map__mdt]) {
            groupTypeMap.put(at.MasterLabel, at.DeveloperName);
        }
    }
    
    public static void processAccountsUpdate(List<Account> accountsToUpdate,List<Account_Staging__c> accountStagesToUpdate){
        Database.SaveResult[] updateResult = Database.update(accountsToUpdate, false);
        for (Integer i = 0; i < updateResult.size(); i++) {
            accountStagesToUpdate.add(processSaveResult(updateResult[i], accountsToUpdate[i].AccountStageId__c));
        }
    }
    
    public static void processAccountsUpsert(List<Account> accountsToUpsert,List<Account_Staging__c> accountStagesToUpdate, String accountSource){
        switch on accountSource {
            when 'FER' {
                upsertAccounts(accountsToUpsert, Account.Fields.External_Id__c, accountStagesToUpdate);
            }
            when 'AMF' {
                upsertAccounts(accountsToUpsert, Account.Fields.Amfert_SAP_number__c, accountStagesToUpdate);
            }
            when 'IBP' {
                upsertAccounts(accountsToUpsert, Account.Fields.IBP_SAP_number__c, accountStagesToUpdate);
            }
            when 'QAD' {
                upsertAccounts(accountsToUpsert, Account.Fields.QAD1_sap_C__c, accountStagesToUpdate);
            }
            when 'BRA' {
                upsertAccounts(accountsToUpsert, Account.Fields.BRAZIL_SAP_NUMBER__c, accountStagesToUpdate);
            }
            when 'PLP' {
                upsertAccounts(accountsToUpsert, Account.Fields.US_SAP_NUMBER__c, accountStagesToUpdate);
            }
            when 'FNT' {
                upsertAccounts(accountsToUpsert, Account.Fields.Fun_erp_number__c, accountStagesToUpdate);
            }
            when 'TRK' {
                upsertAccounts(accountsToUpsert, Account.Fields.TRK_SAP__c, accountStagesToUpdate);
            }
            when else {
                upsertAccounts(accountsToUpsert, Account.Fields.External_Id__c, accountStagesToUpdate);
            }
        }
    }
    
    private static void upsertAccounts(List<Account> accountsToUpsert,Schema.SObjectField byField,List<Account_Staging__c> accountStagesToUpdate){
        Map<String, Account> uniqueAccsToUpsert = new Map<String, Account>();
        List<Account> repeatedAccs = new List<Account>();
        //the list order from the newest Account records to the oldest
        for (Account accToUpsert : accountsToUpsert) {
            // first time with some externalId will stay in the list of Accounts, repeated externalId will be thrown to the repeatedAccs list.
            if (uniqueAccsToUpsert.containsKey((String) accToUpsert.get(byField)))
                repeatedAccs.add(accToUpsert);
            else
                uniqueAccsToUpsert.put(accToUpsert.AccountSource + accToUpsert.Sap_Number__c, accToUpsert);
        }
        
        accountsToUpsert = uniqueAccsToUpsert.values();
        Database.UpsertResult[] upsertResult = Database.upsert(accountsToUpsert, byField, false);
        
        for (Integer i = 0; i < upsertResult.size(); i++) {
            accountStagesToUpdate.add(processUpsertResult(upsertResult[i], accountsToUpsert[i].AccountStageId__c));
        }
        // changing all the repeated Account Staging (from the Accounts list) status into 'success' directly,
        //and adding them to the accountStagesToUpdate list.
        for (Account repeatedAcc : repeatedAccs) {
            accountStagesToUpdate.add(processSaveResult(null, repeatedAcc.AccountStageId__c));
        }
    }
    
    public static void processSalesAreasUpsert(List<Sales_Area__c> salesAreasToUpsert,List<Account_Staging__c> accountStagesToUpdate){
        Map<String, Sales_Area__c> uniqueSalesAreasToUpsert = new Map<String, Sales_Area__c>();
        List<Sales_Area__c> repeatedSalesAreas = new List<Sales_Area__c>();
        //the list order from the newest sales_Areas records to the oldest
        for (Sales_Area__c salesAreaToUpsert : salesAreasToUpsert) {
            // first time with some externalId will stay in the list of sales_Areas, repeated externalId will be thrown to the repeatedSalesAreas list.
            if (uniqueSalesAreasToUpsert.containsKey(salesAreaToUpsert.External_Id__c))
                repeatedSalesAreas.add(salesAreaToUpsert);
            else
                uniqueSalesAreasToUpsert.put(salesAreaToUpsert.External_Id__c, salesAreaToUpsert);
            
        }
        salesAreasToUpsert = uniqueSalesAreasToUpsert.values();
        Database.UpsertResult[] upsertResult = Database.upsert(
            salesAreasToUpsert,
            Sales_Area__c.Fields.External_Id__c,
            false
        );
        for (Integer i = 0; i < upsertResult.size(); i++) {
            accountStagesToUpdate.add(processUpsertResult(upsertResult[i], salesAreasToUpsert[i].AccountStageId__c));
        }
        // changing all the repeated Account Staging (from the sales_Areas list) status into 'success' directly,
        //and adding them to the accountStagesToUpdate list.
        for (Sales_Area__c repeatedSalesArea : repeatedSalesAreas) {
            accountStagesToUpdate.add(processSaveResult(null, repeatedSalesArea.AccountStageId__c));
        }
    }
    
    public static void processFunctionPartnersUpsert(List<Function_Partner__c> functionPartnersToUpsert,List<Account_Staging__c> accountStagesToUpdate){
        Map<String, Function_Partner__c> uniqueFunctionPartnersToUpsert = new Map<String, Function_Partner__c>();
        List<Function_Partner__c> repeatedFunctionPartners = new List<Function_Partner__c>();
        //the list order from the newest FunctionPartners records to the oldest
        for (Function_Partner__c functionPartnerToUpsert : functionPartnersToUpsert) {
            // first time with some externalId will stay in the list of FunctionPartners, repeated externalId will be thrown to the repeatedAccs list.
            if (uniqueFunctionPartnersToUpsert.containsKey(functionPartnerToUpsert.External_Id__c))
                repeatedFunctionPartners.add(functionPartnerToUpsert);
            else
                uniqueFunctionPartnersToUpsert.put(functionPartnerToUpsert.External_Id__c, functionPartnerToUpsert);
        }
        functionPartnersToUpsert = uniqueFunctionPartnersToUpsert.values();
        Database.UpsertResult[] upsertResult = Database.upsert(
            functionPartnersToUpsert,
            Function_Partner__c.Fields.External_Id__c,
            false
        );
        for (Integer i = 0; i < upsertResult.size(); i++) {
            accountStagesToUpdate.add(
                processUpsertResult(upsertResult[i], functionPartnersToUpsert[i].AccountStageId__c)
            );
        }
        // changing all the repeated Account Staging (from the FunctionPartners list) status into 'success' directly,
        //and adding them to the accountStagesToUpdate list.
        for (Function_Partner__c repeatedFunctionPartner : repeatedFunctionPartners) {
            accountStagesToUpdate.add(processSaveResult(null, repeatedFunctionPartner.AccountStageId__c));
        }
    }
    
    public static void processContactsUpdate(List<Contact> contactsToUpdate,List<Account_Staging__c> accountStagesToUpdate){
        List<Contact> skippedContacts = new List<Contact>();
        MAP<Id, Contact> contactsMap = new Map<Id, Contact>();
        
        for (Contact con : contactsToUpdate) {
            if (contactsMap.containsKey(con.Id))
                skippedContacts.add(con);
            else
                contactsMap.put(con.Id, con);
        }
        
        for (Integer i = 0; i < skippedContacts.size(); i++) {
            accountStagesToUpdate.add(processSaveResult(null, skippedContacts[i].AccountStageId__c));
        }
        
        List<Contact> conList = contactsMap.values();
        Database.SaveResult[] updateResult = Database.update(conList, false);
        
        for (Integer i = 0; i < updateResult.size(); i++) {
            accountStagesToUpdate.add(processSaveResult(updateResult[i], conList[i].AccountStageId__c));
        }
    }
    
    public static void processContactsUpsert(List<Contact> contactsToUpsert,List<Account_Staging__c> accountStagesToUpdate){
        Map<String, Contact> uniqueContactsToUpsert = new Map<String, Contact>();
        List<Contact> repeatedContacts = new List<Contact>();
        //the list order from the newest Contact records to the oldest
        for (Contact contactToUpsert : contactsToUpsert) {
            // first time with some externalId will stay in the list of Accounts, repeated externalId will be thrown to the repeatedAccs list.
            if (uniqueContactsToUpsert.containsKey(contactToUpsert.External_Id__c))
                repeatedContacts.add(contactToUpsert);
            else
                uniqueContactsToUpsert.put(contactToUpsert.External_Id__c, contactToUpsert);
        }
        contactsToUpsert = uniqueContactsToUpsert.values();
        Database.UpsertResult[] upsertResult = Database.upsert(contactsToUpsert, Contact.Fields.External_Id__c, false);
        for (Integer i = 0; i < upsertResult.size(); i++) {
            accountStagesToUpdate.add(processUpsertResult(upsertResult[i], contactsToUpsert[i].AccountStageId__c));
        }
        // changing all the repeated Account Staging (from the contacts list) status into 'success' directly,
        //and adding them to the accountStagesToUpdate list.
        for (Contact repeatedContact : repeatedContacts) {
            accountStagesToUpdate.add(processSaveResult(null, repeatedContact.AccountStageId__c));
        }
    }
    
    public static void addToContacts(Account_Staging__c accStage,List<Contact> contactsToUpsert,List<Contact> contactsToUpdate,List<Account_Staging__c> accountStagesToUpdate){
        Contact con = new Contact();
        // Account accParent = new Account(External_Id__c = accStage.Account_Source__c + accStage.Sap_Number__c);
        Account accParent = new Account(External_Id__c = accStage.Sap_Number__c);
        con.Account = accParent;
        con.AccountStageId__c = accStage.Id;
        con.Email = accStage.CPmail__c;
        con.LastName = accStage.Cplname__c;
        con.FirstName = accStage.Cpfname__c;
        con.Phone = accStage.Cptel1__c;
        con.External_id__c = accStage.Account_Source__c + accStage.CpN__c;
        if (accStage.Cptel2__c != null) {
            try {
                con.Id = accStage.Cptel2__c;
                contactsToUpdate.add(con);
            } catch (Exception e) {
                accStage.Error_Message__c = e.getMessage();
                accStage.Status__c = 'Error';
                accountStagesToUpdate.add(accStage);
            }
        } else {
            contactsToUpsert.add(con);
        }
    }
    
    public static void addToAccounts(
        Account_Staging__c accStage,
        Map<String, List<Account>> srcAccountsToUpsertMap,
        Map<String, Account> accountsToUpdateMap,
        Map<String, String> groupTypeMap,
        List<Account_Staging__c> accountStagesToUpdate
    ) {
        Account acc = new Account();
        
        switch on accStage.Account_Source__c {
            when 'FER' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(External_Id__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.External_Id__c = accStage.Sap_Number__c;
            }
            when 'AMF' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(Amfert_SAP_number__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.Amfert_SAP_number__c = accStage.Sap_Number__c;
            }
            when 'IBP' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(IBP_SAP_number__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.IBP_SAP_number__c = accStage.Sap_Number__c;
            }
            when 'QAD' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(QAD1_sap_C__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.QAD1_sap_C__c = accStage.Sap_Number__c;
            }
            when 'BRA' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(BRAZIL_SAP_NUMBER__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.BRAZIL_SAP_NUMBER__c = accStage.Sap_Number__c;
            }
            when 'PLP' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(US_SAP_NUMBER__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.US_SAP_NUMBER__c = accStage.Sap_Number__c;
            }
            when 'FNT' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(Fun_erp_number__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.Fun_erp_number__c = accStage.Sap_Number__c;
            }
            when 'TRK' {
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(TRK_SAP__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.TRK_SAP__c = accStage.Sap_Number__c;
            }
            when else { // All other sys sources
                if (accStage.Parent_Account__c != null) {
                    Account accParent = new Account(External_Id__c = accStage.Parent_Account__c);
                    acc.Parent = accParent;
                }
                acc.External_Id__c = accStage.Sap_Number__c;
            }
        }
        
        acc.Sap_Number__c = accStage.Sap_Number__c;
        acc.Name = accStage.Account_Name__c;
        acc.Fax = accStage.Fax__c;
        if (accStage.Industry__c != null && accStage.Country__c !='IL')
            acc.Industry = accStage.Industry__c;
        acc.Phone = accStage.Phone__c;
        // acc.Type = groupTypeMap.get(accStage.SAP_Account_Group__c);
        acc.Type = accStage.Account_Type__c;
  // Add by yaron 11-01-2023
   if (accStage.Country__c !='IL')
   {        if (accStage.Account_Type__c=='Customer')
        {
            acc.Status__c='Invoiced account';
        }
         if (accStage.Account_Type__c=='Ship To')
        {
            acc.Status__c='Not invoiced partner';
            acc.Contact_Last_Name__c=accstage.Name_2__c;
            if (accStage.Country__c=='fr')
            {
                
            }
        }}

   // add by yaron Create Contact EU 
     //   acc.Contact_Last_Name__c=accstage.Name_2__c;
        acc.Phone_2__c=accstage.Cell_phone_Number__c;
        acc.Invoice_Email__c=accstage.Invoice_Email__c;
        acc.Email__c=accstage.Email__c;
        acc.BillingCountryCode = accStage.Country__c;
        if (accStage.Country__c=='DE')
        {
           accStage.Country__c= accStage.Country__c.replaceFirst( '^0+', ''); 
        }
        acc.LOEVM__c=accStage.LOEVM__c;
        acc.NIELS__c=accStage.NIELS__c;
        acc.CRBLB__c=accStage.CRBLB__c;
        acc.BillingStateCode = accStage.State_Province__c;
        acc.BillingStreet = accStage.Street__c;
        acc.BillingCity = accStage.City__c;
        acc.BillingPostalCode = accStage.Zip_Postal_Code__c;
     //   acc.Old_Identfier__c = accStage.Old_Identfier__c;
        acc.AccountStageId__c = accStage.Id;
        acc.AccountSource = accStage.Account_Source__c;
        acc.SAP_Account_Group__c = accStage.SAP_Account_Group__c;
        acc.Ready_For_SAP__c = false;
        acc.OPUFAEL7__c=accstage.OPUFAEL7__c;
        acc.OPUFAEL14__c=accstage.OPUFAEL14__c;
        acc.OPUFAEL29__c=accstage.OPUFAEL29__c;
        acc.OPUFAEL30__c=accstage.OPUFAEL30__c;
        if (accStage.Account_record_Type__c != null)
            acc.RecordTypeId = accStage.Account_record_Type__c;
        if (accStage.VAT_Number__c != null)
            acc.VAT_Number__c = accStage.VAT_Number__c;
        if (accStage.Account_Number__c != null) {
            try {
                acc.Id = accStage.Account_Number__c;
                if (accountsToUpdateMap.containsKey(acc.Id)) {
                    Account_Staging__c accStageToSuccess = new Account_Staging__c(
                        Id = accountsToUpdateMap.get(acc.Id).AccountStageId__c
                    );
                    accStageToSuccess.Status__c = 'Success';
                    accountStagesToUpdate.add(accStageToSuccess);
                }
                accountsToUpdateMap.put(acc.Id, acc);
            } catch (Exception e) {
                System.debug('Catched an error: ' + e.getMessage());
                accStage.Error_Message__c = e.getMessage();
                accStage.Status__c = 'Error';
                accountStagesToUpdate.add(accStage);
            }
        } else {
            Set<String> sourceSet = new Set<String>(sourceSys);
            String source = sourceSet.contains(accStage.Account_Source__c) ? accStage.Account_Source__c : 'FER';
            srcAccountsToUpsertMap.get(source).add(acc);
        }
    }
    
    public static void addToSalesAreas(Account_Staging__c accStage, List<Sales_Area__c> salesAreasToUpsert) {
        Sales_Area__c sa = new Sales_Area__c();
        if (accStage.Sap_Number__c != null) {
            switch on accStage.Account_Source__c {
                when 'FER','ILF' {
                    Account acc = new Account(External_Id__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'AMF' {
                    Account acc = new Account(Amfert_SAP_number__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'IBP' {
                    Account acc = new Account(IBP_SAP_number__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'QAD' {
                    Account acc = new Account(QAD1_sap_C__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'BRA' {
                    Account acc = new Account(BRAZIL_SAP_NUMBER__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'PLP' {
                    Account acc = new Account(US_SAP_NUMBER__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'FNT' {
                    Account acc = new Account(Fun_erp_number__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when 'TRK' {
                    Account acc = new Account(TRK_SAP__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
                when else {
                    Account acc = new Account(External_Id__c = accStage.Sap_Number__c);
                    sa.Account__r = acc;
                }
            }
            
        }
        sa.Source_system__c = accStage.Account_Source__c;
        sa.ABCD_Classification__c = accStage.ABCD_Classification__c;
        sa.Account_Type__c = accStage.Account_Type__c;
        sa.Sales_Territory__c = accStage.Account_Source__c + accStage.Sales_Territory__c;
        sa.Business_Unit__c = accStage.Account_Source__c + accStage.Business_Unit__c;
        sa.CurrencyIsoCode = accStage.Currency__c;
        sa.Inco_Terms__c = accStage.Inco_Terms__c;
        sa.Payment_Terms__c = accStage.Payment_Terms__c;
        sa.Division__c = accStage.Account_Source__c + accStage.Division__c;
        sa.Distribution_Channel__c = accStage.Account_Source__c + accStage.Distribution_Channel__c;
        sa.Inco_2__c = accStage.Inco_2__c;
        sa.AccountStageId__c = accStage.Id;
        sa.KUNNR__c = accStage.Sap_Number__c;
        sa.External_ID__c = accStage.External_Id__c;
        sa.LOEVM__c=accStage.LOEVM__c;
        
        
        
        salesAreasToUpsert.add(sa);
    }
    
    public static void addToFunctionPartners(Account_Staging__c accStage,List<Function_Partner__c> functionPartnersToUpsert){
        Function_Partner__c fp = new Function_Partner__c();
        
        switch on accStage.Account_Source__c {
            when 'FER' {
                Account acc = new Account(External_Id__c = accStage.Sap_Number__c);
                Account acc2 = new Account(External_Id__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'AMF' {
                Account acc = new Account(Amfert_SAP_number__c = accStage.Sap_Number__c);
                Account acc2 = new Account(Amfert_SAP_number__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'IBP' {
                Account acc = new Account(IBP_SAP_number__c = accStage.Sap_Number__c);
                Account acc2 = new Account(IBP_SAP_number__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'QAD' {
                Account acc = new Account(QAD1_sap_C__c = accStage.Sap_Number__c);
                Account acc2 = new Account(QAD1_sap_C__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'BRA' {
                Account acc = new Account(BRAZIL_SAP_NUMBER__c = accStage.Sap_Number__c);
                Account acc2 = new Account(BRAZIL_SAP_NUMBER__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'PLP' {
                Account acc = new Account(US_SAP_NUMBER__c = accStage.Sap_Number__c);
                Account acc2 = new Account(US_SAP_NUMBER__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'FNT' {
                Account acc = new Account(Fun_erp_number__c = accStage.Sap_Number__c);
                Account acc2 = new Account(Fun_erp_number__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when 'TRK' {
                Account acc = new Account(TRK_SAP__c = accStage.Sap_Number__c);
                Account acc2 = new Account(TRK_SAP__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
            when else {
                Account acc = new Account(External_Id__c = accStage.Sap_Number__c);
                Account acc2 = new Account(External_Id__c = accStage.Sap_Number_2__c);
                fp.Account__r = acc;
                fp.Account_2__r = acc2;
            }
        }
        
        Sales_Area__c sa = new Sales_Area__c(
            External_Id__c = accStage.Account_Source__c +
            accStage.Sap_Number__c +
            accStage.Business_Unit__c +
            accStage.Distribution_Channel__c +
            accStage.Division__c
        );
        
        fp.Account_Source__c = accStage.Account_Source__c;
        fp.Sap_Number__c = accStage.Sap_Number__c;
        fp.Sap_Number_2__c = accStage.Sap_Number_2__c;
        fp.External_Id__c = accStage.External_Id__c;
        fp.Business_Unit__c = accStage.Account_Source__c + accStage.Business_Unit__c;
        fp.Division__c = accStage.Account_Source__c + accStage.Division__c;
        fp.Distribution_Channel__c = accStage.Account_Source__c + accStage.Distribution_Channel__c;
        fp.Partnering_TYPE__c = accStage.Partnering_TYPE__c;
        fp.AccountStageId__c = accStage.Id;
        fp.Sales_Area__r = sa;
        
        functionPartnersToUpsert.add(fp);
    }
    
    private static Account_Staging__c processUpsertResult(Database.UpsertResult upsertResult, String AccountStageId) {
        Account_Staging__c accStage = new Account_Staging__c(Id = AccountStageId);
        accStage.Error_Message__c = '';
        
        if (upsertResult.isSuccess()) {
            accStage.Status__c = 'Success';
        } else {
            for (Database.Error er : upsertResult.getErrors()) {
                accStage.Error_Message__c += er.getMessage() + ' ';
                accStage.Status__c = 'Error';
            }
        }
        return accStage;
    }
    
    public static Account_Staging__c processSaveResult(Database.SaveResult updateSaveResult, String AccountStageId) {
        Account_Staging__c accStage = new Account_Staging__c(Id = AccountStageId);
        accStage.Error_Message__c = '';
        
        // 'updateSaveResult' is null for duplicate records
        // 'updateSaveResult' is success for records upserted to DB successfully
        if (updateSaveResult == null || updateSaveResult.isSuccess()) {
            accStage.Status__c = 'Success';
        } else {
            for (Database.Error er : updateSaveResult.getErrors()) {
                accStage.Error_Message__c += er.getMessage() + ' ';
                accStage.Status__c = 'Error';
            }
        }
        return accStage;
    }
    
    public static void getAccsByExId(List<Account_Staging__c> accStageList, Map<String, Account> accRecs){
        // Map of Sets for all external IDs (Source Systems) 
        Map<String, Set<String>> sourceMap = new Map<String, Set<String>>();
        
        for(String srcSys : sourceSys){
            sourceMap.put(srcSys, new Set<String>());
        }
        
        for(Account_Staging__c accStg : accStageList){
            // ILF, EVR and BKG are not really a systems change them to FER, QAD and TRK
            if(accStg.Account_Source__c == 'ILF') accStg.Account_Source__c = 'FER';
            else if(accStg.Account_Source__c == 'EVR') accStg.Account_Source__c = 'QAD';
            else if(accStg.Account_Source__c == 'BKG') accStg.Account_Source__c = 'TRK';
            else if(accStg.Account_Source__c == 'FUE') accStg.Account_Source__c = 'FNT';
            
            if(accStg.Action_Type__c == 'CM' && accStg.SABNR__c=='0000'){
                if(accStg.Sap_Number__c.startsWith('CLI'))
                    accStg.Sap_Number__c = '43' + accStg.Sap_Number__c.substring(3);
                Set<String> sourceSet = new Set<String>(sourceSys);
                String source = sourceSet.contains(accStg.Account_Source__c) ? accStg.Account_Source__c : 'FER';
                sourceMap.get(source).add(accStg.Sap_Number__c);
            }
        }
        
        List<Account> accounts = [
            SELECT Id, Name, External_Id__c, Amfert_SAP_number__c, IBP_SAP_number__c, Fun_erp_number__c, TRK_SAP__c,
            QAD1_sap_C__c, BRAZIL_SAP_NUMBER__c, US_SAP_NUMBER__c, Sap_Number__c, AccountSource, lAND__c, OPUFAEL30__c,
            OPUFAEL29__c,OPUFAEL14__c,OPUFAEL7__c,India_Thali_Number__c
            FROM Account
            WHERE External_Id__c IN :sourceMap.get('FER') 
            OR Amfert_SAP_number__c IN :sourceMap.get('AMF')
            OR IBP_SAP_number__c IN :sourceMap.get('IBP')
            OR QAD1_sap_C__c IN :sourceMap.get('QAD')
            OR BRAZIL_SAP_NUMBER__c IN :sourceMap.get('BRA')
            OR US_SAP_NUMBER__c IN :sourceMap.get('PLP')
            OR Fun_erp_number__c IN :sourceMap.get('FNT')
            OR TRK_SAP__c IN :sourceMap.get('TRK')
            OR lAND__c IN :sourceMap.get('E0035')
            OR India_Thali_Number__c IN :sourceMap.get('E0228')
        ];
        arrangeAccs(accounts, accRecs);
    }
    
    public static void arrangeAccs(List<Account> accounts, Map<String, Account> accRecs){
        for(Account acc : accounts){
            if(String.isNotBlank(acc.Amfert_SAP_number__c))
                accRecs.put('AMF' + acc.Amfert_SAP_number__c, acc);
            if(String.isNotBlank(acc.IBP_SAP_number__c))
                accRecs.put('IBP' + acc.IBP_SAP_number__c, acc);
            if(String.isNotBlank(acc.QAD1_sap_C__c))
                accRecs.put('QAD' + acc.QAD1_sap_C__c, acc);
            if(String.isNotBlank(acc.BRAZIL_SAP_NUMBER__c))
                accRecs.put('BRA' + acc.BRAZIL_SAP_NUMBER__c, acc);
            if(String.isNotBlank(acc.US_SAP_NUMBER__c))
                accRecs.put('PLP' + acc.US_SAP_NUMBER__c, acc);
            if(String.isNotBlank(acc.External_Id__c))
                accRecs.put('FER' + acc.External_Id__c, acc);
            if(String.isNotBlank(acc.Fun_erp_number__c))
                accRecs.put('FNT' + acc.Fun_erp_number__c, acc);
            if(String.isNotBlank(acc.TRK_SAP__c))
                accRecs.put('TRK' + acc.TRK_SAP__c, acc);
            if(String.isNotBlank(acc.lAND__c))
                accRecs.put('E0035' + acc.lAND__c, acc);
            if(String.isNotBlank(acc.India_Thali_Number__c))
                accRecs.put('E0228' + acc.India_Thali_Number__c, acc);
        }
    }
    
    public static void addToCMAccs(Account_Staging__c accStage,Map<String, Account> accRecs,Map<Id, Account> CMAccountsToUpdate,List<Account_Staging__c> accountStagesToUpdate){
        Set<String> sourceSet = new Set<String>(sourceSys);
        String accSrc = sourceSet.contains(accStage.Account_Source__c) ? accStage.Account_Source__c : 'FER';
        
        Account acc = accRecs.get(accSrc + accStage.Sap_Number__c);
        if(acc != null && CMAccountsToUpdate.get(acc.Id) == null){
            CMAccountsToUpdate.put(acc.Id, new Account(
                Id = acc.Id,
                Customer_credit_file_in_CM__c = accStage.Customer_credit_file_in_CM__c,
                SABNR__c 			= accStage.SABNR__c,
                KLIMK__c 			= accStage.KLIMK__c,
                OBLIG__c 			= accStage.OBLIG__c,
                RISKCL__c 			= accStage.RISKCL__c,
                OPUFAE__c 			= accStage.OPUFAEL__c,
                ATLBRTG__c 			= accStage.ATLBRTG__c,
                VIPCUS__c 			= accStage.VIPCUS__c,
                CurrencyIsoCode 	= accStage.Currency__c,
                JOINTCUS__c 		= accStage.JOINTCUS__c,
                AccountStageId__c 	= accStage.Id,
                OPUFAEL7__c			= accstage.OPUFAEL7__c,
                OPUFAEL14__c		= accstage.OPUFAEL14__c,
                OPUFAEL29__c		= accstage.OPUFAEL29__c,
                OPUFAEL30__c		= accstage.OPUFAEL30__c
            ));
        } else if(accStage.Action_Type__c == 'CM' && accStage.SABNR__c=='0000' ) { // No existing record found
            accountStagesToUpdate.add(new Account_Staging__c(Id = accStage.Id, Status__c = 'Skip'));
            system.debug(loggingLevel.ERROR,'skip status line 672');

        }
    }
    
    public static void processCMAccountsUpdate(Map<Id, Account> CMAccountsToUpdate,List<Account_Staging__c> accountStagesToUpdate){
        List<Account> updateCMAccs = CMAccountsToUpdate.values();
        Database.SaveResult[] updateResult = Database.update(updateCMAccs, false);
        for (Integer i = 0; i < updateResult.size(); i++) {
            accountStagesToUpdate.add(processSaveResult(updateResult[i], updateCMAccs[i].AccountStageId__c));
        }
    }
    
//    ------------------------------------------------------ CREDIT SEGMENT PROCCESS------------------------------------------------------
    public static void getCMSAccsByExId(
        List<Account_Staging__c> accStageList,
        Map<String, List<Account>> accCMSRecs,
        Map<Id,Account_Staging__c> accountStagesToCMSRecs,
        Map<string,CraditSegment__c> CraditSegmentMap
        
    ){
        Set<string> CreditSegmentEXIds  = new Set<string>();
        Set<string> CMFileIds           = new Set<string>();
        map<string,Account> accountIdentifier = new map<string,Account>();
        for(Account_Staging__c accStg :accStageList){
            if( accStg.Action_Type__c=='CM'){
                if(accStg.SABNR__c!='0000'&& accStg.SABNR__c!=null && accStg.SABNR__c!='' && accStg.Customer_credit_file_in_CM__c!=null){
                    if(accStg.Sap_Number__c.startsWith('CLI'))
                        accStg.Sap_Number__c = '43' + accStg.Sap_Number__c.substring(3);
                    CMFileIds.add(accStg.Sap_Number__c);
                    system.debug(loggingLevel.ERROR,'CMFileIds found:'+CMFileIds);
                    IF(accStg.Account_Source__c=='ILF'){
                        accStg.Account_Source__c='FER';
                    }
                    accCMSRecs.put(accStg.Account_Source__c+accStg.Sap_Number__c,new List<Account>());//no change
                    accountStagesToCMSRecs.put(accStg.Id,accStg);//CreditSegmentEXIds
                }
                else if(accStg.SABNR__c!='0000' && (accStg.SABNR__c==null || accStg.SABNR__c=='' || accStg.Customer_credit_file_in_CM__c==null)){
                    accStg.status__c='Skip';
                    system.debug(loggingLevel.ERROR,'skip status line 711');
                    
                    accountStagesToCMSRecs.put(accStg.Id,accStg);
                    system.debug(loggingLevel.ERROR, 'Empty CMS Record:\naccStg.SABNR__c'+accStg.SABNR__c+'--Customer_credit_file_in_CM__c:'+accStg.Customer_credit_file_in_CM__c);
                } 
            }
        }
        system.debug(loggingLevel.ERROR,'accountStagesToCMSRecs.size():'+accountStagesToCMSRecs.size());
                system.debug(loggingLevel.ERROR,'accCMSRecs:'+accCMSRecs);

        if(!CMFileIds.isempty()){
            List<Account> relatedAcc = new List<Account>([SELECT Id,External_Id__c,Amfert_SAP_number__c,IBP_SAP_number__c,lAND__c,India_Thali_Number__c,
                                                          QAD1_sap_C__c,BRAZIL_SAP_NUMBER__c,US_SAP_NUMBER__c,OPUFAEL30__c,OPUFAEL29__c,OPUFAEL14__c,OPUFAEL7__c,
                                                          Fun_erp_number__c,TRK_SAP__c, Name,Customer_credit_file_in_CM__c 
                                                          FROM Account 
                                                          WHERE 
                                                          External_Id__c  IN :CMFileIds 
                                                          OR Amfert_SAP_number__c IN : CMFileIds
                                                          OR IBP_SAP_number__c  IN : CMFileIds
                                                          OR QAD1_sap_C__c  IN : CMFileIds
                                                          OR BRAZIL_SAP_NUMBER__c IN : CMFileIds
                                                          OR US_SAP_NUMBER__c IN : CMFileIds
                                                          OR Fun_erp_number__c IN : CMFileIds
                                                          OR TRK_SAP__c  IN : CMFileIds
                                                          OR lAND__c IN :CMFileIds
                										  OR India_Thali_Number__c IN :CMFileIds]);
            for(Account acc :relatedAcc){
                string accIdentifier ='';
                if(acc.Amfert_SAP_number__c!=null){
                    accIdentifier='AMF'+acc.Amfert_SAP_number__c;
                    accountIdentifier.put(accIdentifier,acc);
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);

                }
                if(acc.IBP_SAP_number__c!=null){
                    accIdentifier='IBP'+acc.IBP_SAP_number__c;
                    accountIdentifier.put(accIdentifier,acc);
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.QAD1_sap_C__c!=null){
                    accIdentifier='QAD'+acc.QAD1_sap_C__c;
                    accountIdentifier.put(accIdentifier,acc);
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.BRAZIL_SAP_NUMBER__c!=null){
                    accIdentifier='BRA'+acc.BRAZIL_SAP_NUMBER__c;
                    accountIdentifier.put(accIdentifier,acc);

                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.US_SAP_NUMBER__c!=null){
                    accIdentifier='PLP'+acc.US_SAP_NUMBER__c;
                    accountIdentifier.put(accIdentifier,acc);
                  
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.Fun_erp_number__c!=null){
                    accIdentifier='FNT' +acc.Fun_erp_number__c;
                    accountIdentifier.put(accIdentifier,acc);
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.TRK_SAP__c!=null){
                    accIdentifier='TRK'+acc.TRK_SAP__c;
                    accountIdentifier.put(accIdentifier,acc);
                    
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.India_Thali_Number__c!=null){
                    accIdentifier='E0228'+acc.India_Thali_Number__c;
                    accountIdentifier.put(accIdentifier,acc);
                    
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                  if(acc.lAND__c!=null){
                    accIdentifier='E0035'+acc.lAND__c;
                    accountIdentifier.put(accIdentifier,acc);
                    
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
                if(acc.External_Id__c!=null){
                    accIdentifier='FER'+acc.External_Id__c;
                    accountIdentifier.put(accIdentifier,acc);
                    system.debug(loggingLevel.ERROR,'set account Identifier:'+accIdentifier+'::'+CMFileIds);
                    
                    if(accCMSRecs.get(accIdentifier)!=null)
                        accCMSRecs.get(accIdentifier).add(acc);
                }
            }            
        }
        if(!accountIdentifier.isempty()){
            for(Account_Staging__c accStg:accountStagesToCMSRecs.values()){
                system.debug(loggingLevel.ERROR,'account Identifier:'+accStg.Account_Source__c+accStg.Sap_Number__c);
                system.debug(loggingLevel.ERROR,'account found:'+accountIdentifier.get(accStg.Account_Source__c+accStg.Sap_Number__c));
                if(accountIdentifier.get(accStg.Account_Source__c+accStg.Sap_Number__c)!=null){
                    
                    accountStagesToCMSRecs.get(accStg.Id).Account__c=accountIdentifier.get(accStg.Account_Source__c+accStg.Sap_Number__c).Id;
                    string CMSIdentifier=accountStagesToCMSRecs.get(accStg.Id).Account__c +accStg.SABNR__c;
                   system.debug(loggingLevel.ERROR,'CMSIdentifier:'+CMSIdentifier);
                    CreditSegmentEXIds.add(CMSIdentifier);
                }
            }
            
        }
        if(!CreditSegmentEXIds.isEmpty()){
            List<CraditSegment__c> existingCS = new List<CraditSegment__c>([SELECT Id, SegmentCreditId__c,OPUFAEL30__c,OPUFAEL29__c,OPUFAEL14__c,OPUFAEL7__c,Account__c,ATLBRTG__c,Clerk_In_Charge__c,KLIMK__c,Sgmnt_Txt__c,VIPCUS__c,JOINTCUS__c,RISKCL__c,OPUFAEL__c,OBLIG__c,AccountStagingId__c FROM CraditSegment__c WHERE SegmentCreditId__c IN :CreditSegmentEXIds]);
            for(CraditSegment__c rec :existingCS){
                CraditSegmentMap.put(rec.SegmentCreditId__c,rec);
            }            
            system.debug(loggingLevel.ERROR,'accCMSRecs found:'+accCMSRecs.size());
        }
        
    }
    
    
    public static void createCMSRecs(Map<Id,Account_Staging__c> accountStagesToCMSRecs,Map<String, List<Account>> accCMSRecs,Map<string,CraditSegment__c> CraditSegmentMap){
        system.debug(loggingLevel.ERROR,'accountStagesToCMSRecs size:'+accountStagesToCMSRecs.size());
        for(Account_Staging__c accStg : accountStagesToCMSRecs.values()){
            
            if(accStg.Status__c =='Waiting' && accStg.Sap_Number__c!=null && accStg.Action_Type__c=='CM' && accStg.SABNR__c!='0000'&& accStg.SABNR__c!=null && accStg.SABNR__c!='' && accStg.Customer_credit_file_in_CM__c!=null){
                string accountCreditSegmentId=accStg.Account_Source__c+accStg.Sap_Number__c;
                if(accStg.Account__c!=null ){
                         string CreditSegmentId=accStg.Account__c +accStg.SABNR__c;
                        if(CraditSegmentMap.get(CreditSegmentId)==null){
                            CraditSegment__c rec= new CraditSegment__c(
                                Account__c          = accStg.Account__c,
                                ATLBRTG__c          = accStg.ATLBRTG__c,
                                Clerk_In_Charge__c  = accStg.Clerk_In_Charge__c,
                                KLIMK__c            = accStg.KLIMK__c,
                                Sgmnt_Txt__c        = accStg.Sgmnt_Txt__c,
                                VIPCUS__c           = accStg.VIPCUS__c,
                                JOINTCUS__c         = accStg.JOINTCUS__c,
                                RISKCL__c           = accStg.RISKCL__c,
                                OPUFAEL__c          = accStg.OPUFAEL__c,
                                OBLIG__c            = accStg.OBLIG__c,
                                AccountStagingId__c = accStg.Id,
                                SegmentCreditId__c  = CreditSegmentId,
                                OPUFAEL7__c			= accStg.OPUFAEL7__c,
                                OPUFAEL14__c		= accStg.OPUFAEL14__c,
                                OPUFAEL29__c		= accStg.OPUFAEL29__c,
                                OPUFAEL30__c		= accStg.OPUFAEL30__c
                                
                            ); 
                            CraditSegmentMap.put(CreditSegmentId,rec);
                        }
                        else if(CraditSegmentMap.get(CreditSegmentId)!=null){
                            CraditSegmentMap.get(CreditSegmentId).Account__c            = accStg.Account__c;
                            CraditSegmentMap.get(CreditSegmentId).ATLBRTG__c            = accStg.ATLBRTG__c;
                            CraditSegmentMap.get(CreditSegmentId).Clerk_In_Charge__c    = accStg.Clerk_In_Charge__c;
                            CraditSegmentMap.get(CreditSegmentId).KLIMK__c              = accStg.KLIMK__c;
                            CraditSegmentMap.get(CreditSegmentId).Sgmnt_Txt__c          = accStg.Sgmnt_Txt__c;
                            CraditSegmentMap.get(CreditSegmentId).VIPCUS__c             = accStg.VIPCUS__c;
                            CraditSegmentMap.get(CreditSegmentId).JOINTCUS__c           = accStg.JOINTCUS__c;
                            CraditSegmentMap.get(CreditSegmentId).RISKCL__c             = accStg.RISKCL__c;
                            CraditSegmentMap.get(CreditSegmentId).OPUFAEL__c            = accStg.OPUFAEL__c;
                            CraditSegmentMap.get(CreditSegmentId).OBLIG__c              = accStg.OBLIG__c;
                            CraditSegmentMap.get(CreditSegmentId).AccountStagingId__c   = accStg.Id;
                            CraditSegmentMap.get(CreditSegmentId).CurrencyIsoCode       = accStg.Currency__c;
                            CraditSegmentMap.get(CreditSegmentId).OPUFAEL7__c			= accStg.OPUFAEL7__c;
                            CraditSegmentMap.get(CreditSegmentId).OPUFAEL14__c			= accStg.OPUFAEL14__c;
                            CraditSegmentMap.get(CreditSegmentId).OPUFAEL29__c			= accStg.OPUFAEL29__c;
                            CraditSegmentMap.get(CreditSegmentId).OPUFAEL30__c			= accStg.OPUFAEL30__c;
                        }
                    
                }
                else{
                    system.debug(loggingLevel.ERROR,'skip status line 855');
                    accountStagesToCMSRecs.get(accStg.Id).status__c='Skip';//No matching account found
                    system.debug(loggingLevel.ERROR, 'No matching account found:'+accountStagesToCMSRecs.get(accStg.Id));
                }
            }
        }
    }
    
    public static void processInsertCMSRecs(Map<string,CraditSegment__c> CraditSegmentMap,Map<Id,Account_Staging__c> accountStagesToCMSRecs,List<CraditSegment__c>upsertCraditSegmentRecs){
        Schema.SObjectField f = CraditSegment__c.Fields.SegmentCreditId__c;
        upsertCraditSegmentRecs.addAll(CraditSegmentMap.values());
        Database.UpsertResult[] upsertResult = Database.upsert(upsertCraditSegmentRecs,f,false);
        for (Integer i = 0; i < upsertResult.size(); i++) {
            system.debug(loggingLevel.ERROR,'result i:'+upsertResult.get(i));
            if(upsertResult.get(i).isSuccess()){
                if(!accountStagesToCMSRecs.isEmpty() && accountStagesToCMSRecs.get(upsertCraditSegmentRecs[i].AccountStagingId__c)!=null){
                    accountStagesToCMSRecs.get(upsertCraditSegmentRecs[i].AccountStagingId__c).Status__c = 'Success';
                    CraditSegmentMap.put(upsertCraditSegmentRecs[i].SegmentCreditId__c,upsertCraditSegmentRecs[i]);
                }
                else{
                    system.debug(loggingLevel.ERROR,'No account staging was found for update- please check:accountStagesToCMSRecs.get(upsertCraditSegmentRecs[i].AccountStagingId__c)---'+accountStagesToCMSRecs.get(upsertCraditSegmentRecs[i].AccountStagingId__c)+'---upsertCraditSegmentRecs[i].AccountStagingId__c--'+upsertCraditSegmentRecs[i].AccountStagingId__c); 
                }
            }
            else{
                Database.Error error = upsertResult.get(i).getErrors().get(0);
                accountStagesToCMSRecs.get(upsertCraditSegmentRecs[i].AccountStagingId__c).Status__c = 'Error';
                accountStagesToCMSRecs.get(upsertCraditSegmentRecs[i].AccountStagingId__c).Error_Message__c =error+' \n\nerrorms:'+ error.getMessage();
                system.debug(loggingLevel.ERROR,'DML Error:'+error+' \n\nerrorms:'+ error.getMessage());
            }
        }
    }
    
    public static void updateaccountStagesToCMSRecs(Map<Id,Account_Staging__c> accountStagesToCMSRecs,Map<string,CraditSegment__c> CraditSegmentMap){
        List<Account_Staging__c> fetchList = new List<Account_Staging__c>([SELECT Id,Account__C,Name,Status__c,OPUFAEL30__c,OPUFAEL29__c,OPUFAEL14__c,OPUFAEL7__c,SABNR__c,Customer_credit_file_in_CM__c,Account_Source__c,Error_Message__c,Sap_Number__c FROM Account_Staging__c WHERE Id IN:accountStagesToCMSRecs.KeySet() AND Status__c!='Success' AND Status__c!='Error' ]);
        List<Account_Staging__c> updateList = new List<Account_Staging__c>();
        for(Account_Staging__c rec:fetchList){
            string segment = accountStagesToCMSRecs.get(rec.Id).Account__c+rec.SABNR__c;
            system.debug(loggingLevel.ERROR,'segment:'+segment);
            
            system.debug(loggingLevel.ERROR,'updateaccountStagesToCMSRecs method: \nCraditSegmentMap.get(segment).AccountStagingId__c:'+CraditSegmentMap.get(segment));
            system.debug(loggingLevel.ERROR,'CraditSegmentMap:'+CraditSegmentMap);
            if(!CraditSegmentMap.isEmpty() && CraditSegmentMap.get(segment)!=null && CraditSegmentMap.get(segment).AccountStagingId__c!=null && accountStagesToCMSRecs.get(CraditSegmentMap.get(segment).AccountStagingId__c)!=null){
                rec.Status__c = accountStagesToCMSRecs.get(CraditSegmentMap.get(segment).AccountStagingId__c).Status__c;
                rec.Account__c=accountStagesToCMSRecs.get(rec.Id).Account__c;
                rec.Error_Message__c=rec.Status__c=='Error'?accountStagesToCMSRecs.get(CraditSegmentMap.get(segment).AccountStagingId__c).Error_Message__c:null;
                updateList.add(rec);
                system.debug(loggingLevel.ERROR,'updateList:'+updateList);
            }
            else if(rec.Status__c == 'Waiting') {
                system.debug(loggingLevel.ERROR,'skip status line 928');
                
                rec.Status__c = 'Skip'; 
                updateList.add(rec);
                system.debug(loggingLevel.ERROR,'updateList:'+updateList);
            }       
        }
        if(!updateList.isEmpty() ){
            update updateList ;
        } 
    }
}