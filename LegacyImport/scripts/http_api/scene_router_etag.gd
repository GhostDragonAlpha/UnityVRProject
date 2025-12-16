extends SceneRouter
class_name SceneRouterETag

## Enhanced SceneRouter with ETag and conditional request support
## This extends the base SceneRouter to add caching capabilities

## Generate ETag for response data
static func generate_etag(data: Dictionary) -> String:
	var json_str = JSON.stringify(data)
	var hash_ctx = HashingContext.new()
	hash_ctx.start(HashingContext.HASH_SHA256)
	hash_ctx.update(json_str.to_utf8_buffer())
	var hash = hash_ctx.finish()
	return '"' + hash.hex_encode().substr(0, 16) + '"'
