({	doSubmit : function(component, event, helper) {
        var Value=component.get("v.Test");
        if(Value== "true"){
            alert("you made a right choice");
            component.set("v.Test","false");
        }
        
        else{
            alert("you made a wrong choice");
            component.set("v.Test","true");
        }
		
    },
   onClickCheckbox : function(Component,event,helper){
        //Call helper function
        console.log("this is text from controller");
        helper.onClickcheckboxHelper(Component,event);
    },
  addDetails: function(Component,event,helper){
      console.log("Add educational Details");
      var CurrentEducationaldetaillist=Component.get("v.EducationDetailsList");
      var currentsize= parseInt((CurrentEducationaldetaillist.length));
      var newsize=parseInt(currentsize.length) + 1;
      CurrentEducationaldetaillist.push(newsize);
      Component.set("v.EducationDetailsList",CurrentEducationaldetaillist);
  }
})