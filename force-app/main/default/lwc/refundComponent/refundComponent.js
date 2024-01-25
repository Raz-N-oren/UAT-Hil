import { LightningElement, wire, api,track } from 'lwc';
import getDeliveryNote from '@salesforce/apex/RefundController.getDeliveryNote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import checkTotalCreditForDN from '@salesforce/apex/BillingCredit_RelatedDNInfo.checkTotalCreditForDN';

// Fields for the product lookup search
import ID from '@salesforce/schema/Billing_Credit__c.Id';
import UNIT_OF_MEASURE from '@salesforce/schema/Billing_Credit__c.Unit_of_measure__c';
import QUANTITY from '@salesforce/schema/Billing_Credit__c.Quantity__c';
import PAYING_CUTOMER from '@salesforce/schema/Billing_Credit__c.Paying_Customer__c';
import ACCOUNT from '@salesforce/schema/Billing_Credit__c.Account__c';
import PRODUCT from '@salesforce/schema/Billing_Credit__c.Product__c';
import WEARHOUSE from '@salesforce/schema/Billing_Credit__c.Wearhouse__c';
import LOADING_POINT from '@salesforce/schema/Billing_Credit__c.Loading_Point__c';
import REFUND_TYPE from '@salesforce/schema/Billing_Credit__c.Type__c';
import ACTION_TYPE from '@salesforce/schema/Billing_Credit__c.Action_Type__c';
import SUM from '@salesforce/schema/Billing_Credit__c.Sum__c';
import DOCUMENT_DATE from '@salesforce/schema/Billing_Credit__c.Document_Date__c';
import VALUE_DATE from '@salesforce/schema/Billing_Credit__c.Value_Date__c';
import EXPIRATION_DATE from '@salesforce/schema/Billing_Credit__c.Expiration_Date__c';
import DELIVERY_NOTE from '@salesforce/schema/Billing_Credit__c.Delivery_Note__c';
import REASON from '@salesforce/schema/Billing_Credit__c.Reason__c';

import DEAL_TYPE from '@salesforce/schema/Billing_Credit__c.deal_type__c';
import REFUND_YEAR from '@salesforce/schema/Billing_Credit__c.refund_year__c';
import BUSINESS_UNIT from '@salesforce/schema/Billing_Credit__c.business_unit__c';
import CUSTOMER_TYPE from '@salesforce/schema/Billing_Credit__c.customer_type__c';
import START_DATE from '@salesforce/schema/Billing_Credit__c.start_date__c';


const fields = [ID, UNIT_OF_MEASURE, QUANTITY, PAYING_CUTOMER, ACCOUNT, PRODUCT, WEARHOUSE, LOADING_POINT, REFUND_TYPE,ACTION_TYPE, SUM, REASON, DOCUMENT_DATE, VALUE_DATE, EXPIRATION_DATE, DELIVERY_NOTE,DEAL_TYPE,REFUND_YEAR,BUSINESS_UNIT,CUSTOMER_TYPE,START_DATE];

export default class RefundComponent extends LightningElement {

    @api recordId;
    activeSections = ['A', 'B', 'C'];
    account;
    product;
    loadingPoint;
    unitOfMeasure;
    PayingAccount;
    actionTypeFromField;
    typeOfRefundFromField;
    deliveryNoteId;
    documentDate;
    valueDate;
    expirationDate;
    reasone;
    wearhouse;

    deal_type;
    refund_year;
    business_unit;
    customer_type;
    start_date;

    disabled = true;
    quantity;
    sum;
    test=false;
    isEditable=true;
    tashlumMirosh=true;
    isMeshalem=true;
isQuantityDisplay;
    validateForm(event) {
    event.preventDefault();
    // const validation = this.template.querySelectorAll(".valid");
    // validation.forEach((currentInput) => {
    //        // let valueOfInput = event.target.value;      
    //        event.target.value.setCustomValidity("זהו שדה חובה"); // if there was a custom error before, reset it
    //        event.target.value.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
    //                  // valueOfInput.focus();
    //                   throw " ולידציה נכשלה";
    //          } );
    console.log("actionTypeFromField",this.actionTypeFromField);
    if ( this.actionTypeFromField == '10' ||  this.actionTypeFromField == '20'){ // לאחר סבמיט, רק אם זה סוג פעולה מול ת.משלוח - בדוק קרדיט אשראי זמין לזיכוי
        this.checkTotalCreditForDN(event);
    }else{
        this.submitForm(event); 
    }
    }

    submitForm(event) {
        console.log("line 87",this.account,event.detail.fields);
        try {
            const fields = event.detail.fields;
            fields.Account__c = this.account;
            fields.Paying_Customer__c = this.PayingAccount;
            fields.Wearhouse__c = this.wearhouse;
            fields.Product__c = this.product;
            fields.Loading_Point__c = this.loadingPoint;
            fields.Delivery_Note__c = this.deliveryNoteId;

            fields.deal_type__c=this.deal_type;
            fields.refund_year__c=this.refund_year;
            fields.business_unit__c=this.business_unit;
            fields.customer_type__c=this.customer_type;
            fields.start_date__c=this.start_date;
        
        
            this.template.querySelector('lightning-record-edit-form').submit(fields); //מתבעצת קריאת שרת תוך שימוש בקומפ בילדאין הזו? וגם השמה ואופציה לעריכה
        } catch (err) {
            console.error(err);
        }
    }

    handleSuccess(event) {
        console.log(`64: RefundComponent -> handleSuccess -> event.detail: ${JSON.stringify(event.detail)}`);
        this.dispatchEvent( new ShowToastEvent({ title: 'הצלחה ביצירת זיכוי', variant: 'success' }) );
        this.handleReset();
    }
    handleError(event) {
        console.log(`277. RefundComponent -> handleError -> event.detail: ${JSON.stringify(event.detail)}`); 
        this.dispatchEvent( new ShowToastEvent({title: 'כישלון ביצירת זיכוי', variant: 'error'}));
    }

    connectedCallback() {
        // this.handleActionTypeChange();
        this.tashlumMirosh = this.actionTypeFromRec =="60"? false : true;

        if (this.recordId) {
            this.disabled = true;
        }
        else {
            // let today = new Date();
            // this.documentDate=today.toISOString().split('T')[0];
            // console.log(" this.documentDate", this.documentDate);
            this.documentDate = new Date().toISOString().slice(0, 10); 
            console.log("this.documentDate",this.documentDate);
            this.start_date = this.documentDate;
        }
    }
    handleReset() {
        this.account = null;
        this.product = null;
        this.loadingPoint = null;
        this.unitOfMeasure = null;
        this.PayingAccount = null;
        this.actionTypeFromField = null;
        this.typeOfRefundFromField = null;
        this.deliveryNoteId = null;
        this.documentDate = null;
        this.valueDate = null;
        this.expirationDate = null;
        this.reasone = null;
        this.wearhouse = null;
        this.deal_type= null;
        this.refund_year= null;
        this.business_unit= null;
        this.customer_type= null;
        this.start_date= null;
    
    }


    handleActionTypeChange(event) {
        console.log("handleActionTypeChange: ", JSON.stringify(event.detail));
        this.tashlumMirosh=event.detail.value=="60"? false : true;
        this.isEditable=false;
        this.test = true;
        this.actionTypeFromField = event.detail.value;
    }

    typeOfRefundHandler(event) {
        this.typeOfRefundFromField = event.detail.value;
        console.log("typeOfRefundFromField",this.typeOfRefundFromField);
    }
    documentDateHandler(event) {
        this.documentDate = event.detail.value;
    }
    valueDateHandler(event) {
        this.valueDate = event.detail.value;
    }
    expirationDateHandler(event) {
        this.expirationDate = event.detail.value;
    }
    loadingPointHandler(event) {
        this.loadingPoint = event.detail.value[0];
    }
    reasoneChangeHanlder(event) {
        this.reasone = event.detail.value;
    }
    wearhouseHandler(event) {
        this.wearhouse = event.detail.value[0];
    }
    PayingAccountHandler(event) {
        this.PayingAccount = event.detail.value[0];
    }
    receieCustomerHandler(event) {
        this.account = event.detail.value[0];
    }
    productHandler(event) {
        this.product = event.detail.value[0];
    }

    // תשלום מראש הנדלרס
    dealTypeHandler(event) {
        this.deal_type = event.detail.value;
        if (this.deal_type=="משלם") {
           this.isMeshalem  =false;
        } else {
            this.isMeshalem  =true;
        }
        console.log( this.deal_type," this.deal_type");
    }
    refundYearHandler(event) {
        this.refund_year = event.detail.value;
    }
    businessUnitHandler(event) {

        this.business_unit = event.detail.value;
    }
    customerTypeHandler(event) {
        this.customer_type = event.detail.value;
    }
    startDateHandler(event) {
        this.start_date = event.detail.value;
    }

    //onchange to delivery
    deliveryNoteHandler(event) {
        console.log("deliveryNoteHandler",Object.values(event.detail.value)[0]);
        if (event.detail?.value.length == 0) {
            this.account = null;
            this.product = null;
            this.loadingPoint = null;
            this.unitOfMeasure = null;
            this.PayingAccount = null;
            this.wearhouse = null;
            this.deal_type= null;
            this.refund_year= null;
            this.business_unit= null;
            this.customer_type= null;
            this.start_date= null;
        }
        else {
          //  this.deliveryNoteId = Object.values(event.detail.value)[0];
            this.deliveryNoteId = event.detail.value[0]; 
            console.log("this.deliveryNoteId 235",this.deliveryNoteId);
           // this.checkTotalCreditForDN();
        }
        console.log("deliveryNoteHandler: ", JSON.stringify(event.detail));
    }
        //onchange to quantity

    quantityHandler(event) {
        console.log("quantityHandler: ", JSON.stringify(event.detail))
        this.quantity = event.detail.value;
       // this.checkTotalCreditForDN();
    }
        //onchange to sum amount

    sumHandler(event) {
        console.log("sumHandler: ", JSON.stringify(event.detail))
        this.sum = event.detail.value;
      //  this.checkTotalCreditForDN();
    }

    @wire(getDeliveryNote, { Id: "$deliveryNoteId" })
    deliveryNote(result) {
        console.log("result getDeliveryNote",result.data);
        if (result.data) {
            let data = result.data[0];
            this.account = data.Account__c;
            this.product = data.Delivery_Note_Line_Items__r[0].Product__c;
            this.loadingPoint = data.LoadingPoint__c;
            this.unitOfMeasure = data.UnitOfMeasure__c;
            this.PayingAccount = data.PayingAccount__c;
            this.documentDate = data.InvoiceDate__c;
            this.wearhouse=data.Order__r.IntermediaryWarehouse__c;
            
            this.deal_type=  data.deal_type__c;
            this.refund_year=  data.refund_year__c;
            this.business_unit=  data.business_unit__c;
            this.customer_type=  data.customer_type__c;
            this.start_date=  data.start_date__c;

            console.log("deliveryNote: ", JSON.stringify(result.data[0]))
        } else if (result.error) {
            console.log(`231. : ${JSON.stringify(result.error)}`);
            this.account = null;
            this.product = null;
            this.loadingPoint = null;
            this.unitOfMeasure = null;
            this.PayingAccount = null;
            this.documentDate = null;
            this.deal_type= null;
            this.refund_year= null;
            this.business_unit= null;
            this.customer_type= null;
            this.start_date= null;

        }
    }
    bilingCredit=[];
    billingCreditData;
    @wire(getRecord, { recordId: '$recordId', fields: fields })
    getRecordOnLoad(res){ //בעלייה 
    this.bilingCredit=res;
this.billingCreditData=this.bilingCredit.data;
if (this.billingCreditData !=null || this.billingCreditData != undefined) {
    const actionType=this.billingCreditData['fields']['Action_Type__c']['value'];
    this.tashlumMirosh=actionType=="60"? false : true;
    this.isEditable=false;
    this.test = true;
} else {
console.log("else");
}
}

    
    checkTotalCreditForDN(event) { //בודקת את סך הסכום הקיים בדאטבייס לזיכוי
        console.log("bilingCredit",this.bilingCredit);
        console.log("line 271",this.deliveryNoteId , this.quantity , this.sum);
       // if ( this.typeOfRefund == '10' ||  this.typeOfRefund == '20'
            //this.deliveryNoteId && this.quantity || this.sum
           //  ) {
            checkTotalCreditForDN({ DN: this.deliveryNoteId, quantity: this.quantity, unitOfMeasure:this.unitOfMeasure  ,amount: this.sum }).then(result => {
                console.log("result #285",result);
                if (result !== null) {
                    this.dispatchEvent(new ShowToastEvent({title: "שגיאה",message: result,variant: 'error',}));
                } else{
                    this.submitForm(event);
                }
                console.log("checkTotalCreditForDN: ", JSON.stringify(result))
            }).catch(error => {
                console.log("checkTotalCreditForDN: ", error)
            })
       // }
    }

    get actionType() {
        if (this.actionTypeFromRec) { 
            return this.actionTypeFromRec; 
        }
        if (this.actionTypeFromField) { 
            return this.actionTypeFromField;
         }
        else { 
            return null; 
        }
    }
    get typeOfRefund() {
        if (this.typeOfRefundFromRec) { return this.typeOfRefundFromRec; }
        if (this.typeOfRefundFromField) { return this.typeOfRefundFromField; }
        else { return null; }
    }

    get actionTypeFromRec() {
    console.log(this.bilingCredit,"this.bilingCredit.data");
        return getFieldValue(this.bilingCredit, ACTION_TYPE);
    }
    get typeOfRefundFromRec() {
        return getFieldValue(this.bilingCredit, REFUND_TYPE);
    }
    get isMoneyType() {
        return this.actionTypeFromField == '10' ? true : false;
    }
    get isQuantityType() {
       
        return this.typeOfRefundFromField == '20' ? true : false;
    }
    get isRefundAgainstDeliveryNote() { // זיכוי למול ת.משלוח 
        return (this.actionTypeFromField != '10') && (this.actionTypeFromField != '60') ? false  : true;
    }
    get isFutureRefundAgainstDeliveryNote() { // זיכוי למול ת.משלוח עתידי
        return this.actionTypeFromField == '20' ? true : false;
    }
    get isFutureOrMoneyRefundAgainstDeliveryNote() { // לקוח
        if (this.test && (this.actionTypeFromField != '20' && this.actionTypeFromField != '10') ){
            return false;
        } else {
            return true;
        }
        // return (this.actionType == '20' || this.actionType == '10') && this.test ? true : false;
    }
    get isUnitOfMeasure(){
        console.log(this.typeOfRefundFromField,"378");
        return this.typeOfRefundFromField !=='10' && this.typeOfRefundFromField != undefined ? true : false;
    }
    get isFutureOrMoneyRefundAgainstRequired() { // תעודת משלוח required?
        return this.actionTypeFromField == '20' || this.actionTypeFromField == '10' ? true : false;
    }
    get getDeliveryNoteDisable() {
        console.log("RAZCHECK, 386, this.actionTypeFromField",this.actionTypeFromField);
      return this.actionTypeFromField == '20' || this.actionTypeFromField == '50' || this.actionTypeFromField == '10' ? false  :true ;
        // return true;
    }

    get isFutureRefund() { // תאריך תוקף ויזיבילי?
        return this.actionTypeFromField == '20' || this.actionTypeFromField == '40' ? true : false;
    }
    get isNotAgainstDeliveryNote() { // תאריך ערך ויזיבילי?
        return this.actionTypeFromField == '30' || this.actionTypeFromField == '40' ? true : false;
    }
    get isRefundNotAgainstDeliveryNote() {
        return this.actionTypeFromField == '30' ? true : false;
    }
    get isFutuerRefundNotAgainstDeliveryNote() {
        return this.actionTypeFromField == '40' ? true : false;
    }
    get isBilling() {
        return this.actionTypeFromField == '50' ? true : false;
    }
    get showSum() {
        return true;
    //     return this.actionTypeFromField == '10' || this.actionTypeFromField == '20' || this.actionTypeFromField == '60' || this.actionTypeFromField == '30' ||this.actionTypeFromField == '40' ? true : false;
    }
}