import { api, LightningElement, track } from "lwc";
import fetchExtendedLookUpValues from "@salesforce/apex/CustomLookUpController.fetchExtendedLookUpValues";
import getLastViewRecords from "@salesforce/apex/CustomLookUpController.getLastViewRecords";
import getWarehousePhone from "@salesforce/apex/OrderCustomerController.getWarehousePhone";

import LastViewedDate from "@salesforce/schema/Account.LastViewedDate";
const DELAY = 300;
export default class OrderGenericLookup extends LightningElement {
  @api searchlabel;
  @api message = "לא נמצאו רישומים.."; //הודעה קטנה מתחת לאינפוטס
  @api messageForLastView = "לקוחות אחרונים שנצפו.."; //הודעה קטנה מתחת לאינפוטס
  @api extrawhereclause; //התניה נוספת להוספה לקווארי בצורה דינמית
  @api objectName = "Account"; //שם טבלה
  @api iconName = "standard:account"; //אייקון חיפוש/ת.משלוח
  @api searchPlaceholder = "חפש.."; // הערך מועבר מהאבא - או פורם או הצ"ח או אורדרדייטטייםקונטקט או אורדראייטם
  @api required = false; //שדה חובה
  @api readOnly = false; //לקריאה בלבד
  @api fieldsToQuery = "Id, Name, LastViewedDate"; //בחיפוש רגיל- מוסיף להצגה בקווארי
  @api lastViewedFields = "Id, Name, LastViewedDate"; //באונפוקוס
  @api selectedValue = "";
  @api selectedRecordId = "";
  @api getLastViewed = false; //  להצגה כן או לא של ערכים אחרונים שנצפו
  @api getAllOnFocus = false; // הצגת כל הערכים המקורים ללקוח נתון, למשל נק' פריקה
  @track accountId;
  @track phoneNumber="";
  onFocusArray = []; //נעמיס כל הערכים ל הלקוח לדרופדאון
  @track recordsList = []; 
  navigatorIndex = 0; //אם ארצה בעתיד להשתמש בזה - לניווט בתוך בדרופדאון
  selectedRec; //כל הרשומה שנבחרה
  searchKey = ""; //התווים שנבחרו
  hideMessage ;
  showSpinner = false;
  showDropdown = false;
  @api invalid = false; //ולידציה של ערך (ריק וגם נכון) עבור כל האינפוטס
//showDivDropdown=false;

  handleKeyChange(event) {
    //אונצ'יינג' אינפוט בחירת מוצר/סוכן/משלם/מחסן/מקום פריקה/ת.משלוח
    setTimeout(() => {
      
      this.hideMessage=true;
    }, 1000);
    this.searchKey = event.target.value;
    this.invalid = false; //יאפס את הגיאה במידה קיימת
    window.clearTimeout(this.timeout); //מנקה הדיליי של סטאינטרוול
    this.timeout = window.setTimeout(() => {
      if (this.searchKey) {
        this.getLookupResult(); //אם קיימת מילת חיפו - הבא את התוצאות שלה מהשרת
      }else{this.hideMessage=false;}
    }, DELAY);
  }
  // handleSelect(event) { //אין שימוש כרגע - קשור לחיפוש עם לחצנים
  //     const selectedRecordId = event.detail;
  //     this.selectedRec = this.recordsList.find(record => record.Id === selectedRecordId);
  //     this.selectedValue = this.selectedRec.Name;
  //     this.onSelectedRecordUpdate();
  // }

  onRecordSelection(event) {
    console.log(" onRecordSelection",event.target.dataset.key);
    console.log(" onRecordSelection",event.target.dataset.name);
    // אם נבחר ערך מתוך דרופדאון קיים - הפעל - ברוב המקרים יוצג לפי לקוח למעט ת.משלוח
    this.selectedRecordId = event.target.dataset.key; // אידי לא זהה לשם שהוא הערך, גם אם הוא מספרי
    this.selectedValue = event.target.dataset.name;
    // RECORDLIST = הדרופדאון בעצם
    console.log("selectedRec 62",this.selectedRec);
    this.selectedRec = this.recordsList.find((rec) => {
      return rec.Id == this.selectedRecordId;
    });
    this.onSelectedRecordUpdate(); // מקפיץ לאבא את האידי של הרשומה ואת כל הרשומה עצמה
    // this.hideMessage = false;

    //this.removeRecordOnLookup();
  }

  removeRecordOnLookup() {
    console.log(" 70 removeRecordOnLookup orderGenericLookup");
    this.searchKey = "";
    this.selectedValue = "";
    this.selectedRecordId = null;
    this.selectedRec = null;
    // console.log(" 71 removeRecordOnLookup orderGenericLookup",this.searchKey,this.selectedValue,this.selectedRecordId,this.selectedRec,this.accountId);

    // this.onFocusArray = []; // לא עבד? להסליש הכל מתחת
    // this.recordsList = []; // 20.11
    // this.message=null;
    // this.showDropdown = false;
    // this.showDivDropdown=false;
    this.hideMessage = false;

      // this.onSelectedRecordUpdate();
  }

  onLeave() {
    // this.showDivDropdown=false;
    this.message=null;
    this.timeout = window.setTimeout(() => {
      this.searchKey = "";
      this.recordsList = [];
      this.phoneNumber="";
      // this.showDropdown=false; // אחראי על הצגה/הסתרה של מלבן ריק מכוער
    }, 210);
    // this.hideMessage = false;
  }

  dispatchRecordsList(){
  const passEvent = new CustomEvent("recordsfocus", {detail: {selectedRecordId: this.selectedRecordId,selectedValue: this.selectedValue,selectedRec: this.selectedRec,recordsList: this.recordsList}});
  console.log("passEvent",passEvent,JSON.stringify(passEvent));
  this.dispatchEvent(passEvent);
}

onMouseOver(){
  console.log("onMouseOver",this.searchlabel,this.selectedRec);
  if (this.searchlabel=="מחסן מתווך") {  
    if( this.selectedRec !== "" ){
      getWarehousePhone({accountId:this.selectedRecordId }).then((response) => {
        console.log("getWarehousePhone",response[0].Phone);
        this.phoneNumber = response[0].Phone;
      }).catch((err) => console.log(err)
      )
  }
}
}
  onFocus() {

    this.showDropdown = true;
    this.hideMessage=true;

    if (!this.searchKey && this.getLastViewed) {
      let recordsList = [];
      getLastViewRecords({
        //, מביא את נקודות הפריקה האחרונות ללקוח!!! דגש על לקוח, אבל רק בהקלקה על אינפוט אונפוקוס
        //במלם/סוכן/מחסן - אם רוצה להציג דרופדאון - הנה מביא מהשרת
        objectName: this.objectName,
        fieldsToQuery: this.lastViewedFields,
        extraWhereClause: this.extrawhereclause
      }).then((result) => { console.log("OGL results 0001:",result);
          for (let i = 0; i < result.length; i++) {
            const rec = result[i];
            let LastViewedDate = "";
            if (this.objectName == "Branch_growth__c") {
              LastViewedDate = rec?.AccountName__c ? rec.AccountName__c : "";
            } else {
              LastViewedDate = rec?.LastViewedDate ? rec.LastViewedDate : "";
            }
            
            recordsList.push({...rec,LastViewedDate: LastViewedDate,selected: i === this.navigatorIndex ? true : false});
          }
          this.recordsList = [...recordsList];
          this.onFocusArray = [...recordsList];
          this.message = "לקוחות אחרונים שנצפו..";
          //this.showDivDropdown=true;

         // this.dispatchRecordsList();
          // this.showDropdown = false;
        }).catch((err) => { 
          // this.showDropdown = false;
          // this.showDivDropdown=false;
           console.error(err);
        });
    } else if (!this.searchKey && this.getAllOnFocus) {
      // אם לא הוקלד ערך וישר נבחר ערך מתוך רשימה
      this.getLookupResult();
    } else if (!this.searchKey && this.onFocusArray.length === 0) {
      this.recordsList = [];
      // this.hideMessage = false;
      this.message = "לא נמצאו רישומים קודמים..";
    } else if (this.onFocusArray.length > 0) {
      // this.hideMessage = false;
      this.message = this.messageForLastView;
      this.recordsList = [...this.onFocusArray];
    }
  }

  //קורה onFocus
  getLookupResult() {
    this.hideMessage=true;

    let recordsList = [];
    console.log("OGL 3 params to Query:",this.objectName,this.lastViewedFields,this.extrawhereclause);

    // apex call with searchText and searchTerms
    fetchExtendedLookUpValues({ searchKeyWord: this.searchKey, fieldsToQuery: this.fieldsToQuery, 
      objectName: this.objectName,extraWhereClause: this.extrawhereclause
    }).then((result) => {
        console.log("fetchExtendedLookUpValues, result:", result); // מציג בדרופדאון את כל תעודות המשלוח, בלחיצה על אינפוט סוג עסקה אונפוקוס onFocus
        for (let i = 0; i < result.length; i++) {
          const rec = result[i];
          console.log("rec",rec);
          let LastViewedDate = "";
          if (this.objectName == "Branch_growth__c") { // בבחירת כל סוגי העסקה - לא קורה התנאי הזה!!!
            console.log("this.objectName == Branch_growth__c");
            LastViewedDate = rec?.AccountName__c ? rec.AccountName__c : "";
          } else {
            LastViewedDate = rec?.LastViewedDate ? rec.LastViewedDate : "";
          }
          recordsList.push({...rec,LastViewedDate: LastViewedDate,selected: i === this.navigatorIndex ? true : false });
          console.log("recordsList",typeof recordsList,recordsList );

        }
       // this.showDivDropdown=true; // הוספת כל הקלאס כולל הקלאס הבעייתי שאחראי על המלבן המכוער slds-dropdown

        this.recordsList = recordsList; //  הדפסת המערך מביאה מערך עם כל ההזמנות האחרונות ללקוח, כולל מוצרים - אובייקט - פרודקט2
        console.log(this.recordsList,"this.recordsList");
        this.showDropdown = true;
         this.message ="תוצאות עבור " + this.searchKey;
      //  if (!this.selectedValue) {
      //       return this.message = "תוצאות עבור " + this.searchKey;
      //  } else {
      //        return this.message = "";    
      //  }
      }).catch((err) => {
       // this.showDivDropdown=false;

        console.error(err);
      });
  }

  //יריית המידע לאבא
  onSelectedRecordUpdate() {
    // TODO: update parent new data from child
    console.log("169",this.selectedRecordId);
    console.log("170",this.selectedValue);
    console.log("171",this.selectedRec);
    const passEvent = new CustomEvent("recordselection", { detail: {selectedRecordId: this.selectedRecordId,selectedValue: this.selectedValue,selectedRec: this.selectedRec} });
    this.dispatchEvent(passEvent);
  }

  @api handleParentOnFocusData(data) {
    // מוטרג כאשר נבחר לקוח/ענף - getPreviousOrdersForGenericLookups חלק מפונקציית
    if (data.length > 1) {
      this.onFocusArray = [...data]; // בכל השמה ושימוש בג'נריק לוקאפ באבא - מצייר וחוזר חלילה
    } else if (data[0]?.Id && !this.readOnly) {
      this.onFocusArray = [...data];
      this.selectedRecordId = data[0].Id;
      this.selectedValue = data[0].Name;
      this.onSelectedRecordUpdate();
    } else {
      this.onFocusArray = [];
    }
  }

  @api focusOnInput() {
    //עושה בכוח פוקוס על אינפוט לא ולידי
    this.template.querySelector("lightning-input").focus();
  }

  @api cleanFields() {
    this.selectedRecordId = null;
    this.selectedValue = null;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////              getters                        //////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   get showMsg() {
//     console.log("this.message:",this.message);
//     return  false;
// }

  get showResults() {
    // if (!this.recordsList) {
    //   return false;
    // } else {
    //   return true;
    // }
    return  this.recordsList.length >0 ? true:false;
    //&& this.recordsList && this.showDropdown;
  }

  get divCssIsRequierdInvalid(){
    return this.invalid && this.required && this.message == null ? "slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right slds-has-error" : "slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right";

  }
  get divWrapperDropdown() { // עיצוב מסגרת באדום עקב ערך אינווליד פולס
    return this.showDivDropdown==true ? "slds-show slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_left slds-dropdown_fluid" : "slds-show slds-dropdown_length-with-icon-7 slds-dropdown_left slds-dropdown_fluid";
  }
  //באג בהצגה שלו
  get showErrorMessage() {
    //מציג הודעת שגיאה בהתאם לערך בוליאני אינווליד
    return this.invalid && this.required ? true : false;
  }
  //בחירה באמצעות לחצנים
  // handleKeyPress(component) { // shift records on lookup with down/up arrows keys (select record with enter key)
  //     let key = component.which;
  //     if (!this.recordsList) {
  //         return;
  //     }
  //     if (this.navigatorIndex > this.recordsList.length - 1){
  //         this.navigatorIndex = 0;
  //     }
  //     if (key === 40) { // arrow down key
  //         if (this.navigatorIndex < this.recordsList.length - 1) {
  //             this.recordsList[this.navigatorIndex].selected = false;
  //             this.navigatorIndex++;
  //         }

  //     } else if (key === 38) { // arrow up key
  //         if (this.navigatorIndex > 0) {
  //             this.recordsList[this.navigatorIndex].selected = false;
  //             this.navigatorIndex--;
  //         }
  //     }
  //     else if (key === 13) { // enter key
  //         var temObj = {};
  //         temObj.detail = this.recordsList[this.navigatorIndex].Id;
  //         this.handleSelect(temObj);
  //     }
  //     this.recordsList[this.navigatorIndex].selected = true;
  // }
}