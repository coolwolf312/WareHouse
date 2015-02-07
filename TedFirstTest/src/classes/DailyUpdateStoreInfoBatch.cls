global class DailyUpdateStoreInfoBatch implements Schedulable{
	
		global void execute(SchedulableContext SC) {
			GoodsInfoBatchHandler b = new GoodsInfoBatchHandler(); 
      		database.executebatch(b);
	
		}
	

}