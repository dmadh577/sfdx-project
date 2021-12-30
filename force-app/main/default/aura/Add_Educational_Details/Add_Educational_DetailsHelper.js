({
	helperDOchange : function(Component,event) {
		var New=Component.get("indexNo");
        var test= parseInt(New)+1;
        Component.set("sequenceNo",test);
	}
})