@isTest
public class Test_UpdateTUCRSettings {
    @isTest
    static void UpdateTUCRSettings() {
        // Create test data
        TU_CR_Settings__c transUnionSettings = new TU_CR_Settings__c();  
        transUnionSettings.TU_Industry_Code__c = 'T';
        transUnionSettings.TU_Certificate_Name__c = 'Tucr';    
        transUnionSettings.TU_Inquiry_Subscriber_Prefix_Code__c = '0522';
        transUnionSettings.TU_Member_Code__c = '1234567';
        transUnionSettings.TU_Password__c = 'L1Y2';
        transUnionSettings.TU_Vendor_Id__c = '1234';
        transUnionSettings.TU_SystemID__c = 'Dynamisch';
        transUnionSettings.TU_System_Password__c = 'Dynamisch123';
        transUnionSettings.TU_Credit_API_Endpoint__c = 'https://nacam-test.transunion.com';
        transUnionSettings.TU_Credit_API_Port__c = '443';
        insert transUnionSettings;
        transUnionSettings.TU_Industry_Code__c = 'I';
        update transUnionSettings;
        
        // Create inputList
        List<String> inputList = new List<String>{'IndustryCode=T, Inquiry=0522, Member=1234567, Password=L1Y2, Vendor=1234,SystemID=Dynamisch,SystemPassword=Dynamisch123,Certificate=Tucr,Port=443,EndPoint=https://nacam-test.transunion.com'};
        
        Test.startTest();
        UpdateTUCRSettings.UpdateTransUnionSettings(inputList);
        Test.stopTest();
  		
        System.assertEquals(1, inputList.size(), 'Custom setting values updated');
        
    }
}