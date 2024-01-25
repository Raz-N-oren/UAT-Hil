import { LightningElement, wire, api, track } from "lwc";
import Utils from "c/utils";
import { label } from "c/utils";
import { fieldForCloneOppLine } from "c/utils";
import {
  createRecord,
  getRecordCreateDefaults,
  generateRecordInputForCreate,
  generateRecordInputForUpdate,
  getRecord,
  deleteRecord,
  updateRecord
} from "lightning/uiRecordApi";
import OPPLINE_OBJECT from "@salesforce/schema/OpportunityLineItem";
import getPlots from "@salesforce/apex/YearlyPlanController.getPlots";
import getOppLineItemDataMdt from "@salesforce/apex/YearlyPlanController.getOppLineItemDataMdt";
import getPlotGrowthType from "@salesforce/apex/YearlyPlanController.getPlotGrowthType";
import getFertilizationSuggestions from "@salesforce/apex/YearlyPlanController.getFertilizationSuggestions";
import {
  subscribe,
  unsubscribe,
  onError,
  setDebugFlag,
  isEmpEnabled
} from "lightning/empApi";
import Id from "@salesforce/user/Id";
import { refreshApex } from "@salesforce/apex";

export default class LmsSubscriberWebComponent extends LightningElement {
  // load custom labels
  @track label = label;

  fieldForCloneOppLine = fieldForCloneOppLine;
  @api oppRecordId;
  @api accountId;
  @track addIns = [];
  @track addInsData = {};
  @api oppProductId;
  oppProductsForDeleteOnEdit = [];
  loading = false;
  productId = "";
  nValue = "";
  pValue = "";
  kValue = "";
  nPrecentage = "";
  pPrecentage = "";
  kPrecentage = "";
  specificGravity = "";
  dates = [];
  @track selectedPlots = [];
  @track selectedPlotsData = [];
  selectedMicroElementsData = [];
  selectedAddInsData = [];
  @track sumSize;
  plotNames;
  growthName;
  irrigationCubicMetersPerDunam = 0;
  numberOfWaterings = 0;
  productFamily = "";
  error;
  productName;
  oppProductQuantityHectare;
  @api isEdit = false;
  oppLineItemDescription = "";
  showFilterCard = false;
  channelName = "/event/Plot_Created__e"; // Channel name for subscribing into PlatformEvents
  subscription = {}; // Holds PE Subscription Data
  userId = Id;
  @track hasRendered = true;
  hasScrolledToContainerSum = false;
  isSecondSearch = false;

  connectedCallback() {
    // need next year forward from current month and december last month in one string like this: 12-2022
    //init years
    const currentDate = new Date();
    const currentMonth = currentDate.getMonth() + 1;
    const currentYear = currentDate.getFullYear();
    const endDate = new Date(currentYear + 1, 12, 1);
    const endMonth = 12;
    const endYear = endDate.getFullYear() - 1;
    const calcYears = endYear - currentYear;
    const calcMonths = calcYears * 12 + (endMonth - currentMonth + 1);
    for (let i = 0; i < calcMonths; i++) {
      const loopDate = new Date(currentDate);
      loopDate.setMonth(loopDate.getMonth() + i);
      this.dates.push({
        label:
          (loopDate.getMonth() + 1).toString() +
          "-" +
          loopDate.getFullYear().toString(),
        value:
          loopDate.getFullYear().toString() +
          "-" +
          (loopDate.getMonth() + 1).toString()
      });
    }
  }

  scrollToElement(elementToBeScrollInto) {
    elementToBeScrollInto.scrollIntoView({
      behavior: "smooth",
      block: "center",
      inline: "nearest"
    });
  }

  renderedCallback() {
    // scroll to 'products lookup field' when containerSumCard appears
    let productLookupElement = this.template.querySelector(".product-lookup");
    let containerSumElement = this.template.querySelector(".container-sum");

    if (containerSumElement == null) {
      this.hasScrolledToContainerSum = false;
    } else if (!this.hasScrolledToContainerSum) {
      this.scrollToElement(productLookupElement);
      this.hasScrolledToContainerSum = true;
    }

    //Init Platform Event Listener for listening to new plot created event
    if (this.hasRendered) {
      // Preventing multi subscription to platfrom events
      this.handleSubscribe();
      this.hasRendered = false;
    }
  }

  handleSubscribe() {
    this.registerErrorListener(); // Callback invoked whenever a new event message is received

    const messageCallback = function (response) {
      // Response contains the payload of the new message received
      if (
        this.accountId === response.data.payload.AccountId_of_plot_created__c
      ) {
        console.log(
          "YPE: PlatformEvent Recieved: New Plot was created. \nRefreshing UI..."
        );
        refreshApex(this.wiredPlotsData); // Refresh the wired method which include wiredPlotsData. This will force the UI to refresh
        // console.log('Acc ID which subscribed the event: ' + response.data.payload.AccountId_of_plot_created__c);
        // console.log('Acc ID of current opportunity: ' + this.accountId);
      } else {
        console.log(
          '-IGNORED- "Platform event: New plot was created ON ANOTHER Account'
        );
      }
    };

    // console.log("Subscribing...");
    subscribe(this.channelName, -1, messageCallback.bind(this)).then(
      (response) => {
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        // console.log('Subscription request sent to: ', JSON.stringify(response.channel));  // Response contains the subscription information on subscribe call
        this.subscription = response;
      }
    );
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }

  unsubscribeFromCreatedPlotEventListener() {
    // console.log('in unsubscribe...');
    unsubscribe(this.subscription, (response) => {
      // console.log('unsubscribe() response: ', JSON.stringify(response));
      // Response is true for successful unsubscribe
    });
  }

  handleShowHideFilterCardChange(event) {
    this.showFilterCard = event.target.checked;
  }

  resetForm() {
    this.oppProductId = "";
    this.nValue = "";
    this.pValue = "";
    this.kValue = "";
    this.addIns = [];
    this.addInsData = {};
    this.productId = "";
    this.nPrecentage = "";
    this.pPrecentage = "";
    this.kPrecentage = "";
    this.specificGravity = "";
    // this.template
    //   .querySelector(".product-lookup")
    //   .preDefineSelectedRecord(null);
    // this.template.querySelector(".plots-picklist").clearSelection();
    // this.template.querySelector(".addins-picklist").clearSelection();
    // this.template.querySelector(".microelements-picklist").clearSelection();
    //this.productFamily = "";
    this.startDate = "";
    this.endDate = "";
    this.selectedPlots = [];
    this.selectedPlotsData = [];
    this.selectedMicroElementsData = [];
    this.selectedAddInsData = [];
    this.sumSize = "";
    // this.plotNames = "";
    this.growthName = "";
    this.irrigationCubicMetersPerDunam = 0;
    this.numberOfWaterings = 0;
    this.relativeFertilization = false;
    this.oppLineItemDescription = "";
    this.isSecondSearch = false;
  }

  onOppLineItemDescriptionChange(event) {
    this.oppLineItemDescription = event.target.value;
  }

  @api
  resetValuesForClone(oppProductId) {
    this.oppProductId = oppProductId;
    //reset vals before binding data from clone to input form
    this.nValue = "";
    this.pValue = "";
    this.kValue = "";

    this.isSecondSearch = false;
  }

  @wire(getRecord, {
    recordId: "$oppProductId",
    fields: "$fieldForCloneOppLine"
  })
  populateOppLineFields({ error, data }) {
    if (data) {
      this.oppProductsForDeleteOnEdit = [];
      this.oppProductsForDeleteOnEdit.push(this.oppProductId);
      this.productId = data.fields.Product2Id.value;
      // Only Nvalue should be retrieved here (Not also P,K) as the ratio for P&K will be calculated based on N.
      // Using Number() in conjuction with toFixed() to remove padding zeroes from decimal
      let tempNValue = data?.fields?.N__c?.value;
      this.nValue = isNaN(Number(tempNValue))
        ? null
        : Number(tempNValue).toFixed(2);
      this.kValue = "";
      this.relativeFertilization = data.fields.Relative_fertilization__c.value;
      this.nPrecentage = data.fields.Product2.value.fields.N__c.value;
      console.log("LINE 209!!" + this.nPrecentage);
      console.log("LINE 210!!" + this.pPrecentage);
      console.log("LINE 211!!" + this.kPrecentage);
      this.pPrecentage = data.fields.Product2.value.fields.P__c.value;
      this.kPrecentage = data.fields.Product2.value.fields.K__c.value;
      this.productFamily = null; // TODO: Check this line - Clone or edit OppLineItem should not be copied into filter card
      this.specificGravity =
        data.fields.Product2.value.fields.specific_gravity__c.value;
      this.numberOfWaterings = data.fields.Division_into_irrigations__c.value;
      this.irrigationCubicMetersPerDunam =
        data.fields.Irrigation_cubic_meters_per_dunam__c.value;
      let sDate = new Date(data.fields.Date__c.value);
      this.startDate =
        sDate.getFullYear().toString() +
        "-" +
        (sDate.getMonth() + 1).toString();
      this.endDate = this.startDate;
      this.selectedPlots = [];
      this.selectedPlotsData = [];
      if (data.fields.Plot__c.value != null) {
        // only one plot
        this.selectedPlots.push(data.fields.Plot__c.value);
      }
      this.sumSize = data.fields.Plot_Size__c.value;
      this.plotNames = data.fields.Plots__c.value;
      this.oppLineItemDescription = data.fields.Description?.value;

      let predefinedProduct = {
        Id: this.productId,
        Name: data.fields.Product2.value.fields.Name.value
      };
      this.template
        .querySelector(".product-lookup")
        .preDefineSelectedRecord(predefinedProduct);

      if (data.fields.Product2.value.fields != null) {
        this.addIns = [];
        this.addInsData = {};
        //populate addIns

        for (let i = 1; i < 9; i++) {
          console.log(JSON.stringify(predefinedProduct));
          predefinedProduct["Extension_" + i + "__c"] =
            data.fields.Product2.value.fields["Extension_" + i + "__c"].value;
          if (predefinedProduct["Extension_" + i + "__c"] == undefined)
            continue;
          let addIn = {
            Id: predefinedProduct["Extension_" + i + "__c"],
            Name: data.fields.Product2.value.fields["Extension_" + i + "__r"]
              .value.fields.Name.value,
            Value:
              data.fields["Extension_" + i + "__c"].value != null
                ? data.fields["Extension_" + i + "__c"].value.split("-")[1]
                : "",
            FieldApi: "Extension_" + i + "__c"
          };
          this.addIns.push(addIn);
          this.addInsData[addIn.Id] = addIn;
          if (data.fields["Extension_" + i + "__c"].value != null) {
            this.oppProductsForDeleteOnEdit.push(
              data.fields["Extension_" + i + "__c"].value.split("-")[0]
            );
          }
        }
      }
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

  get showContainerSum() {
    return this.productId === `` ? false : true;
  }

  // Checks if to apply a cartion filter to the product quick lookup search box
  get toAddRatioFilter() {
    // returns true if granted to begin ratio convertion
    let blankFieldCounter = 0;
    if (this.nValue === "") {
      blankFieldCounter++;
    }
    if (this.pValue === "") {
      blankFieldCounter++;
    }
    if (this.kValue === "") {
      blankFieldCounter++;
    }
    return blankFieldCounter <= 1;
  }

  onNPKvalueChange(event) {
    let fieldName = event.target.name;
    let fieldValue = event.target.value;
    console.log("RAZCHECK , 982 347, fieldName",fieldName);
    console.log("RAZCHECK , 982  348, fieldValue",fieldValue);

    switch (fieldName) {
      case "N__c":
        this.nValue = fieldValue;
        break;

      case "P__c":
        this.pValue = fieldValue;
        break;

      case "K__c":
        this.kValue = fieldValue;
        break;
    }
    this.isSecondSearch = false;
    this.refreshProductLookupResults(this.extraWhereClause);
  }

  get extraWhereClause() {
    // NOTE: will be ignored in case that the getter 'extraWhereClause()' will returns  ''

    let whereClause = " AND Source_System__c = 'FER' ";

    if (this.selectedMicroElements != null)
      // query microelements
      whereClause += this.microElementsFilter;
    if (this.selectedAddIns != null)
      // query microelements
      whereClause += this.addInsFilter;
    if (this.productFamily != "" && this.productFamily != null)
      whereClause += " AND Family = " + "'" + this.productFamily + "'";
    if (this.toAddRatioFilter) {
      // check if there is no more than one empty field (N,P,K)
      // query by npk ratio
      if (!this.isSecondSearch) {
        // if first search
        let normalizedRatio = Utils.convertRatio(
          this.nValue,
          this.pValue,
          this.kValue
        );
        whereClause +=
          " AND " + this.apiFieldPrefix + "=" + "'" + normalizedRatio + "'";
      } else {
        // if first search have no results
        whereClause += this.secondSearchExtraWhereClause();
      }
    } /* else {
            //אם לא הוקלד שום אנפיקיי - אל תוסיף כלום לשאילתא להבאת רשימת המוצרים
            // if no ratio input => query ONLY for n,p,k == null
            whereClause += this.nValue == "" && this.pValue == "" && this.kValue == "" ?
                " AND N__c = null AND P__c = null AND K__c = null" : " AND (N__c != null OR P__c != null OR K__c != null)";
                
        }*/
    return whereClause;
  }

  get apiFieldPrefix() {
    // Gets the correct API field name for later APEX query
    if (this.nValue === "") return "PKratio__c ";
    else if (this.pValue === "") return "NKratio__c ";
    else if (this.kValue === "") return "NPratio__c ";
    else return "NPKratio__c "; // no empty NPK fields
  }

  // Plots multi picklist functionality

  @track allPlotsData;
  wiredPlotsData;
  allPlotsDataMap;

  @wire(getPlots, { accountId: "$accountId" }) plots(result) {
    this.wiredPlotsData = result; // Track the 'wiredPlotsData'
    if (result.data) {
      this.allPlotsData = result.data.map((record) =>
        Object.assign({ label: record.Name, value: record.Id })
      );
      Utils.sortDualListboxValues(this.allPlotsData);
      this.allPlotsDataMap = result.data.map((record) =>
        Object.assign({
          key: record.Id,
          label: record.Name,
          size: record.Plot_Size__c,
          growth: record.Branch_growth__r.Name
        })
      );
    } else if (result.error) {
      this.error = result.error;
      this.allPlotsData = undefined;
    }
  }

  get selectedPlot() {
    return this.selectedPlots.length == 1 ? this.selectedPlots[0] : null;
  }

  updateSelectedPlots(e) {
    this.selectedPlots = e.detail.selectedValues;
    this.selectedPlotsData = this.selectedPlots.map(
      (select) =>
        this.allPlotsDataMap.filter((option) => option.key == select)[0]
    );
    this.sumSize = 0;
    this.plotNames = "";
    this.growthName = "";
    for (const i in this.selectedPlotsData) {
      this.sumSize += this.selectedPlotsData[i].size;
      this.plotNames += this.selectedPlotsData[i].label + " ; ";
      this.growthName = this.selectedPlotsData[i].growth;
    }
    this.plotNames = this.plotNames.slice(0, -2);
  }

  // Product family piclist functionality

  @track productFamiliesMetaData;
  wiredproductFamiliesMetaData;

  // Gets product family info and populate in list
  @wire(getOppLineItemDataMdt, { type: "Product Family" })
  productFamiliesMd(result) {
    this.wiredproductFamiliesMetaData = result;
    if (result.data) {
      this.productFamiliesMetaData = result.data.map((metaDataRecord) =>
        Object.assign({
          label: metaDataRecord.MasterLabel,
          value: metaDataRecord.DeveloperName
        })
      );
      this.productFamiliesMetaData.push({ label: "", value: "" });
      Utils.sortDualListboxValues(this.productFamiliesMetaData);
    } else if (result.error) {
      this.error = result.error;
      this.productFamiliesMetaData = undefined;
    }
  }

  updateProductFamily(event) {
    this.productFamily = event.detail.value;
    this.refreshProductLookupResults(this.extraWhereClause);
  }

  // microElements multi picklist functionality

  @track microElementsMetaData;
  wiredMicroElementsMetaData;

  @wire(getOppLineItemDataMdt, { type: "Micro-elements" })
  microElementsMd(result) {
    this.wiredMicroElementsMetaData = result;
    if (result.data) {
      this.microElementsMetaData = result.data.map((metaDataRecord) =>
        Object.assign({
          label: metaDataRecord.MasterLabel,
          value: metaDataRecord.DeveloperName
        })
      );
      Utils.sortDualListboxValues(this.microElementsMetaData);
    } else if (result.error) {
      this.error = result.error;
      this.microElementsMetaData = undefined;
    }
  }

  get selectedMicroElements() {
    return this.selectedMicroElementsData.length > 0
      ? this.selectedMicroElementsData
      : null;
  }

  get microElementsFilter() {
    let med = this.selectedMicroElements;
    if (med != null) {
      let res = "";
      med.forEach((element) => {
        res += " AND " + element + "__c " + "!=null";
      });
      return res;
    }
  }

  updateSelectedMicroElements(e) {
    // handles change in selectedMicroElements dulaListBox
    this.selectedMicroElementsData = e.detail.selectedValues;
    this.refreshProductLookupResults(this.extraWhereClause);
  }

  // addIns multi picklist functionality

  @track addInsMetaData;
  wiredAddinsMetaData;

  @wire(getOppLineItemDataMdt, { type: "Extension" })
  addInsMd(result) {
    this.wiredAddinsMetaData = result;
    if (result.data) {
      this.addInsMetaData = result.data.map((metaDataRecord) =>
        Object.assign({
          label: metaDataRecord.MasterLabel,
          value: metaDataRecord.Id__c
        })
      );
      Utils.sortDualListboxValues(this.addInsMetaData);
    } else if (result.error) {
      this.error = result.error;
      this.addInsData = undefined;
    }
  }

  get selectedAddIns() {
    return this.selectedAddInsData.length > 0 ? this.selectedAddInsData : null;
  }

  get addInsFilter() {
    let addins = this.selectedAddIns;
    if (addins != null) {
      let res = "";
      addins.forEach((element) => {
        res += " AND (";
        for (let i = 1; i < 9; i++) {
          if (i > 1) {
            res += " OR ";
          }
          res += "Extension_" + i + "__c" + " = '" + element + "'";
        }
        res += ") ";
      });
      return res;
    }
  }
  //Addins=תוספים
  updateselectedAddIns(e) {
    // handles change in selectedAddIns dulaListBox
    this.selectedAddInsData = e.detail.selectedValues;
    this.refreshProductLookupResults(this.extraWhereClause);
  }

  // growthStage multi picklist functionality

  get selectedPlotForGrowthType() {
    return this.selectedPlots.length > 0 ? this.selectedPlots[0] : null;
  }
  growthType = "";

  @wire(getPlotGrowthType, { plotId: "$selectedPlotForGrowthType" })
  plotGrowthTypeWire(result) {
    if (result.data) {
      this.growthType = result.data;
    } else {
      this.growthType = undefined;
      this.growthStageData = undefined;
      this.growthStageDataMap = undefined;
    }

    if (result.error) {
      this.error = result.error;
    }
  }

  @track growthStageData;
  growthStageDataMap;

  @wire(getFertilizationSuggestions, { growthType: "$growthType" })
  growthTypeWire(result) {
    if (result.data) {
      this.growthStageData = result.data.map((record) =>
        Object.assign({
          label: record.Stage_in_growth__c,
          value: record.Stage_in_growth__c
        })
      );
      Utils.sortDualListboxValues(this.growthStageData);
      this.growthStageDataMap = result.data.map((record) =>
        Object.assign({
          key: record.Stage_in_growth__c,
          n: record.N__c,
          p: record.P__c,
          k: record.K__c
        })
      );
    } else if (result.error) {
      this.error = result.error;
      this.growthStageData = undefined;
    }
  }

  updateFertilizationSuggestionsFields(event) {
    let selectedStage = this.growthStageDataMap.filter(
      (option) => option.key == event.detail.value
    )[0];
    this.nValue = selectedStage.n;
    this.pValue = selectedStage.p;
    this.kValue = selectedStage.k;
  }

  // insert OppLineItems functionlity start

  // for extentions insert
  //  after wire default values update: lookup to Opportunity, lookup to Product extention, Quantity, TotalPrice

  @wire(getRecordCreateDefaults, { objectApiName: OPPLINE_OBJECT })
  oppLineCreateDefaults;

  get oppLineInputForCreate() {
    if (!this.oppLineCreateDefaults.data) {
      return undefined;
    }

    const oppLineObjectInfo =
      this.oppLineCreateDefaults.data.objectInfos[OPPLINE_OBJECT.objectApiName];
    const recordDefaults = this.oppLineCreateDefaults.data.record;
    const recordInput = generateRecordInputForCreate(
      recordDefaults,
      oppLineObjectInfo
    );
    return recordInput;
  }

  get oppLineCreateDefaultsErrors() {
    return this.oppLineCreateDefaults.error;
  }

  validateAllFields() {
    //רדיוסר שבודק לפי 2 המתודות השמורות של סיילספורס אם כל אינפוט ולידי, מי שכן נשמר בש"מ אולווליד
    const allValid = [
      ...this.template.querySelectorAll("lightning-input")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    //אם הכל טרוטי - אז הוא עובר ולידציה . אחרת ממשיך לכאן...
    if (!allValid) {
      let errorMessage = "יש לבדוק את תקינות השדות";
      Utils.showToast(this, "שגיאה", errorMessage, "error");
      return false;
    }
    return true;
  }

  insertOppLineItem(event) {
    event.preventDefault();
    //  console.log("line 616: ", JSON.stringify(event.detail));
    if (!this.validateAllFields()) {
      return;
    }
    if (this.template.querySelector(".startdate").reportValidity()) {
      this.loading = true;
      let fields = event.detail.fields;
      this.calculateNPKValues(fields);
      fields.Plot_Size__c = this.sumSize; //גודל סך החלקות שנבחרו! הוספת קי ידני לאותו פורם, בטרם שליחתו לשרת והוספתו שם
      // fields.Plots__c = growthName;
      fields.Plots__c = this.plotNames; //שמות חלקה/ות - סטרינג
      // fields.TotalPrice = 0;
      // year-month-day
      fields.Date__c = this.startDate + "-" + "1";
      let endDate = this.endDate + "-" + "1";
      let numOfOppLinesToInsert = Utils.monthDiff(fields.Date__c, endDate); //מספר שורות לטבלה
      try {
        if (numOfOppLinesToInsert < 2) {
          //שליחה ידנית של הפורם כולל כל השדות מהפורם וידנית לשרת
          this.template
            .querySelector("lightning-record-edit-form")
            .submit(fields);
        } else {
          this.insertOppLineItemBulk(
            numOfOppLinesToInsert,
            fields,
            fields.Date__c
          );
        }
      } catch (error) {
        console.log("error", "line 716", error);
      } finally {
        fields = ``;
        this.endDate = ``;
        this.addIns = [];
        this.nValue = ``;
        this.pValue = ``;
        this.kValue = ``;
        this.template
          .querySelector("c-ux-quick-lookup")
          .preDefineSelectedRecordNEW(null);
          
        // this.resetForm
        // this.sumSize = ``;
        // this.specificGravity=null;
        // this.nValue=``;
        // this.pValue=``;
        // this.kValue=``;
        // this.nPrecentage=``;
        // this.kPrecentage=``;
        // this.pPrecentage=``;
        //  this.oppProductQuantityHectare=null;
      }
    }
  }

  //מיפוי/נסאז' לאוביקט בטרם שליחתו לשרת (ליצירה)
  insertOppLineItemBulk(numOfRecords, fields, startDate) {
    let oppLineItemsToBulkCreate = [];
    this.loading = true;
    let nVal = Utils.cut2Decimal(fields.N__c / numOfRecords);
    let pVal = Utils.cut2Decimal(fields.P__c / numOfRecords);
    let kVal = Utils.cut2Decimal(fields.K__c / numOfRecords);
    let sDate = new Date(startDate);
    for (let i = 0; i < numOfRecords; i++) {
      let oppLineItemToCreate = {
        apiName: "OpportunityLineItem",
        fields: null
      };
      oppLineItemToCreate.fields = fields;
      let sDateString =
        sDate.getFullYear().toString() +
        "-" +
        (sDate.getMonth() + 1).toString() +
        "-" +
        "1";
      oppLineItemToCreate.fields.Date__c = sDateString;
      oppLineItemToCreate.fields.N__c = nVal;
      oppLineItemToCreate.fields.P__c = pVal;
      oppLineItemToCreate.fields.K__c = kVal;
      oppLineItemToCreate.fields.Quantity = Utils.cut2Decimal(
        this.quantity / numOfRecords
      );
      oppLineItemToCreate.fields.Quantity_per_hectare__c = Utils.cut2Decimal(
        this.quantityHectare / numOfRecords
      );
      oppLineItemsToBulkCreate.push(
        JSON.parse(JSON.stringify(oppLineItemToCreate))
      );
      sDate.setMonth(sDate.getMonth() + 1);
      this.startDate = "";
      // this.deleteOriginalOppLine();
    }
    //עבור כל מוצר מבצע קריאה לשרת לשמירה יצירה חדש
    //באלק זה הכל וליין זה מוצר בודד שורה בודדת
    //מבצע מיפוי/מסאג' לכל הערכים בתוך אובייקט אחד ורק אז שולח לשרת
    oppLineItemsToBulkCreate.forEach((oppLineItemToCreate) => {
      createRecord(oppLineItemToCreate)
        .then((newOppLineRecord) => {
          this.deleteOriginalOppLine();
          Utils.showToast(
            this,
            "הצלחה",
            this.isEdit ? "שורה נערכה" : "שורה נוצרה",
            "success"
          );
          if (this.addIns != undefined) {
            this.addIns.forEach((element) => {
              if (
                this.addInsData[element.Id].Value != "" &&
                this.addInsData[element.Id].Value > 0
              ) {
                this.insertAddIn(
                  this.addInsData[element.Id],
                  this.oppRecordId,
                  newOppLineRecord.fields.Date__c.value,
                  newOppLineRecord.id
                );
              }
            });
          }

          // insert Add in with new record Id in loopkup
          // this.oppProductId = "";
          this.refreshOppLineList();
        })
        .catch((error) => {
          Utils.showToast(this, "שגיאה", error.body.message, "error");
        })
        .finally(() => {
          this.loading = false;
        });
    });
  }

  insertAddIn(extention, oppId, sDate, newOppLineRecordId) {
    let oppLineAddInToCreate = this.oppLineInputForCreate;
    oppLineAddInToCreate.fields.Date__c = sDate;
    oppLineAddInToCreate.fields.Plot_Size__c = this.sumSize;
    oppLineAddInToCreate.fields.Quantity = Utils.cut2Decimal(
      (extention.Value * this.sumSize) / 1000
    );
    oppLineAddInToCreate.fields.Plots__c = this.plotNames;
    oppLineAddInToCreate.fields.Product2Id = extention.Id;
    oppLineAddInToCreate.fields.Quantity_per_hectare__c = extention.Value;
    oppLineAddInToCreate.fields.OpportunityId = oppId;
    oppLineAddInToCreate.fields.Plot__c = this.selectedPlot;
    oppLineAddInToCreate.fields.Is_Extension__c = true;
    oppLineAddInToCreate.fields.UnitPrice = 0; // calculate price
    setTimeout(() => {
      createRecord(oppLineAddInToCreate)
        .then((newRecord) => {
          let newOppLineRecordToUpdate = { fields: { Id: newOppLineRecordId } };
          Utils.showToast(
            this,
            "הצלחה",
            this.isEdit ? "שורה נערכה" : "שורה נוצרה",
            "success"
          );
          newOppLineRecordToUpdate.fields[extention.FieldApi] =
            newRecord.id + "-" + extention.Value;
          updateRecord(newOppLineRecordToUpdate)
            .then(() => {
              this.refreshOppLineList();
            })
            .catch((error) => {
              Utils.showToast(this, "שגיאה", error.body.message, "error");
            });
        })
        .catch((error) => {
          Utils.showToast(this, "שגיאה", error.body.message, "error");
        });
    }, 1000);
  }

  // handlers on for fields and updates

  startDate;
  updateStartDate(event) {
    // 2020-11-02
    this.startDate = event.detail.value;

    let startDate = this.startDate + "-" + "1";
    let endDate = this.endDate + "-" + "1";
    if (Utils.monthDiff(startDate, endDate) == 0) {
      this.endDate = this.startDate;
    }
  }

  endDate;
  updateEndDate(event) {
    // 2020-11-02
    this.endDate = event.detail.value;
  }

  populateProductFields(event) {
    console.log("LINE #756!", JSON.stringify(event.detail));
    //init
    this.addIns = [];
    this.addInsData = {};
    this.productId = "";
    this.nPrecentage = "";
    this.pPrecentage = "";
    this.kPrecentage = "";
    this.specificGravity = "";

    if (event.detail != null) {
      //populate addIns
      for (let i = 1; i < 4; i++) {
        if (event.detail["Extension_" + i + "__c"] == undefined) continue;
        let addIn = {
          Id: event.detail["Extension_" + i + "__c"],
          Name: event.detail["Extension_" + i + "__r"].Name,
          Value: "",
          FieldApi: "Extension_" + i + "__c"
        };
        this.addIns.push(addIn);
        this.addInsData[addIn.Id] = addIn;
        console.log("line #895:", JSON.stringify(this.addInsData));
      }
      //populate selected productId
      this.productId = event.detail.Id;
      this.nPrecentage = event.detail["N__c"];
      this.pPrecentage = event.detail["P__c"];
      this.kPrecentage = event.detail["K__c"];
      this.specificGravity = event.detail["specific_gravity__c"];
      this.isSecondSearch = false;
    }
  }

  get isQuantityPerHectareReadOnly() {
    if (this.nValue > 0 || this.kValue > 0 || this.pValue > 0) {
      return true;
    } else {
      return false;
    }
  }

  updateAddIns(event) {
    this.addInsData[event.target.dataset.id].Value = event.detail.value;
  }

  relativeFertilization = false;
  updateRelativeFertilization(event) {
    this.relativeFertilization = event.detail.checked;
  }

  updateIrrigationCubicMetersPerDunam(event) {
    this.irrigationCubicMetersPerDunam = event.detail.value;
  }
  //הפונקציה שמופעלת בעת הצלחה של קריאת השרת
  handleSuccess(event) {
    Utils.showToast(
      this,
      "הצלחה",
      this.isEdit ? "שורה נערכה" : "שורה נוצרה",
      "success"
    );

    let newOppLineRecord = event.detail;
    // this.oppProductId = "";
    //פה להוסיף את הערך של גודל חלקה
    this.addIns.forEach((element) => {
      if (
        this.addInsData[element.Id].Value != "" &&
        this.addInsData[element.Id].Value > 0
      ) {
        this.insertAddIn(
          this.addInsData[element.Id],
          this.oppRecordId,
          this.startDate + "-1",
          newOppLineRecord.id
        );
      }
    });
    // insert Add in with new record Id in loopkup
    this.deleteOriginalOppLine();
    this.refreshOppLineList();
    eval("$A.get('e.force:refreshView').fire();");
    this.startDate = "";
    this.loading = false;
  }

  handleError(event) {
    const payload = event.detail;
    this.loading = false;
  }

  refreshOppLineList() {
    const selectedEvent = new CustomEvent("refreshopplist", {});
    this.dispatchEvent(selectedEvent);
  }

  refreshProductLookupResults(extraWhereClause) {
    console.log("RAZCHECK , 982 , extraWhereClause",extraWhereClause);
    if (this.template.querySelector("c-ux-quick-lookup") != null)
      this.template
        .querySelector("c-ux-quick-lookup")
        .refreshProductLookupResults(extraWhereClause);
  }

  updateNumberOfWaterings(event) {
    this.numberOfWaterings = event.detail.value;
  }

  // calculations חישובים
  //מחשב כמות דשן לדונם, אחרת ליטר לקוב, אחרת פשוט הערך ומשחק עם אורכו ואינפיניוטו
  get quantityHectare() {
    let calculatedQuantityHectare;
    if (!this.relativeFertilization) {
      calculatedQuantityHectare = this.litersPerDonam(); // אם אין דישון יחסי - חישוב כמות דשן לדונם
    } else {
      calculatedQuantityHectare = this.litersPerKub(); //אם יש דישון יחסי - חשב פר קוב
    }

    if (!calculatedQuantityHectare) {
      // אם החישוב לא הלך והוא פולסי - תקצה לו הערך שהוקלד פשוט
      calculatedQuantityHectare = this.oppProductQuantityHectare;
    }
    calculatedQuantityHectare = Utils.cut2Decimal(calculatedQuantityHectare);
    return isFinite(calculatedQuantityHectare) ? calculatedQuantityHectare : 0;
  }
  //עדכון כמות השקיה\דשן לדונם
  updateQuantityHectare(event) {
    this.oppProductQuantityHectare = event.detail.value;
  }

  //שם משתנה דינמי כזה - this.quantity מוגדר כאן
  get quantity() {
    let calculatedQuantity;
    if (!this.relativeFertilization) {
      calculatedQuantity = this.sumPerPlotInKub();
    } else {
      calculatedQuantity = this.sumForRelativeFertilization();
    }
    if (!this.isQuantityPerHectareReadOnly) {
      calculatedQuantity =
        (this.oppProductQuantityHectare * this.sumSize) / 1000;
    }
    calculatedQuantity = Utils.cut2Decimal(calculatedQuantity);
    return isFinite(calculatedQuantity) ? calculatedQuantity : 0;
  }

  get irrigationUnits() {
    let calculatedIrrigationUnits;
    if (this.numberOfWaterings > 0) {
      calculatedIrrigationUnits = this.quantity / this.numberOfWaterings;
      calculatedIrrigationUnits = Utils.cut1Decimal(calculatedIrrigationUnits);
    }

    return isFinite(calculatedIrrigationUnits) ? calculatedIrrigationUnits : 0;
  }
  //כמות דשן לדונם
  litersPerDonam() {
    if (this.nValue != "") {
      return (
        Number(this.nValue) *
        (100 / (Number(this.nPrecentage) * Number(this.specificGravity)))
      );
    }
    if (this.pValue != "") {
      return (
        Number(this.pValue) *
        (100 / (Number(this.pPrecentage) * Number(this.specificGravity)))
      );
    }
    if (this.kValue != "") {
      return (
        Number(this.kValue) *
        (100 / (Number(this.kPrecentage) * Number(this.specificGravity)))
      );
    }
  }

  litersPerKub() {
    if (this.nValue != "") {
      return (
        (Number(this.nValue) / 10) *
        (1 / (Number(this.nPrecentage) * Number(this.specificGravity)))
      );
    }
    if (this.pValue != "") {
      return (
        (Number(this.pValue) / 10) *
        (1 / (Number(this.pPrecentage) * Number(this.specificGravity)))
      );
    }
    //ליטרים לדונם
    if (this.kValue != "") {
      return (
        (Number(this.kValue) / 10) *
        (1 / (Number(this.kPrecentage) * Number(this.specificGravity)))
      );
    }
  }

  sumPerPlotInKub() {
    return (this.litersPerDonam() * this.sumSize) / 1000;
  }

  sumForRelativeFertilization() {
    return (
      (this.litersPerKub() / 1000) *
      this.irrigationCubicMetersPerDunam *
      this.sumSize
    );
  }

  calculateNPKValues(fields) {
    let realRatio;
    console.log("fields line #1126:", JSON.stringify(fields));
    if (this.kValue == "" && this.pValue == "" && this.pValue == "") {
      fields.N__c =
        (this.oppProductQuantityHectare *
          this.nPrecentage *
          this.specificGravity) /
        100;
      fields.P__c =
        (this.oppProductQuantityHectare *
          this.pPrecentage *
          this.specificGravity) /
        100;
      fields.K__c =
        (this.oppProductQuantityHectare *
          this.kPrecentage *
          this.specificGravity) /
        100;
    } else {
      if (this.nValue != "") realRatio = this.nValue / this.nPrecentage;
      if (this.pValue != "") realRatio = this.pValue / this.pPrecentage;
      if (this.kValue != "") realRatio = this.kValue / this.kPrecentage;

      if (this.nValue == "") fields.N__c = realRatio * this.nPrecentage;
      if (this.pValue == "") fields.P__c = realRatio * this.pPrecentage;
      if (this.kValue == "") fields.K__c = realRatio * this.kPrecentage;
    }
  }

  deleteOriginalOppLine() {
    if (this.isEdit) {
      this.isEdit = false;
      let oppProductsForDeleteOnEdit = JSON.parse(
        JSON.stringify(this.oppProductsForDeleteOnEdit)
      );
      oppProductsForDeleteOnEdit.forEach((oppProductIdToDelete) => {
        deleteRecord(oppProductIdToDelete).then(() => {
          this.oppProductId = "";
          this.refreshOppLineList();
        });
      });
      this.oppProductsForDeleteOnEdit = [];
    }
  }

  handleNoResults() {
    this.isSecondSearch = true;
    this.refreshProductLookupResults(this.extraWhereClause);
  }

  secondSearchExtraWhereClause() {
    let whereClauseAddition = "";
    // If non of the npk values is empty, search for both p & k proximity
    if (this.nValue != "" && this.pValue != "" && this.kValue != "") {
      let normalizedRatioP1 = Utils.convertRatio(
        this.nValue,
        (+this.pValue + 1).toString(),
        this.kValue
      );
      let normalizedRatioP2 = Utils.convertRatio(
        this.nValue,
        (+this.pValue - 1).toString(),
        this.kValue
      );
      let normalizedRatioK1 = Utils.convertRatio(
        this.nValue,
        this.pValue,
        (+this.kValue + 1).toString()
      );
      let normalizedRatioK2 = Utils.convertRatio(
        this.nValue,
        this.pValue,
        (+this.kValue - 1).toString()
      );
      whereClauseAddition +=
        " AND (" +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatioP1 +
        "'" +
        " OR " +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatioP2 +
        "'" +
        " OR " +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatioK1 +
        "'" +
        " OR " +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatioK2 +
        "')";
    }
    // all other options - when one of the npk fields is empty
    else if (this.kValue != "") {
      let normalizedRatio1 = Utils.convertRatio(
        this.nValue,
        this.pValue,
        (+this.kValue + 1).toString()
      );
      let normalizedRatio2 = Utils.convertRatio(
        this.nValue,
        this.pValue,
        (+this.kValue - 1).toString()
      );
      whereClauseAddition +=
        " AND (" +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatio1 +
        "'" +
        " OR " +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatio2 +
        "')";
    } else if (this.pValue != "") {
      let normalizedRatio1 = Utils.convertRatio(
        this.nValue,
        (+this.pValue + 1).toString(),
        this.kValue
      );
      let normalizedRatio2 = Utils.convertRatio(
        this.nValue,
        (+this.pValue - 1).toString(),
        this.kValue
      );
      whereClauseAddition +=
        " AND (" +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatio1 +
        "'" +
        " OR " +
        this.apiFieldPrefix +
        "=" +
        "'" +
        normalizedRatio2 +
        "')";
    }
    this.isSecondSearch = false;
    return whereClauseAddition;
  }
}