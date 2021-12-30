Public class ContactTriggerHandler {
    public static void BeforeInsert(List<contact> con){
        for (Contact cont : con){
            cont.Description ='Descrption updated succesfully from  trgger before insert';
        }
    }
    Public static void BeforeUpdate(List<contact> con ){
        for(contact cnt : con){
            cnt.Description ='Descrption updated succesfully from  trgger before updated by  '+ UserInfo.getFirstName();
        }
    }
    Public Static Void BeforeDelete(List<contact> con){
        for (contact cn : con){
        if(cn.Name != null){
             cn.adderror('you can not delete any contact');       
        }
        
        }
    }
}