# MortalDrinksElixir

Elixir-implementation for `GodDrinksJava` in Mili's `World.execute(me);`.

## Inspiration

* self experience and trauma
    * < https://ges233.github.io/2024/06/World-execute-me-lyrics-analyse/ >
* PV in other languages and format

## Usage

### Installation

Install [elixir](https://elixir-lang.org/install.html).

*If it's the first time that you installed elixir, don't forget install hex.*

```sh
mix local.hex
```

Then you can download the repo and install denpendencies.

```sh
# Get code
git clone https://github.com/GES233/MortalDrinksElixir.git
# Fetch resources
mix deps.get
mix deps.compile
# Compile
mix compile
# Assets management
mix esbuild.install
mix esbuild mord_ex
```

### Run

Simply:

```sh
mix run --no-halt
```

and open the browser to see PV.

