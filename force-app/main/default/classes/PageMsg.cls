public class PageMsg {
    public string str { get; set;}
    
    public void addPgMsg(){
        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,str));
    }
}