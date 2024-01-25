import { LightningElement, track, api, wire } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import getSalesPoints from "@salesforce/apex/OrderCustomerController.getSalesPoints";
import getDefaultLP from "@salesforce/apex/OrderCustomerController.getDefaultLP";
import fetchExtendedLookUpValues from "@salesforce/apex/CustomLookUpController.fetchExtendedLookUpValues";
import { createRecord } from "lightning/uiRecordApi";
import getDeliveryNoteId from "@salesforce/apex/OrderCustomerController.getDeliveryNoteId";
import getLoadingPointName from "@salesforce/apex/OrderCustomerController.getLoadingPointName";
import getPBRecord from "@salesforce/apex/priceCalculationInfo.getPBRecord";
import getPriceForProduct from "@salesforce/apex/priceCalculationInfo.getPrice";
import getDiscount from "@salesforce/apex/getProductDiscount.getDiscountRec";
import getProduct from "@salesforce/apex/priceCalculationInfo.getProduct";
import isProductChosen from "@salesforce/apex/OrderCustomerController.isProductChosen";
import isHazardMaterial from "@salesforce/apex/OrderCustomerController.isHazardMaterial";
import isFramDealExit from "@salesforce/apex/OrderCustomerController.isFramDealExit";
import getFramDealDetails from "@salesforce/apex/OrderCustomerController.getFramDealDetails";
import updateTankStatus from "@salesforce/apex/OrderCustomerController.updateTankStatus";
// import getQuantityBalance from "@salesforce/apex/OrderCustomerController.getQuantityBalance";
// import getFramDealQuantity from "@salesforce/apex/OrderCustomerController.getFramDealQuantity";


import Utils from "c/utils";
import LogDate from "@salesforce/schema/EventLogFile.LogDate";

export default class OrderItemComponent extends LightningElement {
  chemicalTransportPrice = 0;
  deliveryUnitOfMeasurePB = '';
  isFramedealModalOpened;
  testFrame=false;
  isFrameModal;
   showFrameText;
         isAddingNote = false;
         unloadingHasContact = true;
         @track extensions = null;
         @api itemId;
         @api accountId;
         @api accSettelment = null;
         @api relatedPricebook;
         getDeliveryNoteId;
         halfArea = false;
         tankPointsFields = "Id, Name, Account__c, Account__r.Name, RelatedContact__c, RelatedContact__r.Name, RelatedContact__r.Phone, RelatedContact__r.MobilePhone";
         sallingPointsFields = "Id, Name";
         @api orderType;
         @api orderStatus; //סטטוס כלל ההזמנה
        // orderTypeFromLayoutOnchange='30';
         @api privateTransport;
        //  @api cosignationWarehouseApprovalForValidate;
        
         @api tankPoints = null;
         @api showChemical = false;


         @api profileType;
         openDischargeLocationAdder = false;
         openDischargeQuantityAdder = false;
         valueOfTankPoint;
         dischargeLocationRequierd = true;
         dischargeLocationRequierd2 = true;
         lastOrders = [];
         selectedProduct;
         isShown = true;
         isHazard = true;
         isFramDeal = true;
         @track frameDealRes=[];
         @track tankArray;
         @track tankArrayToString=[];
         @api isChemicals;
         @api isFrameButton;
         isFrameDealRaz=true;
        originalTransactionTypeForValidate= '';
          productPriceBookForExtValidate = false;
          totalQuantityCounter;
          framDealQuantity;
          originOrderType;
         
          @api myBooleanProp = false;
          isTankPointActive;

          handleTankPointActive(){
          this.isTankPointActive= !this.isTankPointActive;
            updateTankStatus({recordId: this.dischargeLocationId}).then((result) => {
              // this.dispatchEvent(new ShowToastEvent({title: "הצלחה!",message: "הזמנה מספר: "  + " בוטלה בהצלחה!",variant: "success"}));

                    }).catch((err) => { console.error(err); });
          }          
          handleBooleanChange() {
            this.isFrameDealRaz = false;

            const booleanValue = true;
            console.log("handleBooleanChange 85",this.newFramedealArray);
           const arr = this.newFramedealArray;
            const booleanChangeEvent = new CustomEvent('booleanchange', { detail: { booleanValue, arr } });
            this.dispatchEvent(booleanChangeEvent);
          }

         connectedCallback() {
          console.log("this.isFrameDealRaz",this.isFrameDealRaz);
          console.log("RAZCHECK, 94, this.itemId",this.itemId);
          this.originalTransactionTypeForValidate = '';
          this.testFrame=false;
          this.allFramedealArray=[];
          this.framDealQuantity=null;
           this.getSalesPoints();
          // console.log("47 this.rec",this.rec);
        //  if (this.itemId==1) {
        //   this.getDefaultLP();  
        //  }      
          this.rec.id = this.itemId;
          // console.log("RAZCHECK, 106, cosignationWarehouseApprovalForValidate",this.cosignationWarehouseApprovalForValidate);
         }

         renderedCallback() {
          // console.log("RAZCHECK, 110, cosignationWarehouseApprovalForValidate",this.cosignationWarehouseApprovalForValidate);

      }

       onchangeDischargeQuantity(event){
         let dynamicDischargeQuantityInput = Number(event.target.value);
         let dynamicDischargeNameInput = event.target.dataset.key; 
          this.tankArrayToString[dynamicDischargeNameInput]=dynamicDischargeQuantityInput;   
          }
        
        onSubmitDischargeQuantity(){
          const pp = [];
          let counter = 0;
          for (const [key, value] of Object.entries(this.tankArrayToString)) {
            counter+=value;
            if (value!= 0 && value!= null && value!= undefined && value!= "" &&  value > 0) {              
              pp.push(`  ${key}: ${value}  `);
            }
          }
          if (counter > this.rec.quantity) {
            return Utils.showToast(this,"כמות פריקה מופרזת "," .סך הכמויות לפריקה גבוה מהערך בשדה כמות","error"); 
          } else {
            this.rec.Comment__c = `נקודות פריקה לפי כמות -->     `+pp;
            this.isAddingNote=true;
            this.closeDischargeQuantityModal();
          }
         this.dischargeQuantityCounter=0;
         this.tankArrayToString=[];
         }

        getLastViewRecords(){
            fetchExtendedLookUpValues({searchKeyWord: ``,fieldsToQuery: "Id, Name, LastViewedDate",objectName: `Tank__c`,extraWhereClause: ` AND Account__c = '${this.accountId}'` 
            }).then((result) => {
                let dischargeLocationProxy = result;
                this.tankArray = dischargeLocationProxy;
                console.log(this.tankArray,"this.tankArray");
                     this.addDischargeQuantityHandler();
                     this.isAddingNote = !this.isAddingNote;
                    }).catch((err) => { console.error(err); });
          }
         @track rec = {
                  id: null,
                  product: { id: null, name: null },
                  OrderId: null,
                  quantity: null,
                  status: null, //סטטוס המוצר
                  unitOfMeasure: "קוב",
                  fullArea: false,
                  totalPrice: null,
                  dischargeLocation: { id: null, name: null },
                  loadingPoint: {id: this.getDefaultLP()},
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
                  Comment__c: "",
                  Purchase_Order__c: null,
                  relatedContactName: null,
                  relatedContactPhone: null,
                  deliveryNoteExist: null,
                  extensions: null,
                  driver: null,
                  supplyDate: null,
                  orderType: null,
                  OriginOrderItemId__c:null,
         };
         quantityFramedeal;
         originFrameDeal_OrderId;
         originFrameDeal_OrderItemId;

         @api receiveRec(orderItems) { // מוטרגת בכל פעם שמקבלים רקורד קיים-אחרי GETCURRENTORDER
          console.log("RAZCHECK, receiveRec 00013",orderItems,JSON.stringify(orderItems));          
          console.log("RAZCHECK,192,  orderItems[0]?.loadingPoint",JSON.stringify(orderItems[0]?.loadingPoint));          
          console.log("RAZCHECK,192,  orderItems[0]?.loadingPoint.id",JSON.stringify(orderItems[0]?.loadingPoint?.id)); 
          getLoadingPointName({Id:orderItems[0]?.loadingPoint?.id }).then((response) => {
            if(response[0].Name){
              console.log("RAZCHECK, 233 , getLoadingPointName",response[0].Name);
              this.rec.loadingPoint.name = response[0].Name;
            }
          }).catch((err) => console.log(err)
          )         
          this.originalTransactionTypeForValidate = orderItems[0]?.originalTransactionType;
          this.orderTypeHandler(orderItems[0]?.originalTransactionType);
          this.quantityFramedeal=(Number(orderItems[0]?.quantity));
          this.originFrameDeal_OrderId=orderItems[0]?.OrderId;
          this.originFrameDeal_OrderItemId=orderItems[0]?.id;
          console.log("receiveRec 00013 framdeal",this.originFrameDeal_OrderId,this.originFrameDeal_OrderItemId);
                  const found = orderItems.find(({ id }) => id === this.itemId); // פשוט למניעת כפילויות בעליה מהאבא לייאאוט של הזמנה קיימת - אייטמס
                  this.rec = found;
                  console.log("rec from found, 184,RAZ",JSON.stringify(this.rec));
                  this.originOrderType = orderItems[0]?.orderTypeNew; // אכלוס מידע מהזמנה בעליה של מסגרת - סוג עסקה 70
                  this.recordId=orderItems[0].recordId;
                  if (this.rec?.Comment__c) {this.isAddingNote = true;}
                  if (this.rec?.extensions) {this.handleExtenstionsReorder(this.rec.extensions);}
                  if (this.rec?.productSapNumber) {
                  if (this.rec?.productSapNumber.charAt(0) == "D") {this.dischargeLocationRequierd = false;}}
                  if (this.rec?.prodFamily) {this.prodFamily = this.rec.prodFamily;}
                  if (this.rec?.extensions) {this.ext = this.rec.extensions;}
                  if (this.rec?.framedealQuantity__c) {this.rec.quantity = this.rec.framedealQuantity__c;}
                  this.arrangePossibleTransportSelectedValues(found);
                  this.getPriceForProduct();
                 this.getPBRecord();
                //  if (this.originOrderType==70 && !this.recordId) this.isFramDealExit();   

         }

         arrangePossibleTransportSelectedValues(record) {
                  const selectedValues = [];
                  if (record?.refuelingTransport) { selectedValues.push("הובלת תדלוק");}
                  if (record?.nonFreightCharge) { selectedValues.push("ללא חיוב הובלה");}
                  if (record?.combinedPackaging) { selectedValues.push("אריזה משולבת");}
                  if (record?.combinedTransport) { selectedValues.push("הובלה משולבת");}
                  if (record?.specialTransport) { selectedValues.push("מיוחדת");}
                  if (record?.customerPackaging) { selectedValues.push("אריזת לקוח");}
                  if (record?.waitingRequired) { selectedValues.push("נדרשת המתנה");}
                  if (record?.craneTransport) { selectedValues.push("הובלת מנוף");}
                  if (selectedValues.length > 0) { this.template.querySelector("c-mutli-select-picklist").updateSelectedValuesData(selectedValues,this.possibleTransportOptions);}
         }

         @api handlePreviuosesDuplication(orderItem) {
                  const item = JSON.parse(JSON.stringify(orderItem));
                  console.log("ITEM, 213, raz",item);
                  this.rec = {
                           id: null,
                           product: {id: item.product.id,name: item.product.name,},
                           quantity: item.quantity,
                           status: null,
                           unitOfMeasure: item.unitOfMeasure,
                           OrderId: null,
                           fullArea: item.fullArea,
                           totalPrice: item.totalPrice,
                           dischargeLocation: {id: item.dischargeLocation.id,name: item.dischargeLocation.name,},
                           loadingPoint: {id: item.loadingPoint.id,name: item.loadingPoint.name,},
                           OrderItemNumber: null,
                           specialPrice: null,
                           transportPrice: null,
                           deliveryUnitOfMeasure: null,
                           nonFreightCharge: item.nonFreightCharge,
                           combinedPackaging: item.combinedPackaging,
                           refuelingTransport: item.refuelingTransport,
                           combinedTransport: item.combinedTransport,
                           customerPackaging: item.customerPackaging,
                           specialTransport: item.specialTransport,
                           waitingRequired: item.waitingRequired,
                           craneTransport: item.craneTransport,
                           Comment__c: item?.Comment__c,
                           Purchase_Order__c: item.Purchase_Order__c,
                           relatedContactName: item.relatedContactName,
                           relatedContactPhone: item.relatedContactPhone,
                           deliveryNoteExist: null,
                           extensions: item.extensions,
                           driver: null,
                           supplyDate: null,
                  };
                  if (this.rec.Comment__c) {
                           this.isAddingNote = true;
                  }
                  if (this.rec.extensions) {
                           this.handleExtenstionsReorder(this.rec.extensions);
                  }
         }
         @track addingNoteReqiuerd = false;
         idToRemove;
         minQuantity;
         @api populateOrderItemRecord(rec, idToRemove) {
                  this.rec = rec;
                  console.log("line 183 populate", this.rec);
                  this.rec.status = "";
                  this.itemId = rec.id;
                  this.rec.Purchase_Order__c = null;
                  this.rec.specialPrice = null;
                  this.rec.transportPrice = null;
                  this.rec.deliveryUnitOfMeasure = null;
                  this.idToRemove = idToRemove;
                  this.extensionsOptionsValue = "option2";
                  this.totalQuantityAmount = 0;
                  if (this.orderType == "40") {    
                           this.minQuantity = rec.quantity * -1;
                           this.rec.quantity *= -1;
                           this.isAddingNote = true;
                           this.addingNoteReqiuerd = true;
                  }else if (this.orderType == "60") {
                           this.isAddingNote = true;
                           this.addingNoteReqiuerd = true;
                           this.rec.dischargeLocation = {id: null,name: null};
                           // this.rec.product = "";
                           // this.rec.status= null;
                           // this.rec.loadingPoint={id:null};
                           // this.rec.description=null;
                           // this.rec.Purchase_Order__c=null;
                           // this.rec.relatedContactName=null;
                           // this.rec.deliveryNoteExist= null;
                           // this.rec.supplyDate= null;
                  } else{
                    this.isAddingNote = false;
                    this.addingNoteReqiuerd = false;

                  }
                  this.arrangePossibleTransportSelectedValues(rec);
         }

         handleExtenstionsReorder(extensions) { // מוטרג רק בעלייה. אולי כאן ? 
           console.log("233 extensions",JSON.stringify(extensions),this.isPrecentsInput);
                  extensions.forEach((ext, index) => {
                           if (index == 0) {
                                    this.ext.Extension_1__c = ext.Id;
                                    this.ext.Extension_Quantity_1__c =ext.quantity.toFixed(3);
                                    this.ext.Extension_Unit_1__c =this.ext.Extension_Unit_1__c?this.ext.Extension_Unit_1__c:"קוב";
                           }
                           if (index == 1) {
                                    this.ext.Extension_2__c = ext.Id;
                                    this.ext.Extension_Quantity_2__c =ext.quantity.toFixed(3);
                                    this.ext.Extension_Unit_2__c =this.ext.Extension_Unit_2__c?this.ext.Extension_Unit_2__c:"קוב";
                           }
                           if (index == 2) {
                                    this.ext.Extension_3__c = ext.Id;
                                    this.ext.Extension_Quantity_3__c =ext.quantity.toFixed(3);
                                    this.ext.Extension_Unit_3__c =this.ext.Extension_Unit_3__c?this.ext.Extension_Unit_3__c:"קוב";
                           }
                  });
         }
         ext = {
                  Extension_1__c: null,
                  Extension_2__c: null,
                  Extension_3__c: null,
                  Extension_Quantity_1__c: null,
                  Extension_Quantity_2__c: null,
                  Extension_Quantity_3__c: null,
                  Extension_Unit_1__c: "קוב",
                  Extension_Unit_2__c: "קוב",
                  Extension_Unit_3__c: "קוב",
         };

         deliveryNoteId;
         getDeliveryNoteInfo() {
                  getDeliveryNoteId({ orderItemId: this.rec.id }).then((result) => {
                                    this.deliveryNoteId =result[result.length - 1].Id;
                           }).catch((error) => {console.error(error);
                           });
         }

         closeModal() {
                  this.openDischargeLocationAdder = false;
         }

         @api updateTankPoints(tankPoints, accSettelment) {
          this.rec.dischargeLocation.name="";
          this.rec.dischargeLocation.id=null;
                  this.tankPoints = [];
                  this.accSettelment = accSettelment != null || accSettelment? accSettelment: null;
                  if (tankPoints == null) {
                           this.rec.relatedContactName = null;
                           this.rec.relatedContactPhone = null;
                           return;
                  }
                  if (tankPoints != null || tankPoints.length > 0) {
                           tankPoints.forEach((point) => {
                                    if (this.rec.dischargeLocation.id) {
                                             if (point.Id ==this.rec.dischargeLocation.id) {
                                                      this.tankPoints.push({...point,selected: true,});
                                                      if (point.hasOwnProperty("RelatedContact__c")) {
                                                               this.rec.relatedContactName =point.RelatedContact__r?.Name;
                                                               this.rec.relatedContactPhone =point.RelatedContact__r?.Phone? point.RelatedContact__r?.Phone: point.RelatedContact__r?.MobilePhone;
                                                     console.log("319 contacts:",this.rec.relatedContactName,this.rec.relatedContactPhone);
                                                              }
                                                      
                                             } else {this.tankPoints.push({...point,selected: false});}
                                    } else {
                                             if (tankPoints.length == 1) {this.tankPoints.push({...point,selected: true});
                                             } else {
                                                      this.tankPoints.push({...point,selected: false,});}
                                    }
                           });
                  }
         }

         handleTankPointsEditFormSucces(event) {
                  if (event.detail.id && (this.rec.dischargeLocation.id == "" ||this.rec.dischargeLocation.id == null)) {
                           this.rec.dischargeLocation.id = event.detail.id;}
                  const selectEvent = new CustomEvent("tankpointsadded", {});
                  this.dispatchEvent(selectEvent);
         }

         handleDeleteAction(event) {
          console.log("RAZCHECK, 370,handleDeleteAction ");
          console.log("RAZCHECK, 370,this.idToRemove ",this.idToRemove);
          console.log("RAZCHECK, 370,event.target.dataset.id ",event.target.dataset.id);
          console.log("RAZCHECK, 370,event.target ",JSON.stringify(event.target));
                  let id;
                  if (this.idToRemove) {
                           id = this.idToRemove;
                  } else {
                           id = event.target.dataset.id;
                  }
                  event.preventDefault();
                  console.log("RAZCHECK, 380, id",id);
                  const selectEvent = new CustomEvent("removeitem", {detail: id});
                  this.dispatchEvent(selectEvent);
         }
         quantityInSurface;
         prodFamily;
         accumulationState;
         handleProductRecordSelect(event) { //מוטרג בבחירת מוצר 
                  try {
                    console.log("RAZCHECK, 388 ,handleProductRecordSelect");
                    console.log("RAZCHECK, 388 ,handleProductRecordSelect, event",JSON.stringify(event.detail));
                    console.log("RAZCHECK, 424 ,orderTypeFromLayoutOnchange",this.orderTypeFromLayoutOnchange);
                    console.log("RAZCHECK, 424 ,orderType",this.orderType);
                    if(!this.orderTypeFromLayoutOnchange){
                      console.log("RAZCHECK, 424 , if  -- - - -- - - orderTypeFromLayoutOnchange",);
                      if(this.orderType){
                        console.log("RAZCHECK, 424 ,if ----- -- - - orderType");

                        this.orderTypeFromLayoutOnchange = this.orderType;
                      }
                    }
                          this.rec.loadingPoint= {id: this.getDefaultLP()};
                           this.productPriceBook = null;
                           this.dischargeLocationRequierd = true; 
                           if (event.detail.selectedRecordId) {
                             console.log("RAZCHECK,395 333 handleProductRecordSelect , this.rec",JSON.stringify(this.rec));
                             console.log("RAZCHECK,396 333 handleProductRecordSelect , event ",JSON.stringify(event));
                             console.log("RAZCHECK,397 333 handleProductRecordSelect , selectedRecord ",JSON.stringify(event.detail?.selectedRecord));
                             console.log("RAZCHECK,397 333 handleProductRecordSelect , selectedRecord ",JSON.stringify(event.detail?.selectedRecord?.IL_BU__c));
                             console.log("RAZCHECK,397 333 445 handleProductRecordSelect , selectedRecord ",JSON.stringify(event.detail?.selectedRecord?.Packing__c));
                             console.log("RAZCHECK,397 333 handleProductRecordSelect , selectedRecord ",JSON.stringify(event.detail?.selectedRecord?.IL_Group_name__c));
                            console.log("RAZCHECK,398 333 handleProductRecordSelect , selectedValue ",JSON.stringify(event.detail?.selectedValue));
                            console.log("RAZCHECK,399 333 handleProductRecordSelect , LoadingPoint_c ",event.detail?.selectedRecord?.LoadingPoint__c);
                            console.log("RAZCHECK,399 333 handleProductRecordSelect , this.selectedProduct ",this.selectedProduct);
                                    this.rec.product.id =event.detail.selectedRecordId;
                                    this.rec.product.name =event.detail.selectedValue; // בעת שינוי - מקבלים את שם המוצר מהאבנט, מאכלסים כאן
                                    this.quantityInSurface =event.detail?.quantityInSurface;
                                    this.prodFamily =event.detail?.selectedRecord?.IL_Group__c; // מספר כלשהו
                                    this.accumulationState =event.detail?.selectedRecord?.Accumulation_state__c;
                                    const extensions = [...event.detail.extensions];
                                    this.rec.extensions = [];

                                    if(event.detail?.selectedRecord?.LoadingPoint__c){
                                      // במידה וקיימת נקודת מכירה דיפולטיבית למוצר
                                      console.log("RAZCHECK, 405 ,event.detail.selectedRecordId ", event.detail.selectedRecordId);
                                      console.log("RAZCHECK, 405 ,event.detail.selectedRecord.LoadingPoint__r ", JSON.stringify(event.detail.selectedRecord.LoadingPoint__r));
                                      console.log("RAZCHECK, 405 ,event.detail.selectedRecord.LoadingPoint__r.Name ", event.detail.selectedRecord.LoadingPoint__r.Name);
                                      console.log("RAZCHECK, 405 ,event.detail.selectedRecord.LoadingPoint_r.LoadingPointType_c ", event.detail.selectedRecord.LoadingPoint__r.LoadingPointType__c);
                                      this.rec.loadingPoint.id = event.detail.selectedRecord.LoadingPoint__r.Id;
                                      this.rec.loadingPoint.name = event.detail.selectedRecord.LoadingPoint__r.Name;
                                      this.rec.loadingPoint.type = event.detail.selectedRecord.LoadingPoint__r.LoadingPointType__c;
                                    }

                                    if (event.detail?.selectedRecord?.QuantityUnitOfMeasure) {
                                             // במידה וקיים יחידת מידה דיפולטיבית למוצר
                                             console.log("RAZCHECK, 479 ,defualt,  event.detail?.selectedRecord?.QuantityUnitOfMeasure ",event.detail?.selectedRecord?.QuantityUnitOfMeasure);
                                              let defualtQuantityUnitOfMeasure = event.detail?.selectedRecord?.QuantityUnitOfMeasure;
                                             this.rec.unitOfMeasure =this.getUnitOfMeasureName(defualtQuantityUnitOfMeasure);
                                    }
                                    else{

                                      if (event.detail?.selectedRecord?.IL_BU__c == "כימיקלים" && event.detail?.selectedRecord?.IL_Group_name__c !== "נוקסיקליר") {
                                        console.log("RAZCHECK, 479 ,כימיקלים  ");
                                        this.rec.unitOfMeasure =this.getUnitOfMeasureName("TO");
                                      }
                                      if (event.detail?.selectedRecord?.IL_BU__c == "כימיקלים" && event.detail?.selectedRecord?.IL_Group_name__c == "נוקסיקליר") {
                                        console.log("RAZCHECK, 479 ,כימיקלים נוקיסקלייר ");
                                        if(event.detail?.selectedRecord?.Packing__c){
                                          this.rec.unitOfMeasure =this.getUnitOfMeasureName("EA");
                                          console.log("RAZCHECK, 479 ,כימיקלים נוקיסקלייר , EA");
                                        }
                                        else{
                                          this.rec.unitOfMeasure =this.getUnitOfMeasureName("M3");
                                          console.log("RAZCHECK, 479 ,כימיקלים נוקיסקלייר , M3");
                                        }
                                      }

                                    }
                                      if (event.detail?.selectedRecord?.Accumulation_state__c) {
                                        this.rec.unitOfMeasure =this.getUnitOfMeasureByAccumaltionState(event.detail?.selectedRecord?.Accumulation_state__c); }
                                        // במידה ומוצר זה מסוג מוצר שירות
                                    if (event.detail?.selectedRecord?.Sap_Number__c) {
                                             if (event.detail?.selectedRecord?.Sap_Number__c.charAt(0) == "D") {
                                                      this.dischargeLocationRequierd = false;
                                                      this.rec.unitOfMeasure ="יחידה"; }
                                    } else {this.rec.unitOfMeasure = "קוב";}
                                    if (extensions.length > 0) {
                                             extensions.forEach((extension) => {
                                                      this.rec.extensions.push({...extension,unitOfMeasure:"קוב" });
                                             });
                                    } else {
                                             this.ext = {
                                                      Extension_1__c: null,
                                                      Extension_2__c: null,
                                                      Extension_3__c: null,
                                                      Extension_Quantity_1__c: null,
                                                      Extension_Quantity_2__c: null,
                                                      Extension_Quantity_3__c: null,
                                                      Extension_Unit_1__c: null,
                                                      Extension_Unit_2__c: null,
                                                      Extension_Unit_3__c: null,
                                             };
                                    }
                                    if (Array.isArray(extensions)) {
                                             extensions.forEach((ext, index) => {
                                                               if (index == 0) this.ext.Extension_1__c =ext.Id;
                                                               if (index == 1) this.ext.Extension_2__c =ext.Id;
                                                               if (index == 2) this.ext.Extension_3__c =ext.Id;
                                                      }
                                             );
                                    } } else {
                                    this.quantityInSurface = null;
                                    this.prodFamily = null;
                                    this.rec.product.id = null;
                                    this.rec.product.name = null;
                                    this.rec.extensions = null;
                                    this.rec.unitOfMeasure = "קוב";
                                    this.accumulationState = "";
                                    this.prodOriginalDiscount = 0;
                                    this.prodDiscount = 0;
                                    this.prodPrice = 0;
                                    this.prodPriceBeforeDiscount = 0;
                                    this.chemicalTransportPrice = 0;
                                    this.deliveryUnitOfMeasurePB = '';
                                    this.discountRec = null;
                           }
                           this.isProductChosen();
                           this.isHazardMaterial();
                           console.log("handleProductRecordSelect 393",this.orderTypeFromLayoutOnchange,this.rec.id,this.allFramedealArray);
                           console.log("RAZCHECK, 469 - 797, this.rec",JSON.stringify(this.rec));
                           console.log("RAZCHECK, 470 - 797, this.rec.loadingPoint",JSON.stringify(this.rec.loadingPoint));
                           console.log("RAZCHECK, 476 - 797, this.ext.Extension_1__c",this.ext?.Extension_1__c);
                           console.log("RAZCHECK, 476 - 797, this.ext.Extension_2__c",this.ext?.Extension_2__c);
                           console.log("RAZCHECK, 476 - 797, this.ext.Extension_3__c",this.ext?.Extension_3__c);
                         if( this.rec.id == 1 && this.orderTypeFromLayoutOnchange == undefined ) this.isFramDealExit();
                           this.getPBRecord();
                           this.getPriceForProduct();
                           this.getProduct();
                  } catch (err) {
                           console.log("error in orderItem prouct selected handler: ",err);
                  }
         }

         isProductChosen() {
                  this.isShown = true; // טקסט אדום אם נבחר מוצר זה ללקוח בעבר
                  isProductChosen({recordId: this.accountId,productId: this.rec.product.id}).then((response) => {    
                  this.isShown = response;   // return true or false - יש מוצר או לא
                  });
         }
         isHazardMaterial() {
          this.isHazard = true; // טקסט אדום אם נבחר מוצר זה ללקוח בעבר
          isHazardMaterial({productId: this.rec.product.id}).then((response) => {  
            console.log("isHazardMaterial",response);  
          this.isHazard = response;   // return true or false - יש מוצר או לא
          });
 }

         orderTypeFromLayoutOnchange;
         @api orderTypeHandler(ordertype) {
          console.log("type 380:",ordertype);
          this.orderTypeFromLayoutOnchange=ordertype;
         }     

         @track allFramedealArray=[];
         chosenOrderId=null;
         chosenOrderItemId=null;
         chosenOrderItemQuantity=null;
      
         onSaveFrameDeal(event){
          event.preventDefault();
          console.log("onsave 503 hara");
          this.chosenOrderId=event.target.dataset.order;
          this.chosenOrderItemId=event.target.dataset.key;
          this.chosenOrderItemQuantity=event.target.dataset.Quantity;
         if( this.chosenOrderId != null &&  this.chosenOrderId != null) this.fireOrderAndOrderItemIds();  
          this.testFrame=false;
          this.allFramedealArray=[];
          this.framDealQuantity=null;
          this.chosenOrderId=null;
          this.chosenOrderItemId=null;
          this.chosenOrderItemQuantity=null;
          this.closeDischargeQuantityModal();
         }

    isFramDealExit() { // שלב 1: האם קיימת עסקת מסגרת (רק אם שונה מ-70 מוטרג)
      console.log("isFramDealExit 00013");
     this.orderTypeFromLayoutOnchange = '30';
     isFramDealExit({recordId: this.accountId, productId: this.rec.product.id}).then((response) => {    
      this.allFramedealArray=response;
      this.rec.OriginOrderItemId__c=this.allFramedealArray[0]?.Id;
         if (this.allFramedealArray.length > 0) { // אם יש הזמנות מסגרת פתוחות - ג'יבל
          this.getFramDealDetails(); 
          this.isFrameDealRaz = false;
          this.isFrameButton=true;
          console.log(this.isFrameButton,"474 isFrameButton");
        }       
      }).catch((error)=>{console.error(error);});
    }
    quantityFrame;
    @track newFramedealArray;
    getFramDealDetails() {
      console.log("this.isFrameDealRaz",this.isFrameDealRaz)
      console.log("getFramDealDetails 00013  לפני שליחת פונקציה לשרת להבאת 4 נתונים",this.accountId,  this.rec.product.id);
      if (this.allFramedealArray != []) {  
          getFramDealDetails({recordId: this.accountId, productId: this.rec.product.id}).then((response) => {    
          this.allFramedealArray=response;
          console.log("handleBooleanChange 85",this.allFramedealArray);

          console.log(this.allFramedealArray," 479");
          this.newFramedealArray=this.allFramedealArray.map((iteration)=>{
            return {
              Id:iteration.Id,
              Product2Id	:	iteration.Product2Id,
              Quantity:iteration.Quantity,
              OrderId	:	iteration.OrderId,
              framework_agreement_Usege_Quntity__c	:	iteration.framework_agreement_Usege_Quntity__c,
              Product2:{
                Name	:iteration.Product2.Name,
                Id	:	iteration.Product2.Id},
                Order:	{
                  OrderCreatedDate__c	:	iteration.Order.OrderCreatedDate__c,
                  Id	:	iteration.Order.Id},
                  CalculatedQuantity	:	Number(iteration.Quantity) - Number(iteration.framework_agreement_Usege_Quntity__c),
                  isMisgeret:true,
                }
              });
                console.log("480 00013 hara ",this.newFramedealArray);
                this.isFrameDealRaz = false;

                this.handleBooleanChange();
                if (this.allFramedealArray.length > 1 && this.allFramedealArray != null) { // הקפצת מודל מסגרת אם יש יותר מהזמנת מסגרת אחת
                  this.testFrame= true;
            } else{
              console.log("else getFramDealDetails",this.allFramedealArray,response);
              this.chosenOrderId=this.allFramedealArray[0].OrderId;
              this.chosenOrderItemId=this.allFramedealArray[0].Id;
              console.log("else getFramDealDetails fireOrderAndOrderItemIds",this.chosenOrderId,this.chosenOrderItemId);
              this.fireOrderAndOrderItemIds();             
            }
            this.isFrameDealRaz = false;
          }).catch((error)=>{console.error(error);});
        }
        this.allFramedealArray=[];
        this.testFrame = false;
         }

         fireOrderAndOrderItemIds(){
          const selectEvent = new CustomEvent("framedeal", { // יורה לאבא ומטריג הבאת ההזמנה 
            detail:{orderId:this.chosenOrderId, orderItemId:this.chosenOrderItemId}});
           this.dispatchEvent(selectEvent);
         }
         test1;
         test2;
         floz;
         @track productPriceBook = null;
         //priceBook - מחירון מוצר - אם יש מחירון או אין מחירון - אם אין אין אופציה להוסיף הזמנה בכלל!
         getPBRecord() {
                  if (this.relatedPricebook) { 
                    this.productPriceBook = this.relatedPricebook;
                  } else {
                           // productId: any, Account: any, AccountDivision: any, loadingPoint: any, transportType: any, IL_Group: any, invoiceDate: any
                           //PB=product price book , like ILpriceBook,
                           let accountDivision = this.showChemical? "כימיקלים": "דשנים";
                           console.log("RAZCHECK, 663,this.transportType",this.transportType);
                           console.log("RAZCHECK, 663 680,this.rec.product.id",this.rec.product.id);
                           console.log("GETPBRECORED, 663 LILaCH,", 
                           { productId: this.rec.product.id, Account: this.accountId, IL_Group: this.prodFamily, transportType: this.transportType,
                            AccountDivision: accountDivision, loadingPoint: this.rec.loadingPoint.id, invoiceDate: new Date(),
                   }
                           );
                           getPBRecord({ productId: this.rec.product.id, Account: this.accountId, IL_Group: this.prodFamily, transportType: this.transportType,
                                    AccountDivision: accountDivision, loadingPoint: this.rec.loadingPoint.id, invoiceDate: new Date(),
                           }).then((result) => {

                                            console.log("productPriceBook result",JSON.stringify(result));
                                             if (Object.keys(result).length > 0) { 
                                              this.productPriceBook =result;
                                            console.log("productPriceBook",this.productPriceBook);
                                            console.log("RAZCHECK,632, result.chemicalTransportPrice__c",result.ChemicalTransportPrice__c);
                                            this.productPriceBookForExtValidate = true;
                                            this.chemicalTransportPrice = result.ChemicalTransportPrice__c;
                                            this.deliveryUnitOfMeasurePB = result.DeliveryUnitOfMeasure__c;
                                            }    
                                             else {  // there is no discount
                                                      this.productPriceBook =null;
                                                      this.productPriceBookForExtValidate = false;
                                                      const passEvent = new CustomEvent('prudctpricebookvalidation', {detail: this.productPriceBook});
                                                      this.dispatchEvent(passEvent);
                                                      Utils.showToast(this,"חסר מחירון","אין מחירון תקף למוצר זה","error");
                                                      Event.stoppropagation();
                                                    }
                                                    const passEvent = new CustomEvent('prudctpricebookvalidation', {detail: this.productPriceBook});
                                                    this.dispatchEvent(passEvent);
                                    }).catch((err) => {console.error(err);});
                  }
                  // console.log("RAZCHECK, 630 - 797, this.ext.Extension_1__c",this.ext?.Extension_1__c);
                  // console.log("RAZCHECK, 630 - 797, this.rec.extensions",JSON.stringify(this.rec?.extensions));
                  // console.log("RAZCHECK, 630 - 797, this.rec.extensions",this.rec?.extensions[0]?.Name);
                  // console.log("RAZCHECK, 630 - 797, this.ext.Extension_2__c",this.ext?.Extension_2__c);
                  // console.log("RAZCHECK, 630 - 797, this.rec.extensions",this.rec?.extensions[1]?.Name);
                  // console.log("RAZCHECK, 630 - 797, this.ext.Extension_3__c",this.ext?.Extension_3__c);
                  // console.log("RAZCHECK, 630 - 797, this.rec.extensions",this.rec?.extensions[2]?.Name);
                  if(this.productPriceBookForExtValidate && this.ext?.Extension_1__c){
                    let accountDivision = this.showChemical? "כימיקלים": "דשנים";
                    getPBRecord({ productId:this.ext?.Extension_1__c , Account: this.accountId, IL_Group: this.prodFamily, transportType: this.transportType,
                      AccountDivision: accountDivision, loadingPoint: this.rec.loadingPoint.id, invoiceDate: new Date(),
             }).then((result) => {

                              console.log("this.ext.Extension_1__c result",JSON.stringify(result));
                              if (Object.keys(result).length > 0) { 
                                console.log("this.ext.Extension_1__c result == true");
                              }    
                               else {  // there is no discount
                                        this.productPriceBook =null;
                                        Utils.showToast(this,"חסר מחירון",' אין מחירון תקף לתוסף הראשון'+'  '+this.rec?.extensions[0]?.Name,"error");
                                      }
                                      const passEvent = new CustomEvent('prudctpricebookvalidation', {detail: this.productPriceBook});
                                      this.dispatchEvent(passEvent);
                      }).catch((err) => {console.error(err);});
                  }
                  if(this.productPriceBookForExtValidate && this.ext?.Extension_2__c){
                    let accountDivision = this.showChemical? "כימיקלים": "דשנים";
                    getPBRecord({ productId:this.ext?.Extension_2__c , Account: this.accountId, IL_Group: this.prodFamily, transportType: this.transportType,
                      AccountDivision: accountDivision, loadingPoint: this.rec.loadingPoint.id, invoiceDate: new Date(),
             }).then((result) => {

                              console.log("this.ext.Extension_2__c result",JSON.stringify(result));
                              if (Object.keys(result).length > 0) { 
                                console.log("this.ext.Extension_2__c result == true");
                              }    
                               else {  // there is no discount
                                        this.productPriceBook =null;
                                        Utils.showToast(this,"חסר מחירון"," אין מחירון תקף לתוסף השני"+'  '  +this.rec?.extensions[1]?.Name,"error");
                                      }
                                      const passEvent = new CustomEvent('prudctpricebookvalidation', {detail: this.productPriceBook});
                                      this.dispatchEvent(passEvent);
                      }).catch((err) => {console.error(err);});
                  }
                  if(this.productPriceBookForExtValidate && this.ext?.Extension_3__c){
                    let accountDivision = this.showChemical? "כימיקלים": "דשנים";
                    getPBRecord({ productId:this.ext?.Extension_3__c , Account: this.accountId, IL_Group: this.prodFamily, transportType: this.transportType,
                      AccountDivision: accountDivision, loadingPoint: this.rec.loadingPoint.id, invoiceDate: new Date(),
             }).then((result) => {

                              console.log("this.ext.Extension_3__c result",JSON.stringify(result));
                              if (Object.keys(result).length > 0) { 
                                console.log("this.ext.Extension_3__c result == true");
                              }    
                               else {  // there is no discount
                                        this.productPriceBook =null;
                                        Utils.showToast(this,"חסר מחירון"," אין מחירון תקף לתוסף השלישי"+ '  ' +this.rec?.extensions[2]?.Name,"error");
                                      }
                                      const passEvent = new CustomEvent('prudctpricebookvalidation', {detail: this.productPriceBook});
                                      this.dispatchEvent(passEvent);
                      }).catch((err) => {console.error(err);});
                  }
         }
         prodOriginalDiscount = 0;
         prodDiscount = 0;
         prodPrice = 0;
         prodPriceBeforeDiscount = 0;
         discountRec;

        //  Id productId,Id Account,string AccountDivision, String measurementUnit,decimal amount, 
        //                            Id loadingPoint,string transportType ,string IL_Group,Date invoiceDate){

         getPriceForProduct() {
                  //productId: any, Account: any, AccountDivision: any, measurementUnit: any, loadingPoint: any, transportType: any, IL_Group: any, invoiceDate: any
           const accountDivision = this.showChemical? "כימיקלים": "דשנים";
           console.log("getPriceFor 423",this.rec.loadingPoint.id);
           let yourDate = new Date();
               yourDate.toISOString().split('T')[0];
               console.log("getPrice 591",this.rec.product.id,  this.accountId, accountDivision,this.rec.quantity,this.rec.loadingPoint.id,  this.transportType,yourDate)
              getPriceForProduct({ productId: this.rec.product.id, Account: this.accountId, AccountDivision: accountDivision,measurementUnit: "TO",amount:this.rec.quantity,
                 loadingPoint: this.rec.loadingPoint.id, transportType: this.transportType,IL_Group:null,Date:yourDate // הסלשתי 18.12 כי בפונ' צריך רק את ה2 שהשארתי
                  }).then((res) => {
                    console.log("prodPriceBeforeDiscount 424",res);
                                    this.prodPriceBeforeDiscount = res; // השמה למחירון מתחת למחיר מיוחד
                                    if (this.accountId && this.rec.product.id) {
                                             getDiscount({Account: this.accountId,prd: this.rec.product.id}).then((result) => {
                                              console.log(result,"599");
                                                               if (result ==null) {
                                                                        this.prodDiscount = 0;
                                                                        this.prodOriginalDiscount = 0;
                                                                        this.discountRec =result;
                                                                        this.prodPrice =this.prodPriceBeforeDiscount;
                                                               } else {
                                                                        this.discountRec =result;
                                                                        this.prodDiscount =result.Requested_Discount__c;
                                                                        this.prodOriginalDiscount =result.Requested_Discount__c;
                                                                        this.calculatePricesAfterDiscount(null);
                                                               }}).catch((err) => {console.error(err);});
                                    }
                           }).catch((err) => {console.error(err);});
         }

         getProduct() {
                  getProduct({productId: this.rec.product.id,}).then((res) => {
                           this.selectedProduct = res?.Crystallization_temperature__c;
                  });
         }

         productPriceChangeHandler(event) {
                  if (event?.detail?.value) {
                           this.prodPrice = Number(event.detail.value);
                  }
                  if (this.prodPriceBeforeDiscount) {
                           this.prodDiscount = +((1 -this.prodPrice / this.prodPriceBeforeDiscount) *100).toFixed(2); // אמור להיות אחוז הנחה אבל לא מודפס
                  }
         }
         discountValid = true;
         discountUnvalidMessage;
         discountInputClass = "slds-input";

         calculatePricesAfterDiscount(event) {
                  if (event?.target?.value < 0) {
                    console.log("RAZCHECK,812 ,calculatePricesAfterDiscount, קטן ");
                           this.discountUnvalidMessage = "המספר קטן מידי";
                           this.discountInputClass ="slds-input slds-has-error";
                           this.discountValid = false;}
                  if (event?.target?.value > 99.99) {
                           this.discountUnvalidMessage = "המספר גדול מידי";
                           this.discountInputClass ="slds-input slds-has-error";
                           this.discountValid = false;
                     } else {
                           this.discountUnvalidMessage = "";
                           this.discountInputClass = "slds-input";
                           this.discountValid = true;
                   }
                  if (event?.target?.value) { 
                    this.prodDiscount = Number(event.target.value);}
                  if (this.prodPriceBeforeDiscount) { 
                    this.prodPrice = +(this.prodPriceBeforeDiscount *(1 - this.prodDiscount / 100)).toFixed(2);}
         }

         createDiscount() {
                  const fields = {
                           Account__c: this.accountId,
                           CurrencyIsoCode: "ILS",
                           Display_Filter_1__c: "לקוח",
                           Display_Filter_2__c: "מוצר",
                           Start_Date__c: this.currentMonthFirstDay,
                           End_Date__c: this.currentYearLastDay,
                           Requested_Discount__c: this.prodDiscount,
                           Product__c: this.rec.product.id,
                  };
                  const recordInput = { apiName: "Discount__c", fields };
                  createRecord(recordInput).then((res) => {
                                    console.log("Success creating discount: ",res);
                           }).catch((error) => {
                                    console.log("Error creating discount: ",error);
                           });
         }

         @api clearAfterUpdate() {
                  // this.clearScreen();
                  this.template.querySelector("#mainDiv").class = "hidden";
         }

         @api clearScreen() {
          console.log("clearScreen getDefaultLP");
           // getDefault loading point - dshanim at the moment
                  this.rec = {
                           id: null,
                           product: { id: null, name: null },
                           OrderId: null,
                           quantity: null,
                           unitOfMeasure: "קוב",
                           status: null,
                           fullArea: false,
                           totalPrice: null,
                           dischargeLocation: { id: null, name: null },
                           loadingPoint: {id: this.getDefaultLP()},
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
                           Comment__c: "",
                           Purchase_Order__c: null,
                           relatedContactName: null,
                           relatedContactPhone: null,
                           deliveryNoteExist: null,
                           extensions: null,
                           driver: null,
                           supplyDate: null,
                           orderType: null,
                           OriginOrderItemId__c:null
                  };       
                  this.ext = {
                           Extension_1__c: null,
                           Extension_2__c: null,
                           Extension_3__c: null,
                           Extension_Quantity_1__c: null,
                           Extension_Quantity_2__c: null,
                           Extension_Quantity_3__c: null,
                           Extension_Unit_1__c: null,
                           Extension_Unit_2__c: null,
                           Extension_Unit_3__c: null   };
                  this.extensions = null;
                  this.quantityInSurface = null;
                  this.isAddingNote = false;
                  this.addingNoteReqiuerd = false;
                  this.totalQuantityAmount = 0;
                  this.extensionsOptionsValue = "option2";
                  this.template.querySelector("c-order-products-autocomplete").searchKey = "";
                  this.template.querySelector("c-order-generic-lookup").invalid = false;
                  // this.template.querySelector("c-order-generic-lookup").required = false;
                  this.template.querySelector("c-mutli-select-picklist").clearSelection();
                  this.prodOriginalDiscount = 0;
                  this.prodDiscount = 0;
                  this.isFrameDealRaz = true;
                  this.prodPrice = 0;
                  this.prodPriceBeforeDiscount = 0;
                  this.chemicalTransportPrice = 0;
                  this.deliveryUnitOfMeasurePB = '';
                  this.discountRec = null;
                  this.testFrame=false;
                  this.allFramedealArray=[];
                  this.framDealQuantity=null;
                  this.chosenOrderId=null;
                  this.chosenOrderItemId=null;
                  this.chosenOrderItemQuantity=null;
                  this.newFramedealArray=[];
                  this.allFramedealArray=[];
                  this.originalTransactionTypeForValidate = '';

                  const prika = this.template.querySelectorAll(".prika");
                  prika.forEach((prikaInput) => {
                            prikaInput.invalid = false;
                             prikaInput.required = false;
                  })

                  //All 4 were added by Or 13.11.22 - Prob. created a problem uploading last products per customer!!
                  //            this.accountId = null;
                  //            this.prodFamily = null;
                  //            this.transportType = null;
                  //            this.clearAccount();
         }

         consignmentLoadingPointOptions = [];
         otherLoadingPointOptions = [];

         getDefaultLP(){
            getDefaultLP().then((res) => { 
              console.log("RAZCHECK, 797, this.rec.loadingPoint.id",this.rec.loadingPoint.id);
              console.log("RAZCHECK, 797, this.rec.loadingPoint",JSON.stringify(this.rec.loadingPoint));
              console.log("RAZCHECK, 797, res",res);
               // this.rec.loadingPoint.id = res;
                // return this.rec.loadingPoint.id;
              return this.rec.loadingPoint.id = this.rec.loadingPoint.id ? this.rec.loadingPoint.id : res;
          }).catch((err) => {console.error(err.body.message);});
        }

        @api
         getSalesPoints() {
                  // נקודות מכירה
                  getSalesPoints().then((res) => {
                    // console.log("661 res",res, JSON.stringify(res));
                                    if (res.length > 0) {
                                             this.consignmentLoadingPointOptions =[];
                                             this.otherLoadingPointOptions = [];
                                             res.forEach((point) => {
                                                      if (point.LoadingPointType__c =="מחסן קונסיגנציה") {
                                                               this.consignmentLoadingPointOptions.push({label: point.LoadingPointName__c,value: point.Id,type: point.LoadingPointType__c});
                                                      } else {
                                                               this.otherLoadingPointOptions.push({label: point.LoadingPointName__c,value: point.Id,type: point.LoadingPointType__c});
                                                      }
                                             });
                                    }
                           }).catch((err) => {console.error(err.body.message);});
         }

         handleQuantityChange(event) {
           console.log("RAZCHECK,910, quantity",this.rec?.quantity);
           console.log("RAZCHECK,910, event.detail.value",event.detail.value);
           this.rec.quantity = event.detail.value;
           console.log("RAZCHECK,910, this.rec.quantity",this.rec?.quantity);
           console.log("RAZCHECK,910, this.isPrecentsInput",this.isPrecentsInput);
                  // this.getPBRecord();
                  // this.getPriceForProduct();
                  if (this.isPrecentsInput && this.isNumber(event.detail.value)) {
                           this.calculateExtensionsPrecents();
                           
                          }
                          this.getPBRecord();
                          this.getPriceForProduct();
                  // if (this.orderType=='70') {
                  //   this.totalQuantityCounter+= this.rec.quantity;
                  //   console.log(this.totalQuantityCounter,"this.totalQuantityCounter");
                  // }
         }

         onSelectUnitOfMeasureChange(event) {
          console.log("RAZCHECK, 1007 onSelectUnitOfMeasureChange", event.detail.value);
                  this.rec.unitOfMeasure = event.detail.value;
                  // this.getPBRecord();
                  // this.getPriceForProduct();
         }

         onSelectDeliveryUnitOfMeasureChange(event) {
          console.log("RAZCHECK, 960,onSelectDeliveryUnitOfMeasureChange ",event.detail.value);
                  this.rec.deliveryUnitOfMeasure = event.detail.value;
         }

         fullOrHalfSurfaceHandler(event) {
                  if (event.target.value === "mishtahMale") {
                           this.rec.fullArea = true;
                           this.halfArea = false;
                  } else {
                           this.rec.fullArea = false;
                           this.halfArea = true;
                  }
                  if (this.quantityInSurface) {
                           this.rec.quantity = Math.round(this.quantityInSurface / 2);
                           this.rec.unitOfMeasure = "יחידה";
                  }
         }
         handleHalfAreaCheckboxChange(event) {
                  if (event.currentTarget.checked) {
                           this.rec.fullArea = false;
                           this.halfArea = true;
                           if (this.quantityInSurface) {
                                    this.rec.quantity = Math.round(this.quantityInSurface / 2);
                                    this.rec.unitOfMeasure = "יחידה";
                           }
                  } else {
                           this.halfArea = false;
                  }
         }

         handleFullAreaCheckboxChange(event) {
                  if (event.currentTarget.checked) {
                           this.halfArea = false;
                           this.rec.fullArea = true;
                           if (this.quantityInSurface) {
                                    this.rec.quantity = this.quantityInSurface;
                                    this.rec.unitOfMeasure = "יחידה";
                           }
                  } else {
                           this.rec.fullArea = false;
                  }
         }

         handleTankPointsChange(event) {
                  console.log("RAZCHECK, 891 - 797,this.rec.loadingPoind",JSON.stringify(this.rec.loadingPoint));
                  console.log("RAZCHECK, 892 - 797,this.rec",JSON.stringify(this.rec));
                  this.rec.dischargeLocation.name = event.detail.selectedValue? event.detail.selectedValue: "";
                  this.rec.dischargeLocation.id = event.detail.selectedRecordId? event.detail.selectedRecordId: "";

                  if (event.detail.selectedRec == null ) {
                           this.rec.relatedContactName = "";
                           this.rec.relatedContactPhone = "";
                  } else if (
                           event.detail.selectedRec.hasOwnProperty("RelatedContact__c")) {
                           this.rec.relatedContactName =event.detail.selectedRec?.RelatedContact__r?.Name;
                           this.rec.relatedContactPhone = event.detail.selectedRec?.RelatedContact__r?.Phone? event.detail.selectedRec.RelatedContact__r?.Phone: event.detail.selectedRec.RelatedContact__r?.MobilePhone;
                  } else {
                    this.rec.relatedContactName =event.detail.selectedRec?.RelatedContact__r?.Name;
                    this.rec.relatedContactPhone = event.detail.selecteRec?.RelatedContact__r?.Phone;

                  }
         }

         // open modal
         editTankPointHandler() {
                  this.openDischargeLocationAdder = true;
                  if (!this.isDesktop) {window.scrollTo(0, 0);}
         }

         addDischargeQuantityHandler() {
          this.openDischargeQuantityAdder = true;
          if (!this.isDesktop) {window.scrollTo(0, 0);}
        }

          closeDischargeQuantityModal() {
            this.testFrame=false;
          this.openDischargeQuantityAdder = false;
        }


         // @track loadingPointOptions = [];
         //נקודת מכירה
         handleLoadingPointChange(event) {
          console.log("773 new orderTypeListener",event.detail.selectedValue,event.detail,JSON.stringify(event.detail));
          this.rec.loadingPoint.id = event.detail.selectedRecordId;
          this.rec.loadingPoint.name = event.detail.selectedValue;
          this.rec.loadingPoint.type = event.detail.selectedRec.LoadingPointType__c;
          console.log("RAZCHECK, 930 - 797,this.rec.loadingPoind",JSON.stringify(this.rec.loadingPoint));
          console.log("RAZCHECK, 930 - 797,this.rec",JSON.stringify(this.rec));
          const passEvent = new CustomEvent('loadingpointid', {detail: this.rec.loadingPoint.id});
          this.dispatchEvent(passEvent);
//           const found = this.loadingPointOptions.find(({ value }) => value === event.detail.value);
//                   this.rec.loadingPoint.id = event.detail.value;
//                   this.rec.loadingPoint.name = found.label;
//                   this.rec.loadingPoint.type = found.type;
                  this.getPBRecord();
                  this.getPriceForProduct();
         }

         handlePurchaseOrderChange(event) {
                  this.rec.Purchase_Order__c = event.detail.value;
         }

         handleSpecialPriceChange(event) {
                  this.rec.specialPrice = event.detail.value;
         }
         handleTransportPriceChange(event) {
                  this.rec.transportPrice = event.detail.value;
         }

         handleOrderItemNote(event) {
                  this.rec.Comment__c = event.detail.value;
         }

         handleRelatedContactNameChanged(event) {
                  this.rec.relatedContactName = event.detail.value;
         }

         handleRelatedContactPhoneChanged(event) {
                  this.rec.relatedContactPhone = event.detail.value;
                  console.log("this.rec.relatedContactPhone 886",this.rec.relatedContactPhone);
         }
         handleExtensionQuantity(event) { // תוספים - כמות
          try {
                   let val = event.detail.value;
                   let index = event.target.dataset.index;
                   if (index == 0) {this.ext.Extension_Quantity_1__c = val;}
                   if (index == 1) {this.ext.Extension_Quantity_2__c = val;}
                   //if (index == 3) {this.ext.Extension_Quantity_3__c = val;}
                   if (index == 2) {this.ext.Extension_Quantity_3__c = val;}
                   if (this.isPrecentsInput && this.isNumber(val)) {this.calculateExtensionsPrecents();}
          } catch (err) {
                   console.error("handleExtensionQuantity: ", err);
          }
 }

         handleExtensionUnitOfMeasure(event) { // תוספים - יחידת מידה
          try {
                  let val = event.currentTarget.value;
                  let index = event.target.dataset.index;
                  console.log("747 index",index,"val",val);
                  if (index == 0) {this.ext.Extension_Unit_1__c = val;}
                  console.log(this.ext.Extension_Unit_1__c,"line 767 Extension_Unit_1__c");
                  if (index == 1) {this.ext.Extension_Unit_2__c = val;}
                  if (index == 2) {this.ext.Extension_Unit_3__c = val;}
                  console.log("786 233 this.ext",this.ext,JSON.stringify(this.ext));
                 // if (index == 3) {this.ext.Extension_Unit_4__c = val;}
                } catch (err) {
                  console.error("handleExtensionUnitOfMeasure: ", err);
         }

         }

         @track totalQuantityAmount = 0;
         calculateExtensionsPrecents() {
                  this.totalQuantityAmount = 0;
                  let extenQuantitySum = 0;
                  const quantity = this.template.querySelectorAll(".extensions-quantity");
                  quantity.forEach((quantityInput) => {
                           let value = parseFloat(quantityInput.value);
                           extenQuantitySum += value / 100;
                  });
                  this.totalQuantityAmount = (this.rec.quantity *(1 - extenQuantitySum)).toFixed(2);
         }

         isNumber(str) {
                  if (typeof str != "string") return false; // we only process strings!
                  // could also coerce to string: str = ""+str
                  return !isNaN(str) && !isNaN(parseFloat(str));
         }

         toggleNote() {
                  this.isAddingNote = !this.isAddingNote;
                  if (this.isAddingNote && this.isDesktop) {
                           this.template.querySelector("lightning-textarea").focus();
                  } else {
                           this.rec.Comment__c = "";
                  }
         }

         @api validateFields() {
            const quantityBalance = Number(this.rec.framedealQuantity__c);
            // const currentQuantity = Number(this.rec.quantity);
          const calc = quantityBalance + (quantityBalance*0.05)

                  const comp = this.template.querySelector("c-order-products-autocomplete");
                  if (comp.selectedRecordId == "" || comp.selectedRecordId == null) {
                           comp.invalid = true;
                           comp.focusOnInput();
                           throw "אנא הזן ערך בשדה מוצר";}
                  
                  if (!this.rec.loadingPoint.id) {
                    comp.invalid = true;
                    comp.focusOnInput();
                    throw "אנא הזן ערך בשדה נקודת מכירה";
                  }

                  const quantity = this.template.querySelectorAll(".quantity");
                  quantity.forEach((quantityInput) => {
                           let value = quantityInput.value;      
                           if (value == "" || value == null || (value <= 0 && this.orderType != "40")) {  // is input valid number? if order type is not returning type: number can't be negetive
                            quantityInput.invalid = true;      
                          //  quantityInput.setCustomValidity("זהו שדה חובה"); // if there was a custom error before, reset it
                          //  quantityInput.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
                            quantityInput.focus();
                            throw " אנא הזן ערך בשדה כמות ";
                           } 
                           console.log("isFrameDealRaz 1004", this.isFrameDealRaz);
                  if( Number(this.rec.quantity) > calc && this.originalTransactionTypeForValidate == "70"){ // תנאי לחריגה - לא עובר ב5% מכמות מסגרת ובעל מסגרת
                    console.log("953 ",this.rec.quantity,this.rec.framedealQuantity__c);
                    quantityInput.invalid = true;
                   quantityInput.setCustomValidity();
                //   quantityInput.reportValidity();
                   quantityInput.focus();
                   throw ` לא ניתן לייצר הזמנה חדשה, כמות/יתרה נוצלה עד תום (עד חריגה של 5%)`;
                     }
                            else if ((this.productPriceBook == null && (this.orderType != `60` && this.orderType != `40`))) {
                              quantityInput.invalid = true;
                           //   quantityInput.setCustomValidity("זהו שדה חובה"); // if there was a custom error before, reset it
                             // quantityInput.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
                              quantityInput.focus();
                              throw `שגיאה!: אין מחירון תקף למוצר  ${this.rec.product.name}`;
                           }
                           else {
                                   quantityInput.setCustomValidity(""); // if there was a custom error before, reset it
                                   quantityInput.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
                           }
                  });
                 // const tankComp = this.template.querySelector("c-order-generic-lookup");
                 const prika = this.template.querySelectorAll(".prika");
                 if ((this.privateTransport==false) && (this.dischargeLocationRequierd && this.orderType != "20"
                  && (this.rec.dischargeLocation.id == "" || this.rec.dischargeLocation.id == null) 
                  ) ){
                    if(this.isDischargeLocationRequiredByOrederType){
                prika.forEach((prikaInput) => {
                         let value = prikaInput.value;      
                         if ((this.privateTransport==false) ) {  
                          prikaInput.invalid = true;
                           prikaInput.required = true;
                          // tankComp.focusOnInput();
                           throw "אנא הזן ערך בשדה מקום פריקה";
                  }
                    })}
              }
                  if (this.addingNoteReqiuerd && (this.rec.Comment__c == "" || this.rec.Comment__c == null)) {
                           const textarea =this.template.querySelector("lightning-textarea");
                         //  textarea.setCustomValidity(""); // if there was a custom error before, reset it
                         //  textarea.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
                           textarea.focus();
                           throw "אנא הזן ערך בשדה הערת מוצר";
                  }
          

         }

         @api checkIfHaveOnlyOneTank() {
                  // apex call with searchText and searchTerms
                  fetchExtendedLookUpValues({searchKeyWord: "",fieldsToQuery: this.tankPointsFields,objectName: "Tank__c",extraWhereClause: this.tankPointsExtraWhereClause}).then((result) => {
                                        if (result.length == 1 ) { 
                                             this.rec.dischargeLocation.id =result[0].Id;
                                             this.rec.dischargeLocation.name =result[0].Name;
                                             fireEvent = true;
                                    } else {
                                      const prika = this.template.querySelectorAll(".prika");
                                      prika.forEach((prikaInput) => {
                                               let value = prikaInput.value;      
                                                prikaInput.invalid = true;
                                                 prikaInput.required = true;
                                                // tankComp.focusOnInput();
                                                 throw "אנא הזן ערך בשדה מקום פריקה";
                                      })
                                    }
                           }).catch((err) => {
                                    console.error(err);
                                    const prika = this.template.querySelectorAll(".prika");
                                    prika.forEach((prikaInput) => {
                                             let value = prikaInput.value;      
                                              prikaInput.invalid = true;
                                               prikaInput.required = true;
                                              // tankComp.focusOnInput();
                                               throw "אנא הזן ערך בשדה מקום פריקה";
                                    })
                         });
         }
         @api submitDiscount() {
                  if (this.prodOriginalDiscount != this.prodDiscount) {
                           this.createDiscount();
                  }
         }

         @api submitFields() {
          console.log("RAZCHECK,1294 submitFields , this.rec",JSON.stringify(this.rec));
          console.log("RAZCHECK,1294 submitFields , this.rec.status",JSON.stringify(this.rec?.status));
          console.log("902 233 submitFields",this.isPrecentsInput,"this.ext",this.ext ,"this.rec.unitOfMeasure",this.rec.unitOfMeasure);
          console.log("904 233 submitFields","ex1",this.ext.Extension_1__c,"ex2",this.ext.Extension_2__c,);
          if(this.rec?.status == "70"){
            console.log("Rec is canceled");
          }
          else{
                  if (this.isPrecentsInput) {
                           const ext = {
                                    Extension_1__c: this.ext.Extension_1__c? this.ext.Extension_1__c: null,
                                    Extension_2__c: this.ext.Extension_2__c? this.ext.Extension_2__c: null,
                                    Extension_3__c: this.ext.Extension_3__c? this.ext.Extension_3__c: null,
                                    Extension_Quantity_1__c: this.ext.Extension_1__c? ((+this.ext.Extension_Quantity_1__c /100) *+this.rec.quantity).toFixed(3): null,
                                    Extension_Quantity_2__c: this.ext.Extension_2__c? ((+this.ext.Extension_Quantity_2__c /100) *+this.rec.quantity).toFixed(3): null,
                                    Extension_Quantity_3__c: this.ext.Extension_3__c? ((+this.ext.Extension_Quantity_3__c /100) *+this.rec.quantity).toFixed(3): null,
                                    Extension_Unit_1__c: this.ext.Extension_1__c ? this.rec.unitOfMeasure : null,            
                                    Extension_Unit_2__c: this.ext.Extension_2__c?this.rec.unitOfMeasure: null,
                                    Extension_Unit_3__c: this.ext.Extension_3__c? this.rec.unitOfMeasure: null,
                           };
                           const passEventr = new CustomEvent("submitcomponents",{detail: {rec: {...this.rec, quantity: this.totalQuantityAmount,},extensions: ext}});
                           this.dispatchEvent(passEventr);
                  } else {
                           const passEventr = new CustomEvent("submitcomponents",{detail: {rec: this.rec, extensions: this.ext}});
                           this.dispatchEvent(passEventr);
                  }
                }
         }

         @track precents = 0;

         handleExtensionInPrecentsQuantity(event) {
                  this.precents = event.detail.value;
         }

         radioGroupExtensionsHandler(event) { // הנדלר שמשנה את הערך למטה בבחירת אחוז/כמות לתוספים
          console.log("radioGroupExtensionsHandler",event.detail.value);        
          this.extensionsOptionsValue = event.detail.value;
         }
         @track possibleTransportValue;
         @track possibleTransportOptions = [
                  { label: "הובלה משולבת", value: "הובלה משולבת" },
                  { label: "מיוחדת", value: "מיוחדת" },
                  { label: "ללא חיוב הובלה", value: "ללא חיוב הובלה" },
                  { label: "הובלת תדלוק", value: "הובלת תדלוק" },
                  { label: "אריזה משולבת", value: "אריזה משולבת" },
                  { label: "הובלת מנוף", value: "הובלת מנוף" },
                  { label: "אריזת לקוח", value: "אריזת לקוח" },
                  { label: "נדרשת המתנה", value: "נדרשת המתנה" },

         ];
         @track possibleTransportsArray = [];

         possibleTransportchangeHandler(event) {
          console.log("RAZCHECK, 1295,  event.detail.selectedValues", event?.detail?.selectedValues);
                  this.rec.nonFreightCharge = false;
                  this.rec.refuelingTransport = false;
                  this.rec.combinedPackaging = false;
                  this.rec.combinedTransport = false;
                  this.rec.specialTransport = false;
                  this.rec.customerPackaging = false;
                  this.rec.waitingRequired = false;
                  this.rec.craneTransport = false;

                  if (event.detail.selectedValues.length > 0) {
                           event.detail.selectedValues.forEach((val) => {
                                    if (val == "הובלה משולבת") {this.rec.combinedTransport = true;}
                                    if (val == "מיוחדת") {this.rec.specialTransport = true;}
                                    if (val == "אריזת לקוח") {this.rec.customerPackaging = true;}
                                    if (val == "נדרשת המתנה") {this.rec.waitingRequired = true;}
                                    if (val == "ללא חיוב הובלה") {this.rec.nonFreightCharge = true;}
                                    if (val == "הובלת תדלוק") {this.rec.refuelingTransport = true;}
                                    if (val == "אריזה משולבת") {this.rec.combinedPackaging = true;}
                                    if (val == "הובלת מנוף") {this.rec.craneTransport = true;}
                           });
                  }
                  this.getPriceForProduct();
         }

         handlePossibleTransportRemove(event) {
                  const valueRemoved = event.target.value;
                  this.possibleTransportsArray.splice(this.possibleTransportsArray.indexOf(valueRemoved),1);
         }
         openDeliveryNoteModal;
         handleDeliveryNotePopup() {
                  this.openDeliveryNoteModal = true;
                  this.getDeliveryNoteInfo();
         }
         closeDeliveryNoteModal() {
                  this.openDeliveryNoteModal = false;
         }

         @track extensionsOptionsValue = "option2";
         getUnitOfMeasureByAccumaltionState(unitOfMeasureCode) {
                  if (unitOfMeasureCode == "" ||unitOfMeasureCode == undefined ||unitOfMeasureCode == null) {
                           return null;
                  }
                  if (unitOfMeasureCode == "1") {return "טון";}
                  if (unitOfMeasureCode == "2") {return "קוב";}
                  if (unitOfMeasureCode == "9") {return "יחידה";
                  } else return "קוב";
         }

         getUnitOfMeasureName(unitOfMeasureCode) {
                  if (unitOfMeasureCode == "" ||unitOfMeasureCode == undefined ||unitOfMeasureCode == null) {
                           return null;
                  }
                  if (unitOfMeasureCode == "M3") {return "קוב";}
                  if (unitOfMeasureCode == "LTR") {return "ליטר";}
                  if (unitOfMeasureCode == "TO") {return "טון";}
                  if (unitOfMeasureCode == "KG") {return "קילו";}
                  if (unitOfMeasureCode == "EA") {return "יחידה";
                } else return unitOfMeasureCode;
         }

         deliveryNoteLoad = false;
         handleDeliveryNoteLoad() {
                  this.deliveryNoteLoad = true;
         }

         ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         ////////////////////////////////////              getters                        //////////////////////////////////////////
         ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
get getPrivateTransport(){
  console.log("privateTransport",this.privateTransport);
  return this.privateTransport? false :true ;
// return false;
}
         get productPrice() {
             return this.prodPriceBeforeDiscount? this.prodPriceBeforeDiscount: ``;
          }

         get chemicalTransportPriceGetter() {
             return this.chemicalTransportPrice? this.chemicalTransportPrice: ``;
          }

         get deliveryUnitOfMeasureGetter() {
             return this.deliveryUnitOfMeasurePB? this.deliveryUnitOfMeasurePB: ``;
          }

         get labelAmount() {
                  return this.isPrecentsInputTotalQuantityAmount? `מוצר בסיס: ${this.totalQuantityAmount}`: "כמות";
         }

         get currentMonthFirstDay() {
                  const currentMonth = new Date().getMonth();
                  const currentYear = new Date().getFullYear();
                  const firstDayOfTheMonth = new Date(currentYear,currentMonth,2).toISOString();
                  return firstDayOfTheMonth;
         }

         get currentYearLastDay() {
                  const currentYear = new Date().getFullYear();

                  const lastDay = new Date(currentYear, 11, 32).toISOString();
                  return lastDay;
         }
         get hasExtensions() {
                  return this.extensions > 0 ? true : false;
         }
         get isPrecentsInput() {
                  return this.extensionsOptionsValue == "option1"? true: false;
         }

         get extensionsOptions() {
                  return [
                           { label: "אחוז מחומר", value: "option1" },
                           { label: "כמות", value: "option2" },
                  ];
         }
         get surfaceRadioOptions() {
                  return [
                           { label: "חצי משטח", value: "haziMishtah" },
                           { label: "משטח מלא", value: "mishtahMale" },
                  ];
         }

         get selectedProductId() {
                  return this.rec.product.id;
         }

         get tankPointsExtraWhereClause() {
          return this.accountId? ` AND Account__c = '${this.accountId}' AND (Status__c != true)`: "AND Account__c = 'null'";
         }
         get salesPointExtraWhereClause() { // orderGenericLookup extrawhereclause
          // console.log(this.orderTypeFromLayoutOnchange,"this.orderTypeFromLayoutOnchange 380 431");
          console.log("RAZCHECK, 1454,this.orderTypeFromLayoutOnchange ",this.orderTypeFromLayoutOnchange );
          if(this.orderTypeFromLayoutOnchange != '20' && this.orderTypeFromLayoutOnchange != '50'){
            return ` AND LoadingPointType__c != 'מחסן קונסיגנציה'`;
          }
          else{
            return ` AND LoadingPointType__c = 'מחסן קונסיגנציה'`;
          }
          // return this.orderTypeFromLayoutOnchange != '20' ? ` AND LoadingPointType__c != 'מחסן קונסיגנציה'` : ` AND LoadingPointType__c = 'מחסן קונסיגנציה'`;
 }
 dischargeLocationId;
         get container() {
          // console.log("RAZCHECK, 1266", JSON.stringify(this.rec));
          // console.log("RAZCHECK, 1266", JSON.stringify(this.rec.product.name));
          this.dischargeLocationId=this.rec.dischargeLocation.id;
          if (this.rec.status === "70" && this.orderStatus != "מבוטל") {
                           return "hidden";
                  }
                  if (this.rec.status === "30" || this.rec.status === "40" ||this.rec.status === "70") {
                           return "disabled slds-grid slds-wrap";
                  } else {
                           return "slds-grid slds-wrap id={this.rec.id}";
                  }
         }

         get orderItemContainerTitle() {
          console.log("razcheck, 1322,orderItemContainerTitle",this.rec.status);
                  return this.rec.status === "70" ? "מבוטל" : "";
         }

         get unitOfMeasureOptions() {
                  if (this.accumulationState == 1) {
                           return [
                                    { label: "טון", value: "טון" },
                                    {label: "קילו",value: "קילו"},
                                    {label: "יחידה", value: "יחידה"},
                           ];
                  } else {
                           return [
                                    { label: "קוב", value: "קוב" },
                                    {label: "ליטר",value: "ליטר"},
                                    { label: "טון", value: "טון" },
                                    {label: "קילו", value: "קילו"},
                                    {label: "יחידה", value: "יחידה"},
                           ];
                  }
         }
         get deliveryUnitOfMeasureOptions() {
               return [
                             { label: "טון", value: "TO" },
                             {label: "קוב",value: "M3"},
                            {label: "משאית", value: "Truck"},
                     ];
         }

         get qunatityContainerStyle() {
                  switch (FORM_FACTOR) {
                           case "Large":
                                    return "slds-col slds-size_1-of-1 slds-large-size_2-of-12 slds-size_x-small slds-grid";
                           case "Medium":
                                    return "slds-col slds-m-left_small slds-m-right_small slds-size_1-of-1 slds-size_x-small slds-grid";
                           case "Small":
                                    return "slds-col slds-m-left_small slds-m-right_small slds-size_1-of-1 slds-size_x-small slds-grid";
                           default:
                  }
         }

         get unitOfMeasureComboboxStyle() {
                  return "";
                  // return this.isDesktop ? "slds-form-element__control slds-size_xx-small slds-p-top_xxx-small slds-m-top_xxx-small" : "slds-form-element__control slds-size_xx-small slds-p-top_xxx-small";
         }
         get showSalesPoint() {
          return this.isDesktop | this.showChemical ? true : false;}

         get showSpecialPrice() {
          // return this.isChemicals  ? true : false;    12.3.23 הוסלש
          return this.isChemicals  ? true : false;
        }
         get isProductHasAddOn() {
                  if (this.rec.extensions?.length > 0) { return true;
                  } else { return false;
                  }
         }

         get isOrderProductItemNotForChange() {
          // console.log('RAZCHECK,1338,BLABLA,this.rec ',JSON.stringify(this.rec));
          // console.log('RAZCHECK,1339,BLABLA,this.rec.status ', this.rec.status);
          // console.log('RAZCHECK,1339,BLABLA,this.rec.orderTypeNew ', this.rec.orderTypeNew);
          // console.log('RAZCHECK,1340,BLABLA,this.rec.OrderItemNumber ', this.rec.OrderItemNumber);
          // console.log('RAZCHECK,1341,BLABLA,this.orderType ', this.orderType);
          if(!this.rec.status || this.rec.status === ''){
                    // console.log('RAZCHECK,1345,BLABLA,FIRSTIF');
                    if(this.rec.orderTypeNew =='60' && this.orderType ==`60`){
                      // console.log('RAZCHECK,1345,BLABLA,FIRSTIF TRUE');
                      return true;
                    }
                    else{
                      // console.log('RAZCHECK,1345,BLABLA,FIRSTIF, FALSE');
                      return false;
                    }
                  }
             // אם סוג עסקה שיוך או החזרה - הפוך שדה מוצר לדיסאבלד
                  else if (this.rec.OrderItemNumber || this.orderType ==`60` || this.orderType ==`40`) {
                    // console.log('RAZCHECK,1352,BLABLA,this.rec.OrderItemNumber ', this.rec.OrderItemNumber);
                    // console.log('RAZCHECK,1353,BLABLA,this.orderType ', this.orderType);
                    return true;
                  }
                  else if(this.rec.status != 'טיוטה' && this.rec.status != 'מוכן לשיבוץ'){
                    // console.log('RAZCHECK,1357,BLABLA,this.rec.status ', this.rec.status);
                    return true;
                  }
                  else {
                      return false;
                  }
         }

         get isNotAllowedToChangeBecuseOrderItemStatus(){
          // console.log("RAZCHECK,1360, ",this.rec.status);
          if(this.rec.status !== '10' && this.rec.status !== '20' && this.rec.status !== null && this.rec.status !== '' ){
            // console.log("RAZCHECK,1344,true ",this.rec.status);
            return true;
          }
          else{
            // console.log("RAZCHECK,1348,false ",this.rec.status);
            return false;
          }
         }

         get isNotAllowedToChangeBecuseOrderItemStatusAndOrderType(){
          // console.log("RAZCHECK,1360, ",this.rec.status);
          if(this.rec.status !== '10' && this.rec.status !== '20' && this.rec.status !== null && this.rec.status !== '' ){
            // console.log("RAZCHECK,1385,true ",this.rec.status);
            return true;
          }
          else if(this.rec.status === '' || this.rec.status == null && (this.rec.orderTypeNew =='60' && this.orderType ==`60`)){
            // console.log("RAZCHECK,1389,true ",this.rec.status);
            return true;
          }
          else{
            // console.log("RAZCHECK,1348,false ",this.rec.status);
            return false;
          }
         }

        //  switch (this.rec.status) {
        //   case "10":return "טיוטה";
        //   case "20":return "מוכן לשיבוץ";
        //   case "30":return "שובץ";
        //   case "40":return "סגור";
        //   case "50":return "מבוטל";

         

         get isForEditTitle() {
                  return this.rec.dischargeLocation.id == "" || this.rec.dischargeLocation.id == null ? "הוספה" : "עריכה";
         }
         get isForEditIcon() {
                  return this.rec.dischargeLocation.id == "" || this.rec.dischargeLocation.id == null? "utility:add": "utility:edit";
         }

         get isDischargeLocationNotPopulated() {
                  if (this.rec.dischargeLocation.id == "" || this.rec.dischargeLocation.id == null) {
                           return true;
                  } else {
                           return false;
                  }
         }

         get dischargeLocationModalTitle() {
                  if (
                           (this.rec.dischargeLocation.id == "" ||this.rec.dischargeLocation.id == null) && this.openDischargeLocationAdder) {
                           return "הוספת מקום פריקה חדש";
                  } else {
                           return "עריכת מקום פריקה";
                  }
         }
         get dischargeLocationModalTitle2() {
          if ((this.rec.dischargeLocation.id == "" || this.rec.dischargeLocation.id == null) && this.openDischargeLocationAdder ) {
                   return "חלוקת כמויות לפריקה";
          } else {
                   return "עריכת כמויות לפריקה";
          }
 }

         get isPrecentsInputTotalQuantityAmount() {
                  return this.isPrecentsInput && this.totalQuantityAmount? true: false;
         }

         get toggleNoteBtnText() {
                  if (this.isAddingNote) {
                           return "- הסרת הערה";
                  }
                  return "+ הוספת הערה";
         }

         get maxQuantity() {
                  return this.orderType == "40" ? 0 : null;
         }

         get getMinQuantity() {
          console.log("RAZCHECK, 1672,getMinQuantity ",this.minQuantity);
          console.log("RAZCHECK, 1672, oredrtype",this.orderType);
          if(!this.orderType){
            if(this.orderTypeFromLayoutOnchange){
              this.orderType = this.orderTypeFromLayoutOnchange;
              console.log("RAZCHECK, 1672, 1677, oredrtype",this.orderType);
            }
          }
             return this.orderType == "40" ? this.minQuantity : 0;
         }

         get quantityUnitOfMeasureComboboxVariant() {
                  return this.isDesktop ? "label-stacked" : "standard";
         }

         get noChargeCheckboxCss() {
                  switch (FORM_FACTOR) {
                           case "Large":
                                    return "checkboxGroup slds-p-left_small slds-col slds-size_1-of-2 slds-large-size_1-of-8 slds-size_x-small slds-grid";
                           case "Medium":
                                    return "checkboxGroup slds-col slds-size_1-of-1 slds-large-size_1-of-8 slds-size_x-small slds-grid";
                           case "Small":
                                    return "checkboxGroup slds-col slds-size_1-of-1 slds-large-size_1-of-8 slds-size_x-small slds-grid";
                           default:
                  }
         }
         get styleForMeasureUnit() {
                  return this.isDesktop? "desktopStyleForMeasureUnit": "mobileStyleForMeasureUnit";
         }
         get isDesktop() {
                  switch (FORM_FACTOR) {
                           case "Large":return true;
                           case "Medium":return false;
                           case "Small":return false;
                           default:
                  }
         }
         get transportType() {
          let arrOfTransportTypesGetter = '';
          console.log("RAZCHECK, 1671 1680,this.rec.nonFreightCharge ",this.rec.nonFreightCharge);

                  if(this.privateTransport || this.rec.nonFreightCharge || this.rec.customerPackaging || this.rec.waitingRequired) {
                    console.log("RAZCHECK, 1671 1680,Without IF ");

                    if(arrOfTransportTypesGetter != ''){
                      arrOfTransportTypesGetter += ', ';
                    }
                    arrOfTransportTypesGetter += "Without";
                  }
                  if(this.rec.combinedTransport) {
                    if(arrOfTransportTypesGetter != ''){
                      arrOfTransportTypesGetter += ', ';
                    }
                    arrOfTransportTypesGetter += "Integrated transport";
                  }
                  if(this.rec.craneTransport) {
                    if(arrOfTransportTypesGetter != ''){
                      arrOfTransportTypesGetter += ', ';
                    }
                    arrOfTransportTypesGetter += "craneTransport";
                  }
                  if(this.rec.specialTransport || this.rec.refuelingTransport || this.rec.combinedPackaging) {
                    if(arrOfTransportTypesGetter != ''){
                      arrOfTransportTypesGetter += ', ';
                    }
                      arrOfTransportTypesGetter += "Regular";
                  }
                  if(arrOfTransportTypesGetter == ''){
                    arrOfTransportTypesGetter = "Regular"; 
                  }
                  console.log("RAZCHECK, 1671 1680,arrOfTransportTypesGetter ",arrOfTransportTypesGetter);
                  return arrOfTransportTypesGetter;
         }
         get Status() {
                  if (this.rec.status) {
                           switch (this.rec.status) {
                                    case "10":return "טיוטה";
                                    case "20":return "מוכן לשיבוץ";
                                    case "30":return "שובץ";
                                    case "40":return "סגור";
                                    case "70":return "מבוטל";
                                    default:
                           }
                  } else return null;
         }
         get DisplayStatus() {

                  if (this.rec.displayStatus){
                    console.log("get DisplayStatus, RAZ 1436,", this.rec.displayStatus)
                    return this.rec.displayStatus;
                  }
         }

        //נקודות מכירה - מוצג בהתאם לסלקט סוג עסקה
        get loadingPointOptions() {
          console.log("loadingPointOptions 1386 661",this.consignmentLoadingPointOptions,this.otherLoadingPointOptions);
          if (this.orderType == "50") {
                   return [...this.consignmentLoadingPointOptions,...this.otherLoadingPointOptions];
          } else if(this.isKolDeshen){
            return this.orderType == "20"? this.consignmentLoadingPointOptions: this.otherLoadingPointOptions; 
          }else{
            return this.orderType == "20"? this.consignmentLoadingPointOptions: this.otherLoadingPointOptions;
          }
 }

         get userIsAgrunom() {
          // return this.profileType == "IL - Sales manager" || "System Administrator"? true: false;
         return this.profileType == "IL - Sales manager" ? true: false;
        }
         //שדה: מספר הזמנה יוצג במידה ונק' מכירה היא מסוג ספק
         get isLoadingPointTypeSuppliers() {
                  if (
                           this.rec.loadingPoint.loadingType === "ספק" ||
                           this.rec.loadingPoint.type === "ספק"
                  ) {
                           return true;
                  } else {
                           return false;
                  }
         }
         get isDischargeLocationRequiredByOrederType(){
          console.log("RAZCHECK,1660,isDischargeLocationRequiredByOrederType ",this.orderTypeFromLayoutOnchange);
          if(this.orderTypeFromLayoutOnchange == '20'){
            console.log("RAZCHECK,1660,isDischargeLocationRequiredByOrederType, 20 false ",)
            return false;
          }
          else if (this.orderTypeFromLayoutOnchange == '80'){
            console.log("RAZCHECK,1660,isDischargeLocationRequiredByOrederType, 80 false ",)
            return false;
          }
          else if(this.originOrderType == '20'){
            console.log("RAZCHECK,1660,isDischargeLocationRequiredByOrederType, 20 false ",)
            return false;
          }
          else if(this.originOrderType == '80'){
            console.log("RAZCHECK,1660,isDischargeLocationRequiredByOrederType, 80 false ",)
            return false;
          }
          else{
            console.log("RAZCHECK,1660,isDischargeLocationRequiredByOrederType, true ",)
            return true;
          }
         }
}