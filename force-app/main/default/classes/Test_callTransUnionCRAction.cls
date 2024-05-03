@isTest
global class Test_callTransUnionCRAction {
    // Method to create and return mock settings with the required fields set
    private static TU_CR_Settings__c createMockSettings() {
        TU_CR_Settings__c transUnionSettings = new TU_CR_Settings__c();
        transUnionSettings.TU_Industry_Code__c = 'T';
        transUnionSettings.TU_Certificate_Name__c='tucrcertsf2';	
        transUnionSettings.TU_Inquiry_Subscriber_Prefix_Code__c = '0522';
        transUnionSettings.TU_Member_Code__c = '1234567';
        transUnionSettings.TU_Password__c = 'L1Y2';
        transUnionSettings.TU_Vendor_Id__c = '1234';
        transUnionSettings.TU_SystemID__c='Dynamisch';
        transUnionSettings.TU_System_Password__c='Dynamisch123';
        transUnionSettings.TU_Credit_API_Endpoint__c='https://nacam-test.transunion.com';
        transUnionSettings.TU_Credit_API_Port__c='443';
        insert transUnionSettings;
        return transUnionSettings;
    }
    
    @isTest
    private static void testSoapCalloutSuccess() {
        TU_CR_Settings__c transUnionSettings = createMockSettings();
        // Test data
        List<String> creditOutput = new List<String>{'SSNNumber%%%123456789',
            									     'FirstName%%%John',
                                                     'LastName%%%Doe',
                                                     'Apartmentnumber%%%Apt 123',
                                                     'Street%%%Main St',
                                                     'City%%%Springfield',
                                                     'State%%%IL',
                                                     'PostalCode%%%12345',
                                                     'RecordId%%%003an000001LvIrAAK'};
		Test.setMock(HttpCalloutMock.class, new mockHttpResponseGenerator());
        
        Test.startTest();
        List<String> result = callTransUnionCRAction.callTransUnionCR(creditOutput);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Expected only one result');
    }
    
    @isTest
    private static void testSoapCalloutError() {
        TU_CR_Settings__c transUnionSettings = createMockSettings();
        List<String> creditOutput = new List<String>{'SSNNumber%%%123456789',
                                                     'FirstName%%%John',
                                                     'LastName%%%Doe',
                                                     'Apartmentnumber%%%Apt 123',
                                                     'Street%%%Main St',
                                                     'City%%%Springfield',
                                                     'State%%%IL',
                                                     'PostalCode%%%12345',
                                                     'RecordId%%%003an000001LvIrAwg'};
		Test.setMock(HttpCalloutMock.class, new mockHttpResponseGeneratorError());
        
        Test.startTest();
        List<String> result = callTransUnionCRAction.callTransUnionCR(creditOutput);
        Test.stopTest();
        
        System.assert(result != null, 'An error should be returned');
    } 
    
    // Mock HTTP response generator for success
    private class mockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setBody('<response><fileHitIndicator>regularHit</fileHitIndicator><fileHitIndicator>error</fileHitIndicator><fileHitIndicator>Other</fileHitIndicator><fileHitIndicator>regularnohit</fileHitIndicator><address><street>hinjewadi</street></address><address><street>hinjewadi1</street></address><address><street>hinjewadi2</street></address><results>+750</results><transactionTimeStamp>2024-04-05T12:00:00Z</transactionTimeStamp><embeddedData>fake embedded data</embeddedData><error><description>Error message</description></error></response>');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock HTTP response generator for error
    private class mockHttpResponseGeneratorError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setBody('<error><errormessage>Your Subscriber Code is not linked with the System ID.</errormessage><description>Error occurred</description></error>');
            res.setStatusCode(500);
            res.setStatus('500 Internal Server Error');
            return res;
        }
    }
}