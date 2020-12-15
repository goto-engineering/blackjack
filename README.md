# Blackjack

A Blackjack implementation written in [Janet](https://janet-lang.org/). Runs in the command line.

## Install

1. Install Janet per the [instructions](https://janet-lang.org/docs/index.html).
2. Clone this repo
3. Run `jpm deps` to install dependencies to your Janet path
4. Run `janet blackjack.janet` to run in interpreted mode

## Build

Run `jpm build` to build the binary. You can run it, install it to your Janet bin path with `jpm install`, and copy it wherever you like otherwise (e.g. `/usr/local/bin`).

## Notes

Cancel on any prompt with `Ctrl-C`.

Dealer stands on soft 17 and Blackjack pays 3-to-2.

You can set autobetting if you don't care about entering a wager amount every hand. When asked for your betting amount, type `autobet 5` to set $5 as the automatic betting amount. You can later cancel your autobet by typing `c` when asked for your move.

Flags are explained by running with `--help`.

## Known issues

1. Soft hands aren't always calculated correctly.
2. Splitting is currently not implemented.
3. No insurance.
4. Burn card is missing after shuffle.
5. Can't adjust Blackjack pay, fixed at 3-to-2.
6. Can't configure dealer to hit on soft 17.
7. Dealer Blackjack vs. Player Blackjack should be a push - and maybe configurable.
