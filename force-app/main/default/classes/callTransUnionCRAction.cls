public class callTransUnionCRAction { 
    
    @InvocableMethod(label='Credit Report Hard Pull' description='To hard pull the credit report from TransUnion' category='TU4SF')
    public static List<String> callTransUnionCR(List<String> creditOutput) {
        List<String> errorMsgs = new List<String>();
        
        if (Schema.sObjectType.PermissionSet.isAccessible()) {
            String permissionSetName = 'TransUnion_for_Salesforce';
            Boolean hasPermissionSetAssigned=[SELECT Id 
                                              FROM PermissionSetAssignment 
                                              WHERE PermissionSet.Name = :permissionSetName 
                                              AND AssigneeId = :UserInfo.getUserId()
                                             ].size()!=0;
    
			if(hasPermissionSetAssigned) {
                TU_CR_Settings__c transUnionSettings = TU_CR_Settings__c.getOrgDefaults();
                String ssnNumber = '';
                String firstName = '';
                String lastName = '';
                String apartmentNumber = '';
                String street = '';
                String city = '';
                String state = '';
                String country = 'us';
                String postalCode = '';
                String recordId = '';
                List<String> creditScores = new List<String>();
                
                for (String output : creditOutput) {   
                    Map<String, String> keyValuePairs = parseOutput(output);
                    ssnNumber = keyValuePairs.get('SSNNumber');
                    firstName = keyValuePairs.get('FirstName');
                    lastName = keyValuePairs.get('LastName');
                    apartmentNumber = keyValuePairs.get('ApartmentNumber');
                    street = keyValuePairs.get('Street');
                    city = keyValuePairs.get('City');
                    state = keyValuePairs.get('State');
                    postalCode = keyValuePairs.get('PostalCode');
                    recordId = keyValuePairs.get('RecordId');
                }
                
                String apartmentStreet = apartmentNumber + ' ' + street;
                String soapRequestBody = generateSoapRequest(ssnNumber, firstName, lastName, apartmentStreet, city, state, country, postalCode, transUnionSettings);
                String certificateName = transUnionSettings.TU_Certificate_Name__c;
                HttpResponse response = sendSoapRequest(soapRequestBody, certificateName, transUnionSettings);
                
                if (response.getStatusCode() == 200) {
                    String responseBody = response.getBody();
                    List<String> responseToReturn = parseResponse(responseBody, creditScores, errorMsgs, recordId, firstName, lastName);
                    responseToReturn[0]=responseToReturn[0] + '*Request*' + soapRequestBody + '*Response*' + response.getBody();
                    return responseToReturn;
                } else {
                    String errorMessage = 'SOAP Callout Failed: ' + response.getStatusCode() + ' ' + response.getStatus();
                    // Get error Message
                    XmlStreamReader errorReader = new XmlStreamReader(response.getBody()); 
                    while (errorReader.hasNext()) {
                        if (errorReader.getEventType() == XmlTag.START_ELEMENT && 'error' == errorReader.getLocalName()) {
                            while (errorReader.hasNext() && !(errorReader.getEventType() == XmlTag.END_ELEMENT && errorReader.getLocalName() == 'error')) {
                                if (errorReader.getEventType() == XmlTag.START_ELEMENT && errorReader.getLocalName() == 'errormessage') {
                                    errorReader.next();
                                    errorMsgs.add('SOAP Callout Failed: ' + response.getStatusCode() + '  ' + response.getStatus()+ '.' + errorReader.getText());
                                }
                                errorReader.next();
                            }
                            break;
                        }
                        errorReader.next();
                    }
                    errorMsgs[0]=errorMsgs[0] + '*Request*' + soapRequestBody + '*Response*' + response.getBody();
                    return errorMsgs;
        		}
			} else {
                // User does not have the permission set assigned
                String msg='User does not have the required permission set assigned to fetch the credit report.';
                errorMsgs.add(msg);
                return errorMsgs;
        	}
		} else {
            // PermissionSet object is not accessible
            String msg='Permission set object is not accessible to the user';
            errorMsgs.add(msg);
            return errorMsgs;
		} 
	}
    
    // Parse the input String received from flow 
	private static Map<String, String> parseOutput(String output) {
        Map<String, String> keyValuePairs = new Map<String, String>();
        List<String> pairs = output.split('&#&#&');
        
        for (String pair : pairs) {
            List<String> keyValue = pair.split('%%%');
            if (keyValue.size() == 2) {
                keyValuePairs.put(keyValue[0].trim(), keyValue[1].trim());
            }
        }
        return keyValuePairs;
    }
    
    // SOAP Callout Method  
    private static String generateSoapRequest(String ssnNumber, String firstName, String lastName, String apartmentStreet, String city, 
                                              String state, String country, String postalCode, TU_CR_Settings__c transUnionSettings) {
                                                  
        String soapRequestBody = '<?xml version="1.0" encoding="utf-8" ?> ' +
            '<xmlrequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
            'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope"' +
            'xmlns=http://www.netaccess.transunion.com/namespace">' +  
            '<systemId>IVYTEKI1</systemId>' +
            '<systemPassword>Transunion123</systemPassword>' +
            '<productrequest>' +
            '<creditBureau xmlns="http://www.transunion.com/namespace">' +
            '<document>request</document>' +
            '<version>2.26</version>' +
            '<transactionControl>' +
            '<subscriber>' +
            '<industryCode>' + transUnionSettings.TU_Industry_Code__c + '</industryCode>' +
            '<memberCode>' + transUnionSettings.TU_Member_Code__c + '</memberCode>' +
            '<inquirySubscriberPrefixCode>' + transUnionSettings.TU_Inquiry_Subscriber_Prefix_Code__c + '</inquirySubscriberPrefixCode>' +
            '<password>' + transUnionSettings.TU_Password__c + '</password>' +
            '</subscriber>' +
            '<options>' +
            '<processingEnvironment>standardTest</processingEnvironment>' +
            '<country>' + country + '</country>' +
            '<language>en</language>' +
            '<contractualRelationship>individual</contractualRelationship>' +
            '<pointOfSaleIndicator>none</pointOfSaleIndicator>' +
            '</options>' +
            '</transactionControl>' +
            '<product>' +
            '<code>07000</code>' +
            '<subject>' +
            '<number>1</number>' +
            '<subjectRecord>' +
            '<indicative>' +
            '<name>' +
            '<person>' +
            '<first>' + firstName + '</first>' +
            '<last>' + lastName + '</last>' +
            '</person>' +
            '</name>' +
            '<address>' +
            '<status>current</status>' +
            '<street>' +
            '<unparsed> ' + apartmentStreet + '</unparsed>' +
            '</street>' +
            '<location>' +
            '<city>' + city + '</city>' +
            '<state>' + state + '</state>' +
            '<zipCode>' + postalCode + '</zipCode>' +
            '</location>' +
            '</address>' +
            '<socialSecurity>' +
            '<number>' + ssnNumber + '</number>' +
            '</socialSecurity>' +
            '</indicative>' +
            '<custom>' + 
            '<credit>' +
            '<creditSummary>' +
            '<returnAccountRating>false</returnAccountRating>' +
            '</creditSummary>' +
            '</credit>' +
            '</custom>' +
            '</subjectRecord>' +
            '</subject>' +   
            '<responseInstructions>' +
            '<returnErrorText>true</returnErrorText>' +
            '<embeddedData>pdf</embeddedData>' +
            '<document></document>' +
            '</responseInstructions>' +
            '</product>' +
            '</creditBureau>' +
            '</productrequest>' +
            '</xmlrequest>';
        return soapRequestBody;
    }
    
    // SOAP Callout Response    
	private static HttpResponse sendSoapRequest(String soapRequestBody, String certificateName,TU_CR_Settings__c transUnionSettings) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST'); 
        request.setEndpoint(transUnionSettings.TU_Credit_API_Endpoint__c + ':' + transUnionSettings.TU_Credit_API_Port__c);
        request.setClientCertificateName(certificateName);
        request.setHeader('Content-Type', 'text/xml'); 
        request.setBody(soapRequestBody);
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }
    
    // Fetch the data from response    
    private static List<String> parseResponse(String responseBody, List<String> creditScores, List<String> errorMsgs, String recordId, 
                                              String firstName, String lastName) {
        String embeddedData;
        Integer embeddedDataLoopCount = 0;
        String creditScore = 'Null'; 
        Datetime gmtDateTime = null;
        Id contentVersionId;
        String status;
        String statusReportResult;
        String errorMessage;
        List<String> addressList = new List<String>();
        String address1 = '';
        String address2 = '';
        String address3 = '';
        Boolean firstResultsFound = false;
        
        XmlStreamReader reader = new XmlStreamReader(responseBody); 
        
		while (reader.hasNext()) {
            if (reader.getEventType() == XmlTag.START_ELEMENT && 'error' == reader.getLocalName()) {
                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'error')) {
                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'description') {
                        reader.next();
                        errorMsgs.add('%%%' + reader.getText());
                    }	
                    reader.next();
                }
                break;
            } else if (reader.getEventType() == XmlTag.START_ELEMENT && 'fileHitIndicator' == reader.getLocalName()) {
                while (reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.END_ELEMENT) {
                        break;
                    } else if (reader.getEventType() == XmlTag.CHARACTERS) {
                        status = reader.getText().toLowerCase();
                        if (status.equalsIgnoreCase('regularhit')) {
                            statusReportResult = 'Hit';
                        } else if (status.equalsIgnoreCase('regularnohit')) {
                            statusReportResult = 'No Hit';
                        } else if (status.equalsIgnoreCase('error')) {
                            statusReportResult = 'Error';
                        } else {
                            statusReportResult = 'Other';
                        }
                    }
                    reader.next();
                }
            } else if (reader.getEventType() == XmlTag.START_ELEMENT && 'results' == reader.getLocalName() && !firstResultsFound) {
                while (reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.END_ELEMENT) {
                        break;
                    } else if (reader.getEventType() == XmlTag.CHARACTERS) {
                        creditScore = reader.getText();
                        firstResultsFound = true; 
                    }
                    reader.next();
                }
            } else if (reader.getEventType() == XmlTag.START_ELEMENT && 'transactionTimeStamp' == reader.getLocalName() && gmtDateTime == null) {
                while (reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.END_ELEMENT) {
                        break;
                    } else if (reader.getEventType() == XmlTag.CHARACTERS) {
                    	gmtDateTime = (Datetime) JSON.deserialize('"' + reader.getText() + '"', Datetime.class);
                    }
                    reader.next();
                }
            } else if (reader.getEventType() == XmlTag.START_ELEMENT && 'address' == reader.getLocalName()) {
                String address = '';
                Boolean isAddressContent = false;
                while (reader.hasNext()) {
                    reader.next();
                    if (reader.getEventType() == XmlTag.END_ELEMENT && 'address' == reader.getLocalName()) {
                        addressList.add(address);
                        break;
                    } else if (reader.getEventType() == XmlTag.START_ELEMENT && ('street' == reader.getLocalName() || 'location' == reader.getLocalName())) {
                        isAddressContent = true;
                    } else if (reader.getEventType() == XmlTag.END_ELEMENT && ('street' == reader.getLocalName() || 'location' == reader.getLocalName())) {
                        isAddressContent = false;
                    } else if (reader.getEventType() == XmlTag.CHARACTERS && isAddressContent) {
                        address += reader.getText().trim() + ' ';
                    }
                }
            } else if (reader.getEventType() == XmlTag.START_ELEMENT && 'embeddedData' == reader.getLocalName() && embeddedData == null) {
                while (reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.END_ELEMENT) {
                        break;
                    } else if (reader.getEventType() == XmlTag.CHARACTERS) {
                        embeddedDataLoopCount++;
                        if (embeddedDataLoopCount == 1) {
                            embeddedData = reader.getText();
                        } else {
                            embeddedData = embeddedData + reader.getText();
                        }
                    }
                    reader.next();
                }
            }
            reader.next();
        }
        
        if (!addressList.isEmpty()) {
            address1 = addressList[0];
        }
                                                  
        if (addressList.size() >= 2) {
            address2 = addressList[1];
        }
                                                  
        if (addressList.size() >= 3) {
            address3 = addressList[2];
        }
                                                  
        if (embeddedData != null && recordId != null && creditScore != 'Null') {
            contentVersionId = savePDF(embeddedData, recordId, firstName, lastName, gmtDateTime);
        }
                                                  
        if (gmtDateTime != null) {  
            String transUnionResponse = 'errorMessage=' + errorMsgs + 'status=' + status + 'statusreportResult=' + statusReportResult + '###' + creditScore  + ',' + gmtDateTime + ',,' + contentVersionId + 'currentAddress=' + address1 + 'previousAddress1=' + address2 + 'previousAddress2=' + address3;
            creditScores.add(transUnionResponse); 
            return creditScores;
        } else {
            return errorMsgs;
        }
    }
    
    // Convert and save the PDF document 
    private static Id savePDF(String base64Data, String recordId, String firstName, String lastName, Datetime gmtDateTime) {
        Blob pdfBlob = EncodingUtil.base64Decode(base64Data);
        String formattedDate = gmtDateTime.format('mm/dd/yy');
        ContentVersion content = new ContentVersion();
        content.VersionData = pdfBlob;
        content.FirstPublishLocationId = recordId;
        content.Title = 'Credit_Report_' + firstName + '_' + lastName + '_' + formattedDate + '.pdf'; 
        content.PathOnClient = 'Credit_Report_' + firstName + '_' + lastName + '_' + formattedDate + '.pdf'; 
        try {
            insert content;
        } catch(Exception e) {
            System.debug('Error occurred while saving PDF file: ' + e.getMessage());
        }
        return content.Id;
    } 
}