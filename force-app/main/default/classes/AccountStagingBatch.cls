global class AccountStagingBatch implements Database.Batchable<sObject>  {
    global Database.QueryLocator start(Database.BatchableContext bc) {
	String query = 'SELECT ABCD_Classification__c, Account2__c, Account__c, Account_Name__c,OPUFAEL30__c,OPUFAEL29__c,Invoice_email__c,OPUFAEL14__c,OPUFAEL7__c, Account_Number__c, Account_Owner__c, Account_record_Type__c, Account_Source__c,Account_Type__c,Name_2__c,Cell_phone_Number__c, Action_Type__c, ATLBRTG__c, bill_to_flag__c, Business_Unit__c, City__c, Country__c, Cpfname__c, Cplname__c, CPmail__c,  CpN__c, Cptel1__c, CPtel2__c, CreatedById, Currency__c, CurrencyIsoCode, Customer_credit_file_in_CM__c, Customer_grouping__c, customer_type_code__c, Description__c, Distribution_Channel__c, Division__c, domain_code__c, Email__c, Error__c, Error_Message__c, External_Id__c, Fax__c, Id, Inco_2__c, Inco_Terms__c, Industry__c, Inserted__c, JOINTCUS__c, KLIMK__c, LastModifiedById, Name, OBLIG__c, Old_Identfier__c, OPUFAEL__c, OwnerId, Parent_Account__c, Partnering_TYPE__c, Payment_Terms__c, Phone_2__c, Phone__c,Clerk_in_charge__c,Sgmnt_Txt__c, region_code__c, RISKCL__c, SABNR__c, Sales_Territory__c, salesperson1_code__c, salesperson2_code__c, salesperson2_name__c, salesperson3_code__c, salesperson4_Name__c, SAP_AccGr_text__c, SAP_Account_Group__c, Sap_Number_2__c, Sap_Number__c, ship_to_flag__c, sold_to_flag__c, State_Province__c, Status__c, Street__c, Type__c, VAT_Number__c, VIPCUS__c, Zip_Postal_Code__c,CRBLB__c,LOEVM__c,NIELS__c FROM Account_Staging__c WHERE Status__c = \'Waiting\' AND Action_Type__c != null  Order By LastModifiedDate DESC';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Account_Staging__c> accStageList){
        system.debug('accStageList:'+accStageList.size());
		Map<String, List<Account>> srcAccountsToUpsertMap = new Map<String, List<Account>>();

        for(String srcSys : AccountStagingTriggerHelper.sourceSys){
            srcAccountsToUpsertMap.put(srcSys, new List<Account>());
        }
		Map<String,Account> accountsToUpdateMap = new Map<String,Account>();
		List<Contact> contactsToUpdate = new List<Contact>();
		List<Contact> contactsToUpsert = new List<Contact>();
		List<Function_Partner__c> functionPartnersToUpsert = new List<Function_Partner__c>();
		List<Sales_Area__c> salesAreasToUpsert = new List<Sales_Area__c>();
		List<Account_Staging__c> accountStagesToUpdate = new List<Account_Staging__c>();
		Map<String, String> groupTypeMap = new Map<String,String>();
		AccountStagingTriggerHelper.getGroupTypeMap(groupTypeMap);   

		Map<Id, Account> CMAccountsToUpdate = new Map<Id, Account>();
        Map<String, Account> accRecs = new Map<String, Account>();

        //Map based on Credit File Identifier for the Credit Segment process
        Map<String, List<Account>> accCMSRecs= new Map<String, List<Account>>();
        Map<Id,Account_Staging__c> accountStagesToCMSRecs= new Map<Id, Account_Staging__c>();
        List<CraditSegment__c> upsertCraditSegmentRecs = new List<CraditSegment__c>();
        Map<string,CraditSegment__c> CraditSegmentMap = new Map<string,CraditSegment__c>();

        

		// Get the all related Account records
		AccountStagingTriggerHelper.getAccsByExId(accStageList, accRecs);

      	for (Account_Staging__c accStage : accStageList) {
          	if (accStage.Action_Type__c == 'Account'){
				AccountStagingTriggerHelper.addToAccounts(
					accStage,
                    srcAccountsToUpsertMap,
					accountsToUpdateMap, 
					groupTypeMap, 
					accountStagesToUpdate
				);
          	}
			if (accStage.Action_Type__c == 'Partner function')
				AccountStagingTriggerHelper.addToFunctionPartners(accStage, functionPartnersToUpsert);
			if (accStage.Action_Type__c == 'Sales Area')
				AccountStagingTriggerHelper.addToSalesAreas(accStage, salesAreasToUpsert);
			if (accStage.Action_Type__c == 'Contact Partner')
				AccountStagingTriggerHelper.addToContacts(accStage, contactsToUpsert,contactsToUpdate,accountStagesToUpdate);
			if (accStage.Action_Type__c == 'CM' && accstage.SABNR__c=='0000')
				AccountStagingTriggerHelper.addToCMAccs(accStage, accRecs, CMAccountsToUpdate, accountStagesToUpdate);
      	}        
  
		if (!accountsToUpdateMap.isEmpty())
			AccountStagingTriggerHelper.processAccountsUpdate(accountsToUpdateMap.values(), accountStagesToUpdate);
		
		for(String srcSys : AccountStagingTriggerHelper.sourceSys){
            if(!((srcAccountsToUpsertMap.get(srcSys)).isEmpty())){
				AccountStagingTriggerHelper.processAccountsUpsert(
					srcAccountsToUpsertMap.get(srcSys), 
					accountStagesToUpdate, 
					srcSys
				);
			}
        }
		if (!contactsToUpdate.isEmpty())
			AccountStagingTriggerHelper.processContactsUpdate(contactsToUpdate, accountStagesToUpdate);
		if (!contactsToUpsert.isEmpty())
			AccountStagingTriggerHelper.processContactsUpsert(contactsToUpsert, accountStagesToUpdate);
		if (!salesAreasToUpsert.isEmpty())
			AccountStagingTriggerHelper.processSalesAreasUpsert(salesAreasToUpsert, accountStagesToUpdate);
		if (!functionPartnersToUpsert.isEmpty())
			AccountStagingTriggerHelper.processFunctionPartnersUpsert(functionPartnersToUpsert, accountStagesToUpdate);
		if (!CMAccountsToUpdate.isEmpty())
			AccountStagingTriggerHelper.processCMAccountsUpdate(CMAccountsToUpdate, accountStagesToUpdate);
		if (!accountStagesToUpdate.isEmpty())
			update accountStagesToUpdate;
        
        
    		//Credit Segment Section 
		AccountStagingTriggerHelper.getCMSAccsByExId(accStageList,accCMSRecs,accountStagesToCMSRecs,CraditSegmentMap);
		AccountStagingTriggerHelper.createCMSRecs(accountStagesToCMSRecs,accCMSRecs,CraditSegmentMap);
        AccountStagingTriggerHelper.processInsertCMSRecs(CraditSegmentMap,accountStagesToCMSRecs,upsertCraditSegmentRecs);
        AccountStagingTriggerHelper.updateaccountStagesToCMSRecs(accountStagesToCMSRecs,CraditSegmentMap);
        
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}