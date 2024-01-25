import { LightningElement, api , track, wire} from 'lwc';
import 	Branch_growth__c from '@salesforce/schema/Plot__c.Branch_growth__c'; //For salesforce to verify existing of object
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
import ACCOUNTID from "@salesforce/schema/Opportunity.AccountId";
import ACCOUNTNAME from "@salesforce/schema/Opportunity.Account.Name";
const FIELDS = [ACCOUNTID, ACCOUNTNAME]; 
export default class plotsCreateForm extends LightningElement {
    
    @track customFormModal = false; 
    @api recordId; // Id of the parent record page
    @api objectApiName; // API Name of parent record page
    @track isBranchGrowthRecordSelected = false;
    @track selectedBranchGrowthOfAccountId; // refrench to the selected fertilizerHead from custom lookup field
    @track selectedFertilizerHeadOfBranchId; // refrench to the selected branchGrowth from custom lookup field

    
        
      

    customShowModalPopup() {
        this.customFormModal = true;
        
    }
    
    customHideModalPopup() {
        this.selectedBranchGrowthOfAccountId = null;
        this.selectedFertilizerHeadOfBranchId = null;
        this.customFormModal = false;
    }
    
    get disableFertilizerField(){
        return !this.isBranchGrowthRecordSelected;
    }
    
    
    handleSuccess(event) { //use utils for toast
        const evt = new ShowToastEvent({
            title: "חלקה חדשה נוצרה בהצלחה",
            variant: "success"
        });
        this.customHideModalPopup(); 
        this.dispatchEvent(evt);
        eval("$A.get('e.force:refreshView').fire();");
    }
    
    handleSubmit(event){
        event.preventDefault();
        
        
        const fields = event.detail.fields;
        
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    
    
    
    
    get branchGrowthWhereClause() {
        let whereClause = `AND Account__c = '${this.accountId}'`;
        // console.log('AccountID for query = ' + this.accountId);
        return whereClause;
    }
    get fertilizerHeadWhereClause() {
        let whereClause = `AND Branch_growth__c = '${this.selectedBranchGrowthOfAccountId}'`;
        // console.log('BranchGrowthID for query = ' + this.selectedBranchGrowthOfAccountId);
        return whereClause;
    }
    
    
    handleBranchGrowthSelection(event) { 
        
        if (event.detail == null) {
            // console.log('branchGrowthRecord DEselction');
            this.isBranchGrowthRecordSelected = false;
            this.selectedBranchGrowthOfAccountId = null;
            this.selectedFertilizerHeadOfBranchId = null; //fertilizationHead is dependent on branchGrowth thoue it should be null
        }
        else{
            // console.log('branchGrowthRecord selected');
            this.selectedBranchGrowthOfAccountId = event.detail.Id;
            this.isBranchGrowthRecordSelected = true;
        }
    }
    
    
    handleBranchFertilizerHeadSelection(event) { 
        if (event.detail == null) {
            // console.log('fertilizationHead DEselction');
            this.selectedFertilizerHeadOfBranchId = null;
        }
        else{
            // console.log('fertilizationHead selected');
            this.selectedFertilizerHeadOfBranchId = event.detail.Id;
        }
    }
    
    get branchGrowthId(){
        return this.selectedBranchGrowthOfAccountId;
    } 
    get fertilizerHeadId(){
        return this.selectedFertilizerHeadOfBranchId;
    } 
    
    
    // Get Account data of this Opportunity Page
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    opp;    
    
    
    get accountId(){
        return getFieldValue(this.opp.data, ACCOUNTID);
    }
    
    get accountName(){
        return getFieldValue(this.opp.data, ACCOUNTNAME);
    }
    
    
    
    
    
}