import { LightningElement, track, api } from "lwc";
import getParentAccount from "@salesforce/apex/OrderCustomerController.getParentAccount";
import getPreviousOrdersPayerAgentAndWarehouseForAccount from "@salesforce/apex/OrderCustomerController.getPreviousOrdersPayerAgentAndWarehouseForAccount";
import forViewAccount from "@salesforce/apex/OrderCustomerController.forViewAccount";
import FORM_FACTOR from "@salesforce/client/formFactor";

import SENSITIVE_CUSTOMER from '@salesforce/schema/Account.Sensitive_Customer__c';

import isFcSubAdmin from '@salesforce/apex/OrderCustomerController.isFcSubAdmin';
import cosignationWarehouseApprovalExist from '@salesforce/apex/OrderCustomerController.CosignationWarehouseApprovalExist';


export default class OrderFormComponent extends LightningElement {
  realtorWarehouseValue; //ערך שנבחר במחסן מתווך
  paysValue; //ערך שנבחר משלם
  @api agentGetsCommissionValue; //ערך שנבחר מחסן מתווך
  Sensitive_Customer__c=SENSITIVE_CUSTOMER;
  @api Account;
  realtorExtraWhereClause = " WHERE SAP_Account_Group__c ='NOTI'"; // מתווסף לקוורי של מחסן מתווך
 // realtorExtraWhereClause = " AND SAP_Account_Group__c = 'NOTI' AND (AccountSource = 'FER' OR AccountSource = 'ILF')"; // מתווסף לקוורי של מחסן מתווך
  paysExtraWhereClause = " WHERE SAP_Account_Group__c != '0002' AND SAP_Account_Group__c != 'NOTI' AND SAP_Account_Group__c != null AND (AccountSource = 'FER' OR AccountSource = 'ILF')"; // מתווסף לקוורי של משלם
  agentExtraWhereClause =" WHERE (AccountSource = 'FER' OR AccountSource = 'ILF') AND SAP_Account_Group__c != null"; // מתווסף לקוורי של סוכן
  realtorMessage = "..לא נמצא מחסן מתווך"; //כרגע לא נמצא שימוש - רצוי להציג הודעות ולידציה מתחת לאינפוטס
  paysMessage = "..לא נמצא משלם"; // כנ"ל
  agentMessage = "..לא נמצא סוכן מקבל עמלה"; // כנ"ל
  loadingPointIdFromLayout = "";
  isCosignationWarehouseApprovalExist = false;
  @api recordId; // בכל קומפ' אורדר - ההתייחסות כאן להזמנה
  @api isNotCustomerService; //  לא שירות לקוחות - יורש מהאבא - מזהה פרופיל יוזר - מזהה שלא? אישור מעבר/הזמנה דיסאבלד
  @api itemStatusForLockOrderAprove;
  @track readOnlyIntermediaryWarehouse = true;
  @track requiredIntermediaryWarehouse = false;
  @track isUserFcSubAdmin = false;
  @track readOnlyPayingCustomer = true;
  @track requiredPayingCustomer = false;
  @track readOnlyAgentReceivesCommission = true;
  @track requiredAgentReceivesCommission = false;
  @api orderType; //נראה שאין שימוש אז ביי
  @track accSettelment; //מקום פריקה - ייראה רק בהקלקה-מגיע מקומפ' למטה ומתחלחל דרך כאן ללמעלה
  // orderAccountOrBranchAutoComplete --> orderForm --> orderLayout
  @track rec = {
    // כל האינפוטס שבפורם
    account: { id: "", name: "", industry: "", sapType: "" },
    branchGrowth: { id: "", name: "" },
    intermediaryWarehouse: { id: "", name: "" },
    payingCustomer: { id: "", name: "" },
    agentReceivesCommission: { id: "", name: "" },
    payerApproval: "",
    passingPermit: "",
    isChemicalAccount: false,
    industryFromLayout:"",
    orderDeliveredBy:"",
    cosignationWarehouseApproval: ""
  };

  connectedCallback(){
    console.log("RAZCHECK, 57,1111,connectedCallback,isSensitive 170",this.rec.account.isSensitive);
    console.log("RAZCHECK, 54, itemStatusForLockOrderAprove",this.itemStatusForLockOrderAprove);
    console.log("razcheck, 55,fcform,isUserFcSubAdmin",this.isUserFcSubAdmin);
    this.isFcSubAdmin();
    console.log("razcheck, 57,fcform,isUserFcSubAdmin",this.isUserFcSubAdmin);
  }
  renderedCallback(){
    console.log("RAZCHECK, 64,1111,connectedCallback,isSensitive 170",this.rec.account.isSensitive);
    console.log("RAZCHECK, 167, 66 ,this.rec.cosignationWarehouseApproval ",this.rec.cosignationWarehouseApproval);
    console.log("RAZCHECK, 167, 66 ,this.loadingPointIdFromLayout ",this.loadingPointIdFromLayout);
    if(this.rec.cosignationWarehouseApproval && this.loadingPointIdFromLayout){
      this.cosignationWarehouseApprovalExist();
    }
    console.log("RAZCHECK, 167, 66 ,this.isCosignationWarehouseApprovalExist ",this.isCosignationWarehouseApprovalExist);
}

  isFcSubAdmin() {
    isFcSubAdmin().then((response) => {  
      console.log("RAZCHECK,62, fcform, RESPONSE",response);  
    this.isUserFcSubAdmin = response;   // return true or false - יש הקצאה או אין
    });
}

cosignationWarehouseApprovalExist() {
  cosignationWarehouseApprovalExist({ loadingPointId: this.loadingPointIdFromLayout,CosignationWarehouseApproval: this.rec.cosignationWarehouseApproval }).then((response) => {  
      console.log("RAZCHECK,71, cosignationWarehouseApprovalExist, RESPONSE",response);  
    this.isCosignationWarehouseApprovalExist = response;   // return true or false - יש אישור זהה או אין
    });
}

 orderDeliveredByHandler(e){
   let index = e.target.value;
 }
removeRecordOnLookup(){
  const passEventr = new CustomEvent("customerremovedevent", {
    detail: { removed: false }});
  this.dispatchEvent(passEventr);

 }

 @api getLoadingPointIdFromLayout(loadingPointId){
  console.log("RAZCHECK,78,loadingPointId ",loadingPointId);
  this.loadingPointIdFromLayout = loadingPointId;
  this.renderedCallback();
 }

 @api getPurchaseOrderValueFromLayout(purchaseOrder){
  console.log("RAZCHECK, 104 1633, getPurchaseOrderValueFromLayout",purchaseOrder);
  if(!this.rec.payerApproval){
    this.rec.payerApproval = purchaseOrder;
  }
 }

  @api changeAccount(accountId, accountName,payingcustomer) {
    // אם ת.החזרה - מאכלס האינפוטס עם ההזמנה הקיימת
    console.log("65, 318, FORM paying_customer handleOrderItemOnReturnDeal ",JSON.stringify(payingcustomer));
    console.log("65, 318, FORM paying_customer.Name handleOrderItemOnReturnDeal ",payingcustomer?.Name);
    console.log("65, 318, FORM paying_customer.Id handleOrderItemOnReturnDeal ",payingcustomer?.Id);
    console.log("65, 318, FORM paying_customer handleOrderItemOnReturnDeal ",JSON.stringify(payingcustomer));
    // console.log(this.orderType,"type? החזרה");
    // if (this.orderType=='40') {    
      if(payingcustomer){
        this.rec.payingCustomer.name =payingcustomer.Name;
        this.rec.payingCustomer.id =payingcustomer.Id;
      }
    // }
    this.rec.account.id = accountId;
    this.rec.account.name = accountName;
    this.onSelectedRecordUpdate(); //עדכון באבנט את הנתונים ללמעלה ללייאאוט
    //עושה השמה רק לשני הקיז האלה, השאר נול
  }
  @api receiveRec(orderRec) {
    //  מאכלס את השדות של הזמנה קיימת בהתאמה
    this.rec = orderRec;
    console.log("receiveRec FORM 67",JSON.stringify(this.rec));
    this.industry=orderRec.account.industry;
    this.sapType=orderRec.account.sapType;
    this.rec.account.accountSource=orderRec.AccountSource;
    this.rec.account.isSensitive=orderRec.account.isSensitive;
    this.rec.orderDeliveredBy = orderRec.orderDeliveredBy;
    this.handleAccountTypes(this.sapType,this.industry);
    this.getPreviousOrdersForGenericLookups();
  }

  @api initApprovels() {
    //מאפס שדות אישור הזמנה ואישור מעבר
    this.rec.passingPermit = "";
    this.rec.payerApproval = "";
    this.rec.orderDeliveredBy="";
    this.rec.cosignationWarehouseApproval = "";
  }

  initRecord() {
    //אינישיאל לכל השדות של הזמנה
   this.rec = {
      account: { id: "", name: "", industry: "", sapType: "",accountSource:"" },
      branchGrowth: { id: "", name: "" },
      intermediaryWarehouse: { id: "", name: "" },
      payingCustomer: { id: "", name: "" },
      agentReceivesCommission: { id: "", name: "" },
      payerApproval: "",
      passingPermit: "",
      isChemicalAccount: false,
      industryFromLayout:"",
      orderDeliveredBy:"",
      cosignationWarehouseApproval:""
    };
    this.readOnlyPayingCustomer = true; //כן דיסאבלד
    this.requiredPayingCustomer = false; // לא דרוש
    this.readOnlyIntermediaryWarehouse = true;
    this.requiredIntermediaryWarehouse = false;
    this.readOnlyAgentReceivesCommission = true;
    this.requiredAgentReceivesCommission = false;
  }

  @api clearScreen() {
    this.initRecord();
    this.onSelectedRecordUpdate();
  }

  @api validateFields() {
    // להוסיף פה תמיכה - אם מדובר בסוג עסקה 60/40 
    // ערך בלוג מודפס ושמור - זהו סוג העסקה שמתעדכן בעת שמירה בקומפוננטה זו
    console.log("RAZCHECK, 167 ,this.rec.cosignationWarehouseApproval ",this.rec.cosignationWarehouseApproval);
    console.log("RAZCHECK, 167 ,this.loadingPointIdFromLayout ",this.loadingPointIdFromLayout);
    if(this.rec.cosignationWarehouseApproval && this.loadingPointIdFromLayout){
      this.cosignationWarehouseApprovalExist();
    }


    if(this.rec.account.id && ( this.orderType!= "40")){
      const quantity = this.template.querySelectorAll(".must");
      quantity.forEach((quantityInput) => {
               let value = quantityInput.value;      
               if (value == "" || value == null) {  // is input valid number? if order type is not returning type: number can't be negetive
                        quantityInput.setCustomValidity(""); // if there was a custom error before, reset it
                        quantityInput.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
                        quantityInput.focus();
                        throw "שגיאה: שדה מעביר ההזמנה הוא שדה חובה";
               }
              })
    }
  
    //רק אם יש לקוח אידי ניתן לשמור הזמנה
    if (this.rec.account.id == null || this.rec.account.id == "") {
      throw "לא ניתן לשמור הזמנה ללא לקוח";
    }
    // orderGenericLookup מחסן מתווך, משלם וסוכן מקבל עמלה - דינמי
    // עוברת בלופ על 3 הקומפ' מחסן, משלם וסוכן ומוודאת שרקווירד טרו וגם נבחר איזה ערך
    this.template.querySelectorAll("c-order-generic-lookup").forEach((comp) => {
      if (comp.required && (comp.selectedRecordId == "" || comp.selectedRecordId == null)) {
        //סלקטדרקורדאידי הכוונה מרשימה שהגיעה משרת
        comp.invalid = true;
        comp.focusOnInput(); //עושה בכוח פוקוס על אינפוט לא ולידי
        throw "שגיאה: שדה " + comp.searchlabel + " הוא שדה חובה";
      }
    });
    console.log("RAZCHECK, 167 ,this.loadingPointIdFromLayout ",this.isCosignationWarehouseApprovalExist);
    if(this.isCosignationWarehouseApprovalExist){
      throw "קיים אישור מחסן קוגסיגנציה זהה לנקודת מכירה זו"
    }
  }

  @api submitFields() { // וואנס הקלקה על שמירת הזמנה - פונקציה זו מופעלת ומעבירה כל המידע של הרק לאבא לייאאוט
    console.log("141 submitFields",this.rec,this.accSettelment);

    this.forView(this.rec.account.id); // שמור בדאטהבייס את האידי הזמנה להצגה עתידית
    console.log("submitFields line #137",this.rec, typeof this.rec);
    const passEventr = new CustomEvent("submitcomponents", {
      detail: { rec: this.rec }
    });
    this.dispatchEvent(passEventr);
  }

  ///////////   כשלקוח/ענף נבחר  ////////////
  @api 
  handleRecordSelect(event) {
    console.log("handleRecordSelect",event,event.detail,JSON.stringify(event.detail));
    try {
     if (event.detail.selectedRecordId == null) { // אם איכשהו הגעתי לפה ואין בכלל ערך שנבחר - נקה הכל בפורם והקפץ את כל הכלום הזה ללייאאוט
        this.initRecord();
        this.onSelectedRecordUpdate();
        this.template.querySelectorAll("c-order-generic-lookup").forEach((comp) => { comp.cleanFields(); });
      }
      if (event.detail.selectedRecordId != null) {  // אם יש איזשהו ערך שנבחר - האם ענף או לקוח?  
        if (event.detail.isAccount) {  // אם נבחר לקוח
          this.rec.account.name = event.detail.selectedValue;
          this.rec.account.id = event.detail.selectedRecordId;
          this.rec.account.industry = event.detail.industry;
          this.rec.account.accountSource = event.detail.selectedRecord.AccountSource;
          this.rec.account.isSensitive = event.detail.selectedRecord.Sensitive_Customer__c;
          console.log("isSensitive 170",this.rec.account.isSensitive);
          this.industry = event.detail.industry;
          this.sapType = event.detail.sapType;
          if (event.detail.selectedRecord.hasOwnProperty("Setelment__c")) {
            this.accSettelment = event.detail.selectedRecord.Setelment__c;}
            this.rec.account.sapType = event.detail.sapType;
          if (event.detail.selectedRecord.hasOwnProperty("Default_warehouse__c")) {
            console.log("RAZCHECK,187,intermediaryWarehouse",JSON.stringify(this.rec.intermediaryWarehouse));
            // console.log("RAZCHECK,187,payingCustomer",JSON.stringify(this.rec.payingCustomer));
            this.rec.intermediaryWarehouse.id =event.detail.selectedRecord.Default_warehouse__c;
            this.rec.intermediaryWarehouse.name =event.detail.selectedRecord.Default_warehouse__r.Name;
            this.rec.payingCustomer.id =event.detail.selectedRecord.Default_warehouse__r?.ParentId;
            this.rec.payingCustomer.name =event.detail.selectedRecord.Default_warehouse__r?.Parent.Name;
          } else {
            this.onSelectedRecordUpdate();
            this.getPreviousOrdersForGenericLookups(); // אחרי אכלוס - הבא הזמנות קודמות ללקוח
          }
          this.handleAccountTypes(this.industry, this.sapType);
          this.onSelectedRecordUpdate();
        } else {                    // אם נבחר ענף
          this.rec.branchGrowth.name = event.detail.selectedValue;
          this.rec.branchGrowth.id = event.detail.selectedRecordId;
          getParentAccount({ recordId: event.detail.selectedRecordId }).then((response) => { // אחרי אכלוס קצר - הבא קודם חשבון אב - אח"כ הזמנות קודמות ללקוח
              console.log("139 getParentAccount form: ",JSON.stringify(response[0]));
              this.rec.account.name = response[0].Account__r.Name;
              this.rec.account.id = response[0].Account__c;
              this.industry = response[0].Account__r.AccountDivision__c;
              this.sapType = response[0].Account__r.SAP_Account_Group__c;
              this.getPreviousOrdersForGenericLookups(); // כאן אותה פונקציה
              this.handleAccountTypes(this.industry, this.sapType);
              this.onSelectedRecordUpdate();
            }).catch((error) => {
              this.handleAccountTypes(this.industry, this.sapType);
              this.onSelectedRecordUpdate();
            });
        }
      }
    } catch (err) {
      console.error(err);
    }
  }

  forView(accountId) {
    //לאחר שמירת הזמנה - באינפוט לקוח - יוצגו לקוחות אחרונים
    forViewAccount({ accId: accountId }).then(() => {
        console.log("forViewAccount success");
      }).catch((error) => {
        console.log("Error: ", error);
      });
  }

  // במידה שיש מחסן\משלם\סוכן אחרונים שנשמרו - מציג אותם בלחיצה. אחרת ריק
  @api getPreviousOrdersForGenericLookups() {
    getPreviousOrdersPayerAgentAndWarehouseForAccount({accountId: this.rec.account.id}).then((response) => {
        console.log("PreviousOrdersPayerAgentAndWarehouse: ", response);
        if (response.length > 0) {
          let PayingCustomerArray = [];
          let IntermediaryWarehouseArray = [];
          let AgentReceivesCommissionArray = [];
          response.forEach((element) => {
            if (element.hasOwnProperty("Paying_Customer__c")) {
              const found = PayingCustomerArray.find(({ Id }) => Id === element.Paying_Customer__c);
              if (found == undefined) { PayingCustomerArray.push({Id: element.Paying_Customer__c,Name: element.Paying_Customer__r.Name});}
            }
            if (element.hasOwnProperty("IntermediaryWarehouse__c")) {
              const found = IntermediaryWarehouseArray.find(({ Id }) => Id === element.IntermediaryWarehouse__c );
              if (found == undefined) { IntermediaryWarehouseArray.push({Id: element.IntermediaryWarehouse__c, Name: element.IntermediaryWarehouse__r.Name});}
            }
            if (element.hasOwnProperty("AgentReceivesCommission__c")) {
              const found = AgentReceivesCommissionArray.find( ({ Id }) => Id === element.AgentReceivesCommission__c);
              if (found == undefined) { AgentReceivesCommissionArray.push({Id: element.AgentReceivesCommission__c, Name: element.AgentReceivesCommission__r.Name});}
            }
          });
          this.template.querySelector("c-order-generic-lookup[data-id='PayingCustomer']").handleParentOnFocusData(PayingCustomerArray); //מעביר את כל המשלמים של אותו לקוח
          this.template.querySelector("c-order-generic-lookup[data-id='IntermediaryWarehouse']").handleParentOnFocusData(IntermediaryWarehouseArray);
          this.template.querySelector("c-order-generic-lookup[data-id='AgentReceivesCommission']").handleParentOnFocusData(AgentReceivesCommissionArray);
        }
      }).catch((error) => {
        console.log("Error: ", error);
      });
  }

  intermediaryWarehouseHandler(event) { // מחסן מתווך הנדלר
    this.rec.intermediaryWarehouse.name = null;
    this.rec.intermediaryWarehouse.id = null;
     if (!event.detail.selectedValue) {
      this.rec.intermediaryWarehouse.name = null;
      this.rec.intermediaryWarehouse.id = null;
     } else {   
       this.rec.intermediaryWarehouse.name = event.detail.selectedValue;
       this.rec.intermediaryWarehouse.id = event.detail.selectedRecordId;
       if (event.detail.selectedRec?.ParentId) {
         //ParentId  - המשביר לחלקאי והמשביר לחקלאי בע"מ - אז הוא יאוכלס ישר במשלם!!!
         this.rec.payingCustomer.name = event.detail.selectedRec.Parent.Name;
         this.rec.payingCustomer.id = event.detail.selectedRec.ParentId;
       }
     }
  }

  payingCustomerHandler(event) {
    //לקוח משלם
    console.log("FORM payingCustomerHandler 279",JSON.stringify(event));
    this.rec.payingCustomer.name = event.detail.selectedValue;
    this.rec.payingCustomer.id = event.detail.selectedRecordId;
  }

  agentReceivesCommissionHandler(event) {
    //סוכן
    this.rec.agentReceivesCommission.name = event.detail.selectedValue;
    this.rec.agentReceivesCommission.id = event.detail.selectedRecordId;
  }

  changePayerApproval(event) {    //אישור הזמנה
    this.rec.payerApproval = event.detail.value;
  }

  changePassingPermit(event) {    //אישור מעבר
    this.rec.passingPermit = event.detail.value;
  }
  changeorderDeliveredBy(event) {    //מעביר ההזמנה
    this.rec.orderDeliveredBy = event.detail.value;
    console.log("orderDeliveredBy",this.rec.orderDeliveredBy);
  }
  changeCosignationWarehouseApproval(event) {    //אישור מחסן קוגסיגנציה 
    this.rec.cosignationWarehouseApproval = event.detail.value;
    console.log("RAZCHECK, 323, CosignationWarehouseApproval",event.detail.value);
  }

  onSelectedRecordUpdate() {
    // עדכון באבנט למעלה ללייאאוט
    // of who? of what? all the rec plus accSettelment
    console.log("288  onSelectedRecordUpdate",this.rec,this.accSettelment);
    const passEvent = new CustomEvent("recordselection", { detail: { rec: this.rec, accSettelment: this.accSettelment} // הלקוח נבחר באורדרפורם-->עולה ללייאאוט -->
    });
    this.dispatchEvent(passEvent);
  }

  //   מחסן מתווך, משלם וסוכן מקבל עמלה - רידאונלי/דיסאבלד או ריקווירד או רשות
  handleAccountTypes(industry, sapType) {
    // initiate booleans to false -
    console.log("line 48 / 253:", this.industry2, sapType);
    this.readOnlyIntermediaryWarehouse = false;
    this.requiredIntermediaryWarehouse = false;
    this.readOnlyAgentReceivesCommission = false;
    this.requiredAgentReceivesCommission = false;
    this.readOnlyPayingCustomer = false;
    this.requiredPayingCustomer = false;
    this.rec.isChemicalAccount = false;
    // אם הלקוח שנבחר הוא מסוג משלם - אז כל האינפוטס הללו דיסאבלד ולכן טרו
    // readOnly = disabled // required = required
    
// if ((sapType=="NOTI" || sapType=="0002")  && this.rec.account.accountSource=="FER" && industry=="חקלאות") {  // לקוח משלם דשנים 
  
// } else if((sapType=="NOTI" || sapType=="0002")  && this.rec.account.accountSource=="FER" && industry=="כימיקלים"){
// } else if((sapType=="NOTI" || sapType=="0002")  && this.rec.account.accountSource=="FER" && industry=="כימיקלים"){
 
// }
    //old version until 2.2.23
    console.log("All fieldss","sapType:",sapType,"industry:",industry,"AccountSource:",this.rec.account.accountSource);
  if (industry?.includes("כימיקלים")) { // כימיקלים
      if (sapType != "NOTI" && sapType != "0002" && this.rec.account.accountSource=="FER" ) { // כימיקלים משלם     && industry=="כימיקלים"
        console.log("1st if inside types");
        this.readOnlyIntermediaryWarehouse = true; // מחסן נעול לעריכה
        this.readOnlyPayingCustomer = true; // משלם נעול
        this.readOnlyAgentReceivesCommission = true; // סוכן נעול
        this.rec.isChemicalAccount = true;
      }
      else if(sapType == "0002" && this.rec.account.accountSource=="FER" ){ //מקבל כימיקלים      && industry=="לקוחות כימיקלים"
        this.readOnlyIntermediaryWarehouse = true;
        this.requiredPayingCustomer = true; // חובה משלם
        this.readOnlyAgentReceivesCommission = true;
        this.rec.isChemicalAccount = true;
      } 
      else {  
        this.readOnlyIntermediaryWarehouse = false;
        this.readOnlyPayingCustomer = false;
        this.readOnlyAgentReceivesCommission = false;
        // this.requiredIntermediaryWarehouse = true; NEVER TRUE ACCORDING TO YARON 14.2.23
        this.requiredPayingCustomer = true;
        this.requiredAgentReceivesCommission = false;
        this.rec.isChemicalAccount = true;
    }}else{ // דשנים
      if (sapType != "NOTI" && sapType != "0002" && this.rec.account.accountSource=="FER") {// דשנים משלם
      //  this.requiredIntermediaryWarehouse = false;
       this.requiredPayingCustomer = false;
       this.readOnlyAgentReceivesCommission = false; // סוכן נעול
     }else if(sapType == "0002" && this.rec.account.accountSource=="FER" ){ // מקבל דשנים     && industry!="לקוחות כימיקלים"
      // this.requiredIntermediaryWarehouse= false;
      this.requiredPayingCustomer = true; // דרוש משלם
      this.readOnlyAgentReceivesCommission=false;
     }else{
      this.readOnlyIntermediaryWarehouse = false;
      this.readOnlyPayingCustomer = false;
      this.readOnlyAgentReceivesCommission = false;
      // this.requiredIntermediaryWarehouse = true;
      this.requiredPayingCustomer = true;
      this.requiredAgentReceivesCommission = false;
     }
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////              getters                        //////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  get orderDeliveredByOptions(){
    return [
      {label: "אגרונום",value: "אגרונום"},
      {label: "אימייל",value: "אימייל"},
      {label: "וואטסאפ",value: "וואטסאפ"},
      {label: "מסרון", value: "מסרון" },
      {label: "יזום",value: "יזום"},
      {label: "לקוח",value: "לקוח"},
      {label: "מוביל",value: "מוביל"},
      {label: "סוכן",value: "סוכן"},
      {label: "עבודת דישון",value: "עבודת דישון"},
      {label: "פקס",value: "פקס"},
      {label: "אחר",value: "אחר"}
  ];
   }
  
  get isOnlyAccount() {
    return this.rec.account.name != "" && this.rec.branchGrowth?.name == ""? true: false;
  }

  get isAccSelected() {
    return this.rec.account.name ? true : false;
  }
  get isDesktop() {
    switch (FORM_FACTOR) {
      case "Large":
        return true;
      case "Medium":
        return false;
      case "Small":
        return false;
      default:
    }
  }

  get isAllowedToAprroveOrder(){
    console.log("RAZCHECK, 419,this.isNotCustomerService ",this.isNotCustomerService);
    console.log("RAZCHECK, 419,this.itemStatusForLockOrderAprove ",this.itemStatusForLockOrderAprove);
    if(this.isUserFcSubAdmin){
      return false;
    }
    else if(this.isNotCustomerService){
      return true;
    }
    else if(this.itemStatusForLockOrderAprove){
      return true;
    }
    else{
      return false;
    }
  }

  @api orderTypeHandler(type) {
    console.log("type 380:",type);
    this.orderType=type;
    if (type === "10") {
      // 10 = טיוטה
      this.readOnlyIntermediaryWarehouse = true;
      this.readOnlyPayingCustomer = true;
      this.readOnlyAgentReceivesCommission = true;
      this.requiredIntermediaryWarehouse = false;
      this.requiredPayingCustomer = false;
      this.requiredAgentReceivesCommission = false;
      this.rec.isChemicalAccount = false;
    } else if (type === "60") {
      //אם זה טייפ 60 - דהיינו סוג עסקה שיוך
      // אפס את שדות הפורם - סוכן משלם ומחסן
      // this.rec.intermediaryWarehouse = "";
      // this.rec.payingCustomer = "";
      // this.rec.agentReceivesCommission = "";
      this.readOnlyIntermediaryWarehouse = false;
      this.readOnlyPayingCustomer = false;
      this.readOnlyAgentReceivesCommission = false;
      this.requiredIntermediaryWarehouse = false;
      this.requiredPayingCustomer = false;
      this.requiredAgentReceivesCommission = false;
      this.rec.isChemicalAccount = false;
    } else {
      this.handleAccountTypes(this.rec.account.industry,this.rec.account.sapType);
    }
  }
}