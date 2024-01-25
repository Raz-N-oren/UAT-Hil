import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import FORM_FACTOR from '@salesforce/client/formFactor';
import updateLastViewed from '@salesforce/apex/CustomLookUpController.updateLastViewed';
import Utils from "c/utils";
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import PriceBook2Id from "@salesforce/label/c.PriceBook2Id";
import Authorized_Profile from "@salesforce/label/c.Authorized_Profile_name";
import getAccountClassification from '@salesforce/apex/discountDetailsController.getAccountClassification';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getPicklistLabel from '@salesforce/apex/getPicklistLabel_Controller.getPicklistLabel';
// If record already exists - get this fields (rec info)
import OPP_ACCOUNT_NAME from '@salesforce/schema/Opportunity.Account.Name';
import OPP_ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import OPP_CONTRACTOR from '@salesforce/schema/Opportunity.Contractor__c';
import OPP_CONTRACTOR_NAME from '@salesforce/schema/Opportunity.Contractor__r.Name';
import OPP_DESCRIPTION from '@salesforce/schema/Opportunity.Description';
import OPP_SCOPE from '@salesforce/schema/Opportunity.Scope__c';
import OPP_EXECUTION_DATE from '@salesforce/schema/Opportunity.ExecutionDate__c';
import OPP_ACTUAL_AMOUNT_OF_ACRES from '@salesforce/schema/Opportunity.ActualAmountOfAcres__c';
import OPP_CRANE from '@salesforce/schema/Opportunity.crane__c';
import OPP_TRAILER_DAYS from '@salesforce/schema/Opportunity.trailerDays__c';
import OPP_CONTRACTOR_PRICE_PER_ACRE from '@salesforce/schema/Opportunity.contractorPricePerAcre__c';
import OPP_STATUS from '@salesforce/schema/Opportunity.Status__c';
import OPP_TYPE from '@salesforce/schema/Opportunity.Type';
import OPP_VALID_FROM from '@salesforce/schema/Opportunity.Valid_from__c';
import OPP_VALID_TO from '@salesforce/schema/Opportunity.Valid_To__c';
import OPP_WAREHOUSE from '@salesforce/schema/Opportunity.Warehouse__c';
import OPP_WAREHOUSE_NAME from '@salesforce/schema/Opportunity.Warehouse__r.Name';
import OPP_STAGENAME from '@salesforce/schema/Opportunity.StageName';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import OPP_CLOSEDATE from '@salesforce/schema/Opportunity.CloseDate';
import OPP_RECTYPEID from '@salesforce/schema/Opportunity.RecordTypeId';
// import getLoadingPointBySapId from "@salesforce/apex/PriceOfferController.getLoadingPointBySapId";


import OPP_PercentageOfFulfillment__c from '@salesforce/schema/Opportunity.PercentageOfFulfillment__c';
import OPP_TypeOfAlert__c from '@salesforce/schema/Opportunity.TypeOfAlert__c';
import OPP_DaysBeforeEnd2__c from '@salesforce/schema/Opportunity.DaysBeforeEnd2__c';


// Fields for the lookup search
import ACC_ID from '@salesforce/schema/Account.Id';
import LAST_VIEWED_DATE from '@salesforce/schema/Account.LastViewedDate';
import ACC_NAME from '@salesforce/schema/Account.Name';
import ACC_SAP_NUM from '@salesforce/schema/Account.Sap_Number__c';

const fields = [OPP_ACCOUNT_NAME, OPP_ACCOUNT_ID, OPP_CONTRACTOR, OPP_CONTRACTOR_NAME,OPP_CONTRACTOR_PRICE_PER_ACRE, OPP_DESCRIPTION,
    OPP_EXECUTION_DATE, OPP_ACTUAL_AMOUNT_OF_ACRES, OPP_CRANE,OPP_TRAILER_DAYS, OPP_SCOPE, OPP_STATUS, OPP_TYPE, OPP_VALID_FROM, 
    OPP_VALID_TO, OPP_WAREHOUSE, OPP_WAREHOUSE_NAME, OPP_STAGENAME, OPP_NAME, OPP_CLOSEDATE, OPP_RECTYPEID,OPP_PercentageOfFulfillment__c,OPP_TypeOfAlert__c,OPP_DaysBeforeEnd2__c];

const lookupFields = [ACC_ID, ACC_NAME, ACC_SAP_NUM, LAST_VIEWED_DATE];

const ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(Date.now());
const mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(Date.now());
const da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(Date.now());

export default class PriceOfferHead extends LightningElement {
    @api recordId;
    @track rec = {
        account: { id: null, name: null },
        contractor: { id: null, name: null },
        warehouse: { id: null, name: null },
        description: null,
        scope: 'כימיקלים',
        status: 'Draft',
        type: null,
        validFrom: `${ye}-${mo}-${da}`,
        validTo: this.lastDayOfThisYear,
        id: null,
        name: null,
        stageName: null,
        closeDate: null,
        recordTypeId: null,
        TypeOfAlert__c:null,
        PercentageOfFulfillment__c:null,
        DaysBeforeEnd2__c:null
    };
    warehouseExtraWhereClause = " WHERE SAP_Account_Group__c ='NOTI'";
    // warehouseExtraWhereClause = " WHERE (AccountSource='FER' OR SAP_Account_Group__c!='0002') AND SAP_Account_Group__c!='NOTI'";
    // warehouseExtraWhereClause = " AND SAP_Account_Group__c = 'NOTI' AND (AccountSource = 'FER' OR AccountSource = 'ILF')";
    contractorExtraWhereClause = " WHERE Account_Sub_Type__c='קבלן דישון' OR (Industry='קבלן דישון')";
    // contractorExtraWhereClause = " WHERE Industry = 'קבלן דישון'";
    contractorMessage = "לא נמצא קבלן מבצע..";
    warehouseMessage = "לא נמצא מחסן מתווך..";
    requiredWarehouse = true;
    requiredContractor = true;
    label = "לקוח";
    notFoundMessage = "..לקוח לא נמצא ";
    placeholder = "חפש לקוח משתי אותיות ומעלה...";
    lookupFields = lookupFields.map(field => field.fieldApiName).join(', ');
    priceOfferRecId;
    fertPlanRecId;
    defaultCurrencyIsoCode = 'ILS';
    submitionByWrapper = false;
    userProfile;
    @api totalPrice = 0;
    @api totalPricePerHectar = 0;
    @track customerSize = '';
    maxDiscount = 0;
    targetDiscount = 0;
    isPercantage;
    isDays;
    orderData = {
        executionDate: '',
        plotsSize: '',
        crane: false,
        trailerDays: '',
        contractorPricePerAcre: ''
    }
    // get record (Opportunity) by id
    @wire(getRecord, { recordId: '$recordId', fields })
    populateOppLineFields({ error, data }) {
        console.log();
        if (data && !this.rec.type) { // Get record just once
            console.log("populateOppLineFields: ", JSON.stringify(data.fields.DaysBeforeEnd2__c));
            this.rec.account.id = data.fields.Account.value?.id;
            this.rec.account.name = data.fields.Account.value?.fields?.Name?.value;
            this.rec.contractor.id = data.fields.Contractor__c.value;
            this.rec.contractor.name = data.fields.Contractor__r.displayValue;
            this.rec.description = data.fields.Description.value;
            this.rec.scope = data.fields.Scope__c.value;
            this.rec.status = data.fields.Status__c.value;
            this.rec.type = data.fields.Type.value;
            this.rec.validFrom = data.fields.Valid_from__c.value;
            this.rec.validTo = data.fields.Valid_To__c.value;

            this.rec.TypeOfAlert__c = data.fields.TypeOfAlert__c?.value;
            if (this.rec.TypeOfAlert__c==1) {
                this.isPercantage=true;
                this.isDays=false;

            }else{
                this.isDays=true;
                this.isPercantage=false;
        
            }
        
            this.rec.PercentageOfFulfillment__c = data.fields.PercentageOfFulfillment__c?.value;
            this.rec.DaysBeforeEnd2__c = data.fields.DaysBeforeEnd2__c?.value;
            
            this.rec.warehouse.id = data.fields.Warehouse__c?.value;
            this.rec.warehouse.name = data.fields.Warehouse__r?.displayValue;
            this.rec.name = data.fields.Name.value;
            this.rec.stageName = data.fields.StageName.value;
            this.rec.closeDate = data.fields.CloseDate.value;
            this.rec.recordTypeId = data.fields.RecordTypeId.value;

            this.orderData.contractorPricePerAcre = data.fields.contractorPricePerAcre__c.value;
            this.orderData.executionDate = data.fields.ExecutionDate__c.value;
            this.orderData.trailerDays = data.fields.trailerDays__c.value;
            this.orderData.crane = data.fields.crane__c.value;
            this.orderData.plotsSize = data.fields.ActualAmountOfAcres__c.value;
            this.updateWrapper();
            this.getPicklistLabel();
        } else if (error) {
            let message = "@wire(getRecord): Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            Utils.showToast(this, "שגיאה", message, "error");
        }
    }

    getPicklistLabel() {
        getPicklistLabel({fieldApi: "Status__c",ObjApi:'Opportunity' , recId: this.recordId}).then(res => {
            this.rec.status = res;
        }).catch(err => {
            console.error("Error getPicklistLabel: ", err)
        })

    }
    // get the recordTypeIds in this ORG
    @wire(getObjectInfo, { objectApiName: 'Opportunity' })
    getObjectData({ data, error }) {
        if (data) {
            const infos = Object.values(data.recordTypeInfos);
            this.priceOfferRecId = infos.find(rec => rec.name === 'Price Offers' || rec.name === 'הצעת מחיר').recordTypeId;
            this.fertPlanRecId = infos.find(rec => rec.name === 'Fertilize Plan' || rec.name === 'תוכנית דישון').recordTypeId;
        }
        if (error) {
            console.log(`008. Error: ${JSON.stringify(error)}`);
        }
    }
    @wire(getRecord, { recordId: strUserId, fields: [PROFILE_NAME_FIELD] })
    wireuser({ error, data }) {
        console.log("wired Data: ", JSON.stringify(data))
        if (error) {
            console.log(`Error in user info wire: ${JSON.stringify(error)}`);
        } else if (data) {
            
            this.userProfile = data.fields.Profile.value.fields.Name.value;
            if (!this.recordId) {
                if (this.userProfile === 'IL - Sales manager')
                    this.rec.scope = 'דשנים';
                else if (this.userProfile === 'IL - Sales manager Chemicals' ||
                    this.userProfile === 'System Administrator')
                    this.rec.scope = 'כימיקלים';
                this.updateWrapper();
            }
        }
    }

    getAccountClassification(accId) {
        getAccountClassification({ accId: accId }).then((result) => {
            console.log("wiredMatrixLineInfo: ", result);
            this.customerSize = result[0]?.Classification__c;
        }).catch(err => {
            console.log("error getAccountClassification: ", err);
            this.customerSize = '';
        })
    }

    copyFlag = false;

    // renderedCallback() {
    //     if (this.copyFlag) {
    //         this.rec = { ...this.rec };
    //         this.copyFlag = false;
    //     }
    // }

    changeType(e) {
        this.rec.type = e.detail.value;
        console.log("changeType: ", e.detail.value);

        this.updateWrapper();
    }

    changeValidFrom(e) { this.rec.validFrom = e.detail.value; }
    changeValidTo(e) { this.rec.validTo = e.detail.value; }
    changeDescription(e) { this.rec.description = e.detail.value; }
    alertSelected(e) { 
        this.rec.TypeOfAlert__c = e.detail.value;
        console.log("TypeOfAlert__c",this.rec.TypeOfAlert__c);
    if (this.rec.TypeOfAlert__c==1) {
        this.isPercantage=true;
        this.isDays=false;

    }else{
        this.isDays=true;
        this.isPercantage=false;

    }
    }
    percentageSelected(e) { this.rec.PercentageOfFulfillment__c = e.detail.value }
    daysB4EndSelected(e) { this.rec.DaysBeforeEnd2__c= e.detail.value }

    // getLoadingPointBySapId(contrId) {
    //     getLoadingPointBySapId({ contrId: contrId }).then((result) => {
    //         console.log("RAZCHECK,254, getLoadingPointBySapId,: ", result);
    //         // this.customerSize = result[0]?.Classification__c;
    //     }).catch(err => {
    //         console.log("error getLoadingPointBySapId: ", err);
    //         this.customerSize = '';
    //     })
    // }

    changeContractorHandler(e) {
        console.log("RAZCHECK,254 263 changeContractorHandler,: ", e.detail);
        this.rec.contractor.name = e.detail.selectedValue;
        this.rec.contractor.id = e.detail.selectedRecordId;
        // this.getLoadingPointBySapId(this.rec.contractor.id);
    }

    changeWarehouseHandler(e) {
        this.rec.warehouse.name = e.detail.selectedValue;
        this.rec.warehouse.id = e.detail.selectedRecordId;
    }

    changeScope(e) {
        this.rec.scope = e.detail.value;
        this.dispatchEvent(new CustomEvent('updatedefaultunitofmeasure'));
        this.rec.type = null;
    }

    accSelected(event) { //אורדרג'נריקלוקאפ מדספצ' את הלקוח הנבחר לכאן
        if (event?.detail?.selectedRec) {
            this.rec.account.name = event.detail.selectedRec.Name;
            this.rec.account.id = event.detail.selectedRec.Id;
            this.getAccountClassification(event.detail.selectedRec.Id); // לקוח גדול/בינוני/קטן
            updateLastViewed({ objectName: 'Account', recId: event.detail.selectedRec.Id }) //נצפו לאחרונה
                .catch(err => { console.error('Error ocured on Lastviewed update: ' + err); });
        }
        else { // Account unselected
            this.rec.account.name = null;
            this.rec.account.id = null;
            this.customerSize = '';
        }
        const passEventr = new CustomEvent('accselected', {
            detail: { accountId: this.rec.account.id }
        });
        this.dispatchEvent(passEventr);
    }

    updateWrapper() { // update the wrapper with Opportunity data
        console.log("right b4 sending to wrapper",this.rec,this.orderData);
        const passEventr = new CustomEvent('updatewrapper', {
            detail: { oppRecord: this.rec, orderData: this.orderData }
        });
        this.dispatchEvent(passEventr);
    }

    @api resetForm(isNew) {
        console.log(isNew);
        if (isNew != null) {       
            this.rec.account = { id: null, name: null };
            this.rec.contractor = { id: null, name: null };
            this.rec.warehouse = { id: null, name: null };
            this.rec.description = null;
            this.rec.type = null;
            this.rec.validFrom = `${ye}-${mo}-${da}`;
            this.rec.validTo = this.lastDayOfThisYear;
    
            this.rec.DaysBeforeEnd2__c = null;
            this.rec.TypeOfAlert__c = null;
            this.rec.PercentageOfFulfillment__c = null;
            
            if (isNew === true) {
                this.recordId = null;
                this.rec.status = 'Draft';
                this.rec.name = null;
                this.rec.stageName = null;
                this.rec.closeDate = null;
            }
            this.updateWrapper();
        }
    }

    @api submitOpp() {
        this.submitionByWrapper = true;
        const btn = this.template.querySelector('.oppSubmit');
        if (btn) { btn.click(); }
    }

    @api validateFields() {
        let validationPassed = false;
        try {
            if (!this.rec.account?.id) Utils.showToast(this, "חסר לקוח", 'יש לבחור לקוח עבור הצעת המחיר', "error");
            else if (!this.rec.type) Utils.showToast(this, "חסר סוג עסקה", 'יש לבחור סוג עסקה עבור הצעת המחיר', "error");
            else if (!this.rec.validFrom) Utils.showToast(this, "חסר תאריך התחלה", 'יש לבחור תאריך התחלה עבור הצעת המחיר', "error");
            else if (this.isFerJob && !this.rec.warehouse?.id) Utils.showToast(this, "חסר מחסן משלם", 'יש לבחור מחסן משלם עבור הצעת המחיר', "error");
            else if (this.isFerJob && !this.rec.contractor?.id) Utils.showToast(this, "חסר קבלן מבצע", 'יש לבחור קבלן מבצע עבור הצעת המחיר', "error");
            else if (Number(this.rec.PercentageOfFulfillment__c) > 100 ) Utils.showToast(this, "  אחוז גבוה מדי", ' יש להזין ערך נמוך יותר בשדה אחוז מימוש', "error");
            else validationPassed = true;

            // check some hiden fields that should not be empty
            if (!this.rec.name || !this.rec.name.includes(this.rec.account.name)) {
                this.rec.name = `${this.rec.account.name} - ${ye}-${mo}-${da}`;
            }
            if (!this.rec.stageName) this.rec.stageName = `Proposal`;
            if (!this.rec.closeDate) this.rec.closeDate = `${(parseInt(ye) + 1).toString()}-${mo}-${da}`;
            console.log("this.rec.recordTypeId",this.rec.recordTypeId,"this.priceOfferRecId",this.priceOfferRecId);
            if (!this.rec.recordTypeId) this.rec.recordTypeId = this.priceOfferRecId;


            const passEventr = new CustomEvent('approveoppvalidation', { detail: { isValid: validationPassed } });
            this.dispatchEvent(passEventr);
        }
        catch (err) {
            console.log("Error validate head Component: ", err);
        }
    }

    submitForm(event) {
        event.preventDefault();
        if (this.submitionByWrapper) {
            const fieldsSub = event.detail.fields;
            fieldsSub.RecordTypeId = this.rec.recordTypeId;
            fieldsSub.CloseDate = this.rec.closeDate;
            fieldsSub.Valid_To__c = this.rec.validTo;

            fieldsSub.TypeOfAlert__c = this.rec.TypeOfAlert__c;
            fieldsSub.PercentageOfFulfillment__c = this.rec.PercentageOfFulfillment__c;
            fieldsSub.DaysBeforeEnd2__c = this.rec.DaysBeforeEnd2__c;

            fieldsSub.StageName = this.rec.stageName;
            fieldsSub.Name = this.rec.name;
            fieldsSub.Type = this.rec.type;
            fieldsSub.Pricebook2Id = PriceBook2Id;
            fieldsSub.AccountId = this.rec.account.id;
            // fieldsSub.Status__c = this.rec.status;
            fieldsSub.Contractor__c = this.rec.contractor.id;
            fieldsSub.Warehouse__c = this.rec.warehouse.id;
            fieldsSub.CurrencyIsoCode = this.defaultCurrencyIsoCode;
            fieldsSub.All_OLIs_Created__c = false;

            this.template.querySelector('lightning-record-edit-form').submit(fieldsSub);
        }
        this.submitionByWrapper = false;
    }

    handleSuccess(event) {
        const passEventr = new CustomEvent('oppsuccess', {
            detail: { oppRecord: event.detail }
        });
        this.dispatchEvent(passEventr);
        this.recordId = event.detail.id;
    }

    handleError(event) {
        Utils.showToast(this, "Error", `Error: ${event.message}`, "Error");
        console.log("Error creating oppertunity: ", JSON.stringify(event));
    }

    @api copyRec() {
        this.recordId = null;
        this.rec.status = 'Draft';
        this.rec.validFrom = `${ye}-${mo}-${da}`;
        this.rec.stageName = null;
        this.rec.closeDate = null;
        this.rec.name = null;
        this.rec.id = null;
        // this.rec.warehouse = this.rec.warehouse;
        // this.rec.contractor = this.rec.contractor;

        this.updateWrapper();

        this.copyFlag = true;
    }
    @api submitOrderData() {
        if (!this.rec.account?.id) {
            Utils.showToast(this, "חסר לקוח", 'יש לבחור לקוח עבור הצעת המחיר', "error");
        }
        else if (this.isFerJob && !this.rec.contractor?.id) {
            Utils.showToast(this, "חסר קבלן מבצע", 'יש לבחור קבלן מבצע עבור הצעת המחיר', "error");
        }
        else if (this.isFerJob && !this.rec.warehouse?.id) {
            Utils.showToast(this, "חסר מחסן משלם", 'יש לבחור מחסן משלם עבור הצעת המחיר', "error");
        }
        else {
            const passEventr = new CustomEvent('updatecontractorandwarehouse', {
                detail: { contractor:{ id :this.rec.contractor.id, name: this.rec.contractor.name}, warehouse: this.rec.warehouse.id, account: this.rec.account.id }
            });
            this.dispatchEvent(passEventr);
        }
    }

         ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         ////////////////////////////////////              getters                        //////////////////////////////////////////
         ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         get getExtraWhereClause() {
         console.log("getExtraWhereClause",this.rec.scope,this.isFerJob);
        // return this.rec.scope != null ? ' WHERE AccountDivision__c = '+ "'"+ this.rec.scope+ "'" : ""; // גרסה קודמת. מעביר דשנים לשאילתא ולא מחזיר תוצאות כיוון שצריך להיות חקלאות
         return this.rec.scope == 'כימיקלים' ? ' WHERE AccountDivision__c = '+ "'"+ "כימיקלים"+ "'" : ' WHERE AccountDivision__c = '+ "'"+ "חקלאות"+ "'";
        //  if (this.rec.scope == 'כימיקלים') {
        //   return  ' WHERE AccountDivision__c = '+ "'"+ "כימיקלים"+ "'";
        //  } else if(this.rec.scope == 'חקלאות'){
        //     return ' WHERE AccountDivision__c = '+ "'"+ "חקלאות"+ "'";
        // //  } else if(this.rec.scope == 'חקלאות' && this.rec.type == 'עבודת דישון'){
        // //     return ' WHERE Industry = '+ "'"+ "קבלן דישון"+ "'";
        //  } else{ return "";}
        }

    get scopeFerOrChemicals(){
        if (this.rec.scope ==  'כימיקלים') {
            return true;
        } else {
            return false;
        }
    }

    get isFerJob() {
        console.log("this.rec.type",this.rec.type);
        return this.rec.type === 'עבודת דישון';
    }

    get cssForPriceOfferFormHeader() {
        switch (FORM_FACTOR) {
            case 'Large': return 'slds-size_1-of-3';
            case 'Medium': return 'slds-size_2-of-2 slds-p-around_small';
            case 'Small': return 'slds-size_2-of-2 slds-p-around_small';
        }
    }

    get typeOptions() {
        if (this.rec.scope == 'כימיקלים') {
            return [
                { label: 'עסקת מסגרת', value: 'עסקת מסגרת' },
                { label: 'רגילה', value: 'רגילה' },
                { label: 'שרות', value: 'שרות' },
            ];
        } else if (this.rec.scope = 'דשנים') {
            return [
                { label: 'מסגרת', value: 'עסקת מסגרת' },
                { label: 'מוצרים', value: 'רגילה' },
                { label: 'עסקת דישון', value: 'עבודת דישון' },
            ];
        }

    }
    get showMatrixData() {
        return (this.rec.scope == 'דשנים' && this.customerSize) ? true : false;
    }
    get lastDayOfThisYear() {
        const currentYear = new Date().getFullYear();

        const lastDay = new Date(currentYear, 11, 32).toISOString();
        return lastDay;
    }

    get scopeClass() {
        return (this.userProfile === 'System Administrator' || this.userProfile === 'מנהל מערכת' || this.userProfile === Authorized_Profile)
            ? 'noPed slds-size_1-of-1'
            : 'slds-hide';
    }

    get isDraft() {
        return this.rec.status == 'Draft' || this.rec.status == 'טיוטה';
    }

    get isNotDraft() {
        return !this.isDraft;
    }
    get tabClass() { return FORM_FACTOR === 'Small' ? 'slds-col' : 'slds-grid'; }
    get oneOfTwo() { return FORM_FACTOR === 'Small' ? 'slds-col' : 'slds-col slds-size_1-of-2'; }
    get oneOfThree() { return FORM_FACTOR === 'Small' ? 'slds-col' : 'slds-col slds-size_1-of-3'; }

}