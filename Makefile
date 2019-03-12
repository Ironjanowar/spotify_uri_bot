MIX_ENV?=dev

deps:
	mix deps.get
	mix deps.compile
compile: deps
	mix compile

token:
export BOT_TOKEN = $(shell cat bot.token)
export CLIENT_TOKEN = $(shell cat client.token)

run: token
	mix run --no-halt

iex: token
	iex -S mix

clean:
	rm -rf _build

purge: clean
	rm -rf deps
	rm mix.lock

.PHONY: deps compile release run clean purge token iex
