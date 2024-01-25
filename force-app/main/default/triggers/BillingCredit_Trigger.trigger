trigger BillingCredit_Trigger on Billing_Credit__c (before insert, before update) {
    
    BillingCredit_RelatedDNInfo RelatedDNInfo = new BillingCredit_RelatedDNInfo();

}