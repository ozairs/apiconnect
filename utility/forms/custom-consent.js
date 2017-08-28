// @ozair @spoon
var formPost5060 = '<html lang="en" xml:lang="en">' +
	'<head><title>Awesome Application requests your permission for...</title></head>' +
	'<body class="customconsent"><div><div>' +
	'<form method="post" enctype="application/x-www-form-urlencoded" action="authorize">' +
	'<AZ-INJECT-HIDDEN-INPUT-FIELDS/>' +
	'<p>Greeting..</p><DISPLAY-RESOURCE-OWNER/>' +
	'<p>This app </p><OAUTH-APPLICATION-NAME/><p> would like to access your data.</p>' +
	'<div>' +
	'<button class="cancel" type="submit" name="approve" value="false">No Thanks</button>' +
	'<button class="submit" type="submit" name="approve" value="true">Allow Access</button>' +
	'</div></form></div>' +
	'<AZ-INTERNAL-CUSTOM-FORM-ERROR/>' +
	'</div></body></html>';
session.output.write(formPost5060);
apim.output('text/html');
apim.setvariable('message.status.code', 200);