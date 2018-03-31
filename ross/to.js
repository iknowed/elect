<SCRIPT LANGUAGE="JavaScript">
timedouturl = "/elect/ross/phone.pl?ACTION=TIMEOUT&phid=PHID&voter_id=VOTER_ID&cmpid=CMPID";

function Minutes(data) {
for (var i = 0; i < data.length; i++)
if (data.substring(i, i + 1) == ":")
break;
return (data.substring(0, i));
}
function Seconds(data) {
for (var i = 0; i < data.length; i++)
if (data.substring(i, i + 1) == ":")
break;
return (data.substring(i + 1, data.length));
}
function Display(min, sec) {
var disp;
if (min <= 9) disp = " 0";
else disp = " ";
disp += min + ":";
if (sec <= 9) disp += "0" + sec;
else disp += sec; 
return (disp);
}
function Down() { 
sec--;      
if (sec == -1) { sec = 59; min--; }
document.timerform.clock.value = Display(min, sec);
window.status = "Session will time out in: " + Display(min, sec);
if (min == 0 && sec == 0) {
alert("Your session has timed out.");
window.location.href = timedouturl;
}
else down = setTimeout("Down()", 1000);
}
function timeIt() {
min = 1 * Minutes(document.timerform.clock.value);
sec = 0 + Seconds(document.timerform.clock.value);
Down();
}
//  End -->
</script>


