# MortalDrinksElixir  
  
An Elixir implementation of `GodDrinksJava` from Mili's `World.execute(me);`.  
  
## Inspiration  
  
* Personal experiences and trauma  
    * < https://ges233.github.io/2024/06/World-execute-me-lyrics-analyse/ >  
* PVs (Music Videos) in other languages and formats created since 2019  
  
## Usage  
  
### Installation  
  
Install [Elixir](https://elixir-lang.org/install.html).  
  
*If this is your first time installing Elixir, don't forget to install Hex.*  
  
```sh  
mix local.hex  

Then, clone the repository and install dependencies.

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

## Designing and Architecture

### OverView

*(I will add a picture or screenshot here once finished.)*

### Role and Usage

#### Heart

Every creature can receive stimuli (events), react (action), and adapt to the environment (update state) to maintain homeostasis (avoid crashing).

So, we can simply abstract it into a state machine, consisting of two parts:

* running(interation with the environment)
* thinking(building a world model & let virtual "me" to interact)

In 2024, I thought this system could be represented homogeneously—meaning it could be perfectly demonstrated from cover to core using one paradigm.

I chose BEAM because it has OTP. I'm not good at Erlang or Gleam, so I selected Elixir.

I also know that Joe Armstrong, the co-creator of Erlang, studied Theoretical Physics. So, I consider this design paradigm a good model for the real world, including biological and cognitive systems.

But frankly speaking, the complexity was too high for me to implement at that time. So the project was suspended.

When I saw a new PV at the beginning of 2026, as I focused on Orchid (an orchestration engine) and QyEditor (a WebUI-based singing synthesizer interface, WIP).

A Eureka moment struck me: why can't I combine miniKanren and thought processes to make a virtual and lightweight (compared to an LLM's scale) intelligence?

The "real-world" part can be implemented by Elixir: such as the world being a `Supervisor`, "me" being a `GenServer` or `:gen_statem`, and "you"... just some virtual stuff can be explained by rules(maybe not).

Yep. It is comfirmed.

#### Lyrics interpretation

The source PV use Java, with a class name called `GodDrinksJava`. All lyrics can be paralleled to OOP statements easily.

But adding implementation behind the lyrics is EXTREMELY difficult in any single language.

In this polyglot version, lyrics are in Elixir and miniKanren (I like the original Scheme style).

In the virtual part (lines starting with "If I ..."), I use `run*` queries with multiple conditions. In the reality part ("You have left" etc., and execution), I use Elixir[^decode].

[^decode]: There're so many views to the song, this is just one version.

#### Front-end

At the beginning, I wanted to use a terminal UI, but I am not good at TUI or ASCII art. So I selected WebUI. I started learning it in 2022 because I was removed from a small group and wanted to build my own site to become a site owner.

That origin idea was naïve. But I'm motivated.

So here's the reason why I use phoenix without `mix phx.new`.
