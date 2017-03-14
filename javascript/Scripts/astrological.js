var sign = window.prompt('What is your astrological sign?').toLowerCase()
window.alert('Sensing...sensing your future!')
switch (sign) {
  case 'taurus':
    window.alert('The full hamburger moon crosses your ruling planet. You will have a strong urge today to enjoy a meal around noon. You will either eat lunch or not eat lunch and be very hungry.')
    break
  case 'virgo':
    window.alert('I am two with nature.')
    break
  case 'leo':
    window.alert('Men use their wrong thoughts to justify their wrong doings, and speech only to conceal their thoughts.')
    break
  default:
    window.alert('Please enter a valid sign')
    break
}
