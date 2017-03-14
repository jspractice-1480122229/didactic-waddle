window.alert('It is the zombie apocalypse. You are looting a store and suddenly a zombie bursts through the door!');
var weapon = window.prompt('You search around frantically for a weapon. What do you choose? Bow and arrow, an axe or a rubber chicken?');
var rando = Math.round(Math.random());
window.alert('You attack with the zombie your ' + weapon + '.');
if (rando === 0) {
	window.alert('The zombie bites you. You lose!!!')
} else if (rando === 1) {
	window.alert('You kill the zombie with your ' + weapon + '. You WIN!!!')
}
