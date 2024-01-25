import Select_Plots from "@salesforce/label/c.Select_Plots";
import Selected from "@salesforce/label/c.Selected";
import Select_Add_In from "@salesforce/label/c.Select_Add_In";
import Product from "@salesforce/label/c.Product";
import From_date from "@salesforce/label/c.From_date";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const label = {
  Select_Plots,
  Selected,
  Select_Add_In,
  Product,
  From_date
};
export { label };

const fieldsForDeleteOppLine = [
  "OpportunityLineItem.Extension_1__c",
  "OpportunityLineItem.Extension_2__c",
  "OpportunityLineItem.Extension_3__c",
  "OpportunityLineItem.Extension_4__c",
  "OpportunityLineItem.Extension_5__c",
  "OpportunityLineItem.Extension_6__c",
  "OpportunityLineItem.Extension_7__c",
  "OpportunityLineItem.Extension_8__c"
];
export { fieldsForDeleteOppLine };


const fieldForCloneOppLine = [
  "OpportunityLineItem.Name",
  "OpportunityLineItem.N__c",
  "OpportunityLineItem.P__c",
  "OpportunityLineItem.K__c",
  "OpportunityLineItem.Relative_fertilization__c",
  "OpportunityLineItem.Quantity_per_hectare__c",
  "OpportunityLineItem.Date__c",
  "OpportunityLineItem.Plot__c",
  "OpportunityLineItem.Quantity",
  "OpportunityLineItem.UnitPrice",
  "OpportunityLineItem.ListPrice",
  "OpportunityLineItem.Irrigation_units__c",
  "OpportunityLineItem.Division_into_irrigations__c",
  "OpportunityLineItem.Irrigation_cubic_meters_per_dunam__c",
  "OpportunityLineItem.Extension_1__c",
  "OpportunityLineItem.Extension_2__c",
  "OpportunityLineItem.Extension_3__c",
  "OpportunityLineItem.Extension_4__c",
  "OpportunityLineItem.Extension_5__c",
  "OpportunityLineItem.Extension_6__c",
  "OpportunityLineItem.Extension_7__c",
  "OpportunityLineItem.Extension_8__c",
  "OpportunityLineItem.Product2.Name",
  "OpportunityLineItem.Product2.N__c",
  "OpportunityLineItem.Product2.P__c",
  "OpportunityLineItem.Product2.K__c",
  "OpportunityLineItem.Product2.Extension_1__c",
  "OpportunityLineItem.Product2.Extension_1__r.Name",
  "OpportunityLineItem.Product2.Extension_2__c",
  "OpportunityLineItem.Product2.Extension_2__r.Name",
  "OpportunityLineItem.Product2.Extension_3__c",
  "OpportunityLineItem.Product2.Extension_3__r.Name",
  "OpportunityLineItem.Product2.Extension_4__c",
  "OpportunityLineItem.Product2.Extension_4__r.Name",
  "OpportunityLineItem.Product2.Extension_5__c",
  "OpportunityLineItem.Product2.Extension_5__r.Name",
  "OpportunityLineItem.Product2.Extension_6__c",
  "OpportunityLineItem.Product2.Extension_6__r.Name",
  "OpportunityLineItem.Product2.Extension_7__c",
  "OpportunityLineItem.Product2.Extension_7__r.Name",
  "OpportunityLineItem.Product2.Extension_8__c",
  "OpportunityLineItem.Product2.Extension_8__r.Name",
  "OpportunityLineItem.Product2.specific_gravity__c",
  "OpportunityLineItem.Product2.Family",
  "OpportunityLineItem.Product2Id",
  "OpportunityLineItem.Plot_Size__c",
  "OpportunityLineItem.Plots__c",
  "OpportunityLineItem.Description"
];
export { fieldForCloneOppLine };

const fieldForDiscount = [
  "Discount__c.Account__c",
  "Discount__c.Account_Classification__c",
  "Discount__c.CreatedById",
  "Discount__c.CurrencyIsoCode",
  "Discount__c.Name",
  "Discount__c.Display_Filter_1__c",
  "Discount__c.Display_Filter_2__c",
  "Discount__c.End_Date__c",
  "Discount__c.Geographic_Area__c",
  "Discount__c.LastModifiedById",
  "Discount__c.Max_Discount__c",
  "Discount__c.Note__c",
  "Discount__c.OwnerId",
  "Discount__c.Product__c",
  "Discount__c.Product_Family_new__c",
  "Discount__c.Sub_Product_Family__c",
  "Discount__c.Requested_Discount__c",
  "Discount__c.Settlement__c",
  "Discount__c.Start_Date__c",
  "Discount__c.Status__c",
  "Discount__c.Target_Discount__c",
  "Discount__c.Reazon__c"
];
export { fieldForDiscount };

const formatter = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'ILS',

  // These options are needed to round to whole numbers if that's what you want.
  minimumFractionDigits: 0, // (this suffices for whole numbers, but will print 2500.10 as $2,500.1)
  maximumFractionDigits: 2, // (causes 2500.99 to be printed as $2,501)
});
export { formatter };

export default class Utils {
    // translate unitOfMeasure code to name or the opssite
    static getUnitOfMeasureCode(unitOfMeasure) {
      if (unitOfMeasure == "קוב") {
          return "M3";
      }
      if (unitOfMeasure == "ליטר") {
          return "LTR";
      }
      if (unitOfMeasure == "טון") {
          return "TO";
      }
      if (unitOfMeasure == "קילו") {
          return "KG";
      }
      if (unitOfMeasure == "יחידה") {
          return "EA";
      }
      else return null;
  }
  
  static getUnitOfMeasureName(unitOfMeasureCode) {
      if (unitOfMeasureCode == '' || unitOfMeasureCode == undefined || unitOfMeasureCode == null) {
          return null;
      }
      if (unitOfMeasureCode == "M3") {
          return "קוב";
      }
      if (unitOfMeasureCode == "LTR") {
          return "ליטר";
      }
      if (unitOfMeasureCode == "TO") {
          return "טון";
      }
      if (unitOfMeasureCode == "KG") {
          return "קילו";
      }
      if (unitOfMeasureCode == "EA") {
          return "יחידה";
      }
      else return unitOfMeasureCode;
  }
  //

  static showToast = (firingComponent, toastTitle, toastBody, variant) => {
    window.scroll(0, 0);

    const event = new ShowToastEvent({
      title: toastTitle,
      message: toastBody,
      variant: variant,
      mode: "pester"
    });
    firingComponent.dispatchEvent(event);
  };

  static sortDualListboxValues(allDualListboxData) {
    allDualListboxData.sort(this.compareDualListboxData);
  }

  static cut2Decimal(longNum) {
    return Math.floor(longNum * 100) / 100;
  }

  static cut1Decimal(longNum) {
    return Math.floor(longNum * 10) / 10;
  }


  static compareDualListboxData(a, b) {
    if (a.label < b.label) {
      return -1;
    }
    if (a.label > b.label) {
      return 1;
    }
    return 0;
  }

  static monthDiff(d1, d2) {
    let dt1 = new Date(d1);
    let dt2 = new Date(d2);
    let months;
    months = (dt2.getFullYear() - dt1.getFullYear()) * 12;
    months -= dt1.getMonth();
    months += dt2.getMonth() + 1;
    return months <= 0 ? 0 : months;
  }

  static convertRatio(N, P, K) {
    // divide non 0 numbers with min number

    // empty fields exists => check if division is possible or not
    // empty fields not exists => check if division is possible or not
    let emptyFieldLocation = getEmptyFieldLocation();

    let minimum = findGCDInRatio(N, P, K);

    if (emptyFieldLocation === null) {
      return caseNoEmptyFieldsExists();
    } else {
      return caseEmptyFieldsExists();
    }

    function caseNoEmptyFieldsExists() {
      // NOTE: values are NaN if N,P,K isn't representing a number
      let n = parseInt(N);
      let p = parseInt(P);
      let k = parseInt(K);
      if (N === 0 && P === 0 && K === 0) {
        return 0 + "-" + 0 + "-" + 0;
      }
      if (n % minimum === 0 && p % minimum === 0 && k % minimum === 0) {
        // devision is possible for all fields
        return n / minimum + "-" + p / minimum + "-" + k / minimum;
      } else {
        return n + "-" + p + "-" + k;
      }
    }

    function caseEmptyFieldsExists() {
      // one of the fields is empty
      // push the 2 non empty fields into array
      // NOTE: values in map are NaN if N,P,K isn't representing a number
      let mapNPK = { N: parseInt(N), P: parseInt(P), K: parseInt(K) };
      let nonEmptyNumsArr = [];
      for (let intMapKey in mapNPK) {
        if (!isNaN(mapNPK[intMapKey])) {
          nonEmptyNumsArr.push(mapNPK[intMapKey]);
        }
      }
      let num1 = nonEmptyNumsArr[0];
      let num2 = nonEmptyNumsArr[1];

      if ((num1 % minimum === 0) & (num2 % minimum === 0)) {
        return num1 / minimum + "-" + num2 / minimum;
      } else {
        return num1 + "-" + num2;
      }
    }

    function getEmptyFieldLocation() {
      if (N === "") {
        return "N";
      } else if (P === "") {
        return "P";
      } else if (K === "") {
        return "K";
      } else return null;
    }

    // calculates greatest common devider (GCD) for normalizing the NPK ratio input
    function findGCDInRatio(num1, num2, num3) {
      let gcd;

      if (num1 == null) {
        gcd = Utils.gcd(num2, num3);
      }
      else if (num2 == null) {
        gcd = Utils.gcd(num1, num3);
      }
      else if (num3 == null) {
        gcd = Utils.gcd(num1, num2);
      }
      else {
        gcd = Utils.findGCD([num1, num2, num3]);
      }
      return gcd;
    }
  }

  static getMinimum(N, P, K) {
    // Returns the minimum value from N,P,K excluding 0
    // Accepts either Integers or Strings
    // Values which not representing a Number will be treated as 0

    // replaces '' with 0 as only the minimum required regardless if the field is empty or not
    let n = parseInt(N);
    let p = parseInt(P);
    let k = parseInt(K);
    if (n.isNaN) {
      n = 0;
    }
    if (p.isNaN) {
      p = 0;
    }
    if (k.isNaN) {
      k = 0;
    }

    let minValue = Math.min.apply(null, [n, p, k].filter(Boolean)); // gets min value after filtering 0 from npk
    if (minValue == Infinity) {
      minValue = 0;
    } // 'Infinity' will be produced if npk == (0,0,0) as we filtered all zeroes
    return minValue;
  }


  // Function to return gcd of a and b 
  static gcd(a, b) {
    if (a == 0)
      return b;
    return Utils.gcd(b % a, a);
  }

  // Function to find gcd of array of 
  // numbers 
  static findGCD(arr) {
    let result = 0;

    arr.forEach(element => {
      result = Utils.gcd(result, element);

      if (result == 1) {
        return 1;
      }
    });

    return result;
  }
}