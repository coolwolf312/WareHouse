global class DailyBatchCalculateSalesSummary implements Schedulable{



		global void execute(SchedulableContext SC) {
			// this job, we need to backup data for 8 months ago
		
			
			 List<GYOrder__c> dataNeedTobackup = [SELECT id,flashCash__c,
			 												//TotalCost__c,
			 												OtherCost__c,
			 												(select GYProduct__c,SalesDate__c,ProductSoldNumber__c,unitPrice__c from GYP_O_Item__r) 
			 									  FROM GYOrder__c where SoldDate__c = TODAY
			 									];
			
											  // send email to gy and cc ted
			 	// First, reserve email capacity for the current Apex transaction to ensure
						// that we won't exceed our daily email limits when sending email after
						// the current transaction is committed.
						Messaging.reserveSingleEmailCapacity(2);
						
						// Processes and actions involved in the Apex transaction occur next,
						// which conclude with sending a single email.
						
						// Now create a new single email message object
						// that will send out a single email to the addresses in the To, CC & BCC list.
						Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
						
						// Strings to hold the email addresses to which you are sending the email.
						String[] toAddresses = new String[] {'lan.yue.1314@hotmail.com'}; 
						String[] ccAddresses = new String[] {'langpengju312312@hotmail.com'};
						  
						
						// Assign the addresses for the To and CC lists to the mail object.
						mail.setToAddresses(toAddresses);
						mail.setCcAddresses(ccAddresses);
						
						// Specify the address used when the recipients reply to the email. 
						mail.setReplyTo('langpengju312312@hotmail.com');
						
						// Specify the name used as the display name.
						mail.setSenderDisplayName('大月的仓库管理员');
						
						// Specify the subject line for your email address.
						string todayDateStr = system.today().format();
						
						mail.setSubject(todayDateStr +' 销售情况概要 ' );
						
						// Set to True if you want to BCC yourself on the email.
						mail.setBccSender(false);
						
						// Optionally append the salesforce.com email signature to the email.
						// The email address of the user executing the Apex Code will be used.
						mail.setUseSignature(false);
			
			if(dataNeedTobackup==null || dataNeedTobackup.size()==0){
				
				
				mail.setHtmlBody('<b> 哎呀我去， 你也太懒了！！！！ 大懒月月！！！！！！！！！<p>'			   
						     );

						// Send the email you have created.
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				return;
			}else{
	
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
				
				// get the store
				GYStore__c storeOwnByGaoyue = [SELECT Id FROM GYStore__c limit 1];
				
				GYOrder__c newCreatedBackupSoldInfoForToday = new GYOrder__c();
				newCreatedBackupSoldInfoForToday.SoldDate__c = today;
				newCreatedBackupSoldInfoForToday.ProductFrom__c = storeOwnByGaoyue.id;
				newCreatedBackupSoldInfoForToday.flashCash__c = totalFlashCash;
				newCreatedBackupSoldInfoForToday.OtherCost__c = monthlyRentAndOtherFee;
				insert newCreatedBackupSoldInfoForToday;
				
				
				Map<id,GYProduct__c> soldProductInfoMap = new Map<id,GYProduct__c>([select id,unit_price__c,name from GYProduct__c where id=:soldProductAmountMap.keySet() ]);
				
				
				List<GYP_O_Item__c> insertProductlist = new List<GYP_O_Item__c>();
				string todaySalesDetailTableHtmlTemp ='<table border="1"><th>售出商品名称</th><th>售出商品数量</th>';
				for(id soldProduct : soldProductAmountMap.keySet()){
					
					
					GYP_O_Item__c signleProductSoldDetailsByToday = new GYP_O_Item__c();
					signleProductSoldDetailsByToday.GYProduct__c = soldProduct;
					
					
					signleProductSoldDetailsByToday.ProductSoldNumber__c = soldProductAmountMap.get(soldProduct);
					decimal productCostForTheseAmount = signleProductSoldDetailsByToday.ProductSoldNumber__c * soldProductInfoMap.get(soldProduct).unit_price__c;
					signleProductSoldDetailsByToday.subCost__c = productCostForTheseAmount;
					signleProductSoldDetailsByToday.GYOrder__c = newCreatedBackupSoldInfoForToday.id;
					insertProductlist.add(signleProductSoldDetailsByToday);
					
					
					// format the email template
					string soldProductName = soldProductInfoMap.get(soldProduct).name;
					todaySalesDetailTableHtmlTemp = todaySalesDetailTableHtmlTemp+'<tr><td>'+soldProductName+'</td><td>'+signleProductSoldDetailsByToday.ProductSoldNumber__c +'</td></tr>';
					
					// end format the email template
				
				}
				todaySalesDetailTableHtmlTemp = todaySalesDetailTableHtmlTemp + '</table>';
				
				if(insertProductlist!=null && insertProductlist.size()>0){
					insert insertProductlist;
					
					// delete the 
					delete dataNeedTobackup;
					
					
				}
				
				
				// next, we will calculate the total sales maney and send email to GaoYue
				
				list<GYOrder__c> todaySalesInfoList = [SELECT id,flashCash__c,         // total sold maney today
				 												TotalCost__c, // product cost
				 												revenue__c, // today's total revenue
				 												OtherCost__c // today's rent cast
				 												
				 									  FROM GYOrder__c where SoldDate__c = TODAY];
				 									  
				 	
							
				 									  
				 									  
				 									  
				 if (todaySalesInfoList.size()>0){
				 	
				 	GYOrder__c todaySalesInfo = todaySalesInfoList.get(0);
	
							// Specify the text content of the email.
							//mail.setPlainTextBody('Your Case: ' + case.Id +' has been created.');
							
							mail.setHtmlBody('<b> ' + todayDateStr +' </b> 销售情况如下.<p>'+
							    '毛利：       '+ todaySalesInfo.flashCash__c +'<p>'+
							    '售出货物成本： '+todaySalesInfo.TotalCost__c +'<p>'+
							    '店铺租金等：   '+todaySalesInfo.OtherCost__c +'<p>'+
							    '纯利润：      '+ todaySalesInfo.revenue__c +'<p>'+
							    ''+'<p>' +todaySalesDetailTableHtmlTemp
							     );
	
							// Send the email you have created.
							Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				 	
				 	// end sending email
				 	
				 	
				 }									 
			 									  
			// get the daily summary info
			
	
			}
			
		}




}