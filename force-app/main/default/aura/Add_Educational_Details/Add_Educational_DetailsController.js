({
    doinit: function(component, event, helper) {
      console.log("this text is from init funtion");
      //component.set("v.InstituteName","Jntu College of Engineering");
      //helper.helperDOchange(component, event);
    },
	deleteDetails : function(component, event, helper) {
		var Neweducationdetaillist=component.get("v.EducationDetailsListInnerComponent");
        var currentIndex=component.get("v.indexNo");
        if(currentIndex > -1)
        Neweducationdetaillist.splice(currentIndex,1);
        component.set("v.EducationDetailsListInnerComponent",Neweducationdetaillist);
	},
    dochange : function(component, event, helper) {
        console.log("this text is coming beacuse there is a change in iNdexNo");
        helper.helperDOchange(component, event);
    }
})