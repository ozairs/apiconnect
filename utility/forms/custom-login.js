// @ozair @spoon
var form = '<html lang="en" xml:lang="en">' +
	'<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>Spoon Company</head>' +
	'<body>' +
	'<form method="POST" enctype="application/x-www-form-urlencoded" action="authorize">' +
	'<h1>Please sign in</h1>' +
	'<p>Username </p>' +
	'<p style="text-indent: 0em;"><input type="text" name="username" required="required"/></p>' +
	'<p>Password </p>' +
	'<p style="text-indent: 0em;"><input type="password" name="password" required="required"/></p>' +
	'<EI-INJECT-HIDDEN-INPUT-FIELDS/>' +
	'<p style="text-indent: 2em;"> <button id="login_button" type="submit" name="login" value="true">Log in</button></p>' +
	'<EI-LOGINFIRSTTIME><p>If you have forgotten your user name or password, contact your system administrator.</p></EI-LOGINFIRSTTIME>' +
	'<EI-LOGINFAILED><p style="color: red">At least one of your entries does not match our records. ' +
	'If you have forgotten your user name or password, contact your system administrator.</p></EI-LOGINFAILED>' +
	'<EI-INTERNAL-CUSTOM-FORM-ERROR/>' +
	'</form></body></html>';
session.output.write(form);
apim.output('text/html');
apim.setvariable('message.status.code', 200);


