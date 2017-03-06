var rando = Math.round(Math.random() * 15)
// var rando = 15

if (rando % 3 === 0 && rando !== 0) {
  if (rando % 5 === 0) {
    window.alert('fizzbuzz')
  } else {
    window.alert('fizz')
  }
} else if (rando % 5 === 0 && rando !== 0) {
  window.alert('buzz')
} else {
  console.log(rando)
}
