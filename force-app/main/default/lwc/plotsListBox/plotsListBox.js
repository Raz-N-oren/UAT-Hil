import { LightningElement, api, wire, track } from "lwc";
import Utils from 'c/utils';
import { NavigationMixin } from "lightning/navigation";
import getPlots from "@salesforce/apex/YearlyPlanController.getPlots";
import cloneOppWithPlots from "@salesforce/apex/SuperClone.doCloneOppWithPlots";

export default class PlotsListBox extends NavigationMixin(LightningElement) {
  @api oppIdToClone;
  @api accountId;
  @track allPlotsData;
  allPlotsDataMap;

  wiredPlotsData;

  @wire(getPlots, { accountId: "$accountId" }) plots(result) {
    this.wiredPlotsData = result;
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

     this.template.querySelector('c-mutli-select-picklist').fetchSelectedValues();

    } else if (result.error) {
      this.error = result.error;
      this.allPlotsData = undefined;
    }
  }
 
  _selected = [];

  selectedData = [];

  get selected() {
    return this._selected.length == 1 ? this._selected[0] : null;
  }

  handleChange(e) {
    this._selected = e.detail.selectedValues;
    this.selectedData = this._selected.map(
      (select) =>
        this.allPlotsDataMap.filter((option) => option.key == select)[0]
    );
   
    const selectedEvent = new CustomEvent("disablebutton", {
      detail: { State: this._selected.length==0 }
    });
    this.dispatchEvent(selectedEvent);
    
  }


  @api
  cloneOpp(oppIdToClone,isNewCloneTypeValue) {
    let sumSize = 0;
    let plotNames = "";
    let growthName = "";
    for (const i in this.selectedData) {
      sumSize += this.selectedData[i].size;
      plotNames += this.selectedData[i].label + " ; ";
      growthName += this.selectedData[i].growth;
    }
    plotNames = plotNames.slice(0,-2);

    cloneOppWithPlots({
      parentId: oppIdToClone,
      accountId: isNewCloneTypeValue ? null : this.accountId,
      plotNames: isNewCloneTypeValue ? null : plotNames,
      growthName: isNewCloneTypeValue ? null : growthName,
      plotsSize: isNewCloneTypeValue ? null : sumSize 
    })
      .then((result) => {
        console.log(result);
        this.navigateToClonedOpp(result);
      })
      .catch((error) => {
        console.log("Error Occured:- " + error.body.message);
      });
  }

  navigateToClonedOpp(clonedOppId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: clonedOppId,
        objectApiName: "Opportunity",
        actionName: "view"
      }
    });
  }

  // pass oppIdToClone to super clone function to clone and then modify the oppline items woth selected plot
  // configure the super clone metadata to work with Opps and opp lines
}