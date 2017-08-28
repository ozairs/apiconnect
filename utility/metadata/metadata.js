// @ozair @spoon
if (apim.getvariable('demo.authenticate-url.metainfo.4.token') !== '' &&
	apim.getvariable('demo.authenticate-url.metainfo.4.token') !== undefined) {
	apim.setvariable('message.headers.api-oauth-metadata-for-accesstoken', apim.getvariable('demo.authenticate-url.metainfo.4.token'));
}
if (apim.getvariable('demo.authenticate-url.metainfo.4.payload') !== '' &&
	apim.getvariable('demo.authenticate-url.metainfo.4.payload') !== undefined) {
	apim.setvariable('message.headers.api-oauth-metadata-for-payload', apim.getvariable('demo.authenticate-url.metainfo.4.payload'));
}
apim.setvariable('message.status.code', 200);