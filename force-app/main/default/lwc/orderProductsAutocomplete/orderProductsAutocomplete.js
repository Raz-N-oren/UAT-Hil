import { LightningElement, track, wire, api } from "lwc";
// getLastProductsForUser
import searchProductByNameMethod from "@salesforce/apex/OrderCustomerController.searchProductByNameMethod";
import searchProductByNameAndMasterProductMethod from "@salesforce/apex/OrderCustomerController.searchProductByNameAndMasterProductMethod";
import getLastProductsForAccount from "@salesforce/apex/OrderCustomerController.getLastOrdersForAccount";
import getMasterProduct from "@salesforce/apex/OrderCustomerController.getMasterProduct";
import FORM_FACTOR from "@salesforce/client/formFactor";
// import getLastOrdersForAccount2 from "@salesforce/apex/OrderCustomerController.getLastOrdersForAccount2";
// import { getFieldValue } from 'lightning/uiRecordApi';
import getPricebookEntryId from "@salesforce/apex/OrderCustomerController.getPricebookEntryId";

const DELAY = 300;
export default class ProductsAutocomplete extends LightningElement {
  @track recordsList;
  @api searchKey = "";
  currentSearchKey = "";
  @api selectedValue;
  selectedValue2 = true;
  getPreviousOrders = null;
  @api selectedRecordId;
  @api selectedRecord; // כל הרשומה הנבחרת
  @api lookupLabel; //לייבל מעל האינפוט "חפש מוצר"
  @api accountId; // ססטנדרט, הפריימרי קי אידי של אותו יוזר
  @track message; // הודעה קטנה בדרופדאון מתחת לאינפוט
  hideMessage;
  @api disabled = false; //readOnly
  @api invalid; // טוגל ולידי / לא ולידי
  showSpinner = false;
  showHistory = false; //הצג\הסתר רשומות אחרונות
  @track masterProductsOptions = [{ label: "נקה", value: "" }]; //סנן/משפחת מוצרים
  filterValue; // הערך שנבחר בסנן
  @api selectedProduct = false;
  @api isShown = false;
  @api isHazard = false;
  specificGravityValue = ``;
 
  @api clearAccount() {
      this.selectedRecordId = null;
      this.selectedValue = null;
      this.selectedRecord = null;
      // this.onSelectedRecordUpdate();
}
//  @wire getFieldValue({record: Product2, field:Crystallization_temperature__c} )

  // getLastOrderss(event) {
  //   console.log("YOU ARE HERE getLastOrderss, getItemComponent",event);
  //   this.loadingSpinner = true;
  //   this.lastOrders = [];
  //   try {
  //     getLastOrdersForAccount2({ recordId: this.accountId,productId:this.rec.product.id })
  //       .then((response) => {
  //         console.log("is it working????", response);
  //         response.forEach((res) => {
  //           if (res.Id != this.recordId) {
  //             if (res.hasOwnProperty("OrderItems")) {
  //               const orderItems = [];
  //               res.OrderItems.forEach((item) => {
  //                 orderItems.push({ ...item });
  //               });
  //               this.lastOrders.push({ ...res, OrderItems: orderItems });
  //             } else {
  //               this.lastOrders.push({ ...res });
  //             }
  //           }
  //         });
  //         this.loadingSpinner = false;
  //       })
  //       .catch((error) => {
  //         this.loadingSpinner = false;
  //         console.error(error);
  //       });
  //   } catch (error) {
  //     console.log(error, "catch at getLastOrdersForAccount2");
  //   }
  // }

  connectedCallback() { 
    console.log("RAZCHECK, 77,this.selectedValue ",this.selectedValue);
  }

  renderedCallback() {
    console.log("RAZCHECK, 82,this.selectedValue ",this.selectedValue);
  }

  disconnectedCallback() {
    console.log("RAZCHECK, 85,this.selectedValue ",this.selectedValue);
    this.selectedValue = null;
    console.log("RAZCHECK, 87,this.selectedValue ",this.selectedValue);
  }

  onLeave(event) {

    console.log("LINE 64:",event.detail,event.target);
    
    this.getMasterProduct();
    console.log("RAZCHECK, 93,this.selectedValue ",this.selectedValue);

    setTimeout(() => {
      this.recordsList = null;
    }, DELAY);
  }

  onRecordSelection(event) {
    // console.log("EVENT!",event);
    console.log("RAZCHECK, 102,this.selectedValue ",this.selectedValue);
    this.selectedRecordId = event.target.dataset.key;
    this.selectedValue = event.target.dataset.name;
    this.selectedRecord = event.target.dataset.record; //את כל הרקורד
    console.log("RazCHECK, 108,this.selectedRecord !!!!", this.selectedRecord);
    console.log("HERE!!!!", event.target.dataset.key);
    console.log("RAZCHECK, 93,this.selectedValue, ",this.selectedValue);

    // this.searchKey = "";
    // this.getPreviousOrders.forEach((currentOrder) => {
    //   currentOrder.OrderItems.find((currentOrderItemsArray) => {
    //     while (
    //       currentOrderItemsArray.Product2Id === this.selectedRecordId ||
    //       this.selectedValue2 == null
    //     ) {
    //       this.selectedValue2 = true;
    //       console.log("WHILE LOOP - True!!!");
    //       break;
    //     }
    //   });
    // });
    this.onSelectedRecordUpdate(); //הדיספוצ' לאבא
  }

  onFocus() {
    //הבאת מוצרים לפי בחירת ערך מדרופדאון
    if (this.searchKey == "" || this.searchKey == undefined) {
      this.recordsList = [];
      // offset - לימיט בשרת - תביא הכל 0 מההתחלה כלומר את האיבר הראשון
      getLastProductsForAccount({ recordId: this.accountId, offset: 0 }).then((result) => {
        console.log("00 getLastProductsForAccount 114",result );
          try {
            this.getPreviousOrders = result.map((order) => order);
            console.log("007 this.getPreviousOrders 117", this.getPreviousOrders);
            if (result.length > 0) {
              result.forEach((res) => {
                if (res.hasOwnProperty("OrderItems")) {
                  res.OrderItems.forEach((item) => {
                    console.log("RAZCHECK,141, item",item);
                    console.log("RAZCHECK,141, item.Product2",item.Product2);
                    let product = {...item?.Product2,
                      CreatedDate: item?.CreatedDate.split("T")[0],
                      UnitPrice: item?.UnitPrice,
                      Extension_1__r: item?.Extension_1__r,
                      Extension_2__r: item?.Extension_2__r,
                      Extension_3__r: item?.Extension_3__r,
                      Extension_1__c: item?.Extension_1__c,
                      Extension_2__c: item?.Extension_2__c,
                      Extension_3__c: item?.Extension_3__c
                    };
                    const found = this.recordsList.find(
                      ({ Id }) => Id === item.Product2.Id
                    ); //אם באיטרציה קודמת נכנס כבר מוצר זהה למוצר באיטרציה הנוכחית - אל תוסיף למערך
                    if (found == undefined) {
                      this.recordsList.push(product);
                    }
                  });
                  this.recordsList = JSON.parse(JSON.stringify(this.recordsList));
                  // this.recordsList.sort(function(a,b){ // מסדר לפי הא ב  את המוצרים שמופיעים בעת לחיצה על האינפוט
                  //   if(a.Name < b.Name){
                  //     return -1;
                  //   }
                  //   if(a.Name > b.Name){
                  //     return 1;
                  //   }
                  //   return 0
                  // })
                  console.log(" this.recordsList, 170",  JSON.stringify(this.recordsList));
                  this.showHistory = true;
                  this.hideMessage = false;
                  this.message = "מוצרים אחרונים שהוזמנו..";
                } else {
                  this.hideMessage = true;
                  this.message = "";
                }
              });
            } else {
              this.invalid = false; // כן ולידי
              this.hideMessage = true;
              this.message = "";
            }
          } catch (err) {
            console.log("error get on focus data: ", err);
          }
        }).catch((err) => {
          console.error(err);
        });
    } else {
      this.getLookupResult(); // אחרת תביא דאטה לפי מילת חיפוש
    }
  }
  globalChar;
  //חידה: מי מפעיל אותי? זה מלמטה
  getLookupResult() {
    //הבאת מוצרים לפי מילת/תווי חיפוש
    this.showSpinner = true;
    this.showHistory = false;
    if (this.filterValue) {
      searchProductByNameAndMasterProductMethod({searchText: this.searchKey,masterProduct: this.filterValue}).then((result) => {
            console.log("searchProductByNameAndMasterProductMethod res",result);
          this.recordsList = result;
          if (result[0].length === 0) {
            this.showSpinner = false;
            this.hideMessage = false;
            this.message = "לא נמצאו רישומים..";
          } else {
            this.showSpinner = false;
            this.hideMessage = true;
            this.message = "";
          }
          this.error = undefined;
        }).catch((error) => {
          this.showSpinner = false;
          this.error = error;
          this.recordsList = undefined;
        });
    } else {
      console.log("searchKey b4 sending to server",this.searchKey);
                  let convertToString = String(this.searchKey);
                  this.globalChar=/\-/;
                  let convertToString2 = convertToString.replaceAll("-","\-").replaceAll("+","\+").replaceAll("%","\%").replaceAll("|","\|");
                  console.log("convertToString2", convertToString2);
                  let stringForSearch = convertToString2.replaceAll("/","")
             //  const tt=   convertToString.replace(`-`, `\-`).replace(`+`, `\+`);
                 // convertToString.replace("+", "\+");   
                  console.log("string before sending to server",stringForSearch);
      searchProductByNameMethod({ searchText: stringForSearch }).then((result) => {
            console.log("searchProductByNameMethod res",result);
            this.recordsList = result;
            this.recordsList.sort(function(a,b){ // מסדר לפי הא ב את המוצרים שמגיעים בעת חיפוש מוצר
              if(a.Name < b.Name){
                return -1;
              }
              if(a.Name > b.Name){
                return 1;
              }
              return 0
            })
      //     const getIdFromArray = this.recordsList.map((currentProduct)=> {return currentProduct.Id})
      //     console.log("searchProductByNameMethod getIdFromArray:",getIdFromArray);
      // result.map((currentPtoduct)=>{
      //           getPricebookEntryId(currentPtoduct.Id).then((result) => {
      //             console.log("getPricebookEntryId make it ID!:",currentPtoduct);

      //             const bb = result;
      //             console.log("getPricebookEntryId 201",bb);
      //           }).catch(console.log("error getPricebookEntryId 201"));
      //     })
          if (result[0].length === 0) {
            this.showSpinner = false;
            this.hideMessage = false;
            this.message = "לא נמצאו רישומים..";
          } else {
            this.showSpinner = false;
            this.hideMessage = true;
            this.message = "";
          }
          this.error = undefined;
        }).catch((error) => {
          this.showSpinner = false;
          this.error = error;
          this.recordsList = undefined;
        });
    }
  }

  handleKeyChange(event) {
    // מוטרג ע"י ההטמל - מפעיל פונ מעל
    event.stopPropagation(); // עוצר את האבנט רגע
    console.log("event 240",event.target.value);
    const searchKey = event.target.value;
    if (this.searchKey != searchKey) {
      this.searchKey = searchKey;
      window.clearTimeout(this.timeout);
      this.timeout = window.setTimeout(() => {
        this.getLookupResult();
      }, DELAY);
    }
  }

  removeRecordOnLookup() {
    // מוחק רשומה לאחר שנבחרה
    // this.searchKey = "";
    console.log("RAZCHECK, 268,this.selectedValue ",this.selectedValue);
    this.selectedValue = null;
    this.selectedRecordId = null;
    this.selectedRecord = null;
    this.recordsList = null;
    this.masterProductsOptions = [];
    this.onSelectedRecordUpdate();
    console.log("RAZCHECK, 275,this.selectedValue ",this.selectedValue);

  }

  insertSelectedRecordExtensionsToArray(selectedRecord) {
    console.log("RAZCHECK, 300 ,insertSelectedRecordExtensionsToArray,selectedRecord  ",JSON.stringify(selectedRecord));
    //מיפוי לתוספים והוספתם למערך בצורה מסודרת
    const extensions = [];
    if (selectedRecord?.Extension_1__c) {
      const extension1 = {Id: selectedRecord.Extension_1__c,Name: selectedRecord.Extension_1__r.Name};
      extensions.push(extension1);
    }
    if (selectedRecord?.Extension_2__c) {
      const extension2 = {Id: selectedRecord.Extension_2__c,Name: selectedRecord.Extension_2__r.Name};
      extensions.push(extension2);
    }
    if (selectedRecord?.Extension_3__c) {
      const extension3 = {Id: selectedRecord.Extension_3__c,Name: selectedRecord.Extension_3__r.Name};
      extensions.push(extension3);
    }
    if (selectedRecord?.Extension_4__c) {
      const extension4 = {Id: selectedRecord.Extension_4__c,Name: selectedRecord.Extension_4__r.Name};
      extensions.push(extension4);
    }
    if (selectedRecord?.Extension_5__c) {
      const extension5 = {Id: selectedRecord.Extension_5__c,Name: selectedRecord.Extension_5__r.Name};
      extensions.push(extension5);
    }
    if (selectedRecord?.Extension_6__c) {
      const extension6 = {Id: selectedRecord.Extension_6__c,Name: selectedRecord.Extension_6__r.Name};
      extensions.push(extension6);
    }
    if (selectedRecord?.Extension_7__c) {
      const extension7 = { Id: selectedRecord.Extension_7__c, Name: selectedRecord.Extension_7__r.Name };
      extensions.push(extension7);
    }
    if (selectedRecord?.Extension_8__c) {
      const extension8 = {Id: selectedRecord.Extension_8__c, Name: selectedRecord.Extension_8__r.Name };
      extensions.push(extension8);
    }
    return extensions;
  }

  onSelectedRecordUpdate() {
    console.log("autocomplete before try",this.selectedRecord, JSON.stringify(this.recordsList));
    try {
      //עושה סדר במוצר לפני ששולח לאבא
      if (this.recordsList != null) {
        console.log("autocomplete inside 1st if ");
        
        const selectedRecord = this.selectedRecord ? this.selectedRecord : this.recordsList.find((element) => element.Id == this.selectedRecordId); //כל האוביקט הנבחר
        console.log("RAZCHECK, 339 ,selectedRecord ",JSON.stringify(selectedRecord));
        console.log("RAZCHECK, 339 ,specific_gravity__c ",selectedRecord.specific_gravity__c);
        this.specificGravityValue = selectedRecord?.specific_gravity__c ? selectedRecord?.specific_gravity__c : ``;
        console.log("RAZCHECK, 339 ,this.specificGravityValue ",this.specificGravityValue);
        if (selectedRecord?.hasOwnProperty("Extension_1__c") || selectedRecord?.hasOwnProperty("Extension_2__c") || selectedRecord?.hasOwnProperty("Extension_3__c") || selectedRecord?.hasOwnProperty("Extension_4__c") ||
          selectedRecord?.hasOwnProperty("Extension_5__c") || selectedRecord?.hasOwnProperty("Extension_6__c") || selectedRecord?.hasOwnProperty("Extension_7__c") || selectedRecord?.hasOwnProperty("Extension_8__c")
          ){
            console.log("autocomplete inside 2nd if ");
          const extensions = this.insertSelectedRecordExtensionsToArray(selectedRecord);
          const passEventr = new CustomEvent("recordselection", { detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue, quantityInSurface: selectedRecord?.Quantity_in_surface__c, selectedRecord: selectedRecord, extensions: extensions } });
          this.dispatchEvent(passEventr);
          console.log("RAZCHECK, 332,this.selectedValue ",this.selectedValue);

        } else {
          const found = this.recordsList.find(({ Id }) => Id === this.selectedRecordId);
          const selectedRecord = JSON.parse(JSON.stringify(found));
          const passEventr = new CustomEvent("recordselection", { detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue, quantityInSurface: selectedRecord?.Quantity_in_surface__c, selectedRecord: selectedRecord, extensions: [] } });
          this.dispatchEvent(passEventr);
          console.log("RAZCHECK, 339,this.selectedValue ",this.selectedValue);
        }
      } else {
        const passEventr = new CustomEvent("recordselection", { detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue, quantityInSurface: null, extensions: [] } });
        this.dispatchEvent(passEventr);
        console.log("RAZCHECK, 345,this.selectedValue ",this.selectedValue);

      }
    } catch (err) {
      console.log("Error update product: ", err);
    }
  }

  @api focusOnInput() {
    //כופה בכוח פוקוס על האינפוט
    this.template.querySelector(".input").focus();
  }

  getMasterProduct() {
    //onmouse leave event - trigger this function
    if (this.currentSearchKey != this.searchKey) {
      //אם המילת חיפוש מוצר שונה ממילת חיפוש בסטייס
      this.filterValue = ""; //מה נבחר בדרופדאון סנן
      getMasterProduct({ searchKey: "%" + this.searchKey + "%" }).then((result) => {
          this.masterProductsOptions = [{ label: "נקה", value: "" }]; //סנן/משפחת מוצרים
          result.forEach((obj) => {
            if (obj.hasOwnProperty("Name")) {
                  if (obj.Name != "" && obj.Name?.substring(4, 0) !="0211" &&obj.Name?.substring(4, 0) !="0210")
                        this.masterProductsOptions.push({label: obj.Name,value: obj.Name});
            } });
        }).catch((err) => {
          console.log("master products err: ", err);
        });
    } else { this.currentSearchKey = this.searchKey; }
  }

  // חיפוש לפי משפחת מוצרים
  getFilterdProducts(event) {
    //מוטרג מהסנן
    event.preventDefault();
    this.filterValue = event.detail.value;
    if (this.filterValue === "") {
      //סנן ריק
      this.masterProductsOptions = [{ label: "נקה", value: "" }];
    }
    // selectedRecordId - ה״חפש מוצר״ שנבחר
    if (this.selectedRecordId) {
      //מוצר לא! ריק
      // currentSearchKey - מילת החיפוש
      this.searchKey = this.currentSearchKey;
      this.selectedRecordId = "";
      this.selectedValue = "";
      // this.template.querySelector('lightning-input').focus();
    } else {
      this.template.querySelector("lightning-input").focus();
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////              getters                        //////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  get labelProduct() {
      if (!this.selectedProduct) {
            return "חפש מוצר";
      } else {
            return `טמפרטורת התגבשות:  ${this.selectedProduct}`;
      }
      // return this.selectedProduct
      //   ? `טמפרטורת התגבשות:  ${this.selectedProduct}`
      //   : "חפש מוצר";
}
get showHidRedText() {
  if (!this.isShown && !this.selectedProduct) {
        return `לתשומת ליבך, מוצר זה לא הוזמן בעבר ע"י לקוח זה`;
  } else {
        return ``;
  }
}
get hazardMaterial() {
  if (!this.isHazard && !this.selectedProduct) {
        return `חומר מסוכן`;
  } else {
        return ``;
  }
}

get specificGravity() {
  if(this.specificGravityValue){
    return this.specificGravityValue;
  }
  else{
     return ``;
  }
}

get divCssIsInvalid() {
    return this.invalid ? "slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right slds-has-error" : "slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right";
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
  // get isPrecentsInputTotalQuantityAmount() {
  //   return this.searchKey ? true : false;
  // }


}