import { LightningElement, api, track, wire } from 'lwc';
import AccountGetSapInfo from '@salesforce/apex/AccountGetSapInfo.GetAccountSapInfo'

export default class CreditCardComponent extends LightningElement {
    @api recordId;
    @track credit;

    connectedCallback() {
        AccountGetSapInfo({ recordId: this.recordId }).then(response => {
            console.log(response);
            this.credit = response.Credit;
        }).catch(err => {
            console.error('SAP Error Response: ', err.body.message);
        })
    }

}