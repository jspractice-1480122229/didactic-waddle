var rando = Math.round(Math.random());
if (rando === 0) {
  document.open();
  document.writeln('  <link rel="stylesheet" type="text/css" href="css/site0.css">');
  document.close();
} else if (rando === 1) {
  document.open();
  document.writeln('  <link rel="stylesheet" type="text/css" href="css/site1.css">');
  document.close();
}
