public with sharing class AccountController {
    Public static List<account> getAllActiveAccounts(){
        return [Select ID, Name, Active__c from Account where Active__c ='Ýes'];
    }
}