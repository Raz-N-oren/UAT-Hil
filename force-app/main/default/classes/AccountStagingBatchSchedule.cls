//System.schedule('Account Staging Hourly Process', '0 0 * * * ?', new AccountStagingBatchSchedule() );

global class AccountStagingBatchSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        AccountStagingBatch accountStageBatch = new AccountStagingBatch();
        database.executeBatch(accountStageBatch);
    }
}