public with sharing class SampleDataTriggerHandler extends TriggerHandler {
    public override void afterInsert(){
        this.createResultRecords((List<Sample_data__c>)Trigger.new);
    }

    public override void afterUpdate() {
        // Delete all the 'result' records related to the 'samle data' that changed
        Set<ID> sampleDataIds = new Set<ID>();
        Set<Lab_Test_Results__c> resToDelete = new Set<Lab_Test_Results__c>();
        // Copy the 'Trigger.new' List to modify
        Map<Id, Sample_data__c> sampleDataForResultsCreation = 
            new Map<Id,Sample_data__c>((List<Sample_data__c>)Trigger.new);

        for(Sample_data__c sd : (List<Sample_data__c>)Trigger.new){
            sampleDataIds.add(sd.id);
        }
        // Get all related results
        Set<Lab_Test_Results__c> allRes = new Set<Lab_Test_Results__c>([
            SELECT id, Sample_data__c, Sample_data__r.Lab_Test__r.Status__c
            FROM Lab_Test_Results__c
            WHERE Sample_data__c IN :sampleDataIds
        ]);

        // Arrange the results and remvoe those who already been 'sent to lab'
        for(Lab_Test_Results__c res : allRes){
            if(res.Sample_data__r.Lab_Test__r.Status__c == 'טיוטה')
                resToDelete.add(res);
            else // Lab test alredy sent to lab - don't change it
                sampleDataForResultsCreation.remove(res.Sample_data__c);
            
        }

        try{
            // Convert Set to List (Can't opperate DML on Set)
            List<Lab_Test_Results__c> resToDeleteList = new List<Lab_Test_Results__c>(resToDelete);
            delete resToDeleteList;
        } catch (DmlException e) {
            System.debug('DmlException : ' + e);
        }

        //Create all the 'result' records that shuld be related to the 'samle data' that changed
        this.createResultRecords(sampleDataForResultsCreation.values());
    }

    private void createResultRecords(List<Sample_data__c> samples){
        // Set (List) for all checkbox names
        Set<String> testComponents = new Set<String>();

        // List for the lab test results to be cteated
        List<Lab_Test_Results__c> labTestRes = new List<Lab_Test_Results__c>();

        // Map to order all Lab_test_Reference_table__c
        Map<Id, Map<String, Lab_test_Reference_table__c>> labTestsReferences = 
            new Map<Id, Map<String, Lab_test_Reference_table__c>>();

        // Map to order all Lab_tests_List__c
        Map<String, Map<String, Lab_tests_List__c>> labTestsList = new Map<String, Map<String, Lab_tests_List__c>>();

        // Get all tests and references related in single nested SOQL
        List<Lab_tests_List__c> tests = [
            SELECT Id, Name, Type__c, Check_Box_Api_Name__c, Test_Code__c,
            (
                SELECT Id, Name, type__c, desired_value__c, Component_tested__c
                FROM Lab_test_Reference_table__r
            )
            FROM Lab_tests_List__c
            WHERE Type__c != null AND Type__c != ''
        ];

        //Arrange the 'component' in maps by component name and type
        for(Lab_tests_List__c test : tests){
            //Add the checkbox 'API name' to the set of components
            testComponents.add(test.Check_Box_Api_Name__c);

            Map<String, Lab_tests_List__c> tempInnerList = labTestsList.get(test.Check_Box_Api_Name__c);

            // alredy in global - add to inner map
            if(tempInnerList != null){
                // Get all types
                List<String> types = new List<String>();
                types = test.Type__c.split(';');
                for(String type : types){
                    tempInnerList.put(type, test);
                }
                labTestsList.put(test.Check_Box_Api_Name__c, tempInnerList);
            } else {// not yet in global map put it in
                Map<String, Lab_tests_List__c> newInnerList = new Map<String, Lab_tests_List__c>();
                // Get all types
                List<String> types = new List<String>();
                types = test.Type__c.split(';');

                for(String type : types){
                    newInnerList.put(type, test);
                }
                labTestsList.put(test.Check_Box_Api_Name__c, newInnerList);
            }

            // Arrange the references if exist
            if(test.Lab_test_Reference_table__r != null && !test.Lab_test_Reference_table__r.isEmpty()){
                Map<String, Lab_test_Reference_table__c> tempRef = new Map<String, Lab_test_Reference_table__c>();
                for(Lab_test_Reference_table__c ref : test.Lab_test_Reference_table__r){
                    tempRef.put(ref.type__c, ref);
                }
                labTestsReferences.put(test.id, tempRef);
            }
        }

        for(Sample_data__c sampleData : samples){
            for(String testComp : testComponents){
                // if checkbox checked create a labTestResult
                if((Boolean)sampleData.get(testComp)){
                    Lab_tests_List__c tempTest = labTestsList.get(testComp).get(sampleData.Type__c);
                    Lab_test_Reference_table__c tempRef = labTestsReferences?.get(tempTest.id)?.get(sampleData.Type__c);

                    labTestRes.add(new Lab_Test_Results__c(
                        Sample_data__c = sampleData.id, 
                        Reference_table__c = tempRef?.id, // ?. means that 'tempRef may be null so don't crash, just return null' 
                        Component_tested__c = tempTest.id
                    ));
                }
            }
        }
        insert labTestRes;
    }
}