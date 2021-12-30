trigger ContractTrigger on Contact (before Insert, before update, before Delete) {
     /*for(contact con: Trigger.New){
       con.Description ='Description is updating from a trigger event';
    }*/
    if(Trigger.IsInsert && Trigger.IsBefore){
        ContactTriggerHandler.BeforeInsert(Trigger.New);
    }
    if(Trigger.IsUpdate && Trigger.IsBefore){
        ContactTriggerHandler.BeforeUpdate(Trigger.New);
    }
    if(Trigger.IsBefore && Trigger.IsDelete){
        ContactTriggerHandler.BeforeDelete(Trigger.New);
    }
}