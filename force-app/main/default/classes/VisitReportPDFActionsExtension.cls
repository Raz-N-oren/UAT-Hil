public without sharing class VisitReportPDFActionsExtension {
  
  public VisitReportPDFActionsExtension(ApexPages.StandardController std) {
    
  }

  
  @RemoteAction 
  public static void savePDF(Id id,String name) {
    PageReference thePDF = Page.VisitReportPDF;
    thePDF.getParameters().put('id', id);
    thePDF.setRedirect(true);

    Blob fileContent = (Test.isRunningTest()) ? 
    Blob.valueOf(String.valueOf(thePDF)) : thePDF.getContentAsPDF();
    String yourFilesContent = EncodingUtil.base64Encode(
      fileContent
    );

    ContentVersion conVer = new ContentVersion();
    conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
    conVer.PathOnClient = '.Pdf'; // The files name, extension is very important here which will help the file in preview.
    conVer.Title = name; // Display name of the files
    conVer.VersionData = EncodingUtil.base64Decode(yourFilesContent); // converting your binary string to Blog
    insert conVer; //Insert ContentVersion

    // First get the Content Document Id from ContentVersion Object
    Id conDoc = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :conVer.Id
    ]
    .ContentDocumentId;
    //create ContentDocumentLink  record
    ContentDocumentLink conDocLink = new ContentDocumentLink();
    conDocLink.LinkedEntityId = id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
    conDocLink.ContentDocumentId = conDoc; //ContentDocumentId Id from ContentVersion
    conDocLink.shareType = 'V';
    insert conDocLink;

  }
  
 
  

  
}