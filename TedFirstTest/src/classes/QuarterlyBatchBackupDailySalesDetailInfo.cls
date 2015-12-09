global class QuarterlyBatchBackupDailySalesDetailInfo implements Schedulable{



		global void execute(SchedulableContext SC) {
			// this job, we need to backup data for 8 months ago
			Date currentDate = system.today();
			
			//system.debug(currentDate);
			Date lastRunDate = currentDate.addMonths(-9).adddays(-1);
			//system.debug(lastRunDate);
				
			
			 List<GYOrder__c> dataNeedTobackup = [SELECT id,flashCash__c,
			 												//TotalCost__c,
			 												OtherCost__c,
			 												(select GYProduct__c,SalesDate__c,ProductSoldNumber__c,unitPrice__c from GYP_O_Item__r) 
			 									  FROM GYOrder__c where SoldDate__c < last_n_months:8 and SoldDate__c>:lastRunDate
			 									];
			
			if(dataNeedTobackup==null || dataNeedTobackup.size()==0)
				return;
				
			decimal totalFlashCash = 0;
			//decimal totalSoldProductCost=0;
			decimal monthlyRentAndOtherFee = 0;
			
			Map<id,Integer> soldProductAmountMap = new Map<id,Integer>();
			
			for(GYOrder__c dailySalingInfo : dataNeedTobackup ){
				
				totalFlashCash = dailySalingInfo.flashCash__c==null?0:dailySalingInfo.flashCash__c + totalFlashCash;
				//totalSoldProductCost = dailySalingInfo.TotalCost__c==null?0:dailySalingInfo.TotalCost__c;
				monthlyRentAndOtherFee = dailySalingInfo.OtherCost__c==null?0:dailySalingInfo.OtherCost__c + monthlyRentAndOtherFee;
				
				
				for (GYP_O_Item__c  soldProdctDetail : dailySalingInfo.GYP_O_Item__r){
					
					if(soldProductAmountMap.containsKey(soldProdctDetail.GYProduct__c)){
			          Integer soldProductN = soldProductAmountMap.get(soldProdctDetail.GYProduct__c);
			          soldProductN = soldProductN + Integer.valueOf(soldProdctDetail.ProductSoldNumber__c);
			          soldProductAmountMap.put( soldProdctDetail.GYProduct__c,soldProductN);
			          
			          
			        }else{
			        			           
			           soldProductAmountMap.put( soldProdctDetail.GYProduct__c,Integer.valueOf(soldProdctDetail.ProductSoldNumber__c));
			                    
			        }   
		
				}
			
			}
	
			// sold date
			Date today = system.today();
			Date egihtmonthago = today.addMonths(-8);
			Date newCreatedBackupDate = egihtmonthago.toStartOfMonth().addDays(-1);
			// get the store
			GYStore__c storeOwnByGaoyue = [SELECT Id FROM GYStore__c limit 1];
			
			GYOrder__c newCreatedBackupSoldInfoByMonth = new GYOrder__c();
			newCreatedBackupSoldInfoByMonth.SoldDate__c = newCreatedBackupDate;
			newCreatedBackupSoldInfoByMonth.ProductFrom__c = storeOwnByGaoyue.id;
			newCreatedBackupSoldInfoByMonth.flashCash__c = totalFlashCash;
			newCreatedBackupSoldInfoByMonth.OtherCost__c = monthlyRentAndOtherFee;
			insert newCreatedBackupSoldInfoByMonth;
			
			
			Map<id,GYProduct__c> soldProductInfoMap = new Map<id,GYProduct__c>([select id,unit_price__c,name from GYProduct__c where id=:soldProductAmountMap.keySet() ]);
			
			
			List<GYP_O_Item__c> insertProductlist = new List<GYP_O_Item__c>();
			for(id soldProduct : soldProductAmountMap.keySet()){
				
				
				GYP_O_Item__c signleProductSoldDetailsByMonth = new GYP_O_Item__c();
				signleProductSoldDetailsByMonth.GYProduct__c = soldProduct;
				
				signleProductSoldDetailsByMonth.ProductSoldNumber__c = soldProductAmountMap.get(soldProduct);
				decimal productCostForTheseAmount = signleProductSoldDetailsByMonth.ProductSoldNumber__c * soldProductInfoMap.get(soldProduct).unit_price__c;
				signleProductSoldDetailsByMonth.subCost__c = productCostForTheseAmount;
				signleProductSoldDetailsByMonth.GYOrder__c = newCreatedBackupSoldInfoByMonth.id;
				insertProductlist.add(signleProductSoldDetailsByMonth);
			
			}
			if(insertProductlist!=null && insertProductlist.size()>0){
				insert insertProductlist;
				
				// delete the 
				delete dataNeedTobackup;
				
				
			}
			
			
			
		}




}