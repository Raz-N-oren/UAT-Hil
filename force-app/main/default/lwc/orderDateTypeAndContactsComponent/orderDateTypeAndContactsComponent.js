import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { createRecord } from "lightning/uiRecordApi";
import calculateBH from '@salesforce/apex/OrderCustomerController.calculateBH';
import isBH from '@salesforce/apex/OrderCustomerController.isBH';
import isFcSubAdmin from '@salesforce/apex/OrderCustomerController.isFcSubAdmin';

export default class DateTypeAndContactsComponent extends LightningElement {
  today = new Date().toISOString();
 // twoDaysAhead = new Date(this.today); // תאריך מבוקש ברירת מחדל - יומיים קדימה
  // twoDaysAhead ; // תאריך מבוקש ברירת מחדל - יומיים קדימה
  // @api contact = '';
  @api accountId = null; //לקוח
  @api branchId = null; //ענף
  @api recordId = null; //הזמנה
  @api contacts = [""]; //איש קשר מער השגיאה מכאן! להוסיף גטר
  @api isNotCustomerService;
  @api whichProfileType;
  @track aShowModal = false; //מודל הוספת איש קשר
  @track bShowModal = false; //מודל עריכת איש קשר
  @track rowId; //אידי בטבלת איש קשר
  isUserFcSubAdmin = false;
  existingthisRequestedSupplyDate;
  trueBoo = true; //שתמיד הצ'ק בוקס בהוספת איש קשר יהיה לחוץ/בחור
  //בבחירת ת.החזרה בתצוגת ש.לקוחות - נשתמש באורדרג'נריקלוקאפ ונוסיף הפרמטרים הבאים
  deliveryNoteFieldsToQuery = "Id,Order__c, Name, Order__r.Paying_Customer__r.Name, Order__r.Paying_Customer__c,Account__c, Account__r.Name, Product__c, DischargeQuantity__c, LoadingQuantity__c, OrderItem__c, OrderItem__r.Product2.Name, OrderItem__r.Product2Id, OrderItem__r.Quantity, OrderItem__r.UnitOfMeasure__c, OrderItem__r.Extension_1__c, OrderItem__r.Extension_2__c,OrderItem__r.Extension_3__c,OrderItem__r.Extension_1__r.Name, OrderItem__r.Extension_2__r.Name,OrderItem__r.Extension_3__r.Name,OrderItem__r.Extension_Quantity_1__c, OrderItem__r.Extension_Quantity_2__c, OrderItem__r.Extension_Quantity_3__c,OrderItem__r.Extension_Unit_1__c,OrderItem__r.Extension_Unit_2__c,OrderItem__r.Extension_Unit_3__c, OrderItem__r.DischargeLocation__c, OrderItem__r.DischargeLocation__r.Name, OrderItem__r.DischargeLocation__r.Id ,OrderItem__r.LoadingPoint__c, OrderItem__r.LoadingPoint__r.LoadingPointName__c";
  // deliveryNoteFieldsToQuery = "Id,Order__c, Name, Order__r.Paying_Customer__r.Name, Order__r.Paying_Customer__c,Account__c, Account__r.Name, Product__c, RelatedPriceBook__c, DischargeQuantity__c, LoadingQuantity__c, OrderItem__c, OrderItem__r.Product2.Name, OrderItem__r.Product2Id, OrderItem__r.Quantity, OrderItem__r.UnitOfMeasure__c, OrderItem__r.Extension_1__c, OrderItem__r.Extension_2__c,OrderItem__r.Extension_3__c,OrderItem__r.Extension_1__r.Name, OrderItem__r.Extension_2__r.Name,OrderItem__r.Extension_3__r.Name,OrderItem__r.Extension_Quantity_1__c, OrderItem__r.Extension_Quantity_2__c, OrderItem__r.Extension_Quantity_3__c,OrderItem__r.Extension_Unit_1__c,OrderItem__r.Extension_Unit_2__c,OrderItem__r.Extension_Unit_3__c, OrderItem__r.DischargeLocation__c, OrderItem__r.DischargeLocation__r.Name, OrderItem__r.DischargeLocation__r.Id ,OrderItem__r.LoadingPoint__c, OrderItem__r.LoadingPoint__r.LoadingPointName__c";
 //   deliveryNoteFieldsToQuery = "Id, Order__c, Name, Account__c, Account__r.Name, Product__c, RelatedPriceBook__c, DischargeQuantity__c, LoadingQuantity__c, OrderItem__c, OrderItem__r.Product2.Name, OrderItem__r.Product2Id, OrderItem__r.Quantity, OrderItem__r.UnitOfMeasure__c, OrderItem__r.Extension_1__c, OrderItem__r.Extension_2__c, OrderItem__r.Extension_3__c, OrderItem__r.Extension_1__r.Name, OrderItem__r.Extension_2__r.Name, OrderItem__r.Extension_3__r.Name, OrderItem__r.Extension_Quantity_1__c, OrderItem__r.Extension_Quantity_2__c, OrderItem__r.Extension_Quantity_3__c, OrderItem__r.Extension_Unit_1__c, OrderItem__r.Extension_Unit_2__c, OrderItem__r.Extension_Unit_3__c, OrderItem__r.DischargeLocation__c, OrderItem__r.DischargeLocation__r.Name, OrderItem__r.DischargeLocation__r.Id, OrderItem__r.LoadingPoint__c, OrderItem__r.LoadingPoint__r.LoadingPointName__c, Paying_Customer__r.Name";

 agentGetsCommissionValue;
get isLogisticsReason(){
  if(this.rec.reasonForReturn=="לוגיסטיקה"){
    console.log("RAZCHECK,34 ,isLogisticsReason, TRUE");
    return true;
  }
  else{
    console.log("RAZCHECK,34 ,isLogisticsReason, FALSE");
    return false;
  }

}
  connectedCallback() {
    // console.log("init whichProfileType, 34 ",this.whichProfileType);
    //בעליה מג'נרט תאריך של יומיים קדימה
    // this.twoDaysAhead = this.twoDayesAheadGenerator();
    // this.twoDaysAhead = this.calculateBH();
    // this.isDateValid=true;
    // this.calculateBH();
    console.log("razcheck, 42,isUserFcSubAdmin",this.isUserFcSubAdmin);
    this.isFcSubAdmin();
    console.log("razcheck, 44,isUserFcSubAdmin",this.isUserFcSubAdmin);
  }

  calculateBH() {
    // console.log("37",this.rec.requestedSupplyDate);
    calculateBH({ requestedDate: this.today }).then(result => {
      // console.log("calculateBH results:",JSON.stringify(result));
      // this.twoDaysAhead=result;
      this.rec.requestedSupplyDate=result;
    }).catch(error=>console.log("calculateBH error:",error));
    // const myCurrentDate = new Date();
    // const myFutureDate = new Date(myCurrentDate);
    // myFutureDate.setDate(myFutureDate.getDate() + 2); //myFutureDate is now 2 days in the future
    // return myFutureDate.toISOString();
  }

  @track rec = {
    //כל השדות בקומפ' זו
    orderType: "30",
    privateTransport: false,
    requestedSupplyDate:  this.existingthisRequestedSupplyDate?this.existingthisRequestedSupplyDate: this.calculateBH(),
    deliveryNote: { id: null, name: null },
    responsibility: null,
    reasonForReturn: null,
    reasonForReturnDescription: null
  };

  @api receiveRec(orderRec) {
    //מאכלס השדות של כל הקומפוננטה הנוכחית - אורדרדייטטייפ
    // console.log("RAZCHECK, 68, 1001 , orderRec: ", JSON.stringify(orderRec));
    this.rec = orderRec;
    this.rec.requestedSupplyDate=this.rec.requestedSupplyDate;
    this.existingthisRequestedSupplyDate=this.rec.requestedSupplyDate;
    console.log("RAZCHECK,77,receiveRec FORM,this.rec  ",JSON.stringify(this.rec));
    // console.log("RAZCHECK, 72, 1001 ,this.rec.requestedSupplyDate " , this.rec.requestedSupplyDate);
    // console.log("RAZCHECK, 72, 1001 ,this.existingthisRequestedSupplyDate " ,this.existingthisRequestedSupplyDate);
  }

  handleDeliveryNoteChange(event) {
    //מדספצ' ערך מספר תעודת משלוח ישירות! לאבא לייאאוט
    console.log("handleDeliveryNoteChange orderDateTypeContacts: ", JSON.stringify(event.detail));
    this.rec.deliveryNote.name = event.detail.selectedValue? event.detail.selectedValue: "";
    this.rec.deliveryNote.id = event.detail.selectedRecordId? event.detail.selectedRecordId: "";
    
    // this.template.querySelector("c-order-form-component").getPreviousOrdersForGenericLookups();
    const passEvent = new CustomEvent("orderitemid", {detail: event.detail?.selectedRec});
    this.dispatchEvent(passEvent);
    // this.getPreviousOrdersForGenericLookups();
  }

  handleCheckboxChange(event) {
    //הובלה פרטית - העמס וצרף לשאר האוביקט REC
    if (event.currentTarget.checked) {
      this.rec.privateTransport = !this.rec.privateTransport;}
    // } else {
    //   this.rec.privateTransport = false;
    // }
    const passEvent = new CustomEvent("privatetransport", {
      detail: this.rec.privateTransport});
    this.dispatchEvent(passEvent);
  }

  handleMailCopy(event) {
    //נועם ניסה להקליק על אייקון מעטפה של אימייל ויעשה קופי ישר
    let emailToCopy = event.target.dataset.mail;
    // console.log("email clicked: ", emailToCopy);
    // navigator.clipboard.writeText(emailToCopy).then(res => {
    //     console.log("success: " ,res);
    // }).catch (err => {
    //     console.log("failed: " ,err);
    // })
  }

  //  all numbers value detailed here: options . for example: 40: תעודת החזרה
  @api validateFields() {
    if (!this.isDateValid) {
            comp.invalid = true;
            throw "שגיאה: נבחר תאריך לא תקין";
        };

    if (this.rec.orderType == "40" || this.rec.orderType == "60") {
      this.template.querySelectorAll("c-order-generic-lookup").forEach((comp) => {
          if (comp.required && (comp.selectedRecordId == "" || comp.selectedRecordId == null)) {
            comp.invalid = true;
            throw "שגיאה: שדה " + comp.searchlabel + " הוא שדה חובה";
          }
        });  
      }
      this.template.querySelectorAll("lightning-input-field").forEach((element) => {
          if (element.required && (element.value == "" || element.value == null)) {
            element.reportValidity();
            throw "שגיאה: שדה " + element.dataset.label + " הוא שדה חובה";
          }
        });
    if (this.isDesktop && (this.contacts?.length == 0 || this.contacts == null)) {
      throw "לא קיים איש קשר";
    }
  }

  @api clearScreen() {
    // this.connectedCallback();
  //  this.rec={};

    this.rec = {
      orderType: "30", //מכירה ישירה
      privateTransport: false,
      requestedSupplyDate: this.calculateBH(),
      deliveryNote: { id: null, name: null },
      responsibility: null,
      reasonForReturn: null,
      reasonForReturnDescription: null
    };
  }

  isDateValid=true;
  dateHandler(event) {
    //תאריך מבוקש
    this.isDateValid=true;
    this.rec.requestedSupplyDate = event.detail.value;
    console.log("134",this.rec.requestedSupplyDate);
     isBH( {requestedDate:this.rec.requestedSupplyDate}).then(result => {
      console.log("134 isBH results:",JSON.stringify(result));
     if (result==true) {
      return;
     } else {
      this.isDateValid= !this.isDateValid;
this.dispatchEvent(new ShowToastEvent({title: "שגיאה: התאריך שנבחר אינו יום עבודה ",variant: "error"}));
    }
    }).catch(error=>console.log("calculateBH error:",error));
  }

   changeOrderType(event) {
    //סוג עסקה
    this.rec.orderType = event.detail.value; //ערך סוג עסקה מכירה ישירה\קונסיגנציה\שיוך\ת.החזרה
    console.log(this.rec.orderType,"168");
      if (this.rec.orderType === "60") {
        // console.log("reasonForReturnHandler === 60",JSON.stringify(this.rec));
      this.rec.responsibility = null; // אחריות
      this.rec.reasonForReturn = null; // סיבת החזרה
      this.rec.reasonForReturnDescription = null; //תיאור
      
        // this.template.querySelector("c-order-form-component").clearAccountNameForm(); //מעביר את כל המשלמים של אותו לקוח
      //   await this.template.querySelector("c-order-layout-component").handleOrderFormValues();
      //     //  this.template.querySelector("c-order-form-component").appendChild("c-order-generic-lookup"); //מעביר את כל המשלמים של אותו לקוח
      // this.template.querySelector("c-order-generic-lookup[data-id='IntermediaryWarehouse']").res();
      // this.template.querySelector("c-order-generic-lookup[data-id='AgentReceivesCommission']").submit();
    }
    if (this.rec.orderType != "40") { //שונה מהחזרה
      this.rec.responsibility = null; // אחריות
      this.rec.reasonForReturn = null; // סיבת החזרה
      this.rec.reasonForReturnDescription = null; //תיאור
    }
    if (this.rec.orderType != "40" && this.rec.orderType != "60") {    // שונה משיוך וגם ת.החזרה כלומר קונסיגנציה מכירה ישירה
      this.rec.deliveryNote = { id: null, name: null }; //אפס נתוני תעודת משלוח
    }
    // if (this.rec.orderType == "20" && this.rec.orderType == "80") {   
    //   this.today="";
    // }
    // if (this.rec.orderType != "20" && this.rec.orderType != "80") {   
    //   this.today = new Date().toISOString();
    // }
    const passEvent = new CustomEvent("ordertypechange", {detail: this.rec.orderType}); //dispatch to layout the order type (ת.החזרה/שיוך/מכירה ישירה)
    this.dispatchEvent(passEvent);
  }

  responsibilityHandler(event) {
    // אחריות - מוביל\אגרונום וכו, מגיע מהשרת - הערך הנבחר מתעדכן באובייקט רק ברמת הקומפוננטה
    this.rec.responsibility = event.detail.value;
  }

  reasonForReturnHandler(event) {
    // כנ"ל סיבת החזרה
    this.rec.reasonForReturn = event.detail.value;
  }

  reasonForReturnDescriptionHandler(event) {
    // כנ"ל תיאור
    this.rec.reasonForReturnDescription = event.detail.value;
  }

  @api submitFields() {
    //מדספצ'ים את כל אוביקט הרק מעלה לאבא לייאאוט
    // console.log("Date&type: ", JSON.stringify(this.rec));
    // console.log("RAZCHECK, 214, 1001, this.rec",this.rec);
    const passEventr = new CustomEvent("submitcomponents", {      detail: { rec: this.rec }    });
    this.dispatchEvent(passEventr);
  }
  // Row Action event to show the details of the record
  handleContactPopUp(event) {
    // עריכת פרטי איש קשר
    // console.log("248",JSON.stringify(event));
    this.rowId = event.currentTarget.dataset.id; //אכלוס הערכים בפופאפ
    // console.log(this.rowId," 248 הפרטים המתקבלים");
    this.aShowModal = false; // //מודל הוספת איש קשר
    this.bShowModal = true; // //מודל עריכת איש קשר
  }

  renderContacts() {
    const passEvent = new CustomEvent("rendercontacts", {}); //מביא אנשי קשר עבור לקוח
    this.dispatchEvent(passEvent);
  }

  test(event){
    console.log(event);
    console.log(JSON.stringify(event.detail));
  }

  handleNewContactSubmit(event) {
    //הוספת איש קשר חדש
    event.preventDefault();
    if (event.currentTarget.dataset.id) {   
      console.log("234 inside 1st if",event.currentTarget.dataset.id); 
      this.rowId = event.currentTarget.dataset.id; //אכלוס הערכים בפופאפ
      this.aShowModal = true; // //מודל עריכת איש קשר
    } 
    console.log("event.detail.fields, 240", event.detail.fields);
    const fields = event.detail.fields;
    console.log("234 fields",fields,JSON.stringify(fields));
      const Phone = fields.Phone;
      const MobilePhone = fields.MobilePhone;
      // console.log("234 fields HERE!!!",fields, Phone, typeof Phone,Phone.length);
      try {     
        // if (MobilePhone.length != 10 && MobilePhone.length != 11 && MobilePhone.length != 12 && MobilePhone.length != 13 ) {   
        //            this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרוש אורך תקין לטלפון ניידXXX-XXXXXXX",variant: "error"}));
        // }
        if (![10, 11, 12].includes(MobilePhone.length)) {   
                   this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרוש אורך תקין לטלפון ניידXXX-XXXXXXX",variant: "error"}));
        }
        else if (!/^(\d+-?){0,2}\d+$/.test(MobilePhone)){ // אפשר מספרים ורק 2 מקפים --
         this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות או מקסימום 2 מקפים לטלפון נייד XXX-XXXXXXX",variant: "error"}));
        } 
        // else if(! /^[a-zA-Z0-9]+$/.test(MobilePhone)){ // אפשר רק מספרים ואותיות קטנות גדולות
        //  this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות  לטלפון נייד XXX-XXXXXXX",variant: "error"}));
        // } 
        // else if (!/^[0-9-]+$/.test(MobilePhone)){ // אפשר מספרים ומקפים ללא הגבלה
        //  this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות  לטלפון נייד XXX-XXXXXXX",variant: "error"}));
        // } 
        else if (Phone && ((Phone?.length != 10) && (Phone?.length != 9))) {  
          // if (((Phone.length != 10) && (Phone.length != 9))) {
            this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרוש אורך תקין לטלפון -XXXXXXX",variant: "error"}));
        }
        else if(Phone &&  (!/^(\d+-?){0,2}\d+$/.test(Phone))){
            this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות או מקסימום 2 מקפים לטלפון  XXX-XXXXXXX",variant: "error"}));
        }
            // } else if(! /^[a-zA-Z0-9]+$/.test(Phone) ){
        // this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות  לטלפון  XXX-XXXXXXX",variant: "error"}));
      //              if (( (validateMobileNumber < 500000000) && (validateMobileNumber > 599999999) ) || ( !(720000000 < (this.validatePhoneNumber) && (this.validatePhoneNumber) < 799999999 ) ) 
      //              && (!(20000000<this.validatePhoneNumber)  && this.validatePhoneNumber < 99999999) 
      //              && (!this.validatePhoneNumber)       
      else{
        this.template.querySelector("lightning-record-edit-form.new").submit(fields);
        this.closeNewContactModal();            
      }    
      } catch (error) {
        console.log(error,"line 253, 234");
      }
  }

  handleEditContactSubmit(event) {
    //עריכת איש קשר קיים
    event.preventDefault();
    console.log("event.detail.fields, 288", event.detail.fields);
    const fields = event.detail.fields;
    console.log("288 fields",fields,JSON.stringify(fields));
      const Phone = fields.Phone;
      const MobilePhone = fields.MobilePhone;
      // console.log("234 fields HERE!!!",fields, Phone, typeof Phone,Phone.length);
      try {     
        // if (MobilePhone.length != 10 && MobilePhone.length != 11 && MobilePhone.length != 12 && MobilePhone.length != 13 ) {   
        //            this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרוש אורך תקין לטלפון ניידXXX-XXXXXXX",variant: "error"}));
        // }
        if (![10, 11, 12].includes(MobilePhone.length)) {   
                   this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרוש אורך תקין לטלפון ניידXXX-XXXXXXX",variant: "error"}));
        }
        else if (!/^(\d+-?){0,2}\d+$/.test(MobilePhone)){ // אפשר מספרים ורק 2 מקפים --
         this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות או מקסימום 2 מקפים לטלפון נייד XXX-XXXXXXX",variant: "error"}));
        } 
        // else if(! /^[a-zA-Z0-9]+$/.test(MobilePhone)){ // אפשר רק מספרים ואותיות קטנות גדולות
        //  this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות  לטלפון נייד XXX-XXXXXXX",variant: "error"}));
        // } 
        // else if (!/^[0-9-]+$/.test(MobilePhone)){ // אפשר מספרים ומקפים ללא הגבלה
        //  this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות  לטלפון נייד XXX-XXXXXXX",variant: "error"}));
        // } 
        else if (Phone && ((Phone?.length != 10) && (Phone?.length != 9))) {  
          // if (((Phone.length != 10) && (Phone.length != 9))) {
            this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרוש אורך תקין לטלפון -XXXXXXX",variant: "error"}));
        }
        else if(Phone &&  (!/^(\d+-?){0,2}\d+$/.test(Phone))){
            this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות או מקסימום 2 מקפים לטלפון  XXX-XXXXXXX",variant: "error"}));
        }
            // } else if(! /^[a-zA-Z0-9]+$/.test(Phone) ){
        // this.dispatchEvent(new ShowToastEvent({title: " שגיאה ביצירת איש קשר-דרושים רק ספרות  לטלפון  XXX-XXXXXXX",variant: "error"}));
      //              if (( (validateMobileNumber < 500000000) && (validateMobileNumber > 599999999) ) || ( !(720000000 < (this.validatePhoneNumber) && (this.validatePhoneNumber) < 799999999 ) ) 
      //              && (!(20000000<this.validatePhoneNumber)  && this.validatePhoneNumber < 99999999) 
      //              && (!this.validatePhoneNumber)       
      else{
        this.template.querySelector("lightning-record-edit-form.edit").submit(fields);
        this.closeModal();
      }    
      } catch (error) {
        console.log(error,"line 327, 234");
      }
  }

  handleEditSucces() {
    // איש קשר שונה בהצלחה
    try{
      this.renderContacts();
      this.closeModal();
      const evt = new ShowToastEvent({ title: "איש קשר שונה", message: "איש קשר שונה בהצלחה!", variant: "success" });
      this.dispatchEvent(evt);
    }
    catch(err){
      console.log("Error:", err);
    }
  }

  handleEditFailure() {
    // איש קשר שונה כשלון
    this.closeModal();
    const evt = new ShowToastEvent({ title: "שגיאה", message: "שגיאה ביצירת איש קשר", variant: "error"});
    this.dispatchEvent(evt);
  }
  // to close modal window set 'bShowModal' tarck value as false
  closeModal() {
    this.bShowModal = false;
  }

  closeNewContactModal() {
    this.aShowModal = false;
  }

  openNewContactModal() {
    //פתיחת המודל לעדכון איש קשר
    if (this.accountId == null) {
      //אם אין לקוח שנבחר הקפץ טואסט
      const evt = new ShowToastEvent({ title: "לא נבחר לקוח", message: "חובה לבחור קודם לקוח", variant: "error"      });
      this.dispatchEvent(evt);
    } else {
      this.rowId=undefined;
      this.aShowModal = true; //במידה ויש לקוח - פתיחת פופאפ יצירת איש קשר
    }
  }

  handleNewContactError(event) {
    // פתיחת טואסט שגיאה ביצירת איש קשר
    // console.log(JSON.stringify(event.getParams()));
    const evt = new ShowToastEvent({ title: "שגיאה ביצירת איש קשר חדש", message: "", variant: "error" });
    this.dispatchEvent(evt);
  }

  handleNewContactSuccess(event) {
    //איש קשר נוסף בהצלחה
    //console.log("handleNewContactSuccess: ", event.detail.id)
    try {
      if (this.branchId) {
        // במידה שנבחר ענף גידול - נרצה שאנשי הקשר יהיו מקושרים אליו
        this.createContactForBranch(event.detail.id); // במידה שנבחר ברנצ' - נקשר אותו לאנשי הקשר שהתווספו
      }
      this.renderContacts(); //מרענן את האנשי קשר - מדספצ' ומביא כל אנשי קשר מהשרת
      const evt = new ShowToastEvent({ title: "איש קשר חדש נוסף", message: "איש קשר חדש נוסף בהצלחה!", variant: "success" });
      this.dispatchEvent(evt);
    } catch (err) {
      console.log("Error: ", err);
    }
  }

  createContactForBranch(contactId) {
    const fields = {
      Contact__c: contactId, //איש קשר שנוצר בהצלחה
      BranchGrowth__c: this.branchId // ענף הגידול שנבחר
    };
    const recordInput = { apiName: "Branch_Contact_Link__c", fields: fields };

    createRecord(recordInput).then(() => {}).catch((error) => {
        // console.error(error);
        this.dispatchEvent(
          new ShowToastEvent({ title: "Error creating new contact for branch", message: error.body.message, variant: "error" })
        );
      });
  }

  isFcSubAdmin() {
    isFcSubAdmin().then((response) => {  
      console.log("RAZCHECK,416, RESPONSE",response);  
    this.isUserFcSubAdmin = response;   // return true or false - יש הקצאה או אין
    });
}

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////              getters                        //////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  get getContacts() {
    //אם התאריך המבוקש הוא נול - הפעל פונ' חישוב יומיים קדימה. אחרת כנראה שמדובר בהזמנה קיימת
    return this.contacts == null ? [] : this.contacts;
  }

  get dateValue() {
    //אם התאריך המבוקש הוא נול - הפעל פונ' חישוב יומיים קדימה. אחרת כנראה שמדובר בהזמנה קיימת
    return this.rec.requestedSupplyDate == null ? this.twoDaysAhead : this.rec.requestedSupplyDate;
  }

get disableOrderType(){
  console.log("RAZCHECK, 435,this.orderStatus",this.orderStatus);
return this.isNotCustomerService && this.orderStatus != `טיוטה` && (this.rec.orderType==`60` || this.rec.orderType==`40`);
}

  get options() {
    console.log("razcheck, 439,isUserFcSubAdmin",this.isUserFcSubAdmin);

    if(this.rec.orderType == "50"){
        return[ { label: "דישון", value: "50" }]
    }
    else if(this.rec.orderType == "80"){
        return[ { label: "חיוב בדיעבד", value: "80" }]
    }
    else{

      if(this.whichProfileType =="IL External Customer Service"){ // כל דשן
        console.log("IL External Customer Service condition, 373");
          return[
                          { label: "העברה למחסן קונסיגנציה", value: "10" },
                          { label: "מכירה ממחסן קונסיגנציה", value: "20" },
                          { label: "מכירה ישירה", value: "30" },
                          { label: "שיוך", value: "60" },
          ]
      }
      else if(this.isUserFcSubAdmin){ //  האם יש ליוזר הקצאת FC SUB ADMIN 
        console.log("isUserFcSubAdmin in options, 465");
          return[
                          { label: "העברה למחסן קונסיגנציה", value: "10" },
                          { label: "מכירה ממחסן קונסיגנציה", value: "20" },
                          { label: "מכירה ישירה", value: "30" },
                          { label: "תעודת החזרה", value: "40" },
                          { label: "שיוך", value: "60" },
                          { label: "מסגרת", value: "70" },
                          { label: "חיוב בדיעבד", value: "80" },
          ]
      }
      else if( this.whichProfileType =="IL - Sales manager" || this.whichProfileType =="IL - Sales manager Chemicals"){ //  מכירות
          console.log("IL Customer Service || IL - Sales manager Chemicals condition, 373");
              return[
                          { label: "העברה למחסן קונסיגנציה", value: "10" },
                          { label: "מכירה ממחסן קונסיגנציה", value: "20" },
                          { label: "מכירה ישירה", value: "30" },
                          { label: "מסגרת", value: "70" }
              ]
      }
      else {
          console.log("else condiation, 390",this.whichProfileType);
            return [
                          { label: "העברה למחסן קונסיגנציה", value: "10" },
                          { label: "מכירה ממחסן קונסיגנציה", value: "20" },
                          { label: "מכירה ישירה", value: "30" },
                          { label: "תעודת החזרה", value: "40" },
                          { label: "שיוך", value: "60" },
                          { label: "מסגרת", value: "70" }

            ];
      }
    }
    
    //סוג עסקה
    // if (this.isNotCustomerService && this.orderStatus != `טיוטה` && (this.rec.orderType==`60` || this.rec.orderType==`40`)) {
    //   console.log("first condition 361");     
    //   return [
    //                       { label: "העברה למחסן קונסיגנציה", value: "10" },
    //                       { label: "מכירה ממחסן קונסיגנציה", value: "20" },
    //                       { label: "מכירה ישירה", value: "30" },
    //                       { label: "תעודת החזרה", value: "40" },
    //                       { label: "שיוך", value: "60" },
    //                     ];
                      
    // }
    // if (this.isNotCustomerService && this.rec.orderType != "50") {
    //   console.log("2nd condition 372");     
    //   return [
    //     { label: "העברה למחסן קונסיגנציה", value: "10" },
    //     { label: "מכירה ממחסן קונסיגנציה", value: "20" },
    //     { label: "מכירה ישירה", value: "30" },
    //     { label: "תעודת החזרה", value: "40" },
    //     { label: "מסגרת", value: "70" }

    //   ];
    // }
    // if (this.isNotCustomerService && this.rec.orderType == "50") {
    //   return [
    //     { label: "העברה למחסן קונסיגנציה", value: "10" },
    //     { label: "מכירה ממחסן קונסיגנציה", value: "20" },
    //     { label: "מכירה ישירה", value: "30" },
    //     { label: "עבודת דישון", value: "50" },
    //   //  { label: "מסגרת", value: "70" }

    //   ];
    // }
    // if ((!this.isNotCustomerService && this.rec.orderType == "50") ) {
    //   //כן משירות לקוחות וסוג עסקה הוא עבודות דישון- הצג הכל
    //   return [
    //     { label: "העברה למחסן קונסיגנציה", value: "10" },
    //     { label: "מכירה ממחסן קונסיגנציה", value: "20" },
    //     { label: "מכירה ישירה", value: "30" },
    //     { label: "תעודת החזרה", value: "40" },
    //     { label: "עבודת דישון", value: "50" },
    //     { label: "שיוך", value: "60" }
    //   ];
    // } else {
    //   //אם אני שירות לקוחות אבל לא עבודת דישון - הצג הכל חוץ מעבודות דישון
    //   return [
    //     { label: "העברה למחסן קונסיגנציה", value: "10" },
    //     { label: "מכירה ממחסן קונסיגנציה", value: "20" },
    //     { label: "מכירה ישירה", value: "30" },
    //     { label: "תעודת החזרה", value: "40" },
    //     { label: "שיוך", value: "60" },
    //     { label: "מסגרת", value: "70" }

    //   ];
    // }
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

  get deliveryNoteExtraWhereClause() {
    //מספר תעודת משלוח - כדי להביא משרת - אם לא נבחר לקוח מסויים - הצג הכל, אחרת הצג רק את שלו
    if (this.rec.orderType == "60") {
      return ` AND (status__c='15' OR status__c='10' OR Status__c='17') AND DeliveryNoteType__c = '1' `;
    } else {
      return this.accountId ? `AND DeliveryNoteType__c = '1' AND Account__c = '${this.accountId}'` : "AND DeliveryNoteType__c = '1'";
    }
    // return this.accountId ? `AND DeliveryNoteType__c = '1' AND Account__c = '${this.accountId}'` : "AND DeliveryNoteType__c = '1'";
  }

  get isReturningOrder() {
    //אם הזמנה חוזרת\תעודת החזרה
    return this.rec.orderType == "40" ? true : false;
  }

  get isAffiliationOrder() {
    //אם שיוך
    return this.rec.orderType == "60" ? true : false;
  }

  get isReturningContactTableHeightChange() {
    // במידה ולא ת.החזרה - אז מגדיל את הגובה של הטבלת אנשי קשר
    return this.rec.orderType == "40" ? "scrollable-table slds-m-top_medium" : "scrollable-table slds-m-top_medium tableHeightLarger";
  }

  get todayGetter(){
    console.log("RAZCHECK, 593 , this.rec.orderType",this.rec.orderType);
    if (this.rec.orderType == '20' || this.rec.orderType == '80') {   
      console.log("RAZCHECK, 593 , return null");
      return null;
    }
    else{
      console.log("RAZCHECK, 593 , return today",this.today);
      return this.today
    }
  }
}