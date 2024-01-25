trigger OrderItem_Trigger on OrderItem (before insert,before update,after update) {
    
    orderItem_CalculateInfo CalculateInfo = new orderItem_CalculateInfo(trigger.operationType);

}