global class InitializeTrainingOrg {
    public Static void InitializeTrainingOrg(){ 
        
        //Delete all products first
        List<Product2> productsToDelete = [Select id, name from Product2];
            if(productsToDelete != null){
                delete productsToDelete;
            }
        
        //Update the external Ids on existing standard pricebooks
        List<Pricebook2> pbToUpdate = [SELECT Id, Name, ExternalId__c,IsActive,IsStandard from Pricebook2 Where ExternalId__c = ''];
        if(pbToUpdate != null){
            for(Pricebook2 pb : pbToUpdate){
                if(pb.Name == 'Standard'){
                    pb.ExternalId__c = 'STD';
                }else if(pb.Name == 'Standard Price Book'){
                    pb.ExternalId__c = 'STD2';
                }
            }
            update pbToUpdate;
        }
        
        //Create B2B and B2C pricebooks
        StaticResource pricebookStaticResource = [Select Body from StaticResource where Name = 'Pricebook'];
        String pricebookCsv = pricebookStaticResource.Body.toString();
        Pricebook2[] pbList = new Pricebook2[] {};
            for(String row : pricebookCsv.split('\n')){
                String[] column = row.split(',');
                pbList.add(new Pricebook2(
                	Name = column[0].replace('"',''),
                    ExternalId__c = column[1].replace('"',''),
                    IsActive = true
                ));
            }
        upsert pbList ExternalId__c;
        
        //Upserting the products list
        StaticResource productStaticResource = [Select Body from StaticResource where Name = 'Products'];
        String productCsv = productStaticResource.Body.toString();
        Product2[] prodList = new Product2[] {};
            for(String row : productCsv.split('\n')){
                String[] column = row.split(',');
                prodList.add(new Product2(
                	Name = column[0].replace('"',''),
                    ProductCode = column[1].replace('"',''),
                    ExternalId__c = column[2].replace('"',''),
                    Description = column[3].replace('"',''),
                    IsActive = Boolean.valueOf(column[4].replace('"','')),
                    Family = column[5].replace('"',''),
                    SBQQ__NonDiscountable__c = Boolean.valueof(column[6].replace('"','')),
                    SBQQ__PricingMethod__c = column[7].replace('"',''),
                    SBQQ__QuantityEditable__c = Boolean.valueOf(column[8].replace('"','')),
                    SBQQ__SubscriptionPricing__c = column[9].replace('"',''),
                    SBQQ__SubscriptionTerm__c = column[10].replace('"','') == '' ? null : Decimal.valueOf(column[10].replace('"','')),
                    SBQQ__AssetConversion__c = column[11].replace('"',''),
                    InitUnitPrice__c = Decimal.valueOf(column[12].replace('"',''))

                ));
            }
        upsert prodList ExternalId__c;
        
        // Upsert Pricebook Entries to Standard PB
      
        List<Product2> products = [Select id, InitUnitPrice__c from Product2];
        
        Pricebook2 standardPB = [select id from Pricebook2 where ExternalId__c = 'STD2' LIMIT 1];
        List<Pricebookentry> pbeList = new List<Pricebookentry>();
        
        for(Product2 p : products){
            Pricebookentry pbe = new pricebookentry();
            pbe.product2id = p.id;
            pbe.pricebook2id = standardPB.id;
            pbe.UnitPrice = p.InitUnitPrice__c;
            pbe.IsActive = true;
			pbe.UseStandardPrice = false;
            pbeList.add(pbe);
        }
        insert pbeList;
        
        List<Pricebook2> pricebooks = [select id, ExternalId__c from Pricebook2 where ExternalId__c != 'STD2' ORDER BY ExternalId__c ASC];
		List<Pricebookentry> pbe2List = new List<Pricebookentry>();
        
        for(Pricebook2 pb : pricebooks){
            for(Product2 p2 : products){
                Pricebookentry pbe2 = new pricebookentry();
                pbe2.product2id = p2.id;
                pbe2.pricebook2id = pb.id;
                pbe2.IsActive = true;
                pbe2.UseStandardPrice = true;
                pbe2.UnitPrice = p2.InitUnitPrice__c;
                                
                pbe2List.add(pbe2);
            }
        }
        insert pbe2List;
        
    
    }
    
}