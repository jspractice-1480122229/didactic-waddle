var mark = {
  name: 'Mark',
  tshirtColor: 'navy blue'
}

var lisa = {
  name: 'Lisa',
  tshirtColor: 'red'
}

function Friend (name, tshirtColor) {
  this.name = name
  this.tshirtColor = tshirtColor
}

var denny = new Friend('Denny', 'green')

window.alert(denny.name)
