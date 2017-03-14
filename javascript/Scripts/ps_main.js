window.alert('Hello World!')

function lameJoke () {
  'use strict'
  var randomNumber = Math.round(Math.random() * 2)
  if (randomNumber === 1) {
    window.alert('How many tickles does it take to make an octopus laugh? Ten tickles.')
  } else if (randomNumber === 2) {
    window.alert('Why did the scarecrow win an award? Because he was outstanding in his field.')
  } else {
    window.alert('Why did the chicken cross the road? To get to the other side!')
  }
}

lameJoke()
