import { LightningElement, track, api } from 'lwc';
import findRecords from '@salesforce/apex/OrderCustomerController.searchAccountNameMethod';
import getParentAccount from '@salesforce/apex/OrderCustomerController.getParentAccount';
import getLastViewRecords from '@salesforce/apex/OrderCustomerController.recentlyViewRecords';
import FORM_FACTOR from '@salesforce/client/formFactor';

const DELAY = 1000;
export default class AccountOrBranchAutocomplete extends LightningElement {
    @track recordsList; //מאחסן את כל החיפושים האחרונים
    @track searchKey = ""; //התווים שחופש
    @api selectedRecordId; //האידי שלו
    @api selectedValue; //שם הערך שחופש/שנבחר
    selectedRecord; //שומר את הרקורד השלם שנבחר
    @api selectedIsAccount; //האם הערך הוא לקוח
    @api selectedParentAccountId; // במידה נבחר ענף - נמשוך את הלקוח אבא שלו
    @api disabled = false; //Tאחרי שהזמנה נשלחה - השדה יהיה דיסאבלד
    @track message; //הודעה קטנה מתחת לאינפוט
    hideMessage; //טוגל בין הצגה להסתרה של ההודעה הקטנה
    showSpinner = false;
    industry; //מקבל מאחורי הקלעים ומעלה למעלה לקבלת מחסן/משלם/סוכן
    sapType; // משפיע על סוכן/משלם/מחסן מבחינת ריקוורד/דיסאבלד
       
    // @api clearAccount(){
    //     alert("order branch or order");
    //     this.selectedRecordId = null;
    //     this.selectedValue = null;
    //     this.selectedRecord=null;
    //    // this.onSelectedRecordUpdate();
    //   }


    @api cleanRecordList(){
        alert("account auto coplete")
        this.recordsList = [];
    }
        //מושך מידע על הלקוחות האחרונים שנצפו - בטרם נבחר לקוח\ענף כמובן
        onFocus() {
            if (this.searchKey == "" || this.searchKey == undefined) {
                this.recordsList = [];
                console.log("AutocompleteCutomer 3 params to Query:",this.objectName,this.lastViewedFields,this.extrawhereclause);
                getLastViewRecords().then(result => {
                    console.log("AutocompleteCutomer results:",JSON.stringify(result));
                    result.forEach(record => {
                        let iconName = record.Id.substring(0, 3) == '001' ? 'standard:account' : 'custom:custom5';
                        let rec = { ...record, sapType: record.SAP_Account_Group__c, industry: record.AccountDivision__c, iconName: iconName }
                        if (rec) {
                            this.recordsList.push(rec)
                        }    
                    });    
                    this.sortArray();
                    this.hideMessage = false;
                    this.message = "לקוחות אחרונים שנצפו..";
                }).catch(err => {
                    console.error("onfocus error: ", JSON.stringify(err));
                })    
            }    
        }    

        handleKeyChange(event) {
            const searchKey = event.target.value;
            this.searchKey = searchKey;
            this.getLookupResult();
        }

        getLookupResult() {
            this.showSpinner = true;
            let convertToString = String(this.searchKey);
            let convertToString2 = convertToString.replaceAll("-","\-").replaceAll("+","\+").replaceAll("%","\%").replaceAll("|","\|");
            findRecords({ accStrName: convertToString2 }).then((result) => {
                console.log("searchAccountNameMethod",result,JSON.stringify(result));
                    this.recordsList = [];
                    if (result[0].length === 0) {
                        this.showSpinner = false;
                        this.hideMessage = false;
                        this.message = "לא נמצאו רישומים..";
                    } else {
                        result.forEach(record => {
                          //  records.forEach(record => {
                                //סוג האייקון לקוח/ענף   
                                let iconName = record.Id.substring(0, 3) == '001' ? 'standard:account' : 'custom:custom5';
                                console.log("iconName ",iconName);
                                let lastViewedDate = null;
                                if (record?.LastViewedDate) { lastViewedDate = record.LastViewedDate;} else{lastViewedDate=null;}
                                console.log("lastViewedDate 83",lastViewedDate);
                                if (record?.AccountName__c) { //רק לענף י אקאונטניים, אחרת אקאונט
                                    lastViewedDate = record.AccountName__c; }
                                    console.log("lastViewedDate 86",lastViewedDate);
                                let rec = { ...record, sapType: record.SAP_Account_Group__c, industry: record.AccountDivision__c, iconName: iconName, LastViewedDate: lastViewedDate }
                                console.log("rec 89",rec);
                                if (rec) { this.recordsList.push(rec) }
                                console.log("searchAccountNameMethod 88",rec);
                          //  });
                        });
                        this.showSpinner = false;
                        this.hideMessage = true;
                        this.message = "";
                        this.sortArray();
                    }
                    this.error = undefined;
                }).catch((error) => {
                    this.showSpinner = false;
                    this.error = error;
                    this.recordsList = undefined;
                });
        }
    
            //פונקציית הבחירה בערך אונקליק!!!
            onRecordSelection(event) {
                this.selectedRecordId = event.target.dataset?.key;
                this.selectedValue = event.target.dataset?.name;
                this.industry = event.target.dataset?.industry;
                this.sapType = event.target.dataset?.sap;
                //אם בחרתי לקוח 001 או ענף
                if (this.selectedRecordId.substring(0, 3) !== '001') {
                    this.selectedIsAccount = false;
                    getParentAccount({ recordId: this.selectedRecordId }).then(response => {
                        this.selectedParentAccountId = response[0].Account__c;
                        this.sapType = response[0].Account__r.SAP_Account_Group__c;
                        this.industry = response[0].Account__r.AccountDivision__c;
                        this.selectedRecord = this.recordsList.find(({ Id }) => Id === this.selectedParentAccountId);
                    }).catch(error => {
                        console.error("onfocus error: ", JSON.stringify(error));
                    })
                }
                else {
                    this.selectedRecord = this.recordsList.find(({ Id }) => Id === this.selectedRecordId);
                    this.selectedIsAccount = true;
                }
                this.searchKey = "";
                this.onSelectedRecordUpdate();
            }
    
        onLeave(event) { // דיליי של שנייה בעת יציאה מאזור בחירת לקוח/ענף
        setTimeout(() => {
            this.searchKey = "";
            this.recordsList = null;
        }, DELAY);    
    }    

//כשלוחץ על האיקס - מוחק רשומה שנבחרה
   @api removeRecordOnLookup() {
        this.contacts = [];
        this.searchKey = "";
        this.selectedValue = null,
        this.selectedRecordId = null,
        this.selectedParentAccountId = null,
        this.recordsList = [];
        this.onSelectedRecordUpdate();
    }

    onSelectedRecordUpdate() { //גם כנבחר ערך וגם כשנמחק לעדכון ההורה וכל שאר הקומפוננטות
        const passEventr = new CustomEvent('recordselection', {
            detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue, isAccount: this.selectedIsAccount, selectedParentAccountId: this.selectedParentAccountId, industry: this.industry, sapType: this.sapType, selectedRecord: this.selectedRecord }
        });
        this.dispatchEvent(passEventr);
    }

    sortArray() { //סורט לרשימת כל רשימת רשומות 
        this.recordsList.sort(function (a, b) {
            var nameA = a.Name.toUpperCase(); // ignore upper and lowercase
            var nameB = b.Name.toUpperCase(); // ignore upper and lowercase
            if (nameA < nameB) {
                return -1;
            }
            if (nameA > nameB) {
                return 1;
            }

            // names must be equal
            return 0;
        });
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////              getters                        //////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    get iconName() {
        if (this.selectedRecordId) {
            return this.selectedRecordId.substring(0, 3) == '001' ? 'standard:account' : 'custom:custom5';
        }
        return null;
    }
    
    get isDesktop() {
        switch (FORM_FACTOR) {
            case 'Large':
                return true;
            case 'Medium':
                return false;
            case 'Small':
                return false;
            default:
        }
    }
}