"""ASGI path aliases for clients that omit the API version prefix."""


class PathAliasMiddleware:
    ALIASES = {
        "/responses": "/v1/responses",
        "/messages": "/v1/messages",
        "/anthropic/v1/messages": "/v1/messages",
    }

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http" and scope["path"] in self.ALIASES:
            scope = dict(scope)
            scope["path"] = self.ALIASES[scope["path"]]
            scope["raw_path"] = scope["path"].encode("ascii")
        await self.app(scope, receive, send)
