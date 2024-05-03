public class UpdateTUCRSettings {
    
    @InvocableMethod(label='Update TUCR setting' description='To update TransUnion credit report custom setting' category='TU4SF')
    public static void UpdateTransUnionSettings(List<String> inputList) {
        
        // Check if PermissionSet object is accessible
		if (Schema.sObjectType.PermissionSet.isAccessible()) {
			String permissionSetName = 'TransUnion_for_Salesforce';
            Boolean hasPermissionSetAssigned=[SELECT Id 
                                              FROM PermissionSetAssignment 
                                              WHERE PermissionSet.Name = :permissionSetName 
                                              AND AssigneeId = :UserInfo.getUserId()
                                             ].size()!=0;
            
			if(hasPermissionSetAssigned) {
                TU_CR_Settings__c transUnionSettings = TU_CR_Settings__c.getOrgDefaults();
                List<TU_CR_Settings__c> settingsToUpdate = new List<TU_CR_Settings__c>();
                
                for (String input : inputList) {
                    Map<String, String> keyValuePairs = parseInput(input);
                    transUnionSettings.TU_Industry_Code__c = keyValuePairs.get('IndustryCode');
                    transUnionSettings.TU_Inquiry_Subscriber_Prefix_Code__c = keyValuePairs.get('Inquiry');
                    transUnionSettings.TU_Member_Code__c = keyValuePairs.get('Member');
                    transUnionSettings.TU_Password__c = keyValuePairs.get('Password');
                    transUnionSettings.TU_Vendor_Id__c = keyValuePairs.get('Vendor');
                    transUnionSettings.TU_System_Password__c = keyValuePairs.get('SystemPassword');
                    transUnionSettings.TU_Certificate_Name__c = keyValuePairs.get('Certificate'); 
                    transUnionSettings.TU_SystemID__c = keyValuePairs.get('SystemID');
                    transUnionSettings.TU_Credit_API_Port__c = keyValuePairs.get('Port');
                    transUnionSettings.TU_Credit_API_Endpoint__c =keyValuePairs.get('EndPoint');
                    settingsToUpdate.add(transUnionSettings);
                }
                update settingsToUpdate;
            } 
    	}
    }
        
    //Method to parse the input received
    private static Map<String, String> parseInput(String input) {
        Map<String, String> keyValuePairs = new Map<String, String>();
        List<String> pairs = input.split(',');
        
        for (String pair : pairs) {
            List<String> keyValue = pair.split('=');
            
            if (keyValue.size() == 2) {
                keyValuePairs.put(keyValue[0].trim(), keyValue[1].trim());
            }            
        }
        return keyValuePairs;
    }
}