public class SuperClone {
    private static SuperCloneService service = new SuperCloneService();
    @AuraEnabled
    public static Id doClone(Id parentId) {
        Id clonedId = service.doClone(parentId);
        return clonedId;
    }


    @AuraEnabled
    public static Id doCloneOppWithPlots(String parentId, Id accountId, String plotNames, String growthName, Decimal plotsSize) {
        Id clonedId = service.doCloneOppWithPlots(parentId, accountId, plotNames,growthName,plotsSize);
        return clonedId;
    }
    
}