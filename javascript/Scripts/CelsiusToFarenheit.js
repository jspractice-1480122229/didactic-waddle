function CtoF () {
  var cTemp = 21  // temperature in Celsius
// Let's be generous with parentheses
  var fTemp = ((cTemp * 9) / 5) + 32
  return 'Temperature in Celsius: ' + cTemp + ' ' + 'degrees.' + '\nTemperature in Fahrenheit: ' + fTemp + ' ' + 'degrees.'
}
var message = CtoF()
window.window.alert(message)
