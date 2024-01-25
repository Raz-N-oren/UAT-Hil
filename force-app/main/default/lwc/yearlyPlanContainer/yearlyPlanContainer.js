import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
import ACCOUNTID from "@salesforce/schema/Opportunity.AccountId";
import ACCOUNTNAME from "@salesforce/schema/Opportunity.Account.Name";
const FIELDS = [ACCOUNTID, ACCOUNTNAME]; 

export default class YearlyPlanContainer extends LightningElement {



    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    opp;    
    

    get accountId(){
        return getFieldValue(this.opp.data, ACCOUNTID);
    }

    get accountName(){
        return getFieldValue(this.opp.data, ACCOUNTNAME);
    }

    updateOppProductrecordId(event){
        this.template.querySelector('c-yearly-plan-edit').isEdit = true;
        this.template.querySelector('c-yearly-plan-edit').resetValuesForClone(event.detail.Id);
        
    }

    refreshOppLineList(){
        this.template.querySelector('c-yearly-plan').refreshOppLineList();
    }
    
    preperOppProductClone(event){
        this.template.querySelector('c-yearly-plan-edit').isEdit = false;
        this.template.querySelector('c-yearly-plan-edit').resetValuesForClone(event.detail.Id);
    }
    
    preperOppProductDelete(event){
        if(this.template.querySelector('c-yearly-plan-edit').oppProductId == event.detail.id){
            this.template.querySelector('c-yearly-plan-edit').oppProductId = '';
        }
    }

}