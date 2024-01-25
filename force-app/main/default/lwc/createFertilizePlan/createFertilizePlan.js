import { api, LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import Utils from "c/utils";
import SAVEBUTTON from '@salesforce/label/c.SaveBtn';
import CANCELBUTTON from '@salesforce/label/c.CancelBtn';
import getUserProfile from '@salesforce/apex/OrderCustomerController.getUserProfile';
import Id from '@salesforce/user/Id';


// import Opportunity_Details from '@salesforce/label/c.Opportunity_Details';
// import Additional_Details from '@salesforce/label/c.Additional_Details';
// import LANG from '@salesforce/i18n/lang';

export default class CreateFertilizePlan extends NavigationMixin(LightningElement) {
    @api recordTypeId;
    savebtn=SAVEBUTTON;
    cancelbtn=CANCELBUTTON;
    userId = Id;
    isHebrew = false;
    // saveHebrew = "שמירה"
    // saveEnglish = "Save"
    // cancelHebrew = "ביטול"
    // cancelEnglish = "Cancel"
    recordId;
    // lang = LANG;
    // label = {
    //     Opportunity_Details,
    //      Additional_Details
    // };
    // get pageDirection (){
    //     if (this.lang=='he') {
    //         return "direction:rtl";
    //     } else {
    //         return "direction:ltr";
   
    //     }
    // }

    connectedCallback() {
        this.getUserProfile();
    }
    submitForm(event) {
        event.preventDefault();
        
        const fieldsSub = event.detail.fields;
        fieldsSub.RecordTypeId = this.recordTypeId;
        fieldsSub.Scope__c = 'דשנים';
    
        this.template.querySelector('lightning-record-edit-form').submit(fieldsSub);
    }

    handleReset() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

    handleSuccess(event) {
        Utils.showToast(this, "תוכנית הדישון נוצרה בהצלחה!", event.detail.fields.Name.value, "success");
        this.handleReset();
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: event.detail.id,
              objectApiName: "Opportunity",
              actionName: "view"
            } 
        });
    }

    handleCancel(event){
        this.handleReset();
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'home'
            }
        });
    }

    getUserProfile() {
        getUserProfile({ Id: this.userId }).then(result => { //סוג היוזר
            console.log("getUserProfile: RAZ", result);
            console.log("getUserLlanguage: RAZ", result[0].LanguageLocaleKey);

            if(result[0].LanguageLocaleKey == "he" || result[0].LanguageLocaleKey == "iw"){
                this.isHebrew = true;
            }
            else{
                this.isHebrew = false;
            }
            console.log("getUserLlanguage isHebrew: RAZ", this.isHebrew);

        }).catch(error => {
            console.log(`008. Error: ${JSON.stringify(error)}`);
        })
    }

    get dirByLanguage() { return this.isHebrew === false ? 'ltr' : 'rtl'; }

}