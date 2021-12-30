({
	onClickcheckboxHelper : function(cmp, evt) {
		console.log("this text is from helper function");
        var value = cmp.find("checkBox").get("v.checked");
        cmp.set("v.CheckBoxValue",value);
	}
})