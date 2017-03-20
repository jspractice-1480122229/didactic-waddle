var rando = Math.round(Math.random());
if (rando === 0) {
  document.open();
  document.writeln('  <link rel="stylesheet" type="text/css" href="css/site.css">');
  document.close();
} else if (rando === 1) {
  document.open();
  document.writeln('  <link rel="stylesheet" type="text/css" href="css/local-style.css">');
  document.close();
}
