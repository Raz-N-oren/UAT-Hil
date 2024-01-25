import { LightningElement, api, track } from "lwc";
import fetchLookUpValues from "@salesforce/apex/CustomLookUpController.fetchLookUpValues";
import fetchExtendedLookUpValues from "@salesforce/apex/CustomLookUpController.fetchExtendedLookUpValues";

export default class UxQuickLookup extends LightningElement {
  @api objectApiName;
  @api iconName = "standard:account";
  @api label = "Lookup";
  @api placeholder = "";
  @api fields = null;
  @api fieldName = null;
  @api extraWhereClause = "";
  @api isInputRequired = false;
  @api independentFieldToQuery = null; // field that allow to be search regardless of other filters on lookup search

  @track resultClass;
  @track selectedRecord = null;
  @track results = null;
  @track message = null;
  @track showSpinner = false;
  @track lastSearchValue;
  isfocused = false; // is rhe uxDebouncedInput is focused
  scrollBarClicked = false;
  isSecondSearch = false;
  approximateMessage =
    "המערכת לא מצאה התאמה ליחס המבוקש לכן מוצגים מוצרים עם היחס הקרוב ביותר";

  constructor() {
    super();
    this.switchResult(false);
  }

  handleFocus(event) {
    this.isfocused = true;
    // this.refreshProductLookupResults('AND Source_System__c = \'FER\'');
  }

  handleBlure(event) {
    if (this.scrollBarClicked) {
      // prevents results element from hiding when clicking on the scrollbar
      this.template.querySelector(".debounced").focus(); // preserve focus on uxDebounced as long as the user is 'clicking' inside the element
      return;
    }
    this.isfocused = false;
  }

  renderedCallback() {
    // listerns for mouse up and down events prevents results element from hiding when clicking on the scrollbar
    this.template
      .querySelector(".products-results")
      .addEventListener("mousedown", (e) => {
        this.scrollBarClicked = true;
      });
    this.template
      .querySelector(".products-results")
      .addEventListener("mouseup", (e) => {
        this.scrollBarClicked = false;
      });
  }

  handleClick(e) {
    //
  }
  // הפונקציה שמפעילה את הקריאה לשרת
  @api refreshProductLookupResults(extraWhereClause) {
    console.log("Line 60 -> extraWhereClause: " + extraWhereClause);
    if (this.lastSearchValue) {
      let searchParams = {
        searchKeyWord: this.lastSearchValue,
        objectName: this.objectApiName,
        extraWhereClause: extraWhereClause
      };

      if (this.fields) {
        this.addFieldsToParam(searchParams);
        fetchExtendedLookUpValues(searchParams)
          .then((result) => this.setResult(result))
          .catch((error) => this.handleError(error));
      } else {
        fetchLookUpValues(searchParams)
          .then((result) => this.setResult(result))
          .catch((error) => this.handleError(error));
      }
    } else this.showValidationError("");
  }

  // Takes 'searchValue', Query with 'searchValue', Update the element search boxUI on changes to data
  handleSearchTerm(event) {
    let searchValue = event.detail;
    let options = {
      //default options
      switch: true,
      message: "searching...",
      showspinner: true,
      initiatesearch: true
    };

    if (this.isfocused) {
      this.switchResult(true);
      if (
        this.independentFieldToQuery !== "" &&
        this.independentFieldToQuery !== null &&
        searchValue === ""
      ) {
        // use default options
      } else if (searchValue != "") {
        // use defualt options
      } else {
        // dont proceed with search
        options.message = "";
        options.showspinner = false;
        options.initiatesearch = false;
      }

      if (options.initiatesearch) {
        this.switchResult(options.switch);
        this.message = options.message;
        this.showSpinner = options.showspinner;
        this.message = options.message;

        let searchParams = {
          searchKeyWord: searchValue,
          objectName: this.objectApiName,
          extraWhereClause: this.extraWhereClause
        };

        if (this.fields) {
          this.addFieldsToParam(searchParams);
          fetchExtendedLookUpValues(searchParams)
            .then((result) => this.setResult(result))
            .catch((error) => this.handleError(error));
        } else {
          fetchLookUpValues(searchParams)
            .then((result) => this.setResult(result))
            .catch((error) => this.handleError(error));
        }
      } else {
        this.switchResult(false);
        this.message = null;
        this.showSpinner = false;
        this.results = null;
      }
      this.lastSearchValue = searchValue;
    } else {
      this.switchResult(false);
      this.message = null;
      this.showSpinner = false;
    }
  }

  /* Ensure we always have Name and Id in the query */
  addFieldsToParam(searchParam) {
    let allFields = this.fields.split(",");
    allFields.push("Id");
    allFields.push("Name");
    let cleanFields = this.dedupeArray(allFields).join(",");
    searchParam.fieldsToQuery = cleanFields;
  }

  dedupeArray(incoming) {
    var uniqEs6 = (arrArg) => {
      return arrArg.filter((elem, pos, arr) => {
        return arr.indexOf(elem) === pos;
      });
    };
    return uniqEs6(incoming);
  }

  setResult(newValues) {
    this.showValidationError("");
    this.showSpinner = false;
    if (newValues && newValues.length > 0) {
      if (this.isSecondSearch) {
        this.showValidationError(this.approximateMessage);
        this.isSecondSearch = false;
      }
      this.message = null;
      this.results = newValues;
    } else {
      this.message = "לא נמצאו תוצאות מתאימות";
      this.results = null;

      if (!this.isSecondSearch) {
        // No results for first search
        const noResEvent = new CustomEvent("noresultsreceived");
        this.dispatchEvent(noResEvent);
        this.isSecondSearch = true;
      } else {
        // No results for second search
        this.isSecondSearch = false;
      }
    }
  }

  /* Shows and hides the result area */
  switchResult(on) {
    this.resultClass = on
      ? "slds-form-element slds-lookup slds-is-open"
      : "slds-form-element slds-lookup slds-is-close";
  }

  handlePillRemove() {
    // Called when removing the selection
    this.selectedRecord = null;
    this.dispatchSelectionResult();
    // Restore last results
    this.switchResult(this.lastSearchValue && this.results);
    this.sendSelected();
  }

  /* 
    Sends back the result of a selection, compatible to extendedForm
    when the property fieldName is set
    */
  dispatchSelectionResult() {
    let eventName = this.fieldName ? "valueChanged" : "recordselected";
    let payload = {
      canceled: this.selectedRecord ? true : false,
      recordId: this.selectedRecord,
      value: this.selectedRecord,
      name: this.fieldName
    };
    let selected = new CustomEvent(eventName, {
      detail: payload,
      bubbles: true,
      cancelable: true
    });
    this.dispatchEvent(selected);
  }

  handleError(error) {
    this.showSpinner = false;
    this.message = "Sorry didn't work";
    let errorDispatch = new CustomEvent("failure", { detail: error });
    this.dispatchEvent(errorDispatch);
  }

  handleRecordSelect(event) {
    this.selectedRecord = event.detail;
    this.dispatchSelectionResult();
    this.switchResult(false);
    this.sendSelected();
    this.isSecondSearch = false;
  }

  sendSelected() {
    const selectedEvent = new CustomEvent("lookupselectdevent", {
      detail: this.selectedRecord
    });
    this.dispatchEvent(selectedEvent);
  }

  @api preDefineSelectedRecord(record) {
    this.selectedRecord = record;
    if (record == null) {
      this.lastSearchValue = "";
    }
  }
  @api preDefineSelectedRecordNEW(record) {
    this.selectedRecord = record;
    this.lastSearchValue = record;

  }

  showValidationError(message) {
    let valErrElement = this.template
      .querySelector(".debounced")
      .validationError();
    valErrElement.setCustomValidity(message);
    valErrElement.reportValidity();
  }
}