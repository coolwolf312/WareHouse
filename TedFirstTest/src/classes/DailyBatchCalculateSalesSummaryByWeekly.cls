global class DailyBatchCalculateSalesSummaryByWeekly implements Schedulable{



		global void execute(SchedulableContext SC) {
		
			// this job, we need to backup data for 8 months ago
		
			
			 List<GYOrder__c> dataNeedTobackup = [SELECT id,flashCash__c,
			 												TotalCost__c,
			 												OtherCost__c,
															revenue__c,
			 												(select GYProduct__c,SalesDate__c,ProductSoldNumber__c,unitPrice__c 
			 												from GYP_O_Item__r) 
			 									  FROM GYOrder__c where SoldDate__c = THIS_MONTH 
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
						 //String[] toAddresses = new String[] {'langpengju312312@hotmail.com'};
						
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
				
				
				mail.setHtmlBody('<b> 哎呀我去， 你也太懒了！！！！ 大懒月月！！！！！！！！！<p>'	);

						// Send the email you have created.
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				return;
			}else{
	
				// flash cash for this week or month
				decimal totalFlashCash = 0;
				decimal totalSoldProductCost=0;
				decimal weeklyRentAndOtherFee = 0;
				decimal totalRevenue = 0;
				
				Map<id,Integer> soldProductAmountMap = new Map<id,Integer>();
				
				// daily summary info
				for(GYOrder__c dailySalingInfo : dataNeedTobackup ){
					
					totalFlashCash = dailySalingInfo.flashCash__c==null?0:dailySalingInfo.flashCash__c + totalFlashCash;
					totalSoldProductCost = dailySalingInfo.TotalCost__c==null?0:dailySalingInfo.TotalCost__c + totalSoldProductCost;
					 weeklyRentAndOtherFee = dailySalingInfo.OtherCost__c==null?0:dailySalingInfo.OtherCost__c + weeklyRentAndOtherFee;
					totalRevenue = dailySalingInfo.revenue__c==null?0:dailySalingInfo.revenue__c + totalRevenue;
					// daily sales info
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
		
				Map<id,GYProduct__c> soldProductInfoMap = new Map<id,GYProduct__c>([select id,unit_price__c,name from GYProduct__c where id=:soldProductAmountMap.keySet() ]);
				string todaySalesDetailTableHtmlTemp ='<table border="1"><th>售出商品名称</th><th>售出商品数量</th>';
				for(id soldProduct : soldProductAmountMap.keySet()){
					
					// format the email template
					string soldProductName = soldProductInfoMap.get(soldProduct).name;
					todaySalesDetailTableHtmlTemp = todaySalesDetailTableHtmlTemp+'<tr><td>'+soldProductName+'</td><td>'+soldProductAmountMap.get(soldProduct) +'</td></tr>';
					
					// end format the email template
				
				}
				todaySalesDetailTableHtmlTemp = todaySalesDetailTableHtmlTemp + '</table>';
		
				// next, we will calculate the total sales maney and send email to GaoYue

							// Specify the text content of the email.
							//mail.setPlainTextBody('Your Case: ' + case.Id +' has been created.');
							
							mail.setHtmlBody('<b> ' + todayDateStr +' </b> 本月至今销售情况如下.<p>'+
							    '毛利：       '+ totalFlashCash +'<p>'+
							    '售出货物成本： '+totalSoldProductCost +'<p>'+
							    '店铺租金等：   '+weeklyRentAndOtherFee +'<p>'+
							    '纯利润：      '+ totalRevenue +'<p>'+
							    ''+'<p>' +todaySalesDetailTableHtmlTemp
							     );
	
							// Send the email you have created.
							Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				 	
				 	// end sending email
		 	
				 	
				 }									 
			 									  		
	
			
			
		
		
		}
			
		
		
		}