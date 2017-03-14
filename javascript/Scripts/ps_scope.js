var three = '3'

function alertNumber () {
  var one = '1'
  alert(one)

  function alertAnotherNumber () {
    var two = '2'
    alert(two)
    alert(three)
    alert(one)
  }

  alertAnotherNumber()
  alert(two)
}

alertNumber()
