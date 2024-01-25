public with sharing class CreateUpdateMetadataUtils implements Metadata.DeployCallback {
    // Method that updates the token in metadata
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            // Deployment was successful, take appropriate action.
            System.debug('Deployment Succeeded!');
        } else {
            // Deployment wasn’t successful, take appropriate action.
	        System.debug('Deployment Failed!');
        }
    }
}