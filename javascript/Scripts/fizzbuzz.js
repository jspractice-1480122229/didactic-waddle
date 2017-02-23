var rando = Math.round(Math.random() * 15)
// var rando = 15

if (rando % 3 === 0 && rando != 0) {
  if (rando % 5 === 0) {
    alert('fizzbuzz')
  } else {
    alert("fizz")
  }
} else if (rando % 5 === 0 && rando != 0) {
  alert('buzz')
} else {
  console.log(rando)
}