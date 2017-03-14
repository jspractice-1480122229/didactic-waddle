var mydate = new Date()
// document.write("Dynamically created: " + mydate.toDateString() + " " + mydate.toTimeString() + "<br />");
// mydate.setDate(mydate.getDate() + 33); // add 33 days to the 'date' part
// document.write("After adding 33 days: " + mydate.toDateString() + " " + mydate.toTimeString());
// window.alert("Right now, it's " + mydate + ", ya know?");
var year = mydate.getFullYear()
// window.alert("The year is " + year);
// window.window.alert("Here is my message");
// document.write("<h1>Here is another message for you.</h1><p>New paragraph.</p>");
// window.window.alert(document.title);
// document.write(15 / 8);
// document.write("<p>Here is yet <em>another</em> message for you.</h1><p><em>Another</em> new paragraph.</p>");
// document.write(15 % 6);
// document.title = "NO TITLES";
function button () {
  window.alert('So you clicked, eh?')
};
function buttonReport (buttonId, buttonName, buttonValue) {
  var userMessage1 = 'Button id: ' + buttonId + '\n'
  var userMessage2 = 'Button name: ' + buttonName + '\n'
  var userMessage3 = 'Button value: ' + buttonValue
  window.alert(userMessage1 + userMessage2 + userMessage3)
}
