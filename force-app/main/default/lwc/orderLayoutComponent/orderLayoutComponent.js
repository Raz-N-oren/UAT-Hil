import { LightningElement, track, api, wire } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
//כל הבאים מספרית לווסי:
import {  createRecord,  deleteRecord,  updateRecord,  getRecord} from "lightning/uiRecordApi";
import getContactsForAccount from "@salesforce/apex/OrderCustomerController.getContactsForAccount";
import getContactsForBranch from "@salesforce/apex/OrderCustomerController.getContactsForBranch";
import getNotesToAccount from "@salesforce/apex/OrderCustomerController.getNotesToAccount";
import getPricebookEntryId from "@salesforce/apex/OrderCustomerController.getPricebookEntryId";
import getLastOrdersForAccount from "@salesforce/apex/OrderCustomerController.getLastOrdersForAccount";
import getTankPoints from "@salesforce/apex/OrderCustomerController.getTankPoints";
import getOrderAndOrderItems from "@salesforce/apex/OrderCustomerController.getOrderAndOrderItems";
import getLoadingPointName from "@salesforce/apex/OrderCustomerController.getLoadingPointName";
import getUserProfile from "@salesforce/apex/OrderCustomerController.getUserProfile";
import getDeliveryNoteId from "@salesforce/apex/OrderCustomerController.getDeliveryNoteId";
import updateAccountDescription  from "@salesforce/apex/OrderCustomerController.updateAccountDescription";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Utils from "c/utils";
import Id from "@salesforce/user/Id";
import getDefaultLP from "@salesforce/apex/OrderCustomerController.getDefaultLP";
import updateOrderAndOrderItemStatusNew from "@salesforce/apex/OrderCustomerController.updateOrderAndOrderItemStatusNew";
import calculateBH from '@salesforce/apex/OrderCustomerController.calculateBH';


export default class OrderLayoutComponent extends LightningElement {
  userId = Id;
  @track products = [];
  @track accountId;
  @track accountName;
  @track branchGrowthId;
  @track contacts;
  @track lastOrders = [];
  @track orderLocked = false;
  @track notes = {Description: "",Regular_note_to_the_driver__c: "",Note_for_discharge__c: ""};
  @track tankPoints;
  isCustomerRemoved;
  orderNumber = "הזמנה חדשה";
  @api orderStatus = "טיוטה";
  isButtonClicked; //defaulted to false
  id = 1;
  twoDaysAhead = '';
  @api recordId;
  defaultCurrencyIsoCode = "ILS";
  profileType;
  @track isChemicalAccount = false;
  @track isSaveBtnClickedValue = false;
  @track loadingPointIdFromOrderItem = "";
  isChemicals; 
  @track isFrameButton=false;
  today = new Date().toISOString();
  industry2=null;
  @track orderItems = [];
  @track orderItemsToUpdate = [];
  @track orderItemsToCreate = [];
  @track accSettelment;
  itemStatusForForm = null;
  extensions;
  itemsToPopulate = [];
  offset = 0;
  originalOrderId;
  originalOrderItemId;
  industryFromLayout;
  relatedPricebook;
  addProductClickedFromExistOrder = false;
  renderOrderItemsCounter = 1;
  orderId;
  OriginOrderItemId;
  //the upper object
  @track order = {
    id: null,
    orderNumber: "הזמנה חדשה",
    Status: "טיוטה",
    AccountId: "",
    Branch_growth__c: "",
    Paying_Customer__c: "",
    AgentReceivesCommission__c: "",
    IntermediaryWarehouse__c: "",
    Payer_Approval__c: "",
    CosignationWarehouseApproval__c: "",
    PassingPermit__c: "",
    RequestedSupplyDate__c: "",
    TransactionType__c: "",
    PrivateTransport__c: false,
    DeliveryNote__c: null,
    responsibility__c: null,
    reasonForReturn__c: null,
    reasonForReturnDescription__c: null,
    Description: "",
    Order_Delivered_By__c: "",
  };

  //the lower object
  item = {
    OrderId: null,
    Product2Id: null,
    Quantity: null,
    UnitOfMeasure__c: null,
    status: null,
    TotalPrice: null,
    DischargeLocation__c: null,
    Description: null,
    NonFreightCharge__c: false,
    RefuelingTransport__c: null,
    combinedTransport__c: false,
    specialTransport__c: false,
    CustomerPackaging__c: false,
    WaitingRequired__c: false,
    CraneTransport__c: false,
    LoadingPoint__c: null,
    Extension_1__c: null,
    Extension_2__c: null,
    Extension_3__c: null,
    Extension_Quantity_1__c: null,
    Extension_Quantity_2__c: null,
    Extension_Quantity_3__c: null,
    Extension_Unit_1__c: null,
    Extension_Unit_2__c: null,
    Extension_Unit_3__c: null,
    Purchase_Order__c: null,
    Price_from_customer_order__c: null,
    DeliveryPrice__c: null,
    DeliveryUnitOfMeasure__c: null,
    relatedContactName: null,
    relatedContactPhone: null,
    driver: null,
    supplyDate: null
  };
  frame_OrderId;
  frame_OrderItemId;
  @track myBooleanVariable = false;


  
  handleBooleanChange(event) {
    //this.myBooleanVariable = event.detail.booleanValue;
    console.log("you arrived to your",this.myBooleanVariable);
    this.frame_OrderId=event.detail.arr[0].OrderId;
    this.frame_OrderItemId=event.detail.arr[0].Id;
  }
  // handleFrameBTN(event){
  //   alert(2)
  //   this.isFrameButton = event.detail.isFrameButton;
  //   alert(this.isFrameButton)
  // }
  //component 1 (upper/right side) object
  orderFormRec = {
    account: { id: "", name: "", industry: "", sapType: "" },
    branchGrowth: { id: "", name: "" },
    intermediaryWarehouse: { id: "", name: "" },
    payingCustomer: { id: "", name: "" },
    agentReceivesCommission: { id: "", name: "" },
    payerApproval: "",
    passingPermit: "",
    isChemicalAccount: false,
    isChemicals:false,
    industry2:"",
    cosignationWarehouseApproval: ""
  };

  //component 2 (upper/center side) object
@api orderDateAndTypeRec = {
    orderType: "מכירה ישירה",
    privateTransport: false,
    requestedSupplyDate: null,
    deliveryNote: { id: null, name: null },
    responsibility: null,
    reasonForReturn: null,
    reasonForReturnDescription: null
  };

  //component 3
  orderNotesRec = {    Description: "" };
  //initial function to empty all objects value. NOT clearScreenFileds function bcause doesn't catch HTML element to reset it's value
  initObjects() {
    this.accountId = null;
    this.accountName = null;
    this.agronom = "";
    this.createdByName = "";
    this.createdDate = "";
    this.LastModifiedById="";
    this.LastModifiedByName="";
    this.branchGrowthId = null;
    this.orderType = null;
    this.order = {
      id: null,
      orderNumber: "הזמנה חדשה",
      Status: "טיוטה",
      AccountId: "",
      Branch_growth__c: "",
      Paying_Customer__c: "",
      AgentReceivesCommission__c: "",
      IntermediaryWarehouse__c: "",
      Payer_Approval__c: "",
      CosignationWarehouseApproval__c: "",
      PassingPermit__c: "",
      RequestedSupplyDate__c: "",
      TransactionType__c: "",
      PrivateTransport__c: false,
      Description: "",
      Order_Delivered_By__c: ""

    };
    this.item = {
      OrderId: null,
      Product2Id: null,
      Quantity: null,
      UnitOfMeasure__c: null,
      status: null,
      TotalPrice: null,
      DischargeLocation__c: null,
      Description: null,
      NonFreightCharge__c: null,
      RefuelingTransport__c: null,
      combined_Packaging__c: null,
      combinedTransport__c: false,
      specialTransport__c: false,
      CustomerPackaging__c: false,
      WaitingRequired__c: false,
      CraneTransport__c: false,
      LoadingPoint__c: null,
      Extension_1__c: null,
      Extension_2__c: null,
      Extension_3__c: null,
      Extension_Quantity_1__c: null,
      Extension_Quantity_2__c: null,
      Extension_Quantity_3__c: null,
      Extension_Unit_1__c: null,
      Extension_Unit_2__c: null,
      Extension_Unit_3__c: null,
      Purchase_Order__c: null,
      Price_from_customer_order__c: null,
      DeliveryPrice__c: null,
      DeliveryUnitOfMeasure__c: null,
      relatedContactName: null,
      relatedContactPhone: null,
      driver: null,
      supplyDate: null
      // LoadingPointType__c:null
    };
    this.originalOrderId = "";
    this.originalOrderItemId = "";
  }
  closeFrameDealHandle() {
    updateOrderAndOrderItemStatusNew({orderId: this.order.id ? this.order.id : this.frame_OrderId,
      orderItemId:this.itemsToPopulate[0].id ? this.itemsToPopulate[0].id : this.frame_OrderItemId}).then(() => {
      this.dispatchEvent( new ShowToastEvent({ title: "הזמנת מסגרת נסגרה בהצלחה", message: "סטטוס ההזמנה שונה לסגור",variant: "success"}));
    }).catch((error) => {
      this.dispatchEvent( new ShowToastEvent({ title: "הזמנת מסגרת לא נסגרה", message: error,variant: "error"}));
    });  
} 
 updateOrderAndOrderItemStatusNew() {
    updateOrderAndOrderItemStatusNew({ orderId: this.accountId, orderItemId: this.rec.product.id }).then((result) => {
        console.log("Now what? updateOrderAndOrderItemStatusNew 218 004 : ");
      }).catch((error) => {console.log(`008. Error: ${JSON.stringify(error)}`);
      });
      };
  
  

//dd to change sales type display, according to user type -  שיוך/תעודת החזרה
  getUserProfile() {
    getUserProfile({ Id: this.userId }).then((result) => {
        console.log("getUserProfile: ", result);
        this.profileType = result[0].Profile.Name;
        // with every new order - we'll add the currency type - just because it was requested (no reason)
        this.defaultCurrencyIsoCode = result[0].DefaultCurrencyIsoCode;
      }).catch((error) => {console.log(`008. Error: ${JSON.stringify(error)}`);
      });
  }

  //identify customer number. If not login - not able to open new order!
  //get contacts from DB
  getContactsForAccount() {
    getContactsForAccount({ recordId: this.accountId }).then((response) => {
        if (response.length > 0) {
          console.log("RAZCHECK,272 , getContactsForAccount,response  ",response);
          this.contacts = response;
        } else {
          // other then desktop theres no need for contacts
          if (this.isDesktop) {
            this.dispatchEvent( new ShowToastEvent({ title: "לא קיים איש קשר", message: "לא יהיה ניתן לשמור הזמנה",variant: "error"}));
          }
        }
      }).catch((error) => {console.error(error);});
  }

  // הבא אנשי קשר! בהתאם לערך שהוכנס בשורת החיפוש העליונה (ענף/לקוח)
  getContacts() {
    if (this.branchGrowthId) {
      getContactsForBranch({ recordId: this.branchGrowthId }).then((response) => {
          //in the highest search box - is ענף has chosen? if yes - contacts = [..sth..], else fetch customer contacts
          if (response.length > 0) {
            console.log("response of branch contacts: ", response);
            this.contacts = [];
            response.forEach((res) => {
              // the question mark refer to the key RIGHT AFTER THE CURRENT ONE!!!!
              this.contacts.push({Id: res.Contact__c,Name: res.Contact__r?.Name,Phone: res.Contact__r?.Phone,MobilePhone: res.Contact__r?.MobilePhone,Email: res.Contact__r?.Email});
            });
          } else {
            this.getContactsForAccount();
          }
        }).catch((error) => { console.error("getContactsForBranch: ", error);
        });
    } else {
      this.getContactsForAccount();
    }
  }
  //CHECK !
  payingCustomer;
  //תעודת החזרה? אז תעשה אכלוס לשדות של המוצר!
  handleOrderItemOnReturnDeal(event) {
    console.log("handleOrderItemOnReturnDeal , 288, RAZCHECK",JSON.stringify(event));
    this.originalOrderId = "";
    this.originalOrderItemId = "";
    this.relatedPricebook = null;
    
    try {
      if (event.detail?.OrderItem__c) {
        this.itemsToPopulate = [];
        // console.log("handleOrderItemOnReturnDeal1: ",JSON.stringify(event.detail.OrderItem__c));
        // console.log(event.detail.DischargeQuantity__c,event.detail.LoadingQuantity__c,event.detail.OrderItem__r.Quantity);
        const Quantity = event.detail.DischargeQuantity__c ? event.detail.DischargeQuantity__c : event.detail.LoadingQuantity__c ? event.detail.LoadingQuantity__c  : event.detail.OrderItem__r.Quantity;
        // console.log("handleOrderItemOnReturnDeal2: ",JSON.stringify(event.detail));
        this.originalOrderId = event.detail?.Order__c;
        this.originalOrderItemId = event.detail?.OrderItem__c;
        this.relatedPricebook = event.detail.RelatedPriceBook__c;
        this.payingCustomer = event.detail?.Order__r?.Paying_Customer__r;
        this.order.Payer_Approval__c = event.detail?.Order__r?.Paying_Customer__r;
        // this.order.Paying_Customer__c = event.detail?.Order__r?.Paying_Customer__r;
        // this.order.Paying_Customer__c.name = event.detail?.Order__r?.Paying_Customer__r?.Name;

        console.log("handleOrderItemOnReturnDeal,308,Raz",JSON.stringify(this.payingCustomer));

        let newOrderItem = {...event.detail.OrderItem__r,Id: this.id,Quantity: Quantity,OrderId: null,OrderItemNumber: null};
        this.arrangeOrderItemValues(newOrderItem);
        this.template.querySelector("c-order-item-component").populateOrderItemRecord(this.itemsToPopulate[0], 1);
        if (!this.accountId) {
          console.log("RAZCHECK, 314,this.accountId ",this.accountId);
          console.log("RAZCHECK, 314,this.accountName ",this.accountName);
          this.accountId = event.detail.Account__c;
          this.accountName = event.detail.Account__r.Name;
          console.log("RAZCHECK, 314 318,this.accountId ",this.accountId);
          console.log("RAZCHECK, 314 318,this.accountName ",this.accountName);
          console.log("RAZCHECK, 314 318,this.payingCustomer ",this.payingCustomer);
          console.log("RAZCHECK, 314 318,this.order.TransactionType__c ", JSON.stringify(this.order.TransactionType__c));
          if(this.order.TransactionType__c !== "60"){
            console.log("RAZCHECK, 314 318,this.order.TransactionType__c");
            this.template.querySelector("c-order-form-component").changeAccount(this.accountId, this.accountName,this.payingCustomer);
          }
        }
      } else {
        this.template.querySelector("c-order-item-component").clearScreen();
      }
    } catch (err) {
      console.log("handleOrderItemOnReturnDeal: ", err);
    }
  }

  //בבחירת לקוח --> מביא נקודות פריקה (מיכל) שלו
  getTankPoints() {
    // נקודות פריקה
    if (!this.accountId) {
      this.tankPoints = [];
      this.template.querySelectorAll("c-order-item-component").forEach((comp) => {
          comp.updateTankPoints(null, null);
        });
    } else {
      getTankPoints({ accountId: this.accountId }).then((res) => {
          if (res.length > 0) {
            this.tankPoints = [];
            this.tankPoints = res;
            this.template.querySelectorAll("c-order-item-component").forEach((comp) => {
                comp.updateTankPoints(res, this.accSettelment);
              });
          } else {
            this.tankPoints = null;
            this.template.querySelectorAll("c-order-item-component").forEach((comp) => {
                comp.updateTankPoints(null, this.accSettelment);
              });
          }
        }).catch((err) => {
          console.error(err);
        });
    }
  }

  // בגע שנבחר לקוח - מביא מדאטהבייס את ההערות שלו
  getNotes() {
    getNotesToAccount({ recordId: this.accountId }).then((response) => {
      console.log("RAZCHECK,386,getNotesToAccount ",JSON.stringify(response));
      console.log("RAZCHECK,386,getNotesToAccount,response?.id ",response[0]?.Id);
      console.log("RAZCHECK,386,getNotesToAccount,response?.Description ",response[0]?.Description);
        // this.notes = response[0];
        this.notes.Id = response[0]?.Id;
        this.notes.Description = response[0]?.Description;
        this.notes.Regular_note_to_the_driver__c =  response[0]?.Regular_note_to_the_driver__c;
        this.notes.Note_for_discharge__c =  response[0]?.Note_for_discharge__c;
        // @track notes = {Description: "",Regular_note_to_the_driver__c: "",Note_for_discharge__c: ""};

        console.log("RAZCHECK,386,getNotesToAccount,this.notes ",this.notes);
      }).catch((error) => {
        console.error(error.body.message);
      });
  }

  // onclick func get previous orders (aside component) for account
  // הבא היסטוריית הזמנות ללקוח (לשונית מוחבאת משמאל)
  getLastOrders() {
    this.loadingSpinner = true;
    getLastOrdersForAccount({ recordId: this.accountId, offset: this.offset }).then((response) => {
      console.log("Response check, 368 RazCHECKING",response);
        this.lastOrders = [];
        response.forEach((res) => {
          console.log("last Orders: ", res);
          if (res.Id != this.recordId) {
            if (res.hasOwnProperty("OrderItems")) {
              const orderItems = [];
              res.OrderItems.forEach((item) => {
                orderItems.push({...item,
                  deliveryNoteExist: item.DeliveryNoteExist__c,
                  status: item?.Status__c? this.getOrderItemStatusCodeValue(item.Status__c): null,
                  truckCode: item?.Truck_code__c,
                  deliveryDate: item?.DeliveryDate__c,
                  UnitOfMeasure__c: this.getUnitOfMeasureName(item.UnitOfMeasure__c),
                  Extension_Unit_1__c: this.getUnitOfMeasureName(item?.Extension_Unit_1__c),
                  Extension_Unit_2__c: this.getUnitOfMeasureName(item?.Extension_Unit_2__c),
                  Extension_Unit_3__c: this.getUnitOfMeasureName(item?.Extension_Unit_3__c)
                });
              });
              this.lastOrders.push({...res,Status: this.getStatusCodeValue(res.Status),OrderItems: orderItems});
            } else {
              this.lastOrders.push({...res,Status: this.getStatusCodeValue(res.Status)
              });
            }
          }
        });
        this.loadingSpinner = false;
      }).catch((error) => {
        this.loadingSpinner = false;
        console.error(error);
      });
  }
  //
  loadingSpinner = false;

  //טען עוד היסטוריית הזמנות (באג! במסך לפטופ לא רואים)
  getMoreLastOrdersRecords() {
    this.offset += 10;
    this.loadingSpinner = true;
    // offset  - קאונטר שסופר את 10 ההזמנות הקודמות, ואז הקריאה הבאה מביאה את ה10 שאחריו
    getLastOrdersForAccount({ recordId: this.accountId, offset: this.offset }).then((response) => {
        // this.lastOrders = [];
        console.log("last Orders: ", JSON.stringify(response));
        response.forEach((res) => {
          if (res.Id != this.recordId) {
            if (res.hasOwnProperty("OrderItems")) {
              const orderItems = [];
              res.OrderItems.forEach((item) => {
                orderItems.push({...item,
                  deliveryNoteExist: item.DeliveryNoteExist__c,
                  status: item?.Status__c? this.getOrderItemStatusCodeValue(item.Status__c): null,
                  truckCode: item?.Truck_code__c,
                  deliveryDate: item?.DeliveryDate__c,
                  UnitOfMeasure__c: this.getUnitOfMeasureName(item.UnitOfMeasure__c),
                  Extension_Unit_1__c: this.getUnitOfMeasureName(item?.Extension_Unit_1__c),
                  Extension_Unit_2__c: this.getUnitOfMeasureName(item?.Extension_Unit_2__c),
                  Extension_Unit_3__c: this.getUnitOfMeasureName(item?.Extension_Unit_3__c)
                });
              });
              this.lastOrders.push({...res,Status: this.getStatusCodeValue(res.Status),OrderItems: orderItems});
            } else {
              this.lastOrders.push({...res,Status: this.getStatusCodeValue(res.Status)});
            }
          }
        });
        this.loadingSpinner = false;
      }).catch((error) => {
        this.loadingSpinner = false;
        console.error(error);
      });
  }

  // on aside component onclick-orderNumber view record
  // בקליק - תעשה נביגציה לעמוד הזמנה שלחצתי
  viewRecord(event) {
    event.preventDefault();
    // Navigate to Order record page
    console.log("Click ", event.target.dataset.id);
    window.location.assign(window.open("/" + event.target.dataset.id));
  }
  //
  // -בקליק - תעשה שכפול לעמוד הזמנה שלחצתי - יש באג!
  duplicatePreviousOrder(event) {
    event.preventDefault();
    let obj = this.lastOrders.find(({ Id }) => Id == event.target.dataset.id);
    const order = { ...obj };
    console.log("duplicte button!!!!!", JSON.stringify(order));
    this.arrangeOrderValues({...order,Status: "Draft",OrderNumber: "הזמנה חדשה",PassingPermit__c: "",Payer_Approval__c: ""});
   // console.log("line 404:", JSON.stringify(this.arrangeOrderValues));
    if (order.hasOwnProperty("OrderItems")) {
      this.itemsToPopulate = [];
      try {
        this.id = 1;
        order.OrderItems.forEach((orderItem) => {
          this.arrangeOrderItemValues({...orderItem,Id: this.id,OrderId: null,OrderItemNumber: null});
          this.id++;
        });
        this.orderItems = JSON.parse(JSON.stringify(this.itemsToPopulate));
      } catch (error) {
        console.log("002: error: ", error);
      } finally {
        if (this.itemsToPopulate.length > 0) {
          const orderItemsComponents = this.template.querySelectorAll("c-order-item-component");
          orderItemsComponents.forEach((comp, index) => {
            comp.populateOrderItemRecord(this.itemsToPopulate[index],index + 1);
          });
        }
      }
    }
  }

  createdByName = "";
  agronom = "";
  // populate exitsting order values
  // ברגע שיש הזמנה קיימת - מאכלס את השדות במקומות הרלוונטיים ב-HTML
  arrangeOrderValues(order) {
    console.log("RAZCHECK,507,arrangeOrderValues : ", JSON.stringify(order));
    console.log("arrangeOrderValues : ", this.recordId);
    this.order.TransactionType__c=order.TransactionType__c;
    console.log("arrangeOrderValues - TransactionType__c: ", this.order.TransactionType__c, this.orderItems.id);
    this.createdByName = order.CreatedBy.Name;
    this.agronom = order?.Agronom__c;
    this.accountId = order.AccountId;
    this.accountName = order?.Account.Name;
    this.branchGrowthId = order.Branch_growth__c? order.Branch_growth__c: null;
    this.industry= order.Account.AccountDivision__c;
    this.isChemicals = order.Account.AccountDivision__c==`כימיקלים` && this.order.TransactionType__c!= "40" ? true :false;
    this.industry2 = order.Account.AccountDivision__c;
    this.createdDate = order.EffectiveDate;
    this.LastModifiedById=order.LastModifiedById;
    this.LastModifiedByName=order.LastModifiedBy.Name;
   
    //Form
    console.log("RAZCHECK,517, order",order);
    this.orderFormRec = {
      account: {id:  order.AccountId,  name:order.Account.Name,  industry: order.Account.AccountDivision__c, sapType:  order.Account.SAP_Account_Group__c, isSensitive: order.Account.Sensitive_Customer__c},  //industry - דשנים או כימיקלים
      branchGrowth: {id: order.Branch_growth__c  ? order.Branch_growth__c : "",  name: order.Branch_growth__r?.Name ? order.Branch_growth__r.Name : ""},
      intermediaryWarehouse: {id: order.IntermediaryWarehouse__c ? order.IntermediaryWarehouse__c: "", name: order.IntermediaryWarehouse__r?.Name  ? order.IntermediaryWarehouse__r.Name : ""},
      payingCustomer: {id: order.Paying_Customer__c ? order.Paying_Customer__c : "" , name: order.Paying_Customer__r?.Name ? order.Paying_Customer__r.Name : ""},
      agentReceivesCommission: {id: order.AgentReceivesCommission__c ? order.AgentReceivesCommission__c : "", name: order.AgentReceivesCommission__r?.Name  ? order.AgentReceivesCommission__r.Name : ""},
      
      payerApproval: order.Payer_Approval__c ? order.Payer_Approval__c : "",
      cosignationWarehouseApproval: order.CosignationWarehouseApproval__c ? order.CosignationWarehouseApproval__c : "",
     
      passingPermit: order.PassingPermit__c && this.order.TransactionType__c !='70' ? order.PassingPermit__c : "",
      isChemicalAccount:order.Account?.AccountDivision__c === "כימיקלים" ? true : false, // לבדוק אם להשאיר בהזמנת מסגרת
      orderDeliveredBy: (order.Order_Delivered_By__c && this.order.TransactionType__c !='70') || (this.order.TransactionType__c =='70' && this.recordId)? order.Order_Delivered_By__c : "",
      AccountSource: order.Account.AccountSource && this.order.TransactionType__c !='70' ? order.Account.AccountSource : "",
    };
    this.isChemicalAccount = order.Account?.AccountDivision__c == "כימיקלים" && this.order.TransactionType__c!= "40" && this.order.TransactionType__c !='70' ? true : false;
    
    //OrderDateAndTypeRec
    this.orderDateAndTypeRec = {

      orderType: (order.TransactionType__c && this.order.TransactionType__c !='70') || (this.order.TransactionType__c =='70' && this.recordId)? order.TransactionType__c : '30',

      privateTransport:  order.PrivateTransport__c ? order.PrivateTransport__c : false,
      requestedSupplyDate: order.RequestedSupplyDate__c  ? order.RequestedSupplyDate__c : null,
      deliveryNote: {id: order.OriginalDeliveryNote__c && this.order.TransactionType__c !='70' ? order.OriginalDeliveryNote__c: null,name: order.OriginalDeliveryNote__c && this.order.TransactionType__c !='70' ? order?.OriginalDeliveryNote__r?.Name : null},
      responsibility: order.responsibility__c && this.order.TransactionType__c !='70' ? order.responsibility__c : null,
      reasonForReturn: order.reasonForReturn__c && this.order.TransactionType__c !='70' ? order.reasonForReturn__c : null,
      reasonForReturnDescription: order.reasonForReturnDescription__c && this.order.TransactionType__c !='70' ? order.reasonForReturnDescription__c : null};
    //Notes
    this.orderNotesRec = {Description: order?.Description && this.order.TransactionType__c !='70' ? order.Description : "" };
    console.log("RAZCHECK, 567, this.orderNotesRec",this.orderNotesRec);
    //Order Form
    this.order = {
      id:   order.Id,
      AccountId:  order.AccountId ,
      orderNumber: order.OrderNumber ,
      Status: order.Status ? this.getStatusCodeValue(order.Status) : null,
      Branch_growth__c: order.Branch_growth__c ? order.Branch_growth__c : "",
      Paying_Customer__c: order.Paying_Customer__c  ? order.Paying_Customer__c: "",
      AgentReceivesCommission__c: order.AgentReceivesCommission__c  ? order.AgentReceivesCommission__c: "",
      IntermediaryWarehouse__c: order.IntermediaryWarehouse__c ? order.IntermediaryWarehouse__c : "",
      Payer_Approval__c: order.Payer_Approval__c ? order.Payer_Approval__c : "",
      CosignationWarehouseApproval__c: order.CosignationWarehouseApproval__c ? order.CosignationWarehouseApproval__c : "",
      PassingPermit__c: order.PassingPermit__c  ? order.PassingPermit__c : "",
      RequestedSupplyDate__c: order.RequestedSupplyDate__c ? order.RequestedSupplyDate__c : null,
      TransactionType__c: order.TransactionType__c ? order.TransactionType__c : "",
      PrivateTransport__c: order.PrivateTransport__c ,
      Description: order.Description  ? order.Description : "",
      Order_Delivered_By__c: order.Order_Delivered_By__c  ?order.Order_Delivered_By__c : "",

    };
    console.log("order line 488 layout", order);
    // דחיפת הערכים לקומפוננטות HTML אחרי מסאז'
    this.template.querySelector("c-order-form-component").receiveRec(this.orderFormRec);
    this.template.querySelector("c-order-date-type-and-contacts-component").receiveRec(this.orderDateAndTypeRec);
    if (this.isDesktop) {this.template.querySelector("c-order-notes-component").receiveRec(this.orderNotesRec);}
    this.template.querySelector("c-order-form-component").orderTypeHandler(order.TransactionType__c);
    this.getNotes();
    this.getContacts();
    if (this.order.TransactionType__c=='70' && (this.order.Status != 'סגור') && this.order.Status != 'מבוטל' && this.orderDateAndTypeRec.orderType=='70'
    ) {
      console.log("triggerProcessorHandler",this.order.TransactionType__c);
      this.myBooleanVariable=true;
    } else { this.myBooleanVariable=false;}
 }
  //רק עם המוצרים - אותו דבר - מיפוי!-כנ"ל למטה
  arrangeOrderItemValues(item,TransactionType__c) {
    console.log("itemitemitem 564",item);
    if (item.Extension_1__c) {
      this.extensions = [];
      this.extensions.push({Id: item.Extension_1__c,Name: item.Extension_1__r.Name ? item.Extension_1__r.Name : null,quantity: item.Extension_Quantity_1__c? item.Extension_Quantity_1__c: null,unitOfMeasure: item.Extension_Unit_1__c? this.getUnitOfMeasureName(item.Extension_Unit_1__c): null      });
    }
    if (item.Extension_2__c) {
      this.extensions.push({Id: item.Extension_2__c,Name: item.Extension_2__r.Name ? item.Extension_2__r.Name : null,quantity: item.Extension_Quantity_2__c? item.Extension_Quantity_2__c: null,        unitOfMeasure: item.Extension_Unit_2__c? this.getUnitOfMeasureName(item.Extension_Unit_2__c): null      });
    }
    if (item.Extension_3__c) {
      this.extensions.push({ Id: item.Extension_3__c,Name: item.Extension_3__r.Name ? item.Extension_3__r.Name : null,quantity: item.Extension_Quantity_3__c? item.Extension_Quantity_3__c: null,        unitOfMeasure: item.Extension_Unit_3__c? this.getUnitOfMeasureName(item.Extension_Unit_3__c): null      });
    } else if (!item.Extension_1__c) {
      this.extensions = null;
    } 
    const rec = {
      id: item.Id,
      product: { id: item.Product2Id, name: item.Product2.Name },
      OrderId: item.OrderId,
      quantity: item.Quantity,
      originalTransactionType: TransactionType__c,
      unitOfMeasure: this.getUnitOfMeasureName(item?.UnitOfMeasure__c),
      status: item?.Status__c,
      displayStatus: item?.DisplayStatus__c,
      fullArea: false,
      totalPrice: item.TotalPrice,
      dischargeLocation: {id: item.DischargeLocation__c ? item.DischargeLocation__c : null,name: item.DischargeLocation__r?.Name? item.DischargeLocation__r.Name: null},
      loadingPoint: {id: item.LoadingPoint__c ? item.LoadingPoint__c : null,name: item.LoadingPoint__r?.LoadingPointName__c? item.LoadingPoint__r.LoadingPointName__c: null,loadingType: item.LoadingPoint__r?.LoadingPointType__c? item.LoadingPoint__r.LoadingPointType__c: null},
      OrderItemNumber: item?.OrderItemNumber,
      specialPrice: item?.Price_from_customer_order__c,
      transportPrice: item?.DeliveryPrice__c,
      deliveryUnitOfMeasure:this.getDeliveryUnitOfMeasureName(item?.DeliveryUnitOfMeasure__c),
      nonFreightCharge: item?.NonFreightCharge__c,
      refuelingTransport: item?.RefuelingTransport__c,
      combinedPackaging: item?.combined_Packaging__c,
      combinedTransport: item?.combinedTransport__c,
      specialTransport: item?.specialTransport__c,
      customerPackaging: item?.CustomerPackaging__c,
      waitingRequired: item?.WaitingRequired__c,
      craneTransport: item?.CraneTransport__c	,
      Comment__c: item?.Comment__c,
      Purchase_Order__c: item?.Purchase_Order__c? item.Purchase_Order__c: null,
      relatedContactName: item?.RelatedContactName__c,
      relatedContactPhone: item?.RelatedContactPhone__c,
      productSapNumber: item?.Product2?.Sap_Number__c? item.Product2.Sap_Number__c: null,
      prodFamily: item.Product2?.IL_Group__c? item.Product2?.IL_Group__c: null,
      deliveryNoteExist: item?.DeliveryNoteExist__c? item.DeliveryNoteExist__c: null,
      extensions: this.extensions,
      driver: item?.Truck_code__c ? item.Truck_code__c : null,
      supplyDate: item?.DeliveryDate__c ? item.DeliveryDate__c : null,
      orderTypeNew: this.order.TransactionType__c,
      recordId:this.recordId,
      framework_agreement_Usege_Quntity__c:item.framework_agreement_Usege_Quntity__c,
      framedealQuantity__c: (Number(item.Quantity) - Number(item.framework_agreement_Usege_Quntity__c))
    };
    console.log("RAZCHECK, line 622 rec in orderitem",rec);
    
    this.itemsToPopulate.push(rec);
    console.log("RAZCHECK,624,this.itemitemitem",this.itemsToPopulate);
  }
  
  
  renderedCallback() {
    console.log("RAZCHECK,668 , renderedCallback in layount,this.renderOrderItemsCounter",this.renderOrderItemsCounter);
    if(!this.addProductClickedFromExistOrder && this.renderOrderItemsCounter == 1){
      this.renderOrderItems();
    }
    this.addProductClickedFromExistOrder = false;
      console.log("RAZCHECK, renderedCallback in layount");
  }

  disconnectedCallback(){
    console.log("RAZCHECK, disconnectedCallback in layount");
  }

  renderOrderItems() {
    console.log("RAZCHECK,634,ITEM.ID,renderOrderItems,this.recordId  ",this.recordId);
    console.log("RAZCHECK,634,renderOrderItems,this.orderId  ",this.orderId);
    console.log("RAZCHECK,634,renderOrderItems,this.order.orderNumber  ",this.order.orderNumber);
    if (this.recordId || this.orderId) { // רנדר ההזמנה אם בעלית הזמנה קיימת או אם עסקת מסגרת קיימת
      let orderItemsComponents = this.template.querySelectorAll("c-order-item-component");
      console.log("RAZCHECK, 634 637,orderItemsComponents",orderItemsComponents);
      orderItemsComponents.forEach((comp, index) => {
        console.log("RAZCHECK, 634 664,this.orderItems ",JSON.stringify(this.orderItems));
        comp.receiveRec(this.orderItems);});
    }
  }


isExistOrder=false;
  // אם קיים בכל שלב בURL RECORDID - הצג פרטיו לאחר מסאז'
  // קורה רק אחרי שליחת משהו, סוג עסקה לא משפיע כאן
  // קורה בעליית הזמנה 
  @api
  getCurrentOrder(orderAndOrderItemId) {
    console.log( "getCurrentOrder 576",this.recordId);
    this.isExistOrder = true;
    if (orderAndOrderItemId != undefined ) { // אם יש עסקת מסגרת ללקוח ולמוצר
     this.orderId = orderAndOrderItemId?.detail;
    this.OriginOrderItemId = this?.orderId['orderItemId'];
   } 
    getOrderAndOrderItems({ recordId: this.recordId ? this.recordId : this.orderId['orderId']}).then((result) => { // תכלס פה מביא את נתוני ההזמנה הקיימת מהשרת
      console.log("603  getOrderAndOrderItems",result);
        const order = result[0];
        this.arrangeOrderValues(order);
        if (order.hasOwnProperty("OrderItems")) {
          console.log(order,"order 603 INSIDE THE IF!DSDS");
          order.OrderItems.forEach((item, index) => {
            console.log(item,"order 603 INSIDE THE LOOP! whos item");
            // console.log("order.TransactionType__c 648",order[0].TransactionType__c);
            console.log("order.TransactionType__c 648",order.TransactionType__c );

            this.arrangeOrderItemValues(item, order.TransactionType__c);
            console.log("RAZCHECK, this.isOrderLocked = true, 664",this.isOrderLocked);
            console.log("RAZCHECK, item = true, 664",item);
            console.log("RAZCHECK, item.status = true, 664",item.status);
            console.log("RAZCHECK,item.Status__c = true, 664",item.Status__c);
            this.itemStatusForForm = item.Status__c;
            if(item.Status__c !== "10" && item.Status__c !== "20" && item.Status__c !== "70" ){
                this.isOrderLocked = true;
            }
            // if (item.status === "30" || item.status === "40" || item.status === "50") {
            //   console.log("RAZCHECK, this.isOrderLocked = true, 666",this.isOrderLocked);
            //   this.isOrderLocked = true;
            // }
          });
          console.log("RAZCHECK,705,this.itemsToPopulate ",JSON.stringify(this.itemsToPopulate));
          console.log("RAZCHECK,705,this.orderItems ",JSON.stringify(this.orderItems));
          this.orderItems = [...this.itemsToPopulate];
        }
      }).catch((error) => {
        let message = "Unknown error";
        console.log(`001. Error: ${error}`);
        if (Array.isArray(error.body)) {
          message = error.body.map((e) => e.message).join(", ");
        } else if (typeof error?.body?.message === "string") {
          message = error.body.message;
        }
        console.error("627",message);
      });
  }

  connectedCallback() { 
    console.log("RAZCHECK, connectedCallback in layount");
    this.calculateBH();
    this.id = 1;
    this.payingCustomer = null;
    this.getUserProfile();
    if (this.recordId) {
      this.getCurrentOrder();
      console.log("RAZCHECK, connectedCallback in layount inside if");
    } else {
     // this.getDefaultLP();
      //הוסף איבר לתחילת המערך והחזר את אורך המערך
      console.log("RAZCHECK, connectedCallback in layount inside else");
      this.orderItems.unshift({
        id: 1,
        product: { id: null, name: null },
        OrderId: null,
        quantity: null,
        unitOfMeasure: null,
        status: null,
        fullArea: false,
        totalPrice: null,
        dischargeLocation: { id: null, name: null },
        // loadingPoint: { id: this.loadingPointLayout },
        loadingPoint: { id: null, name: null },
        OrderItemNumber: null,
        specialPrice: null,
        transportPrice: null,
        deliveryUnitOfMeasure: null,
        nonFreightCharge: false,
        refuelingTransport: false,
        combinedPackaging: false,
        combinedTransport: false,
        specialTransport: false,
        customerPackaging: false,
        waitingRequired: false,
        craneTransport: false,
        Comment__c: null,
        Purchase_Order__c: null,
        relatedContactName: null,
        relatedContactPhone: null,
        extensions: []
      });
    }
  }
  // הנדלר בפורם - אינפוט בחירת לקוח
  // אינפוט לקוח אוטוקומפליט משתמש בפונקציה זו מלמטה, מפורם, להעברת המידע לכאן בעת בחירת לקוח
  @api
  handleRecordSelect(event) {
    console.log("#######", JSON.stringify(event.detail));
    console.log("#######,716,RAZCHECK,",event.detail.rec.account.id );
    if (event.detail.rec.account.id) { // אם יש אקאונט/אבנט - אכלס. אחרת - תאפס הכל
      // console.log("accSettelment Layout", event.detail.accSettelment);
      this.accountId = event.detail.rec.account.id;
      this.accountName = event.detail.rec.account.name;
      this.branchGrowthId = event.detail.rec.branchGrowth.id;
      this.isChemicalAccount = event.detail.rec.isChemicalAccount;
      this.isChemicals = event.detail.rec.account.industry ==`כימיקלים` && this.order.TransactionType__c!= "40" ? true :false;
      this.industry2=event.detail.rec.account.industry;
      this.getContacts();
      this.getNotes();
      if (event.detail.accSettelment) {
        this.accSettelment = event.detail.accSettelment;}
    } else {
      this.isChemicals=false;
      this.industry2="";
      this.isChemicalAccount = false;
      this.accountId = null;
      this.branchGrowthId = null;
      this.accSettelment = null;
      this.contacts = [];
      this.tankPoints = null;
      this.notes = {Description: "", Regular_note_to_the_driver__c: "",Note_for_discharge__c: ""};
    }
  }
  //
  loadingPointLayout;
  getDefaultLP(){ // Loading Point
    getDefaultLP().then((res) => { 
      this.loadingPointLayout = res;
    }).catch((err) => {console.error(err.body.message);});
  }
  // handle adding order item line component

  //כפתור "הוספת מוצר"
  addProductHandler() {
    console.log("RAZCHECK , 11122233, 833");
    this.renderOrderItemsCounter = 1;
    if(this.order.orderNumber !== "הזמנה חדשה"){
      this.addProductClickedFromExistOrder = true;
      console.log("RAZCHECK, 831, this.addProductClickedFromExistOrder ", this.addProductClickedFromExistOrder);
    }
    this.getDefaultLP();
    this.id++;
    this.orderItems.unshift({
      id: this.id,
      product: { id: null, name: null },
      OrderId: null,
      quantity: null,
      unitOfMeasure: "קוב",
      fullArea: false,
      status: null,
      totalPrice: null,
      dischargeLocation: { id: null, name: null },
      loadingPoint: { id: this.loadingPointLayout },
      OrderItemNumber: null,
      specialPrice: null,
      transportPrice: null,
      deliveryUnitOfMeasure: null,
      nonFreightCharge: false,
      refuelingTransport: false,
      combinedTransport: false,
      specialTransport: false,
      customerPackaging: false,
      waitingRequired: false,
      craneTransport: false,
      Comment__c: null,
      Purchase_Order__c: null,
      relatedContactName: null,
      relatedContactPhone: null,
      extensions: null
    });
  }
  // handle remove order line item component
  // כפתור פח קטן עד בלתי נראה צד שמאל למטה קיצוני
  remove(e) {
    const id = e.detail;
    console.log("RAZCHECK, 812, id",id);
    const newOrderItems = [];
    this.orderItems.forEach((item) => {
      if (id == item.id && item.OrderItemNumber != null && this.recordId) {
        const fields = { Id: item.id, Status__c: "70" };
        const recordInput = { fields };
        updateRecord(recordInput).then(() => {
            this.triggerProcessorHandler(this.order.orderNumber, this.order.id);
            console.log("Order Item Record Canceled Succesfully");
          })
          .catch((err) => {
            console.error("error canceling order item record => ", err);
          });
      }
      if (id != item.id) {
        newOrderItems.push(item);
      }
    });
    this.orderItems = newOrderItems;
  }

  // Handles click on the 'Show/hide previous orders' button
  //כפתור מודל קטן כחול צד שמאל
  handleAsideToggle() {
    this.isButtonClicked = !this.isButtonClicked; //set to true if false, false if true.
    if (this.isButtonClicked) {
      this.offset = 0;
      this.getLastOrders();
    }
  }

  // הוספת איש קשר מקופמפוננטת בן ששמו orderDateAndTypeAndContactsComponent
  handleNewContactAddition(event) {
    const fields = event.detail;
    const contact = new Object();
    contact.Id = fields.Id;
    contact.Name = fields.Name;
    contact.Phone = fields.Phone;
    contact.MobilePhone = fields.MobilePhone;
    contact.Email = fields.Email;
    this.contacts.unshift(contact);
  }

  //שימוש בכפתור ניקוי שדות ובפונקציית אינאיט לניקוי כל השדות
  cleanScreenFields() {
    console.log("RAZCHECK , 11122233, 918");
    this.renderOrderItemsCounter = 1;
    console.log("RAZCHECK, this.orderItems, 834, ",JSON.stringify(this.orderItems));
    console.log("RAZCHECK, this.orderItems,this.orderItemsToCreate, 834, ",JSON.stringify(this.orderItemsToCreate));
    console.log("cleanScreenFields 788");
    this.isChemicalAccount = false;
    this.isChemicals = false;
    this.industry2="";
    this.itemsToPopulate = [];
    // this.orderItems = [];
    // this.orderItemsToCreate = [];
    // this.orderItemsToUpdate = [];
    this.initObjects();
    this.template.querySelector("c-order-form-component").clearScreen();
    this.template.querySelector("c-order-item-component").clearScreen();
    this.template.querySelector("c-order-date-type-and-contacts-component").clearScreen();
    this.template.querySelectorAll("c-order-date-type-and-contacts-component").forEach((comp)=>{
      comp.clearScreen();
    })
    console.log("RAZCHECK, this.orderItems, 862, ",JSON.stringify(this.orderItems));
    
    // this.order.RequestedSupplyDate__c = "";
    // this.order.TransactionType__c = "";
    // this.order.PrivateTransport__c = "";
    // this.order.DeliveryNote__c = "";
    // this.order.responsibility__c = "";
    // this.order.reasonForReturn__c = "";
    // this.order.reasonForReturnDescription__c ="";

    if (this.isDesktop) {
      this.template.querySelector("c-order-notes-component").clearScreen();
    }

    this.id = 1;
    this.orderItems = [
      {
        id: 1,
        product: { id: null, name: null },
        OrderId: null,
        quantity: null,
        unitOfMeasure: null,
        fullArea: false,
        status: null,
        totalPrice: null,
        dischargeLocation: { id: null, name: null },
        loadingPoint: { id: null, name: null },
        OrderItemNumber: null,
        specialPrice: null,
        transportPrice: null,
        deliveryUnitOfMeasure: null,
        nonFreightCharge: false,
        refuelingTransport: false,
        combinedTransport: false,
        specialTransport: false,
        customerPackaging: false,
        waitingRequired: false,
        craneTransport: false,
        Comment__c: null,
        Purchase_Order__c: null,
        relatedContactName: null,
        relatedContactPhone: null,
        extensions: null,
                          //          driver: null,
                          //  supplyDate: null,
                          //  orderType: null,
                          //  OriginOrderItemId__c:null

      }
    ];
    this.orderItemsToCreate = [];
    console.log("RAZCHECK, this.orderItems, 894, ",JSON.stringify(this.orderItems));
  }

  // handlers for submitting components fields
  // - רלוונטי ל4 ההנדלרים הבאים הנדלרים עבור כל הקומפוננטות ילדים שלו! וואנס יש סבמיט - נורה אבנט עבור כל אחת מהן!
  @api
  handleOrderFormValues(event) {
    const rec = event.detail.rec;
    console.log("RAZCHECK, 997 , rec layout 892",JSON.stringify(rec));
    this.order.AccountId = rec.account.id;
    this.order.Branch_growth__c = rec.branchGrowth.id;
    this.order.Paying_Customer__c = rec.payingCustomer.id;
    this.order.AgentReceivesCommission__c = rec.agentReceivesCommission.id;
    this.order.IntermediaryWarehouse__c = rec.intermediaryWarehouse.id;
    this.order.Payer_Approval__c = rec.payerApproval;
    this.order.CosignationWarehouseApproval__c = rec.cosignationWarehouseApproval;
    this.order.PassingPermit__c = rec.passingPermit;
    this.order.Order_Delivered_By__c = rec.orderDeliveredBy;
    console.log("RAZCHECK, 997 , rec layout 892  this.order.Order_Delivered_By__c", this.order.Order_Delivered_By__c);

  }
  handleOrderFormRemovedCustomer(event) {
    this.orderItems.dischargeLocation= { id: null, name: null };
    this.tankPoints = [];
    this.template.querySelector("c-order-item-component").updateTankPoints(null, null);
    

  }

  handleOrderDateTypeTransportValues(event) {
    const rec = event.detail.rec;
    console.log(rec,"866",JSON.stringify(rec));
    this.order.RequestedSupplyDate__c = rec.requestedSupplyDate;
    this.order.TransactionType__c = rec.orderType;
    this.order.PrivateTransport__c = rec.privateTransport;
    this.order.DeliveryNote__c = rec.deliveryNote.id;
    this.order.responsibility__c = rec.responsibility;
    this.order.reasonForReturn__c = rec.reasonForReturn;
    this.order.reasonForReturnDescription__c = rec.reasonForReturnDescription;
    console.log(this.order.reasonForReturnDescription__c,"873");
  }


  handleOrderNotesValues(event) {
    console.log("RAZCHECK, handleOrderNotesValues 1013 notes",JSON.stringify(event.detail));
    console.log("RAZCHECK, handleOrderNotesValues 1013 Description",JSON.stringify(event?.detail?.rec?.Description));
    const rec = event.detail.rec;
    this.order.Description = rec.generalOrderNote;

      updateAccountDescription({ accountId: this.order.AccountId, newDescription: event?.detail?.rec?.Description })
          .then(() => {
            console.log("RAZCHECK, handleOrderNotesValues 1013 Description  Record updated successfully ");
          })
          .catch(error => {
            console.error("RAZCHECK, 1024, updateAccountDescription ERROR",error);
          });
  
  }
  handleOrderItemsValues(event) {
    const rec = event.detail.rec;
    console.log("rec line 1036 rec:", JSON.stringify(rec));
    console.log("rec line 1037 rec.id:", rec.id);
    console.log("rec line 1038 this.recordId:", this.recordId);
    const extensions = event.detail.extensions;

    let newItem = { ...this.item };
    console.log("RAZCHECK, 962,item.id, ",newItem.id);

    newItem.id = this.recordId && rec.id ? rec.id : null;
    newItem.OrderId = this.recordId && rec.OrderId ? rec.OrderId : null;
    newItem.OrderItemNumber = this.recordId && rec.OrderItemNumber ? rec.OrderItemNumber : null;
    newItem.Product2Id = rec.product.id;
    newItem.Quantity = rec.quantity;
    newItem.UnitOfMeasure__c = rec.unitOfMeasure;
    newItem.TotalPrice = rec.totalPrice;
    newItem.DischargeLocation__c = rec.dischargeLocation.id;
    newItem.Description = rec.Comment__c;
    newItem.RefuelingTransport__c = rec.refuelingTransport;
    newItem.combined_Packaging__c = rec.combinedPackaging;
    newItem.combinedTransport__c = rec.combinedTransport;
    newItem.specialTransport__c = rec.specialTransport;
    newItem.CraneTransport__c = rec.craneTransport;
    newItem.CustomerPackaging__c = rec.customerPackaging;
    newItem.WaitingRequired__c = rec.waitingRequired;
    newItem.NonFreightCharge__c = rec.nonFreightCharge;
    newItem.LoadingPoint__c = rec.loadingPoint.id;
    newItem.Purchase_Order__c = rec.Purchase_Order__c;
    newItem.Price_from_customer_order__c = rec.specialPrice;
    newItem.DeliveryPrice__c = rec.transportPrice;
    newItem.DeliveryUnitOfMeasure__c = rec.deliveryUnitOfMeasure;
    newItem.relatedContactName = rec.relatedContactName;
    newItem.relatedContactPhone = rec.relatedContactPhone;
    newItem.Crystallization_temperature__c = rec.Crystallization_temperature__c;
    newItem.OriginOrderItemId__c=rec.OriginOrderItemId__c;

    if (extensions.Extension_1__c) {
      console.log("873",extensions.Extension_1__c,extensions.Extension_Unit_1__c);
      newItem.Extension_1__c = extensions.Extension_1__c;
      newItem.Extension_Quantity_1__c = extensions.Extension_Quantity_1__c;
      newItem.Extension_Unit_1__c = extensions.Extension_Unit_1__c;
    }
    if (extensions.Extension_2__c) {
      newItem.Extension_2__c = extensions.Extension_2__c;
      newItem.Extension_Quantity_2__c = extensions.Extension_Quantity_2__c;
      newItem.Extension_Unit_2__c = extensions.Extension_Unit_2__c;
    }
    if (extensions.Extension_3__c) {
      newItem.Extension_3__c = extensions.Extension_3__c;
      newItem.Extension_Quantity_3__c = extensions.Extension_Quantity_3__c;
      newItem.Extension_Unit_3__c = extensions.Extension_Unit_3__c;
    }
    // orderItem יכול להיות כמה כאלה לכן נדחף למערך
    // קורה הפוך - אפדייט ביצירה והפוך
    if (!this.recordId) {
      this.orderItemsToCreate.push(newItem);
      console.log(JSON.stringify(this.orderItemsToUpdate),"orderItemsToCreate");
    } else {
      this.orderItemsToUpdate.push(newItem);
      console.log(JSON.stringify(this.orderItemsToUpdate), "orderItemsToUpdate");
    }
  }
  // orderDateTypeContact, מעביר מספר סוג עסקה, למשל 60 -הנדלר שנורה מקומפוננטת בן   -
  orderTypeListener(event) {
    console.log("orderTypeListener:",JSON.stringify(event.details));
    this.order.TransactionType__c = null;
   this.order.TransactionType__c = event.detail;

    if ((event.detail != "40" && this.industry2=="כימיקלים") ){
     this.isChemicals = true ;
   } else {
     this.isChemicals = false;
    }
    if (this.order.TransactionType__c == 60) { // שיוך
      console.log("accountName:",this.accountName);
      this.accountName = ``;
    }
    this.template.querySelector("c-order-form-component").orderTypeHandler(event.detail);
    this.template.querySelector("c-order-item-component").orderTypeHandler(event.detail);
  }
  // translate statusCode to value
  // מצב מוצר הזמנה - orderItem
  getOrderItemStatusCodeValue(code) {
    if (code == "" || code == undefined || code == null) {  return null;}
    if (code == "10") { return "טיוטה";}
    if (code == "15") {return "לא מאושר Credit";}
    if (code == "20") {return "מוכן לשיבוץ";}
    if (code == "30") {return "שובץ";}
    if (code == "40") {return "סגור";}
    if (code == "50") {return "מבוטל";
  } else return code;
  }
  // translate statusCode to value
  // מצב הזמנה - טיוטה למשל, הדר עליון מימין
  getStatusCodeValue(code) {
    if (code == "" || code == undefined || code == null) {return null;}
    if (code == "10") {return "טיוטה";}
      if (code == "15") {return "לא מאושר Credit";}
    if (code == "20") {return "לא מאושר SAP";}
    if (code == "30") {return "מאושר";}
    if (code == "40") {return "בתהליך";}
    if (code == "50") {return "סגור";} 
    if (code == "60") {return "מבוטל";
    } else return code;
  }
  //
  // translate unitOfMeasure code to name or the opssite
  // ההיפך מהתחתון. אם שלחתי ללילך
  getUnitOfMeasureCode(unitOfMeasure) {
    if (unitOfMeasure == "קוב") {return "M3";}
    if (unitOfMeasure == "ליטר") {return "LTR";}
    if (unitOfMeasure == "טון") {return "TO";}
    if (unitOfMeasure == "קילו") {return "KG";}
    if (unitOfMeasure == "יחידה") {return "EA";
    } else return null;
  }
  // ההיפך מהקודם. אם קיבלתי מלילך
  getUnitOfMeasureName(unitOfMeasureCode) {
    console.log("unitOfMeasureCode",unitOfMeasureCode);
    if (unitOfMeasureCode == "" || unitOfMeasureCode == undefined || unitOfMeasureCode == null) {return null;} 
    if (unitOfMeasureCode == "M3") {return "קוב";}
    if (unitOfMeasureCode == "LTR") {return "ליטר";}
    if (unitOfMeasureCode == "TO") {return "טון";}
    if (unitOfMeasureCode == "KG") {return "קילו";}
    if (unitOfMeasureCode == "EA") {return "יחידה";
    } else return unitOfMeasureCode;
  }

  getDeliveryUnitOfMeasureName(unitOfMeasureCode) {
    console.log("RAZCHECK, 1111, getDeliveryUnitOfMeasureName",unitOfMeasureCode);
    if (unitOfMeasureCode == "" || unitOfMeasureCode == undefined || unitOfMeasureCode == null) {return null;} 
    if (unitOfMeasureCode == "TO") {return "TO";}
    if (unitOfMeasureCode == "M3") {return "M3";}
    if (unitOfMeasureCode == "Truck") {return "Truck";}
    else return unitOfMeasureCode;
  }

  // enableSaveBtn(){
  //   setTimeout(function() {
  //     this.isSaveBtnClickedValue = false; // Set the value to false after 5 seconds
  //   }, 5000);
  // }

  //בלחיצת כפתור עדכון/שליחת הזמנה - מתבצע מאחורי הקלעים= עובר על כל הקומפ' ועושה ולידציה
  validate() {
    console.log("RAZCHECK , 11122233, 1190");
    this.renderOrderItemsCounter = 1;
    // debugger;
    this.isSaveBtnClickedValue = true;
    setTimeout(() => {
      this.isSaveBtnClickedValue = false;
    }, 2000);
      try {
        this.template.querySelector("c-order-form-component").validateFields();
        this.template.querySelector("c-order-date-type-and-contacts-component").validateFields();
        this.template.querySelectorAll("c-order-item-component").forEach((comp) => {
          const tt = JSON.stringify(this.orderItems);
          const parse = JSON.parse(tt);
          const orderItem_status = parse[0]["status"];
          console.log("parse",orderItem_status);
          // 15.3 הוספתי מסגרת
          if(orderItem_status=="10" || orderItem_status=="20" || orderItem_status=="70" || orderItem_status==null || orderItem_status==undefined){ // אם סטטוס של אורדר אייטם כחלק מההזמנה הוא טיוטה או ממתין לשיבוץ
            comp.validateFields(); //CHECK
          }
          });
        //מתחת פה
        this.handleSaveOrder();
    } catch (error) {
      console.log("979",error);
      this.dispatchEvent(new ShowToastEvent({title: "שגיאה ביצירת הזמנה",message: error,variant: "error"}));
    }
  }
  // save or update order onclick function
  // ולידציה --> submit --> create/update/delete in failure
  handleSaveOrder() {
    try {
      console.log("RAZCHECK, 1106 , this.recordID", this.recordId);
      this.submitComponents();
      if (this.recordId) {
        this.renderOrderItemsCounter++;
        this.updateOrder();
      } else {
        this.createOrder();
      }
    } catch (error) {
      if (!this.recordId) {
        deleteRecord(this.order.id).then(() => {
          console.log("994",error);
          this.dispatchEvent(new ShowToastEvent({title: "שגיאה ביצירת הזמנה",message: error.body.message,variant: "error"}));
        });
      } else {
        this.dispatchEvent(new ShowToastEvent({title: "שגיאה בעדכון הזמנה",message: error.body.message,variant: "error"}));
      }
    }
  }
  //
  submitComponents() {
    console.log("submitComponents layout 1042 hara");
    try {
      this.template.querySelector("c-order-form-component").submitFields();
      this.template.querySelector("c-order-date-type-and-contacts-component").submitFields();
      if (this.isDesktop) { //אם גרסת דסקטופ - ולידייט נוטס קומפ'
        this.template.querySelector("c-order-notes-component").submitFields();
      }
      console.log("recordId",this.recordId);
      if (!this.recordId) { this.orderItemsToCreate = [];
      } else { this.orderItemsToUpdate = [];
      }
      this.template.querySelectorAll("c-order-item-component").forEach((orderItemComponent) => {
          orderItemComponent.submitFields();
          orderItemComponent.clearScreen();
          
        });
//         this.clearScreen(); // עושה קצר - מקפיץ הודעת שגיאה "שגיאה ביצירת הזמנה"
// ניסיון ניקוי שדה מוצר - מקצר את התילך בעיקר בשיוך
    } catch (err) {
      this.dispatchEvent(new ShowToastEvent({title: "שגיאה ביצירה או עדכון הזמנה",message: err,variant: "error"}));
    }
  }
  //
  orderNumber;
  // new order
  createOrder() {
    console.log("createOrder 1066 hara",JSON.stringify(this.order));
    const fields = {
      Pricebook2Id: "01s4K0000017MZ1QAM",
      EffectiveDate: new Date(),
      AccountId: this.order.AccountId,
      Status: "10",
      CurrencyIsoCode: this.defaultCurrencyIsoCode,
      Branch_growth__c: this.order.Branch_growth__c ? this.order.Branch_growth__c : null,
      Paying_Customer__c: this.order.Paying_Customer__c,
      AgentReceivesCommission__c: this.order.AgentReceivesCommission__c,
      IntermediaryWarehouse__c: this.order.IntermediaryWarehouse__c,
      Payer_Approval__c: this.order.Payer_Approval__c,
      CosignationWarehouseApproval__c: this.order.CosignationWarehouseApproval__c,
      PassingPermit__c: this.order.PassingPermit__c,
      RequestedSupplyDate__c: this.order.RequestedSupplyDate__c,
      TransactionType__c: this.order.TransactionType__c,
      OriginalDeliveryNote__c: this.order.DeliveryNote__c,
      responsibility__c: this.order.responsibility__c,
      reasonForReturn__c: this.order.reasonForReturn__c,
      reasonForReturnDescription__c: this.order.reasonForReturnDescription__c,
      PrivateTransport__c: this.order.PrivateTransport__c,
      Description: this.order.Description,
      Order_Delivered_By__c: this.order.Order_Delivered_By__c,
    };
    const recordInput = { apiName: "Order", fields: fields };
    console.log("recordInput",recordInput);
    console.log("fields to create: ", fields);
    createRecord(recordInput).then((order) => {
        console.log("new order created: ", order);
        try {
          this.order.id = order.id; // קשור לעסקת מסגרת
          this.orderNumber = order.fields.OrderNumber.value;
          try {
            this.orderItemsToCreate.forEach((item, index, array) => {
              if (!item.Product2Id) { 
                throw "no product selected"; 
              }
              this.getPricebookEntryId(item.Product2Id).then((result) => {
                console.log("getPricebookEntryId",result);
                this.createOrderItem(item,index,array,order.id,result[0].Id); });
            });
          } catch (err) {
            console.log("Error create order inside promise: ", err);
            throw new Error(err);
          } finally {
            this.template.querySelectorAll("c-order-item-component").forEach((orderItemComponent) => {
                orderItemComponent.submitDiscount();});
            // this.triggerProcessorHandler(order.fields.OrderNumber.value);
            // this.dispatchEvent(new ShowToastEvent({title: "הצלחה!",message: "הזמנה מספר: " + this.orderNumber + " נוספה בהצלחה!",variant: "success"}));
            this.cleanScreenFields();
          }
        } catch (error) {
          console.log("1110",error);
          this.dispatchEvent( new ShowToastEvent({ title: "שגיאה ביצירת הזמנה", message: error.body.message, variant: "error"}));
          deleteRecord(this.order.id).then(() => {console.log("Draft order deleted");}).catch((err) => {
              console.error(err);
            });
        }
      }).catch((error) => {
        console.log("1124",error);
        this.dispatchEvent(new ShowToastEvent({title: "שגיאה ביצירת הזמנה",message: error.body.message,variant: "error"}));
      });
  }
  //  Create New Order Items
  createOrderItem(item, index, array, orderId, pricebookEntryId) {
    // console.log("createOrderItem: ", JSON.stringify(item), orderId);
    console.log("RAZCHECK, 1213,createOrderItem(item) ", JSON.stringify(item));
    const fields = {
      OrderId: orderId,
      PricebookEntryId: pricebookEntryId,
      Product2Id: item.Product2Id,
      Status__c: this.order.Status == "מאושר" ? "20" : "10",
      Quantity: item.Quantity,
      UnitOfMeasure__c: Utils.getUnitOfMeasureCode(item.UnitOfMeasure__c),
      UnitPrice: 0,
      DischargeLocation__c: item.DischargeLocation__c,
      Comment__c: item.Description,
      NonFreightCharge__c: item.NonFreightCharge__c,
      RefuelingTransport__c: item.RefuelingTransport__c,
      combined_Packaging__c: item.combined_Packaging__c,
      combinedTransport__c: item.combinedTransport__c,
      specialTransport__c: item.specialTransport__c,
      CraneTransport__c: item.CraneTransport__c,
      CustomerPackaging__c: item.CustomerPackaging__c,
      WaitingRequired__c: item.WaitingRequired__c,
      LoadingPoint__c: item.LoadingPoint__c,
      Extension_1__c: item.Extension_1__c,
      Extension_2__c: item.Extension_2__c,
      Extension_3__c: item.Extension_3__c,
      Extension_Quantity_1__c: item.Extension_Quantity_1__c,
      Extension_Quantity_2__c: item.Extension_Quantity_2__c,
      Extension_Quantity_3__c: item.Extension_Quantity_3__c,
      Extension_Unit_1__c: Utils.getUnitOfMeasureCode(item.Extension_Unit_1__c),
      Extension_Unit_2__c: Utils.getUnitOfMeasureCode(item.Extension_Unit_2__c),
      Extension_Unit_3__c: Utils.getUnitOfMeasureCode(item.Extension_Unit_3__c),
      Purchase_Order__c: item.Purchase_Order__c,
      // "OriginalOrderItemId": this.originalOrderItemId ? this.originalOrderItemId : '',
      Price_from_customer_order__c: item?.Price_from_customer_order__c,
      DeliveryPrice__c: item?.DeliveryPrice__c,
      DeliveryUnitOfMeasure__c: item?.DeliveryUnitOfMeasure__c,
      RelatedContactName__c: item?.relatedContactName,
      RelatedContactPhone__c: item?.relatedContactPhone,
      // OriginOrderItemId__c:item.OriginOrderItemId__c,
      OriginOrderItemId__c: this?.OriginOrderItemId,
      // CraneTransport__c:item?.specialTransport__c=="הובלת מנוף"? true : false,
    };
    console.log("RAZCHECK, 1249,createOrderItem(item) ", JSON.stringify(item));
    console.log("RAZCHECK, 1249,createOrderItem(item.loadingPoint) ", item.LoadingPoint__c);

    const recordInput = { apiName: "OrderItem", fields };
    console.log("fields 1198: ", fields);    
    // פונקציה שמורה של הספריה ליצירת רשומה חדשה - בתוך פונקצית יצירת מוצר
    
    createRecord(recordInput).then((res) => {
        console.log("new item created: ", res);
        if (index === array.length - 1) {
          this.triggerProcessorHandler(this.order.orderNumber, orderId); 
          // חיווי ללילך/לבקאנד שנוצר אובייקט חדש
        }
      }).catch((error) => {
        console.log("1178",error);
        console.log("1178 catch error this.recordId",this.recordId);
        this.dispatchEvent(new ShowToastEvent({title: "שגיאה ביצירת הזמנה",message: error,variant: "error"}));
        if (!this.recordId) {
          console.log("1178 catch error this.order.id",this.order.id);
          deleteRecord(this.order.id).then(() => {
              console.log("Draft order deleted");
            }).catch((err) => {
              console.error(err,"Layout, 1213 createOrderItem");
            });
        }
      });
  }
  // update order- עדכון הזמנה קיימת
  updateOrder() {
    console.log("updateOrder 1209 hara");
    console.log("RAZCHECK, 1428 ,this.order.PrivateTransport__c ", this.order.PrivateTransport__c);
    const fields = {
      Id: this.order.id,
      Pricebook2Id: "01s4K0000017MZ1QAM",
      AccountId: this.order.AccountId,
      CurrencyIsoCode: this.defaultCurrencyIsoCode,
      Branch_growth__c: this.order.Branch_growth__c ? this.order.Branch_growth__c : null,
      Paying_Customer__c: this.order.Paying_Customer__c,
      AgentReceivesCommission__c: this.order.AgentReceivesCommission__c,
      IntermediaryWarehouse__c: this.order.IntermediaryWarehouse__c,
      Payer_Approval__c: this.order.Payer_Approval__c,
      CosignationWarehouseApproval__c: this.order.CosignationWarehouseApproval__c,
      PassingPermit__c: this.order.PassingPermit__c,
      RequestedSupplyDate__c: this.order.RequestedSupplyDate__c,
      TransactionType__c: this.order.TransactionType__c,
      OriginalDeliveryNote__c: this.order.DeliveryNote__c,
      responsibility__c: this.order.responsibility__c,
      reasonForReturn__c: this.order.reasonForReturn__c,
      reasonForReturnDescription__c: this.order.reasonForReturnDescription__c,
      Description: this.order.Description,
      Order_Delivered_By__c: this.order.Order_Delivered_By__c,
      PrivateTransport__c: this.order.PrivateTransport__c
    };
    console.log("RAZCHECK, 1428 ,updateOrder fields ", JSON.stringify(fields));
    console.log("RAZCHECK, 1428 ,this.order.PrivateTransport__c ", this.order.PrivateTransport__c);
    // אם מנהל מכירות כימיקלים טרוטי - העבר את האוביקט הזה, אחרת כל ישות בדשנים. ההבדל? רק ברנצ'!
    // אך ורק למנהל מכירות כימיקלים אין הרשאה לצפות/לשלוח שדה ברנץ'! לכל השאר אפשר לשלוח נול
    
   // const recordInput = { fields: this.isSalesManagerChemicals ? salesManagerChemicalsFields : fields };
    //const recordInput = { apiName: "Order", fields: fields };
    const recordInput = {  fields: fields };


    updateRecord(recordInput).then(() => {
        console.log("order number: " + this.order.orderNumber + " updated successfully! ");
        try {
          this.orderItemsToUpdate.forEach((item, index, array) => {
            console.log("RAZCHECK, 1439,item.OrderItemNumber  array ",JSON.stringify(array));
            if (item.OrderItemNumber) {
              console.log("RAZCHECK, 1439,item.OrderItemNumber if ");
              this.updateOrderItem(item, index, array);
            } else {
              console.log("RAZCHECK, 1439,item.OrderItemNumber else ");

              this.getPricebookEntryId(item.Product2Id).then((result) => {
                  this.createOrderItem(item,index,array,this.order.id,result[0].Id);}).then(() => {
                    console.log("item inside loop of orderItem",item);
                  this.template.querySelectorAll("c-order-item-component").forEach((comp) => {
                      comp.clearAfterUpdate();
                    }).then(() => {
                      this.orderItems = [];
                      this.id = 1;
                      this.renderOrderItemsCounter = 1;
                      console.log("RAZCHECK , 11122233, 1450");
                    });
                });
            }
          });
        } catch (error) {
          console.error(error);
          this.dispatchEvent(new ShowToastEvent({title: "שגיאה בעדכון הזמנה",message: error.body.message,variant: "error"}));
        } finally {
          // this.orderItems = this.orderItemsToUpdate;
          // this.template.querySelectorAll('c-order-item-component').forEach(comp => {
          //     comp.clearAfterUpdate();
          // }).then(()=>{
          //     this.orderItems = [];
          //     this.id = 1;
          //     this.getCurrentOrder();
          // });
          console.log("RAZCHECK , 11122233, 1477");

          this.template.querySelectorAll("c-order-item-component").forEach((orderItemComponent) => {
              orderItemComponent.submitDiscount();
            });
          this.getCurrentOrder();

        }
        
      }).catch((error) => {
        this.dispatchEvent(new ShowToastEvent({title: "שגיאה בעדכון הזמנה",message: error.body.message,variant: "error"}));
      });
  }
  //

  //  Update Order Items
  updateOrderItem(item, index, array) {
    console.log("updateOrderItem: ", JSON.stringify(item));
    console.log("RAZCHECK, 1344,item.id, ",item.id);
    const fields = {
      Id: item.id,
      Quantity: item.Quantity, //כמות
      UnitOfMeasure__c: Utils.getUnitOfMeasureCode(item.UnitOfMeasure__c), //יחידת מידה
      UnitPrice: 0,
      DischargeLocation__c: item.DischargeLocation__c, //מקום פריקה
      Comment__c: item.Description,
      NonFreightCharge__c: item.NonFreightCharge__c, //ללא חיוב הובלה
      RefuelingTransport__c: item.RefuelingTransport__c, //הובלת תדלוק
      combined_Packaging__c: item.combined_Packaging__c, // אריזה משולבת
      combinedTransport__c: item.combinedTransport__c, // הובלה משולבת
      specialTransport__c: item.specialTransport__c, // מיוחדת
      CustomerPackaging__c: item.CustomerPackaging__c, // אריזת לקוח
      WaitingRequired__c: item.WaitingRequired__c, // נדרשת המתנה
      CraneTransport__c: item.CraneTransport__c, // הובלת מנוף
      LoadingPoint__c: item.LoadingPoint__c, //נק' מכירה/העמסה
      Extension_Quantity_1__c: item.Extension_Quantity_1__c, //תוספים
      Extension_Quantity_2__c: item.Extension_Quantity_2__c, //תוספים
      Extension_Quantity_3__c: item.Extension_Quantity_3__c, //תוספים
      Extension_Unit_1__c: Utils.getUnitOfMeasureCode(item.Extension_Unit_1__c), //תוספים
      Extension_Unit_2__c: Utils.getUnitOfMeasureCode(item.Extension_Unit_2__c), //תוספים
      Extension_Unit_3__c: Utils.getUnitOfMeasureCode(item.Extension_Unit_3__c), //תוספים
      Purchase_Order__c: item.Purchase_Order__c, //מספר הזמנה להזמנות צד ג' - אם אין מהסאפ - נופלת ההזמנה לא מאושר סאפ
      Price_from_customer_order__c: item.Price_from_customer_order__c, //מחיר מיוחד - כימיקלים
      DeliveryPrice__c: item.DeliveryPrice__c, //מחיר הובלה - כימיקלים
      DeliveryUnitOfMeasure__c: item.DeliveryUnitOfMeasure__c, //יחידת מידה הובלה - כימיקלים
      RelatedContactName__c: item.relatedContactName, //איש קשר למקום פריקה - שם
      RelatedContactPhone__c: item.relatedContactPhone //איש קשר למקום פריקה - טלפון
    };

    const recordInput = { fields };
    //פונ' בילד אין!
    updateRecord(recordInput).then((res) => {
        console.log("item updated: ", res);
        if (index === array.length - 1) {
          //טריגר ללילך שעדכון המוצר האחרון הסתיים
          this.triggerProcessorHandler(this.order.orderNumber, this.order.id);
        }
      }).catch((error) => {
        console.error("Error updateOrderItem: ", error);
        this.dispatchEvent(new ShowToastEvent({title: "שגיאה בעדכון הזמנה",message: error.body.message,variant: "error"}));
      });
  }
  //

  // getPricebookEntryId of product, needed to create orderitem - נטו קריאת שרת להבאת מחירון של מוצר, חובה כדי לשמור מוצר חדש עבור הזמנה
  async getPricebookEntryId(product2Id) {
    return new Promise(async (resolve, reject) => {
      const pricebookEntryId = await getPricebookEntryId({ productId: product2Id });
      resolve(pricebookEntryId);
    }).catch((error) => {
      console.error(error.body.message);
    });
  }
  //

  // Trigger to backend that had been changes. חיווי ללילך - יצרתי הזמנה!
  triggerProcessorHandler(orderNumber, orderId) {
    if(orderId && orderNumber != "הזמנה חדשה"){
      console.log("RAZCHECK,1487","orderNumber:",orderNumber, "orderId:",orderId);
        this.itemsToPopulate = [];
        this.getCurrentOrder();
        // this.renderedCallback();
    }
    console.log("001 triggerProcessorHandler","orderNumber",orderNumber, "orderId",orderId);
    console.log("001 triggerProcessorHandler","orderId",this.orderId);
    if (orderId) {
      const fields = { Id: orderId, triggerProcessor__c: true };
      console.log("002 triggerProcessorHandler fields",fields);
      const recordInput = { fields };
      console.log("003 triggerProcessorHandler recordInput",recordInput);

      const orderNum = orderNumber != "הזמנה חדשה" ? orderNumber : this.orderNumber;
      console.log("004 triggerProcessorHandler orderNum",orderNum);

      updateRecord(recordInput).then(() => {
        // this.itemsToPopulate = [];
        console.log("005 triggerProcessorHandler recordInput",recordInput);
        this.dispatchEvent(new ShowToastEvent({title: "הצלחה!",message: "הזמנה מספר: " + orderNum + " עודכנה בהצלחה!",variant: "success"}));
        this.renderOrderItems();
          if (!this.isDesktop) {
            window.scrollTo(0, 0);
          }
          // this.getCurrentOrder();
          // this.renderedCallback();
        }).catch((error) => {console.error("Error triggerProcessorHandler: " + JSON.stringify(error));
        });
    } else{
      try {        
        const fields = { Id: this.recordId, triggerProcessor__c: true,SapValidationsPerformed__c :false };
        const recordInput = { fields };
        updateRecord(recordInput).then(() => {
          console.log("005 triggerProcessorHandler recordInput sap btn",recordInput);
          this.dispatchEvent(new ShowToastEvent({title: "הצלחה!",message: " ההזמנה נשלחה לאישור בהצלחה!",variant: "success"}));
          this.renderOrderItems();
        })
      } catch (error) {
      console.error("Error triggerProcessorHandler SAP BUTTON: " + JSON.stringify(error));
      }

    }
  }

  calculateBH() {
    // console.log("37",this.rec.requestedSupplyDate);
    calculateBH({ requestedDate: this.today }).then(result => {
      // console.log("calculateBH results:",JSON.stringify(result));
      // this.twoDaysAhead=result;
      console.log("RAZCHECK,calculateBH, 1512, result",result);
      this.twoDaysAhead = result;
      console.log("RAZCHECK,this.twoDaysAhead , 1512, ",this.twoDaysAhead );
    }).catch(error=>console.log("calculateBH error:",error));
    // const myCurrentDate = new Date();
    // const myFutureDate = new Date(myCurrentDate);
    // myFutureDate.setDate(myFutureDate.getDate() + 2); //myFutureDate is now 2 days in the future
    // return myFutureDate.toISOString();
  }

  // onclick function duplicate Order Handler
  duplicateOrderHandler() {
    console.log("RAZCHECK , 11122233, 1601");
    this.renderOrderItemsCounter = 1;
    console.log("RAZCHECK, 1460,duplicateOrderHandler ");
    console.log("RAZCHECK, 1480 ,orderDateAndTypeRec ",this.orderDateAndTypeRec);
    this.recordId = null;
    //שומר המשתנים ובסוף השמה מחדש, כי תיכף יאפס
    let accountId = this.accountId;
    let accountName = this.accountName;
    //הנה מאפס את כל המשתנים
    this.initObjects();
    //מאפס שדות אישור הזמנה ואישור מעבר
    //הפונקציה ממוקמת בקומפוננטה
    this.template.querySelector(`c-order-form-component`).initApprovels();
    this.id = 1; //id=counter
    try {
      this.orderItems.forEach((item, index) => {
        console.log("RAZCHECK, 1473, duplicateOrderHandler item in loop",JSON.stringify(item));
        // console.log("duplicateOrderHandler item in loop",item.dischargeLocation.name);
        // console.log("duplicateOrderHandler item in loop",item.dischargeLocation);
        // item.dischargeLocation.name = "";
        // item.dischargeLocation.id = "";
        // רץ בלופ על מערך כלל המוצרים להזמנה זו
        console.log("RAZCHECK, item.ststus, 1501,",item.status);
        if(item.status != "70"){
          item.status = null;
          const newItem = {...item,id: this.id,OrderId: null,OrderItemNumber: null}; //מאחסן בא' את כל האוביקט הנוכחי ואידי חדש - קאונטר
          this.id++;
        }
        // this.template.querySelectorAll(`c-order-item-component`).forEach(comp => {
        //     if (comp.itemId == item.id) {
        //         comp.populateOrderItemRecord(newItem, item.id);
        //     }
        // })
      });

    } catch (err) {
      console.error("Error duplicateOrderHandler: ", err);
    } finally {
      this.accountId = accountId;
      this.accountName = accountName;
      //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      // console.log("RAZCHECK, 1490, this.order",JSON.stringify(this.order));
      // console.log("RAZCHECK, 1512,twoDaysAhead ",this.twoDaysAhead);
      // console.log("RAZCHECK, 1490, this.order.RequestedSupplyDate__c",this.order?.RequestedSupplyDate__c);
      // console.log("RAZCHECK, 1460,twoDaysAhead ",this.twoDaysAhead);
      this.orderDateAndTypeRec.requestedSupplyDate = this.twoDaysAhead;
      // console.log("RAZCHECK, 1480 , 1522,orderDateAndTypeRec ",this.orderDateAndTypeRec);
      // this.order.RequestedSupplyDate__c = this.calculateBH();
      // console.log("RAZCHECK, 1495, this.order.RequestedSupplyDate__c",this.order?.RequestedSupplyDate__c);
      // this.twoDaysAhead = this.calculateBH();
      // console.log("razcheck typeof", typeof twoDaysAhead);
      this.template.querySelector("c-order-date-type-and-contacts-component").receiveRec(this.orderDateAndTypeRec);
    }
  }

  //
  isModalOpen;
  // כפתור ביטול הזמנה - כשטרו - מוצג מודל
  cancleOrderHandler() {
    this.isModalOpen = true;
  }

  cancleOrder() {
    if (this.isOrderLocked) {
      // הזמנה נעולה כאשר הזמנה נכנסה לפעולה
      this.dispatchEvent(new ShowToastEvent({title: "ההזמנה נעולה לביטול",message: "אי אפשר לבטל הזמנה שנכנסה לפעולה.",variant: "error"}));
    }
    if (!this.isOrderLocked && !this.order.id) {
      this.dispatchEvent(new ShowToastEvent({title: "ההזמנה עדיין חדשה ולא במערכת",message: "אי אפשר לבטל הזמנה שלא רשומה במערכת.",variant: "error"}));
    } else {
      this.changeOrderItemsTypeToCanceled(); // TYPE = סטטוס // טיוטה
    }
    this.isModalOpen = false;
  }
  closeModal() {
    this.isModalOpen = false;
  }
  //הובלה פרטית
  privateTransportHandler(event) {
   this.order.PrivateTransport__c = event.detail;
    console.log("PrivateTransport__c",this.order.PrivateTransport__c);
  }
  //ביטול כל ההזמנה
  changeOrderTypeToCanceled() {
    // TYPE = סטטוס
    const fields = {Id: this.order.id,Status: "60",triggerProcessor__c: true}; // 60 = מבוטל
    const recordInput = { fields };
    updateRecord(recordInput).then(() => {
        this.order.Status = "מבוטל"; // הסטטוס בהזמנה למעלה, כמו טיוטה רק מבוטל
        this.dispatchEvent(new ShowToastEvent({title: "הצלחה!",message: "הזמנה מספר: " + this.order.orderNumber + " בוטלה בהצלחה!",variant: "success"}));
      }).catch((error) => {console.error("Error changeOrderTypeToCanceled: " + JSON.stringify(error));
      });
  }
  //ביטול כל המוצרים המשוייכים להזמנה
  changeOrderItemsTypeToCanceled() {
    try {
      //orderItems - מערך שמחזיק את כל המוצרים לאותה הזמנה
      this.orderItems.forEach((item) => {
        console.log("RAZCHECK, 1511,item.id, ",item.id);
        item.status = "70";
        const fields = { Id: item.id, Status__c: "70" }; // 50 = מוצר הזמנה מבוטל
        const recordInput = { fields };
        console.log("RAZCHECK, 814,item.id,recordInput ",recordInput);
        updateRecord(recordInput).then(() => {
            //תשקלי להוסיף טואסט - מוצר נמחק בהצלחה
          }).catch((error) => {
            throw new Error(error);
          });
      });
    } catch (err) {
      console.error("Error changeOrderItemsTypeToCanceled: " + JSON.stringify(err));
    } finally {
      this.changeOrderTypeToCanceled(); //בסוף תבטל גם את ההזמנה
    }
  }
  @track textToDisplay = "";
  @track deliveryNoteId = "";

  //כפתור צדי פופאפ - הזמנות קודמות - אייקון תעודת משלוח
  //קריאת שרת - בלחיצת כפתור - מזהה את אידי מוצר הזמנה, מושך מדאטהבייס את האידי של תעודת משלוח המקושרת לאותו מוצר הזמנה ואז יש עוד
  //קריאת שרת!!! של הרכיב record-view-form
  //שנקרא לאחר הצבת האידי של תעודת המשלוח
  handleReadMoreDeliveryNote(event) {
    // last orders aside popoup function
    const targetId = event.target.dataset.id;
    const ItemId = event.target.dataset.item;
    console.log("targetId: ", targetId, "ItemId: ", ItemId);
    this.textToDisplay = event.target.dataset.item;
    try {
      //Delivery Note = תעודת משלוח
      getDeliveryNoteId({ orderItemId: ItemId }).then((result) => {
          console.log("getDeliveryNoteId ", result);
          if (result.length > 0) {
            this.deliveryNoteId = result[0]?.Id;
          } else {
            this.deliveryNoteId = null;
          }
        }).catch((err) => {console.error("Error handleReadMoreDeliveryNote: ", err);
        });
    } catch (err) {
    } finally {
      // this.deliveryNoteId = event.target.dataset.delivery;
      this.lastOrders.forEach((order) => {
        // לופ על הזמנות אחרונות (בפופאפ)
        if (order.Id == targetId) {
          const targetElement = this.template.querySelector(`div[data-id="${targetId}"]`); //משנה את האידי של הדיב לטרגטאידי ואז מציג/מסתיר
          if (targetElement.style.display === "block") {
            targetElement.style.display = "none";
          } else {
            targetElement.style.display = "block";
          }
        } else {
          this.template.querySelector(`div[data-id="${order.Id}"]`).style ="display: none;"; //אם דיב אחר - תסתיר
        }
      });
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////              getters                        //////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  getProductPriceBookValidationValue(event){
    console.log("RAZCHECK,getProductPriceBookValidationValue, 1633 1634, event.detail",JSON.stringify(event.detail));
    console.log("RAZCHECK,getProductPriceBookValidationValue, 1633 1634, event.detail.Purchase_Order__c",JSON.stringify(event.detail?.Purchase_Order__c));
    if(event.detail == null){
      this.isSaveBtnClickedValue = true;
    }
    else{
      this.isSaveBtnClickedValue = false;
      if(event.detail?.Purchase_Order__c){
        this.template.querySelector("c-order-form-component").getPurchaseOrderValueFromLayout(event.detail?.Purchase_Order__c);
      }

    }
    console.log("RAZCHECK,getProductPriceBookValidationValue, 1633 1641, this.isSaveBtnClickedValue",this.isSaveBtnClickedValue);
  }
  


  getLoadingPointId(event){
    console.log("RAZCHECK,1658, loadingpointid",this.loadingPointIdFromOrderItem);
    console.log("RAZCHECK,1658, loadingpointid",JSON.stringify(event.detail));
    this.loadingPointIdFromOrderItem = event.detail;
    this.template.querySelector("c-order-form-component").getLoadingPointIdFromLayout(this.loadingPointIdFromOrderItem);

  }


  //אם  תעודת החזרה או שיוך - הסתר את כפתור הוסף מוצר
  get isReturningTypeOrder() {
    return this.order.TransactionType__c == "40" || this.order.TransactionType__c == "60"? true : false;
  }

  get itemStatusForLockOrderAprove(){
    console.log("RAZCHECK, 1652,  419,this.itemStatusForForm ",this.itemStatusForForm);
    return this.itemStatusForForm == '10' || this.itemStatusForForm == '20' || this.itemStatusForForm == '70' || this.itemStatusForForm == null? false : true;
  }
  get isOrderCanceled() {
    //אם ההזמנה מבוטל - כפתור שליחת הזמנה מוסתר
    return this.order.Status == "מבוטל" ? true : false;
  }
  get orderContainerStyle() {
    // אם הזמנה מבוטלת - דיסאבלד=לא ניתן ללחיצה או הצבעה
    return this.order.Status == "מבוטל" ? "layout slds-col slds-grow disabled" : "layout slds-col slds-grow";
  }
  get isOrderLockedAndNotNew() {
    // בהזמנה קיימת - אם נעולה ולא חדשה - הצג כפתור ביטול, אחרת לא
    return this.isOrderLocked || !this.order.id || this.order.Status == "מבוטל" ? true : false;
  }

  get isOrderNotSapApproved() {
    //הצג כפתור רק אם הזמנה לא מאושרת סאפ
    return this.order.Status == "לא מאושר SAP" && this.order.id ? true : false;
  }
  get saveOrderLabel() {
    //טוגל כפתור שמירה או עדכון להזמנה קיימת
    return this.recordId ? "עדכון הזמנה" : "שליחת הזמנה";
  }

  get modal() {
    return this.isButtonClicked ? "displayBlock modal" : "displayNone";
  }

  get statusIcon() {
    // אם יש רקורדאידי להזמנה - שנה האייקון
    return this.recordId ? "action:defer" : "action:clone";
  }

  get cssForHeaders() {
    // לשנותתת
    switch (FORM_FACTOR) {
      case "Large":
        return "slds-size_1-of-3";
      case "Medium":
        return "slds-size_1-of-2 slds-p-around_small";
      case "Small":
        return "slds-size_2-of-2 slds-p-around_small";
      default:
    }
  }

  get cssForOrderFormHeader() {
    switch (FORM_FACTOR) {
      case "Large":
        return "slds-size_1-of-3";
      case "Medium":
        return "slds-size_2-of-2 slds-p-around_small";
      case "Small":
        return "slds-size_2-of-2 slds-p-around_small";
      default:
    }
  }

  get lastOrdersIcon() {
    //אם הכפתור הזמנות אחרונות נלחץ - מימין אחרת שמאל
    return this.isButtonClicked? "utility:jump_to_right" : "utility:jump_to_left";
    }

  get toggleBtnLastOrders() {
    switch (FORM_FACTOR) {
      case "Large":
        return this.isButtonClicked ? "sticky2" : "sticky1"; //חפשי בCSS נדבק לצד המסך אחרת לצד של הדיב
      case "Medium":
        return "hidden";
      case "Small":
        return "hidden";
      default:
    }
  }

  get orderItemContainerStyle() {
    // גטר שמוסיף מרג'ין במידה שהמסך לא מחשב
    return this.isDesktop ? "slds-size_2-of-2" : "slds-size_2-of-2 slds-m_around_small";
  }

  get isDesktop() {
    switch (
      FORM_FACTOR // FORM_FACTOR- בילדאין של הספריה לזהות גודל מסך מתוך 3
    ) {
      case "Large":
        return true;
      case "Medium":
        return false;
      case "Small":
        return false;
      default:
    }
  }

  get isNotCustomerService() {
    console.log("order layout isNotCustomerService 1628",this.profileType);
    if((this.profileType == "IL Customer Service") || (this.profileType =="IL External Customer Service") ){
      return false;
    } else{
      return true ;
    }   ; // אם יוזר משירות לקוחות - חלחל פולס לקומפ' למטה
  }

  get whichProfileType(){
    return this.profileType;
  }

  get isSalesManagerChemicals() {
    return this.profileType == "IL - Sales manager Chemicals" ? false : true;
  }
  
  get isNotAllowedToCancelOrder(){
    if(this.orderItems.status =='100' ){
      return true;
    }
    else{
      return false;
    }
  }

    // get isAllowedToAprroveOrder(){
  //   if(isNotCustomerService){
  //     return true;
  //   }
  //   else{
  //     return false;
  //   }
  // }

  // get isSaveBtnClicked(){
  //   return isSaveBtnClickedValue ? true : false;
  // }
}


// getStatusCodeValue(code) {
//   if (code == "" || code == undefined || code == null) {return null;}
//   if (code == "10") {return "טיוטה";}
//     if (code == "15") {return "לא מאושר Credit";}
//   if (code == "20") {return "לא מאושר SAP";}
//   if (code == "30") {return "מאושר";}
//   if (code == "40") {return "בתהליך";}
//   if (code == "50") {return "סגור";} 
//   if (code == "60") {return "מבוטל";
//   } else return code;
// }