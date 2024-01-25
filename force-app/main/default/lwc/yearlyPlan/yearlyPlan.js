import { LightningElement, wire, track, api } from "lwc";
import { createRecord, deleteRecord, getRecord } from "lightning/uiRecordApi";
import { loadStyle } from 'lightning/platformResourceLoader';
import cssResource from '@salesforce/resourceUrl/yearlyPlanCss';
import Utils from "c/utils";
import { fieldsForDeleteOppLine } from "c/utils";
import { refreshApex } from "@salesforce/apex";
import getOppProducts from "@salesforce/apex/YearlyPlanController.getOppProducts";
import getOppLineItemDataMdt from "@salesforce/apex/YearlyPlanController.getOppLineItemDataMdt";


const actions = [
  { label: "ערוך", name: "edit" },
  { label: "שכפל", name: "clone" },
  { label: "מחק", name: "delete" }
];

// Declaring the columns in the datatable
const columns = [
  {
    label: "חודש",
    fieldName: "Date__c",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "2-digit",
    },
    initialWidth: 80

  },
  {
    label: "גודל חלקה",
    fieldName: "Plot_Size__c",
    wrapText: "true",
    initialWidth: 80
  },
  {
    label: "חלקות",
    fieldName: "Plots__c",
    wrapText: "true",
    initialWidth: 100
  },

  {
    label: "שם המוצר",
    fieldName: "Product2.Name",
  },
  {
    label: "הערה",
    fieldName: "Description",
    wrapText: "true",
  },
  {
    label: "כמות לדונם (ליטר)",
    fieldName: "Quantity_per_hectare__c",
    type: "number",
    typeAttributes:
    {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'left' }
  },
  {
    label: "כמות לחלקה (קוב)",
    fieldName: "Quantity",
    type: "number",
    typeAttributes:
    {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'left' }
  },
  {
    label: "K",
    fieldName: "K__c",
    type: "number",
    typeAttributes: {
      maximumFractionDigits: "2",
    },
    cellAttributes: { alignment: 'left' },
    initialWidth: 50
  },
  {
    label: "P",
    fieldName: "P__c",
    type: "number",
    typeAttributes: {
      maximumFractionDigits: "2",
    },
    cellAttributes: { alignment: 'left' },
    initialWidth: 50

  },
  {
    label: "N",
    fieldName: "N__c",
    type: "number",
    typeAttributes: {
      maximumFractionDigits: "2",
    },
    cellAttributes: { alignment: 'left' },
    initialWidth: 50

  },
  {
    label: "מחיר מחירון",
    fieldName: "UnitPrice",
    initialWidth: 80
  },
  //   {
  //     type: 'action',
  //     typeAttributes: { rowActions: actions },
  //     cellAttributes: { class: { fieldName: 'cssClass' }}
  // },
  { label: 'פעולות', type: 'action', typeAttributes: { rowActions: actions }, cellAttributes: { class: { fieldName: 'cssClass' } } }

];


export default class LmsPublisherWebComponent extends LightningElement {
  @api recordId;
  @track columns = columns;
  @track sortBy;
  @track sortDirection;
  @track isCheckboxChecked = false;
  @track aShowModal = false;

  @track allOppProductsData;
  fieldsForDeleteOppLine = fieldsForDeleteOppLine;
  loading = true;
  connectedCallback() {
    loadStyle(this, cssResource);
  }

  handleRecycledOpp() { //כפתור שחזור
    const elementsToRecycle = JSON.parse(sessionStorage.getItem("deleted-elements"));
    const recycledElements = [];
    elementsToRecycle.forEach(element => {
      const newElement = {
        apiName: "OpportunityLineItem",
        fields: {
          Relative_fertilization__c: element.Relative_fertilization__c,
          Date__c: element.Date__c,
          Is_Extension__c: element.Is_Extension__c,
          N__c: element.N__c,
          P__c: element.P__c,
          K__c: element.K__c,
          Plots__c: element.Plots__c,
          Plot_Size__c: element.Plot_Size__c,
          Irrigation_units__c: element.Irrigation_units__c,
          Division_into_irrigations__c: element.Division_into_irrigations__c,
          Description: element.Description,
          OpportunityId: element.OpportunityId,
          Product2Id: element.Product2Id,
          Quantity: element.Quantity,
          Quantity_per_hectare__c: element.Quantity_per_hectare__c,
          UnitPrice: element.UnitPrice
        }
      }
      console.log(recycledElements);

      recycledElements.push(newElement);
      console.log(JSON.stringify(recycledElements));
    })
    recycledElements.forEach(element => {
      createRecord(element).then((res) => {
        console.log("res: ", res);
      }).catch((err) => {
        console.error(err.body.message);
      })
    })
    this.refreshOppLineList();
    sessionStorage.removeItem("deleted-elements");
  }
  //fields for edit OppLineItem form

  /** Wired Apex result so it can be refreshed programmatically */
  wiredOppProductsData;
  @wire(getOppProducts, { oppId: "$recordId" }) oppProducts(result) {
    let sumN = 0;
    let sumP = 0;
    let sumK = 0;
    this.wiredOppProductsData = result;
    if (result.data) {
      this.allOppProductsData = result.data.map((record) =>
        Object.assign(
          {
            "Product2.Name": record.Product2.Name,
            cssClass: record.Is_Extension__c ? "hideActionButton"  : "showActionButton"
          },
          record
        )
      );

      // Add last row to table for summing NPK values
      result.data.forEach((record) => {
        sumN += record.N__c != null ? parseFloat(record.N__c) : 0;
        sumP += record.P__c != null ? parseFloat(record.P__c) : 0;
        sumK += record.K__c != null ? parseFloat(record.K__c) : 0;
      }
      );
      let sumNPKValRow = {
        "Plots__c": 'סיכום יחידות:',
        "N__c": sumN,
        "P__c": sumP,
        "K__c": sumK,
        cssClass: "hideActionButton"
      }
      this.allOppProductsData.push(sumNPKValRow);

      this.loading = false;
    } else if (result.error) {
      this.error = result.error;
      this.allOppProductsData = undefined;
      this.loading = false;
    }
  }

  // get Add list ins for hide actions
  addInsList = [];

  @wire(getOppLineItemDataMdt, { type: "Extension" }) addInsMd(result) {
    if (result.data) {
      result.data.map((addInRecord) => {
        this.addInsList.push(addInRecord.Id__c);
      });
    } else if (result.error) {
      this.error = result.error;
    }
  }

  // Sorting functions

  doSorting(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortData(this.sortBy, this.sortDirection);
  }

  sortData(fieldname, direction) {
    let parseData = JSON.parse(JSON.stringify(this.allOppProductsData));
    // Return the value stored in the field
    let keyValue = (a) => {
      return a[fieldname];
    };
    // cheking reverse direction
    let isReverse = direction === "asc" ? 1 : -1;
    // sorting data
    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : ""; // handling null values
      y = keyValue(y) ? keyValue(y) : "";
      // sorting values based on direction
      return isReverse * ((x > y) - (y > x));
    });
    this.allOppProductsData = parseData;
  }

  @api refreshOppLineList() {
    this.loading = true;
    refreshApex(this.wiredOppProductsData).then(() => {
      this.loading = false;
    });
  }
  closeApproveDeletionModal() {
    this.aShowModal = false;
  }
  openApproveDeletionModal() {
    this.aShowModal = true;
  }

  handleRowSelection() {
    const selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
    if (selectedRecords.length > 0) {
      this.isCheckboxChecked = true;
    }
    else {
      this.isCheckboxChecked = false;
    }
    this.closeApproveDeletionModal();
  }
  // handleEditSelectedRows() { :TODO

  // }
  oppProductsClone;
  handleDeleteSelectedRows() {
    const selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
    this.oppProductsForDelete = [];
    sessionStorage.setItem("deleted-elements", JSON.stringify(selectedRecords));
    selectedRecords.forEach(element => {
      this.oppProductsForDelete.push(element.Id);
    })
    this.deleteOppLines();
    this.oppProductsForDelete = [];
  }

  handleRowAction(event) {
    let row = JSON.stringify(event.detail.row);
    const oppLinerecordId = JSON.parse(row).Id;
    const payload = { recordId: oppLinerecordId };
    const actionName = event.detail.action.name;

    switch (actionName) {
      case "clone":
        this.handleCloneAction(oppLinerecordId);
        break;
      case "edit":
        this.sendOppLineId(oppLinerecordId);
        break;

      case "delete":
        this.oppLineRecordIdToDelete = oppLinerecordId;
        break;
      default:
    }
  }

  oppLineRecordIdToDelete = "";
  oppProductsForDelete;

  @wire(getRecord, { recordId: "$oppLineRecordIdToDelete", fields: "$fieldsForDeleteOppLine" })
  getOppProductsForDelete({ error, data }) {
    this.oppProductsForDelete = [];
    this.oppProductsForDelete.push(this.oppLineRecordIdToDelete);

    const deletedOppLinesEvent = new CustomEvent("deletedopplines", { detail: { id: this.oppLineRecordIdToDelete } });
    this.dispatchEvent(deletedOppLinesEvent);

    if (data) {
      for (let i = 1; i < 9; i++) {
        if (data.fields["Extension_" + i + "__c"].value != null)
          this.oppProductsForDelete.push(data.fields["Extension_" + i + "__c"].value.split("-")[0]);
      }
      this.deleteOppLines();

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

  deleteOppLines() {
    this.loading = true;
    this.oppProductsForDelete.forEach((oppProductIdToDelete) => {
      console.log("oppproducte id to delete: ", oppProductIdToDelete);
      deleteRecord(oppProductIdToDelete)
        .then(() => {
          this.oppLineRecordIdToDelete = "";
          Utils.showToast(this, "הצלחה", "שורה נמחקה", "info");
          // eval("$A.get('e.force:refreshView').fire();");
          this.refreshOppLineList();
        })
        .catch((error) => {
          Utils.showToast(this, "שגיאה", error.body.message, "error");
          this.loading = false;
        });
    });
  }

  sendOppLineId(oppLineId) {
    const selectedEvent = new CustomEvent("opplineidsent", {
      detail: { Id: oppLineId }
    });
    this.dispatchEvent(selectedEvent);
  }

  handleCloneAction(oppLineId) {
    const selectedEvent = new CustomEvent("opplineidclone", {
      detail: { Id: oppLineId }
    });
    this.dispatchEvent(selectedEvent);
  }


  get showIllustration() {
    return (
      (typeof this.allOppProductsData == "undefined" ||
        this.allOppProductsData == null ||
        this.allOppProductsData.length == null ||
        this.allOppProductsData.length == 0) &&
      !this.loading
    );
  }

  get hasSessionStorage() {
    return sessionStorage.getItem("deleted-elements") === null ? false : true;
  }

}