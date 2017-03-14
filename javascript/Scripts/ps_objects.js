// var coffeeFlavor = 'espresso'
// var coffeeTemperature = 'piping hot'
// var coffeeOunces = 100
// var coffeMilk = true

var myCoffee = {
  flavor: 'espresso',
  temperature: 'piping hot',
  ounces: 100,
  milk: true,

  reheat: function () {
    if (myCoffee.temperature !== 'piping hot') {
      myCoffee.temperature = 'piping hot'
      window.alert('Your coffee has been reheated!')
    }
  }
}

myCoffee.temperature = 'cold'
myCoffee['temperature'] = 'lukewarm'

myCoffee.reheat()
