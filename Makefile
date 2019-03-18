MIX_ENV?=dev

deps:
	mix deps.get
	mix deps.compile
compile: deps
	mix compile

token:
export BOT_TOKEN = $(shell cat bot.token)
export CLIENT_TOKEN = $(shell cat client.token)

start: token
	_build/dev/rel/spotify_uri_bot/bin/spotify_uri_bot start

iex: token
	iex -S mix

clean:
	rm -rf _build

purge: clean
	rm -rf deps
	rm mix.lock

stop:
	_build/dev/rel/spotify_uri_bot/bin/spotify_uri_bot stop

attach:
	_build/dev/rel/spotify_uri_bot/bin/spotify_uri_bot attach

release: deps compile
	mix release

debug: token
	_build/dev/rel/spotify_uri_bot/bin/spotify_uri_bot console

.PHONY: deps compile release start clean purge token iex stop attach debug
